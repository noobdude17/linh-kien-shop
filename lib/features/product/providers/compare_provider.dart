import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_model.dart';

const _kMaxCompare = 3;

class CompareNotifier extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() => [];

  void toggle(ProductModel product) {
    final idx = state.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      state = [...state]..removeAt(idx);
    } else if (state.length < _kMaxCompare &&
        (state.isEmpty || state.first.categoryId == product.categoryId)) {
      state = [...state, product];
    }
  }

  bool contains(String productId) => state.any((p) => p.id == productId);
  bool get atLimit => state.length >= _kMaxCompare;
  String? get categoryId => state.isEmpty ? null : state.first.categoryId;
  String? get categoryName => state.isEmpty ? null : state.first.categoryName;
  void clear() => state = [];
}

final compareProvider = NotifierProvider<CompareNotifier, List<ProductModel>>(
  CompareNotifier.new,
);
