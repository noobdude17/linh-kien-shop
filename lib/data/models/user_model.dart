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
  // Địa chỉ giao hàng mặc định — chốt MỘT LẦN lúc tạo tài khoản, sửa hồ sơ
  // không đụng tới.
  final AddressModel? defaultAddress;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.address,
    this.phone,
    this.dob,
    this.defaultAddress,
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
      defaultAddress: data['defaultAddress'] != null
          ? AddressModel.fromMap(
              'default', data['defaultAddress'] as Map<String, dynamic>)
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
}
