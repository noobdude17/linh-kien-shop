import 'package:flutter_test/flutter_test.dart';
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
}
