import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../mock_data.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../product_listing_adapter.dart';

/// Query keywords that mean "show me this whole product group". When a query
/// resolves to a category, we match by categoryId instead of fuzzy spec text —
/// otherwise "cpu" also drags in coolers/mainboards whose specs mention "CPU".
const _categoryAliases = <String, String>{
  'cpu': 'cpu', 'processor': 'cpu', 'vi xử lý': 'cpu', 'chip': 'cpu',
  'ram': 'ram', 'memory': 'ram', 'bộ nhớ': 'ram', 'ddr': 'ram',
  'gpu': 'gpu', 'vga': 'gpu', 'card đồ họa': 'gpu', 'graphics': 'gpu',
  'storage': 'storage', 'ssd': 'storage', 'hdd': 'storage', 'nvme': 'storage',
  'ổ cứng': 'storage', 'lưu trữ': 'storage',
  'mainboard': 'mainboard', 'motherboard': 'mainboard', 'bo mạch': 'mainboard',
  'main': 'mainboard',
  'psu': 'psu', 'nguồn': 'psu', 'power supply': 'psu',
  'cooler': 'cooler', 'tản nhiệt': 'cooler', 'tản': 'cooler',
  'laptop': 'laptop',
  'monitor': 'monitor', 'màn hình': 'monitor',
  'keyboard': 'keyboard', 'bàn phím': 'keyboard',
  'mouse': 'mouse', 'chuột': 'mouse',
  'case': 'case', 'vỏ máy': 'case', 'thùng máy': 'case',
  'accessory': 'accessory', 'phụ kiện': 'accessory',
};

/// Strips Vietnamese diacritics so "màn hình" and "man hinh" both resolve.
String _stripDiacritics(String s) {
  const from = 'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệ'
      'ìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ';
  const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeee'
      'iiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final buffer = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i == -1 ? ch : to[i]);
  }
  return buffer.toString();
}

/// Alias lookup keyed by diacritic-stripped text, so "nguon", "man hinh",
/// "o cung" resolve the same as their accented forms.
final _normalizedCategoryAliases = {
  for (final e in _categoryAliases.entries) _stripDiacritics(e.key): e.value,
};

/// Returns true if all whitespace-separated tokens in [query] appear in at
/// least one of: name, brand, categoryName, or any specs key/value.
/// Handles queries like "16gb ram", "ddr5", "am4", "1tb", "6000mhz".
bool matchesProductSearchQuery(ProductModel p, String query) {
  final q = query.toLowerCase().trim();
  final categoryId = _normalizedCategoryAliases[_stripDiacritics(q)];
  if (categoryId != null) return p.categoryId.toLowerCase() == categoryId;

  final normalizedQuery = normalizeProductSearch(query);
  if (normalizedQuery.isEmpty) return false;
  final text = productSearchText(p);
  if (text.contains(normalizedQuery)) return true;

  final compactText = text.replaceAll(' ', '');
  final compactQuery = normalizedQuery.replaceAll(' ', '');
  if (compactQuery.isNotEmpty && compactText.contains(compactQuery)) {
    return true;
  }

  final tokens = normalizedQuery
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return false;
  return tokens.every(
    (token) => text.contains(token) || compactText.contains(token),
  );
}

int productSearchScore(ProductModel product, String query) {
  final normalizedQuery = normalizeProductSearch(query);
  if (normalizedQuery.isEmpty) return 0;
  final text = productSearchText(product);
  final compactText = text.replaceAll(' ', '');
  final compactQuery = normalizedQuery.replaceAll(' ', '');
  var score = 0;

  if (text.contains(normalizedQuery)) score += 80;
  if (compactQuery.isNotEmpty && compactText.contains(compactQuery)) {
    score += 100;
  }
  if (product.name.toLowerCase().contains(query.toLowerCase().trim())) {
    score += 120;
  }

  final queryNumbers = _numbersFromText(normalizedQuery);
  for (final number in queryNumbers) {
    if (_productHasExactNumber(product, number)) score += 240;
  }

  final tokens = normalizedQuery
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList();
  for (final token in tokens) {
    if (text.contains(token)) score += 12;
    if (compactText.contains(token)) score += 16;
  }

  return score;
}

String productSearchText(ProductModel product) {
  final parts = <String>[
    product.name,
    product.brand,
    product.categoryId,
    product.categoryName,
    product.imageLabel,
    ..._categorySearchAliases(product.categoryId),
    ...product.specs.keys,
    ...product.specs.values,
    ...product.compatibility.keys,
    ...product.compatibility.values.map(_searchValue),
    ..._compatibilitySearchAliases(product.compatibility),
  ];
  for (final variant in product.variants) {
    parts
      ..add(variant.id)
      ..add(variant.name)
      ..addAll(variant.attributes.keys)
      ..addAll(variant.attributes.values.map(_searchValue))
      ..addAll(_compatibilitySearchAliases(variant.attributes));
  }
  return normalizeProductSearch(parts.join(' '));
}

