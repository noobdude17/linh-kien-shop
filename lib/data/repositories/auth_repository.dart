import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';
import '../models/address_model.dart';
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
    String? address,
    String? dob,
  });

  Future<UserModel> signInWithGoogle();

  /// Bổ sung/cập nhật thông tin cá nhân. Trường nào null thì giữ nguyên.
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? dob,
  });

  Future<void> signOut();

  /// Xóa hẳn tài khoản (Auth + hồ sơ Firestore). Dùng để test lại từ đầu.
  Future<void> deleteAccount();
}

/// Gộp thông tin mới vào hồ sơ hiện tại; trường null hoặc rỗng thì giữ nguyên.
UserModel _merge(
    UserModel cur, String? name, String? phone, String? address, String? dob) {
  String? keep(String? v, String? old) =>
      (v == null || v.trim().isEmpty) ? old : v.trim();
  final mergedName = keep(name, cur.name) ?? '';
  final mergedPhone = keep(phone, cur.phone);
  final mergedAddress = keep(address, cur.address);
  return UserModel(
    id: cur.id,
    name: mergedName,
    email: cur.email,
    role: cur.role,
    phone: mergedPhone,
    address: mergedAddress,
    dob: keep(dob, cur.dob),
    // Chốt một lần: chỉ tạo địa chỉ giao hàng mặc định khi chưa có. Sửa hồ sơ
    // (đổi tên/SĐT) KHÔNG lan sang địa chỉ giao hàng.
    defaultAddress: cur.defaultAddress ??
        _defaultFrom(mergedName, mergedPhone, mergedAddress),
  );
}

/// Tạo địa chỉ giao hàng mặc định từ thông tin lúc tạo tài khoản (nếu có địa chỉ).
AddressModel? _defaultFrom(String name, String? phone, String? address) =>
    (address != null && address.isNotEmpty)
        ? AddressModel(
            id: 'default',
            name: name,
            phone: phone ?? '',
            detail: address,
            isDefault: true)
        : null;

/// Hiện thực Firebase Auth + lưu hồ sơ user vào Firestore `users`.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  // Một kênh duy nhất: vừa nhận đổi trạng thái Auth, vừa nhận cập nhật hồ sơ
  // (updateProfile/signUp) — nhờ vậy UI luôn đồng bộ với _cached.
  final _controller = StreamController<UserModel?>.broadcast();

  FirebaseAuthRepository(this._auth, this._db) {
    _auth.authStateChanges().listen((fbUser) async {
      if (fbUser == null) {
        _cached = null;
      } else if (_cached?.id != fbUser.uid) {
        // Chỉ tải khi chưa có hồ sơ cho uid này (vd: khôi phục phiên lúc mở app).
        // signIn/signUp/google tự set _cached trước → tránh ghi đè bằng fallback.
        _cached = await _loadOrCreateProfile(fbUser);
      }
      _resolved = true;
      _controller.add(_cached);
    });
  }

  UserModel? _cached;
  // Đã xác định trạng thái Auth lần đầu chưa (Firebase khôi phục phiên xong).
  bool _resolved = false;

  void _emit(UserModel? u) {
    _resolved = true;
    _cached = u;
    _controller.add(u);
  }

  @override
  UserModel? get currentUser => _cached;

  @override
  Stream<UserModel?> authStateChanges() async* {
    // Chưa resolve thì KHÔNG phát null sớm (tránh splash nhảy onboarding khi
    // đang khôi phục phiên). Subscriber muộn được replay giá trị hiện tại.
    if (_resolved) yield _cached;
    yield* _controller.stream;
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
    _emit(await _loadOrCreateProfile(cred.user!));
    return _cached!;
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? address,
    String? dob,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = UserModel(
      id: cred.user!.uid,
      name: name,
      email: email.trim(),
      role: AppConstants.roleCustomer,
      phone: phone,
      address: address,
      dob: dob,
      defaultAddress: _defaultFrom(name, phone, address?.trim()),
    );
    // Set _cached NGAY (đồng bộ) để listener authState bỏ qua, không ghi fallback.
    _emit(user);
    await _db
        .collection(AppConstants.colUsers)
        .doc(user.id)
        .set(user.toFirestore());
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
    _emit(await _loadOrCreateProfile(cred.user!));
    return _cached!;
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? dob,
  }) async {
    final updated = _merge(_cached!, name, phone, address, dob);
    await _db
        .collection(AppConstants.colUsers)
        .doc(updated.id)
        .set(updated.toFirestore(), SetOptions(merge: true));
    _emit(updated);
    return updated;
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut(); // listener authState sẽ phát null
  }

  @override
  Future<void> deleteAccount() async {
    final u = _auth.currentUser;
    if (u != null) {
      await _db.collection(AppConstants.colUsers).doc(u.uid).delete();
      // ponytail: có thể ném 'requires-recent-login' nếu phiên quá cũ —
      // đăng nhập lại rồi xóa. Khi test ngay sau đăng nhập thì không gặp.
      await u.delete();
    }
    await GoogleSignIn().signOut();
    _emit(null);
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
          role: AppConstants.roleCustomer,
          phone: '0900000000',
          address: 'Hà Nội'),
    ),
    'admin@lks.vn': (
      password: '123456',
      user: UserModel(
          id: 'mock-admin',
          name: 'Quản trị viên',
          email: 'admin@lks.vn',
          role: AppConstants.roleAdmin,
          phone: '0900000000',
          address: 'Hà Nội'),
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
    String? address,
    String? dob,
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
      address: address,
      dob: dob,
      defaultAddress: _defaultFrom(name, phone, address?.trim()),
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
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? dob,
  }) async {
    final updated = _merge(_current!, name, phone, address, dob);
    final key = updated.email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      _accounts[key] = (password: _accounts[key]!.password, user: updated);
    }
    _current = updated;
    _controller.add(_current);
    return updated;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final key = _current?.email.trim().toLowerCase();
    if (key != null) _accounts.remove(key);
    _current = null;
    _controller.add(null);
  }
}
