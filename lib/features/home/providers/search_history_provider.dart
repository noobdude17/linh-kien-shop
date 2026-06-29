import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../product/providers/product_providers.dart';

const _kSearchKey = 'recent_searches';
const _kSearchMax = 10;

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_kSearchKey) ?? [];
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    state = [q, ...state.where((s) => s != q)].take(_kSearchMax).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSearchKey, state);
  }

  Future<void> remove(String query) async {
    state = state.where((s) => s != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSearchKey, state);
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSearchKey);
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
      RecentSearchesNotifier.new,
    );

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