String normalizeProductSearch(String value) {
  return _stripDiacritics(value.toLowerCase())
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> _categorySearchAliases(String categoryId) => switch (categoryId) {
  'cpu' => ['processor', 'vi xu ly', 'bo xu ly'],
  'mainboard' => ['motherboard', 'main', 'bo mach chu', 'socket'],
  'ram' => ['memory', 'bo nho', 'ddr', 'gb ram'],
  'storage' => ['ssd', 'hdd', 'o cung', 'nvme', 'm2', 'tb', 'gb'],
  'gpu' => ['graphics card', 'vga', 'card man hinh', 'vram'],
  'psu' => ['power supply', 'nguon', 'watt', 'watts', 'w'],
  'case' => ['vo may', 'thung may', 'atx', 'micro atx', 'mini itx'],
  'cooler' => ['tan nhiet', 'aio', 'air cooler', 'radiator'],
  'monitor' => ['man hinh', 'hz', 'inch'],
  'keyboard' => ['ban phim'],
  'mouse' => ['chuot', 'dpi'],
  _ => const [],
};

List<String> _compatibilitySearchAliases(Map<String, dynamic> data) {
  final aliases = <String>[];

  void addCapacityAliases(Object? value, {required String unitContext}) {
    final number = _numberFromValue(value);
    if (number == null) return;
    aliases.add('${_formatSearchNumber(number)}gb');
    aliases.add('${_formatSearchNumber(number)} gb');
    aliases.add('${_formatSearchNumber(number)}gb $unitContext');
    if (number >= 1000) {
      final tb = number / 1000;
      aliases.add('${_formatSearchNumber(tb)}tb');
      aliases.add('${_formatSearchNumber(tb)} tb');
      aliases.add('${_formatSearchNumber(tb)}tb $unitContext');
    }
  }

  void addSpeedAliases(Object? value) {
    final number = _numberFromValue(value);
    if (number == null) return;
    aliases.add('${_formatSearchNumber(number)}mhz');
    aliases.add('${_formatSearchNumber(number)} mhz');
    aliases.add('${_formatSearchNumber(number)} mt s');
    aliases.add('${_formatSearchNumber(number)}mts');
  }

  void addWattAliases(Object? value) {
    final number = _numberFromValue(value);
    if (number == null) return;
    aliases.add('${_formatSearchNumber(number)}w');
    aliases.add('${_formatSearchNumber(number)} w');
    aliases.add('${_formatSearchNumber(number)}watt');
    aliases.add('${_formatSearchNumber(number)} watts');
  }

  addCapacityAliases(data['ramCapacityGb'], unitContext: 'ram');
  addCapacityAliases(data['gpuVramGb'], unitContext: 'vram');
  addCapacityAliases(data['storageCapacityGb'], unitContext: 'storage');
  addSpeedAliases(data['ramSpeedMhz']);
  addWattAliases(data['psuWattage']);
  addWattAliases(data['gpuPowerWatts']);
  addWattAliases(data['estimatedPowerWatts']);

  final memoryType = _searchValue(data['ramMemoryType']);
  if (memoryType.isNotEmpty) {
    aliases.add(memoryType);
    aliases.add(memoryType.replaceAll(' ', ''));
  }

  final socket = _searchValue(data['cpuSocket'] ?? data['mbSocket']);
  if (socket.isNotEmpty) aliases.add(socket.replaceAll(' ', ''));

  final storageInterface = _searchValue(data['storageInterface']);
  if (storageInterface.isNotEmpty) {
    aliases.add(storageInterface);
    aliases.add(storageInterface.replaceAll('.', ''));
    aliases.add(storageInterface.replaceAll(' ', ''));
  }

  return aliases;
}

bool _productHasExactNumber(ProductModel product, num queryNumber) {
  final dataMaps = <Map<String, dynamic>>[
    product.compatibility,
    if (!product.id.contains(productListingVariantSeparator))
      for (final variant in product.variants) variant.attributes,
  ];
  for (final data in dataMaps) {
    final relevantValues = [
      data['ramCapacityGb'],
      data['ramSpeedMhz'],
      data['storageCapacityGb'],
      data['gpuVramGb'],
      data['psuWattage'],
    ];
    for (final value in relevantValues) {
      final number = _numberFromValue(value);
      if (number == null) continue;
      if (_sameSearchNumber(number, queryNumber)) return true;
      if (number >= 1000 && _sameSearchNumber(number / 1000, queryNumber)) {
        return true;
      }
    }
  }
  return false;
}

bool _sameSearchNumber(num a, num b) => (a - b).abs() < 0.001;

List<num> _numbersFromText(String value) {
  return RegExp(r'\d+(?:\.\d+)?')
      .allMatches(value)
      .map((match) => num.tryParse(match.group(0)!))
      .whereType<num>()
      .toList();
}

num? _numberFromValue(Object? value) {
  if (value is num) return value;
  final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(_searchValue(value));
  return match == null ? null : num.tryParse(match.group(0)!);
}

String _searchValue(Object? value) {
  if (value == null) return '';
  if (value is Iterable) return value.map(_searchValue).join(' ');
  return '$value';
}

String _formatSearchNumber(num value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}

/// Hợp đồng truy xuất sản phẩm. UI/provider phụ thuộc vào abstract này,
/// không phụ thuộc Firestore trực tiếp → dễ test & thay nguồn dữ liệu.
abstract class ProductRepository {
  Future<List<ProductModel>> getFeatured();
  Future<List<ProductModel>> getByCategory(String? categoryId);
  Future<ProductPage> getByCategoryPage(
    String? categoryId, {
    required int limit,
    Object? cursor,
  });
  Future<ProductModel?> getById(String id);
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> search(String query);
  Future<ProductPage> searchPage(
    String query, {
    required int limit,
    Object? cursor,
  });
}

class ProductPage {
  final List<ProductModel> items;
  final Object? cursor;
  final bool hasMore;

  const ProductPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });
}

