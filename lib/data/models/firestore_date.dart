import 'package:cloud_firestore/cloud_firestore.dart';

/// Đọc createdAt/updatedAt từ Firestore khi dữ liệu không đồng nhất:
/// Timestamp (chuẩn), String ISO, hoặc int (epoch ms). Trả về now nếu hỏng.
DateTime parseFirestoreDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.now();
}
