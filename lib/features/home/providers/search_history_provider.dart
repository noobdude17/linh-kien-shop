import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../product/providers/product_providers.dart';

class RecentSearchesNotifier extends Notifier<List<String>> {
  static const _max = 10;

  @override
  List<String> build() => [];

  void add(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    state = [q, ...state.where((s) => s != q)].take(_max).toList();
  }

  void remove(String query) {
    state = state.where((s) => s != query).toList();
  }

  void clear() => state = [];
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
        RecentSearchesNotifier.new);

/// Trending = brands + category names từ featured products.
final trendingSearchesProvider = FutureProvider<List<String>>((ref) async {
  final featured = await ref.watch(featuredProductsProvider.future);
  final brands = featured
      .map((p) => p.brand)
      .where((b) => b.isNotEmpty)
      .toSet();
  final categories = featured
      .map((p) => p.categoryName)
      .where((c) => c.isNotEmpty)
      .toSet();
  return {...brands, ...categories}.take(8).toList();
});
