/// Cấu hình toàn cục.
///
/// [firebaseEnabled] được set ở runtime trong `main.dart`: bật TRUE khi
/// `Firebase.initializeApp` thành công (máy đã có `assets/config/firebase_config.json`),
/// ngược lại FALSE → app tự chạy bằng dữ liệu mẫu (Mock).
///
/// Nhờ vậy: máy của bạn (đã cấu hình Firebase) dùng backend thật;
/// thành viên chưa có file config vẫn chạy được ở chế độ mock — không cần sửa code.
class AppConfig {
  AppConfig._();

  /// Có dùng Firebase thật hay không. Do `main.dart` gán sau khi init.
  static bool firebaseEnabled = false;
}
