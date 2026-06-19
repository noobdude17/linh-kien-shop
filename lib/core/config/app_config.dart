/// Cấu hình toàn cục để bật/tắt backend thật.
///
/// CÁCH BẬT FIREBASE (sau khi Lead chạy `flutterfire configure`):
///   đổi `useFirebase` = true → mọi repository tự chuyển từ Mock sang Firestore/Auth thật.
/// Để false → app chạy hoàn toàn bằng dữ liệu mẫu (không cần Firebase).
class AppConfig {
  AppConfig._();

  /// ⬇️ ĐỔI THÀNH true SAU KHI CẤU HÌNH FIREBASE XONG ⬇️
  static const bool useFirebase = false;
}
