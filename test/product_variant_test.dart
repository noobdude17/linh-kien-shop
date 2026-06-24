import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/models/product_model.dart';
import 'package:linh_kien_shop/data/models/product_variant.dart';

void main() {
  test('variant attributes round-trip and override product configuration', () {
    const variant = ProductVariant(
      id: '32gb-2x16gb-6000',
      name: '32GB (2x16GB) · 6000MT/s',
      price: 2800000,
      stock: 7,
      attributes: {
        'ramCapacityGb': 32,
        'ramModuleCount': 2,
        'ramSlotsUsed': 2,
        'ramSpeedMhz': 6000,
      },
    );
    const product = ProductModel(
      id: 'crucial-pro-ddr5',
      name: 'Crucial Pro DDR5',
      price: 1600000,
      categoryId: 'ram',
      stock: 20,
      compatibility: {'ramMemoryType': 'DDR5'},
      variants: [variant],
    );

    final restored = ProductVariant.fromMap(variant.toMap());
    final selected = product.withVariant(restored);

    expect(restored.attributes['ramCapacityGb'], 32);
    expect(selected.id, 'crucial-pro-ddr5::32gb-2x16gb-6000');
    expect(selected.name, 'Crucial Pro DDR5');
    expect(selected.price, 2800000);
    expect(selected.stock, 7);
    expect(selected.compatibility['ramSpeedMhz'], 6000);
    expect(selected.specs['ramCapacityGb'], '32');
    expect(selected.variants, isEmpty);
  });
}
