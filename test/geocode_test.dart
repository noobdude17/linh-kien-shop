import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:linh_kien_shop/features/location/geocode.dart';

// ponytail: chỉ test nhánh không tầm thường — "rỗng = địa chỉ không hợp lệ".
void main() {
  test('kết quả rỗng → ném GeocodeException (chặn địa chỉ không hợp lệ)', () {
    expect(() => firstLocationOrThrow([]), throwsA(isA<GeocodeException>()));
  });

  test('có kết quả → trả toạ độ đầu tiên', () {
    final p = firstLocationOrThrow([
      Location(latitude: 16.0, longitude: 108.0, timestamp: DateTime(2024)),
    ]);
    expect(p.latitude, 16.0);
    expect(p.longitude, 108.0);
  });
}
