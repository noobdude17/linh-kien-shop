import 'package:flutter_test/flutter_test.dart';

import 'package:linh_kien_shop/data/mock_data.dart';

void main() {
  test('Mock fixtures sẵn sàng', () {
    expect(MockData.categories.length, 13);
    expect(MockData.featured.isNotEmpty, true);
    expect(MockData.featured.first.discountPercent, isNotNull);
  });
}
