import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product_model.dart';
import '../models/pc_build_model.dart';

class PcBuildNotifier extends Notifier<PcBuildModel> {
  @override
  PcBuildModel build() => const PcBuildModel();

  void select(PartCategorySpec category, ProductModel product) {
    state = state.select(category.id, product, multiple: category.multiple);
  }

  void remove(String categoryId, String productId) {
    state = state.remove(categoryId, productId);
  }

  void clear() => state = const PcBuildModel();
}

final pcBuildProvider = NotifierProvider<PcBuildNotifier, PcBuildModel>(
  PcBuildNotifier.new,
);

final partPickerScrollOffsetProvider = StateProvider<double>((ref) => 0);
