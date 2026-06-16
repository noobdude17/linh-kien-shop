import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'customer' | 'admin'
  final String? address;
  final String? phone;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.address,
    this.phone,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      address: data['address'],
      phone: data['phone'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role,
        'address': address,
        'phone': phone,
      };
}
