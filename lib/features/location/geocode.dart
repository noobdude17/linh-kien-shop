import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Lỗi geocoding "có thể đọc được" để màn hình hiển thị cho người dùng.
class GeocodeException implements Exception {
  final String message;
  GeocodeException(this.message);
  @override
  String toString() => message;
}

/// Plugin `geocoding` chỉ chạy trên Android/iOS — không có bản web.
bool get geocodingSupported => !kIsWeb;

// ponytail: cả app gọi geocoding QUA file này. Muốn hỗ trợ web thì chỉ cần đổi
// 2 hàm dưới sang gọi HTTP Nominatim (~15 dòng), không đụng UI.

/// Địa chỉ chữ → toạ độ. Đây CHÍNH LÀ bộ kiểm tra địa chỉ hợp lệ:
/// ném [GeocodeException] khi không tra được → màn hình bắt nhập lại.
Future<LatLng> forwardGeocode(String address) async {
  if (!geocodingSupported) {
    throw GeocodeException('Bản đồ chưa hỗ trợ trên nền web');
  }
  return firstLocationOrThrow(await geo.locationFromAddress(address));
}

/// Vị trí GPS hiện tại, hoặc null nếu không có quyền/không bật/lỗi.
Future<LatLng?> currentLatLng() async {
  if (kIsWeb) return null;
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return null; // ponytail: GPS là "nice-to-have", lỗi gì cũng rơi về mặc định
  }
}

/// Toạ độ → địa chỉ chữ. Trả '' khi không có kết quả (giữ text hiện tại).
Future<String> reverseGeocode(LatLng p) async {
  if (!geocodingSupported) return '';
  final marks = await geo.placemarkFromCoordinates(p.latitude, p.longitude);
  return marks.isEmpty ? '' : formatPlacemark(marks.first);
}

/// Hàm thuần (không gọi nền tảng) → test được nhánh "rỗng = không hợp lệ".
LatLng firstLocationOrThrow(List<geo.Location> results) {
  if (results.isEmpty) throw GeocodeException('Không tìm thấy địa chỉ');
  return LatLng(results.first.latitude, results.first.longitude);
}

/// Ghép Placemark thành chuỗi địa chỉ gọn, bỏ phần rỗng/trùng.
String formatPlacemark(geo.Placemark m) {
  final parts = <String?>[
    m.street,
    m.subAdministrativeArea,
    m.administrativeArea,
    m.country,
  ].where((s) => s != null && s.trim().isNotEmpty).map((s) => s!.trim());
  return parts.join(', ');
}
