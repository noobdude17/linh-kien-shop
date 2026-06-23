import '../../../data/models/product_model.dart';

class PartCategorySpec {
  final String id;
  final String label;
  final bool multiple;

  const PartCategorySpec(this.id, this.label, {this.multiple = false});
}

const partPickerCategories = <PartCategorySpec>[
  PartCategorySpec('cpu', 'CPU'),
  PartCategorySpec('cooler', 'Tản nhiệt CPU'),
  PartCategorySpec('mainboard', 'Mainboard'),
  PartCategorySpec('ram', 'RAM', multiple: true),
  PartCategorySpec('storage', 'Ổ cứng', multiple: true),
  PartCategorySpec('gpu', 'Card đồ họa', multiple: true),
  PartCategorySpec('case', 'Vỏ máy'),
  PartCategorySpec('psu', 'Nguồn máy tính'),
  PartCategorySpec('os', 'Hệ điều hành'),
  PartCategorySpec('monitor', 'Màn hình', multiple: true),
  PartCategorySpec('keyboard', 'Bàn phím'),
  PartCategorySpec('mouse', 'Chuột'),
];

class PcBuildModel {
  final Map<String, List<ProductModel>> selections;

  const PcBuildModel({this.selections = const {}});

  List<ProductModel> items(String categoryId) =>
      selections[categoryId] ?? const [];

  ProductModel? single(String categoryId) {
    final values = items(categoryId);
    return values.isEmpty ? null : values.first;
  }

  Iterable<ProductModel> get allProducts => selections.values.expand((e) => e);

  double get totalPrice =>
      allProducts.fold(0, (total, product) => total + product.price);

  PcBuildModel select(
    String categoryId,
    ProductModel product, {
    required bool multiple,
  }) {
    final next = <String, List<ProductModel>>{
      for (final entry in selections.entries) entry.key: [...entry.value],
    };
    if (multiple) {
      final values = next.putIfAbsent(categoryId, () => []);
      if (!values.any((item) => item.id == product.id)) values.add(product);
    } else {
      next[categoryId] = [product];
    }
    return PcBuildModel(selections: next);
  }

  PcBuildModel remove(String categoryId, String productId) {
    final next = <String, List<ProductModel>>{
      for (final entry in selections.entries) entry.key: [...entry.value],
    };
    next[categoryId]?.removeWhere((item) => item.id == productId);
    if (next[categoryId]?.isEmpty ?? false) next.remove(categoryId);
    return PcBuildModel(selections: next);
  }
}
