import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../mock_data.dart';

class BrandModel {
  final String id;
  final String name;
  const BrandModel({required this.id, required this.name});
}

/// CRUD hãng (thương hiệu). Danh sách dùng chung cho form admin,
/// slider "Thương hiệu" ở tab danh mục. Filter/search theo hãng đọc trực tiếp
/// từ products nên hãng mới tự lan ra khi có sản phẩm gắn hãng đó.
abstract class BrandRepository {
  Future<List<BrandModel>> getAll();
  Future<void> add(String name);

  /// Đổi tên hãng và cập nhật luôn field `brand` của các sản phẩm đang dùng
  /// tên cũ (để danh mục/search/part-picker không lệch tên).
  Future<void> rename(String id, String newName);
  Future<void> delete(String id);
}

String brandSlug(String name) {
  final slug = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'brand-${DateTime.now().millisecondsSinceEpoch}' : slug;
}

class MockBrandRepository implements BrandRepository {
  final _brands = <BrandModel>[
    for (final (name, _) in MockData.brands)
      BrandModel(id: brandSlug(name), name: name),
  ];

  @override
  Future<List<BrandModel>> getAll() async =>
      _brands.toList()..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<void> add(String name) async {
    _brands.add(BrandModel(id: brandSlug(name), name: name.trim()));
  }

  @override
  Future<void> rename(String id, String newName) async {
    final i = _brands.indexWhere((b) => b.id == id);
    if (i >= 0) _brands[i] = BrandModel(id: id, name: newName.trim());
  }

  @override
  Future<void> delete(String id) async {
    _brands.removeWhere((b) => b.id == id);
  }
}

class FirestoreBrandRepository implements BrandRepository {
  final FirebaseFirestore _db;
  FirestoreBrandRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colBrands);

  @override
  Future<List<BrandModel>> getAll() async {
    final snap = await _col.orderBy('name').get();
    return snap.docs
        .map((d) => BrandModel(id: d.id, name: (d.data()['name'] ?? d.id) as String))
        .toList();
  }

  @override
  Future<void> add(String name) =>
      _col.doc(brandSlug(name)).set({'name': name.trim()});

  @override
  Future<void> rename(String id, String newName) async {
    final doc = await _col.doc(id).get();
    final oldName = (doc.data()?['name'] ?? '') as String;
    await _col.doc(id).set({'name': newName.trim()});
    if (oldName.isEmpty || oldName == newName.trim()) return;
    // ponytail: 1 batch (giới hạn 500 sản phẩm/hãng) — chia batch nếu vượt.
    final prods = await _db
        .collection(AppConstants.colProducts)
        .where('brand', isEqualTo: oldName)
        .get();
    final batch = _db.batch();
    for (final p in prods.docs) {
      batch.update(p.reference, {'brand': newName.trim()});
    }
    await batch.commit();
  }

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