/// Hiện thực bằng dữ liệu mẫu — dùng cho skeleton & test khi chưa có backend.
class MockProductRepository implements ProductRepository {
  static const _featuredCategoryIds = ['gpu', 'cpu', 'ram', 'storage'];

  Future<T> _delayed<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 300), () => value);

  @override
  Future<List<ProductModel>> getFeatured() {
    final products =
        [
            ...MockData.featured,
            ...MockData.gpuList,
          ].where((p) => _featuredCategoryIds.contains(p.categoryId)).toList()
          ..sort((a, b) {
            final price = b.price.compareTo(a.price);
            if (price != 0) return price;
            return b.rating.compareTo(a.rating);
          });
    return _delayed(expandProductsForListing(products).take(12).toList());
  }

  @override
  Future<List<ProductModel>> getByCategory(String? categoryId) {
    final all = [...MockData.featured, ...MockData.gpuList];
    final filtered = categoryId == null
        ? all
        : all.where((p) => p.categoryId == categoryId).toList();
    return _delayed(expandProductsForListing(filtered));
  }

  @override
  Future<ProductPage> getByCategoryPage(
    String? categoryId, {
    required int limit,
    Object? cursor,
  }) async {
    final all = await getByCategory(categoryId);
    final start = cursor is int ? cursor : 0;
    final end = (start + limit).clamp(0, all.length);
    return ProductPage(
      items: all.sublist(start, end),
      cursor: end,
      hasMore: end < all.length,
    );
  }

  @override
  Future<ProductModel?> getById(String id) {
    final all = [...MockData.featured, ...MockData.gpuList];
    final realId = realProductId(id);
    final found = all.where((p) => p.id == realId).toList();
    return _delayed(
      found.isEmpty ? null : formatProductForRouteId(found.first, id),
    );
  }

  @override
  Future<List<CategoryModel>> getCategories() => _delayed(MockData.categories);

  @override
  Future<List<ProductModel>> search(String query) {
    final all = [...MockData.featured, ...MockData.gpuList];
    return _delayed(
      expandProductsForListing(all)
          .where((p) => matchesProductSearchQuery(p, query))
          .toList(),
    );
  }

  @override
  Future<ProductPage> searchPage(
    String query, {
    required int limit,
    Object? cursor,
  }) async {
    final all = await search(query);
    final start = cursor is int ? cursor : 0;
    final end = (start + limit).clamp(0, all.length);
    return ProductPage(
      items: all.sublist(start, end),
      cursor: end,
      hasMore: end < all.length,
    );
  }
}

