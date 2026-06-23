import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../mock_data.dart';
import '../models/address_model.dart';

/// CRUD địa chỉ giao hàng. Nguồn sự thật: subcollection `users/{uid}/addresses`.
abstract class AddressRepository {
  Stream<List<AddressModel>> watch(String uid);
  Future<void> add(String uid, AddressModel a);
  Future<void> update(String uid, AddressModel a);
  Future<void> delete(String uid, String id);
  Future<void> setDefault(String uid, String id);
}

class FirestoreAddressRepository implements AddressRepository {
  final FirebaseFirestore _db;
  FirestoreAddressRepository(this._db);

  CollectionReference<Map<String, dynamic>> _col(String uid) => _db
      .collection(AppConstants.colUsers)
      .doc(uid)
      .collection(AppConstants.colAddresses);

  @override
  Stream<List<AddressModel>> watch(String uid) =>
      _col(uid).snapshots().asyncMap((snap) async {
        if (snap.docs.isEmpty) return _seedFromEmbedded(uid);
        final list =
            snap.docs.map((d) => AddressModel.fromFirestore(d)).toList();
        list.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
        return list;
      });

  /// Tài khoản cũ/mock: subcollection rỗng nhưng có user.defaultAddress → seed 1 lần.
  Future<List<AddressModel>> _seedFromEmbedded(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    final def = doc.data()?['defaultAddress'];
    if (def is Map<String, dynamic>) {
      final seeded =
          AddressModel.fromMap('default', def).copyWith(isDefault: true);
      await _col(uid).doc('default').set(seeded.toFirestore());
      return [seeded];
    }
    return const [];
  }

  @override
  Future<void> add(String uid, AddressModel a) async {
    final ref = await _col(uid).add(a.toFirestore());
    if (a.isDefault) await _makeDefault(uid, ref.id, a);
  }

  @override
  Future<void> update(String uid, AddressModel a) async {
    await _col(uid).doc(a.id).set(a.toFirestore());
    if (a.isDefault) await _makeDefault(uid, a.id, a);
  }

  @override
  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();

  @override
  Future<void> setDefault(String uid, String id) async {
    final doc = await _col(uid).doc(id).get();
    if (doc.exists) await _makeDefault(uid, id, AddressModel.fromFirestore(doc));
  }

  /// Đặt [id] làm mặc định: gỡ cờ các địa chỉ khác + mirror vào user.defaultAddress.
  Future<void> _makeDefault(String uid, String id, AddressModel a) async {
    final all = await _col(uid).get();
    final batch = _db.batch();
    for (final d in all.docs) {
      batch.update(d.reference, {'isDefault': d.id == id});
    }
    await batch.commit();
    // ponytail: mirror giữ reader cũ (checkout/profile đọc user.defaultAddress)
    // chạy được; bỏ khi mọi reader đã chuyển sang subcollection.
    await _db.collection(AppConstants.colUsers).doc(uid).set(
      {'defaultAddress': a.copyWith(id: 'default', isDefault: true).toFirestore()},
      SetOptions(merge: true),
    );
  }
}

/// Mock in-memory (chế độ chưa bật Firebase). Seed từ [MockData.addresses] để demo.
class MockAddressRepository implements AddressRepository {
  final _store = <String, List<AddressModel>>{};
  final _ctrl = StreamController<void>.broadcast();

  List<AddressModel> _list(String uid) =>
      _store.putIfAbsent(uid, () => List.of(MockData.addresses));

  @override
  Stream<List<AddressModel>> watch(String uid) async* {
    yield _list(uid);
    yield* _ctrl.stream.map((_) => _list(uid));
  }

  @override
  Future<void> add(String uid, AddressModel a) async {
    final id = 'm${DateTime.now().millisecondsSinceEpoch}';
    _list(uid).add(a.copyWith(id: id));
    if (a.isDefault) _clearDefaultsExcept(uid, id);
    _ctrl.add(null);
  }

  @override
  Future<void> update(String uid, AddressModel a) async {
    final list = _list(uid);
    final i = list.indexWhere((e) => e.id == a.id);
    if (i >= 0) list[i] = a;
    if (a.isDefault) _clearDefaultsExcept(uid, a.id);
    _ctrl.add(null);
  }

  @override
  Future<void> delete(String uid, String id) async {
    _list(uid).removeWhere((e) => e.id == id);
    _ctrl.add(null);
  }

  @override
  Future<void> setDefault(String uid, String id) async {
    _clearDefaultsExcept(uid, id);
    _ctrl.add(null);
  }

  void _clearDefaultsExcept(String uid, String id) {
    final list = _list(uid);
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isDefault: list[i].id == id);
    }
    list.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
  }
}
