import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Hợp đồng xác thực. UI/provider phụ thuộc abstract này.
abstract class AuthRepository {
  /// Stream phát UserModel khi đăng nhập, null khi đăng xuất.
  Stream<UserModel?> authStateChanges();

  /// User hiện tại (đồng bộ) — dùng cho redirect router.
  UserModel? get currentUser;

  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> signOut();
}

/// Hiện thực Firebase Auth + lưu hồ sơ user vào Firestore `users`.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  FirebaseAuthRepository(this._auth, this._db);

  UserModel? _cached;

  @override
  UserModel? get currentUser => _cached;

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) {
        _cached = null;
        return null;
      }
      final doc =
          await _db.collection(AppConstants.colUsers).doc(fbUser.uid).get();
      _cached = doc.exists
          ? UserModel.fromFirestore(doc)
          : UserModel(
              id: fbUser.uid,
              name: fbUser.displayName ?? '',
              email: fbUser.email ?? '',
              role: AppConstants.roleCustomer,
            );
      return _cached;
    });
  }

  @override
  Future<UserModel> signIn(
      {required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    final doc =
        await _db.collection(AppConstants.colUsers).doc(cred.user!.uid).get();
    _cached = doc.exists
        ? UserModel.fromFirestore(doc)
        : UserModel(
            id: cred.user!.uid,
            name: '',
            email: email,
            role: AppConstants.roleCustomer);
    return _cached!;
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = UserModel(
      id: cred.user!.uid,
      name: name,
      email: email.trim(),
      role: AppConstants.roleCustomer,
      phone: phone,
    );
    await _db
        .collection(AppConstants.colUsers)
        .doc(user.id)
        .set(user.toFirestore());
    _cached = user;
    return user;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Hiện thực giả lập — cho phép chạy app & test luồng khi chưa bật Firebase.
/// Quy ước demo: email chứa "admin" sẽ được gán role admin.
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _current;

  @override
  UserModel? get currentUser => _current;

  @override
  Stream<UserModel?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<UserModel> signIn(
      {required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _current = UserModel(
      id: 'mock-uid',
      name: 'Người dùng',
      email: email,
      role: email.contains('admin')
          ? AppConstants.roleAdmin
          : AppConstants.roleCustomer,
    );
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _current = UserModel(
      id: 'mock-uid',
      name: name,
      email: email,
      role: AppConstants.roleCustomer,
      phone: phone,
    );
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}
