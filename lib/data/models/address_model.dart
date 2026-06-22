import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String detail; // địa chỉ đầy đủ
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.detail,
    this.isDefault = false,
  });

  factory AddressModel.fromFirestore(DocumentSnapshot doc) =>
      AddressModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  factory AddressModel.fromMap(String id, Map<String, dynamic> data) =>
      AddressModel(
        id: id,
        name: data['name'] ?? '',
        phone: data['phone'] ?? '',
        detail: data['detail'] ?? '',
        isDefault: data['isDefault'] ?? false,
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'detail': detail,
        'isDefault': isDefault,
      };
}
