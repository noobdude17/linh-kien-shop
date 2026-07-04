import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/models/product_model.dart';
import 'package:linh_kien_shop/data/repositories/product_repository.dart';

void main() {
  final repo = MockProductRepository();

  test('category keyword returns only that product group', () async {
    for (final entry in {'cpu': 'cpu', 'ram': 'ram', 'gpu': 'gpu'}.entries) {
      final results = await repo.search(entry.key);
      expect(results, isNotEmpty, reason: 'no results for "${entry.key}"');
      expect(
        results.every((p) => p.categoryId == entry.value),
        isTrue,
        reason: '"${entry.key}" leaked non-${entry.value} products',
      );
    }
  });

  test('no-diacritic Vietnamese aliases resolve to category', () async {
    for (final entry in {'vi xu ly': 'cpu', 'bo nho': 'ram'}.entries) {
      final results = await repo.search(entry.key);
      expect(results, isNotEmpty, reason: 'no results for "${entry.key}"');
      expect(
        results.every((p) => p.categoryId == entry.value),
        isTrue,
        reason: '"${entry.key}" should map to ${entry.value}',
      );
    }
  });

  test('non-category query still fuzzy-matches specs/name', () async {
    final results = await repo.search('ddr5');
    expect(results, isNotEmpty);
  });

  test('hardware shorthand matches storage, speed, and memory specs', () async {
    final twoTbResults = await repo.search('2tb');
    final mhzResults = await repo.search('6000mhz');
    final gddrResults = await repo.search('gddr6');

    expect(twoTbResults, isNotEmpty);
    expect(mhzResults, isNotEmpty);
    expect(gddrResults, isNotEmpty);
  });

  test('shared product matcher supports numeric compatibility aliases', () {
    const products = [
      ProductModel(
        id: 'ram-4000',
        name: 'Test DDR4 RAM',
        price: 1,
        categoryId: 'ram',
        compatibility: {'ramSpeedMhz': 4000},
      ),
      ProductModel(
        id: 'storage-4tb',
        name: 'Test NVMe Storage',
        price: 1,
        categoryId: 'storage',
        compatibility: {'storageCapacityGb': 4000},
      ),
    ];

    expect(matchesProductSearchQuery(products[0], '4000mhz'), isTrue);
    expect(matchesProductSearchQuery(products[1], '4tb'), isTrue);
  });
}
