import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

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

  Future<UserModel> signInWithGoogle();

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
      _cached = await _loadOrCreateProfile(fbUser);
      return _cached;
    });
  }

  Future<UserModel> _loadOrCreateProfile(fb.User fbUser) async {
    // Hồ sơ tạm dựng từ tài khoản auth — luôn dùng được kể cả khi Firestore lỗi.
    final fallback = UserModel(
      id: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
      role: AppConstants.roleCustomer,
    );
    // Đọc/ghi Firestore là TÙY CHỌN: nếu lỗi (rules/chưa bật/mạng) vẫn cho đăng nhập.
    try {
      final ref = _db.collection(AppConstants.colUsers).doc(fbUser.uid);
      final doc = await ref.get().timeout(const Duration(seconds: 5));
      if (doc.exists) return UserModel.fromFirestore(doc);
      await ref.set(fallback.toFirestore());
      return fallback;
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Bỏ qua lỗi Firestore hồ sơ user: $e');
      return fallback;
    }
  }

  @override
  Future<UserModel> signIn(
      {required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    _cached = await _loadOrCreateProfile(cred.user!);
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
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await GoogleSignIn(
      serverClientId: '605283360947-c5mniq9t6h5ij2glcrprq8eouu97n683.apps.googleusercontent.com',
    ).signIn();
    if (googleUser == null) {
      throw fb.FirebaseAuthException(
          code: 'cancelled', message: 'Đã hủy đăng nhập Google');
    }
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    _cached = await _loadOrCreateProfile(cred.user!);
    return _cached!;
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}

/// Hiện thực giả lập — chạy app khi chưa cấu hình Firebase.
///
/// Sửa bug "email bừa cũng đăng nhập": [signIn] kiểm tra với danh sách tài khoản
/// đã đăng ký (in-memory). Có sẵn 2 tài khoản demo để test ngay:
///   - khách:  demo@lks.vn  / 123456
///   - admin:  admin@lks.vn / 123456
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _current;

  // email -> (password, UserModel)
  final Map<String, ({String password, UserModel user})> _accounts = {
    'demo@lks.vn': (
      password: '123456',
      user: UserModel(
          id: 'mock-demo',
          name: 'Khách Demo',
          email: 'demo@lks.vn',
          role: AppConstants.roleCustomer),
    ),
    'admin@lks.vn': (
      password: '123456',
      user: UserModel(
          id: 'mock-admin',
          name: 'Quản trị viên',
          email: 'admin@lks.vn',
          role: AppConstants.roleAdmin),
    ),
  };

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
    final acc = _accounts[email.trim().toLowerCase()];
    if (acc == null) {
      throw fb.FirebaseAuthException(
          code: 'user-not-found', message: 'Tài khoản không tồn tại');
    }
    if (acc.password != password) {
      throw fb.FirebaseAuthException(
          code: 'wrong-password', message: 'Sai mật khẩu');
    }
    _current = acc.user;
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
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw fb.FirebaseAuthException(
          code: 'email-already-in-use', message: 'Email đã được dùng');
    }
    final user = UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email.trim(),
      role: AppConstants.roleCustomer,
      phone: phone,
    );
    _accounts[key] = (password: password, user: user);
    _current = user;
    _controller.add(_current);
    return user;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _current = const UserModel(
      id: 'mock-google',
      name: 'Google User',
      email: 'google.user@gmail.com',
      role: AppConstants.roleCustomer,
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