/// Hiện thực bằng Firestore — bật khi đã cấu hình Firebase.
class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _db;
  FirestoreProductRepository(this._db);

  static const _featuredCategoryIds = ['gpu', 'cpu', 'ram', 'storage'];
  static const _featuredCategoryWeight = {
    'gpu': 0,
    'cpu': 1,
    'ram': 2,
    'storage': 3,
  };

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colProducts);

  @override
  Future<List<ProductModel>> getFeatured() async {
    final groups = await Future.wait(
      _featuredCategoryIds.map((categoryId) async {
        final snap = await _col
            .where('isActive', isEqualTo: true)
            .where('categoryId', isEqualTo: categoryId)
            .get(const GetOptions(source: Source.server));
        final products = snap.docs.map(ProductModel.fromFirestore).toList()
          ..sort(_compareFeaturedByPrice);
        return products.take(3);
      }),
    );

    final products = groups.expand((items) => items).toList()
      ..sort(_compareFeatured);
    return expandProductsForListing(products).take(12).toList();
  }

  int _compareFeaturedByPrice(ProductModel a, ProductModel b) {
    final price = b.price.compareTo(a.price);
    if (price != 0) return price;
    final rating = b.rating.compareTo(a.rating);
    if (rating != 0) return rating;
    return a.name.compareTo(b.name);
  }

  int _compareFeatured(ProductModel a, ProductModel b) {
    final category = (_featuredCategoryWeight[a.categoryId] ?? 99).compareTo(
      _featuredCategoryWeight[b.categoryId] ?? 99,
    );
    if (category != 0) return category;
    return _compareFeaturedByPrice(a, b);
  }

  @override
  Future<List<ProductModel>> getByCategory(String? categoryId) async {
    Query<Map<String, dynamic>> q = _col.where('isActive', isEqualTo: true);
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    final snap = await q.get(const GetOptions(source: Source.server));
    return expandProductsForListing(snap.docs.map(ProductModel.fromFirestore));
  }

  @override
  Future<ProductPage> getByCategoryPage(
    String? categoryId, {
    required int limit,
    Object? cursor,
  }) async {
    Query<Map<String, dynamic>> q = _col.where('isActive', isEqualTo: true);
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    q = q.orderBy(FieldPath.documentId).limit(limit);
    if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
      q = q.startAfterDocument(cursor);
    }

    final snap = await q.get(const GetOptions(source: Source.server));
    return ProductPage(
      items: expandProductsForListing(
        snap.docs.map(ProductModel.fromFirestore),
      ),
      cursor: snap.docs.isEmpty ? cursor : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  @override
  Future<ProductModel?> getById(String id) async {
    final doc = await _col
        .doc(realProductId(id))
        .get(const GetOptions(source: Source.server));
    if (!doc.exists) return null;
    return formatProductForRouteId(ProductModel.fromFirestore(doc), id);
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final snap = await _db
        .collection(AppConstants.colCategories)
        .get(const GetOptions(source: Source.server));
    return snap.docs.map(CategoryModel.fromFirestore).toList();
  }

  @override
  Future<List<ProductModel>> search(String query) async {
    // Firestore không hỗ trợ full-text search nên fetch toàn bộ active
    // rồi filter client-side (case-insensitive). Ổn với catalog nhỏ.
    // Production nên dùng Algolia / Typesense.
    final snap = await _col
        .where('isActive', isEqualTo: true)
        .get(const GetOptions(source: Source.server));
    return expandProductsForListing(snap.docs.map(ProductModel.fromFirestore))
        .where((p) => matchesProductSearchQuery(p, query))
        .toList();
  }

  @override
  Future<ProductPage> searchPage(
    String query, {
    required int limit,
    Object? cursor,
  }) async {
    final qText = query.toLowerCase().trim();
    if (qText.isEmpty) {
      return const ProductPage(items: [], cursor: null, hasMore: false);
    }

    const scanBatchSize = 80;
    final matches = <ProductModel>[];
    Object? nextCursor = cursor;
    var hasMoreDocs = true;

    while (matches.length < limit && hasMoreDocs) {
      Query<Map<String, dynamic>> q = _col
          .where('isActive', isEqualTo: true)
          .orderBy(FieldPath.documentId)
          .limit(scanBatchSize);
      if (nextCursor is DocumentSnapshot<Map<String, dynamic>>) {
        q = q.startAfterDocument(nextCursor);
      }

      final snap = await q.get(const GetOptions(source: Source.server));
      hasMoreDocs = snap.docs.length == scanBatchSize;
      if (snap.docs.isEmpty) break;
      nextCursor = snap.docs.last;

      for (final doc in snap.docs) {
        final products = expandProductForListing(
          ProductModel.fromFirestore(doc),
        );
        for (final product in products) {
          if (matchesProductSearchQuery(product, qText)) {
            matches.add(product);
            if (matches.length == limit) break;
          }
        }
      }
    }

    return ProductPage(
      items: matches,
      cursor: nextCursor,
      hasMore: hasMoreDocs,
    );
  }
}
