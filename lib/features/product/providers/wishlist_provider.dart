import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/product_model.dart';

const _kWishlistKey = 'wishlist_ids';

class WishlistNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = Set<String>.from(prefs.getStringList(_kWishlistKey) ?? []);
  }

  Future<void> toggle(String productId) async {
    final next = Set<String>.from(state);
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kWishlistKey, state.toList());
  }

  bool contains(String productId) => state.contains(productId);
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, Set<String>>(WishlistNotifier.new);

final wishlistProductsProvider = Provider<List<ProductModel>>((ref) {
  final ids = ref.watch(wishlistProvider);
  if (ids.isEmpty) return [];
  final all = [...MockData.featured, ...MockData.gpuList];
  return all.where((p) => ids.contains(p.id)).toList();
});
