import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String detail; // địa chỉ đầy đủ
  final bool isDefault;
  // Toạ độ đã xác nhận trên bản đồ. Null khi nhập tay (web/bản đồ lỗi).
  final double? latitude;
  final double? longitude;

  const AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.detail,
    this.isDefault = false,
    this.latitude,
    this.longitude,
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
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'detail': detail,
        'isDefault': isDefault,
        'latitude': latitude,
        'longitude': longitude,
      };

  AddressModel copyWith({String? id, bool? isDefault}) => AddressModel(
        id: id ?? this.id,
        name: name,
        phone: phone,
        detail: detail,
        isDefault: isDefault ?? this.isDefault,
        latitude: latitude,
        longitude: longitude,
      );
}
