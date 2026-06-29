import 'package:cloud_firestore/cloud_firestore.dart';

import 'address_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'customer' | 'admin'
  final String? address;
  final String? phone;
  final String? dob; // ngày sinh, dd/MM/yyyy
  // Ảnh đại diện. Firestore chỉ lưu URL ảnh tự tải lên (Cloudinary); avatar
  // Google đọc trực tiếp từ Auth lúc đăng nhập, KHÔNG lưu (xem auth_repository).
  final String? photoUrl;
  // Địa chỉ giao hàng mặc định — chốt MỘT LẦN lúc tạo tài khoản, sửa hồ sơ
  // không đụng tới.
  final AddressModel? defaultAddress;
  // Email đã xác nhận chưa. Mặc định true để Mock/Google/admin không bị chặn;
  // chỉ tài khoản đăng ký bằng email (Firebase) mới khởi đầu ở false.
  final bool emailVerified;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.address,
    this.phone,
    this.dob,
    this.photoUrl,
    this.defaultAddress,
    this.emailVerified = true,
  });

  bool get isAdmin => role == 'admin';

  /// Hồ sơ đủ thông tin? (phone + address bắt buộc). Dùng để buộc người dùng
  /// đăng nhập Google bổ sung thông tin — kể cả khi đóng app giữa chừng.
  bool get profileComplete =>
      (phone?.trim().isNotEmpty ?? false) &&
      (address?.trim().isNotEmpty ?? false);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      address: data['address'],
      phone: data['phone'],
      dob: data['dob'],
      photoUrl: data['photoUrl'],
      defaultAddress: data['defaultAddress'] != null
          ? AddressModel.fromMap(
              'default',
              data['defaultAddress'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'role': role,
    'address': address,
    'phone': phone,
    'dob': dob,
    'defaultAddress': defaultAddress?.toFirestore(),
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? dob,
    String? photoUrl,
    AddressModel? defaultAddress,
    bool? emailVerified,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email,
    role: role,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    dob: dob ?? this.dob,
    photoUrl: photoUrl ?? this.photoUrl,
    defaultAddress: defaultAddress ?? this.defaultAddress,
    emailVerified: emailVerified ?? this.emailVerified,
  );
}
