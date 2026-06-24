import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/product_model.dart';
import '../../product/providers/product_providers.dart';

const _kRecentKey = 'recently_viewed';
const _kRecentMax = 10;

class RecentlyViewedNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_kRecentKey) ?? [];
  }

  Future<void> add(String productId) async {
    final next = [productId, ...state.where((id) => id != productId)]
        .take(_kRecentMax)
        .toList();
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kRecentKey, state);
  }

  void clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentKey);
  }
}

final recentlyViewedProvider =
    NotifierProvider<RecentlyViewedNotifier, List<String>>(
        RecentlyViewedNotifier.new);

final recentlyViewedProductsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final ids = ref.watch(recentlyViewedProvider);
  if (ids.isEmpty) return [];
  final repo = ref.watch(productRepositoryProvider);
  // Giữ thứ tự MRU: Future.wait theo thứ tự id đầu vào.
  final products = await Future.wait(ids.map(repo.getById));
  return products.whereType<ProductModel>().toList();
});
