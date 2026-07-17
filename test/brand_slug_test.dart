import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/repositories/brand_repository.dart';

void main() {
  test('brandSlug chuẩn hóa tên hãng thành doc id', () {
    expect(brandSlug('G.SKILL'), 'g-skill');
    expect(brandSlug('Crucial / Micron'), 'crucial-micron');
    expect(brandSlug('  ASUS  '), 'asus');
    expect(brandSlug('///'), startsWith('brand-')); // tên rỗng sau khi lọc
  });
}
