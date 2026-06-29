import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_variant.dart';
import '../../../data/product_listing_adapter.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../routes/app_routes.dart';
import '../models/compatibility_result.dart';
import '../models/pc_build_model.dart';
import '../providers/pc_build_provider.dart';
import '../services/compatibility_engine.dart';

enum _PartSort { compatibility, priceLow, priceHigh, rating, nameAsc, nameDesc }

class PartSelectionScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const PartSelectionScreen({super.key, required this.categoryId});

  @override
  ConsumerState<PartSelectionScreen> createState() =>
      _PartSelectionScreenState();
}

class _PartSelectionScreenState extends ConsumerState<PartSelectionScreen> {
  static const _engine = CompatibilityEngine();
  static const _pageSize = 30;
  static const _loadMoreMinDuration = Duration(milliseconds: 1000);
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  final Set<String> _brandFilters = {};
  bool _showIncompatible = false;
  bool _isLoadingMore = false;
  int _visibleCount = _pageSize;
  _PartSort _sort = _PartSort.compatibility;

  PartCategorySpec get category => partPickerCategories.firstWhere(
    (item) => item.id == widget.categoryId,
    orElse: () => PartCategorySpec(widget.categoryId, widget.categoryId),
  );

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetPaging() {
    _visibleCount = _pageSize;
    _isLoadingMore = false;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _loadMore(List<_Candidate> candidates) async {
    if (_isLoadingMore || _visibleCount >= candidates.length) return;
    setState(() => _isLoadingMore = true);
    final start = _visibleCount;
    final end = (_visibleCount + _pageSize).clamp(0, candidates.length).toInt();
    await Future.wait([
      Future<void>.delayed(_loadMoreMinDuration),
      _precacheCandidateImages(candidates.sublist(start, end)),
    ]);
    if (!mounted) return;
    setState(() {
      _visibleCount = end;
      _isLoadingMore = false;
    });
  }

  Future<void> _precacheCandidateImages(List<_Candidate> candidates) async {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (54 * ratio).clamp(160, 360).round();
    final futures = candidates
        .map((candidate) => candidate.product.primaryImageUrl.trim())
        .where((url) => url.isNotEmpty)
        .take(10)
        .map(
          (url) => precacheImage(
            CachedNetworkImageProvider(
              optimizedProductImageUrl(url, cacheSize),
              maxWidth: cacheSize,
              maxHeight: cacheSize,
            ),
            context,
            onError: (_, _) {},
          ),
        );
    await Future.wait(
      futures,
    ).timeout(const Duration(milliseconds: 900), onTimeout: () => <void>[]);
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsByCategoryProvider(widget.categoryId));
    final build = ref.watch(pcBuildProvider);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.partPicker)),
        title: Text('Chọn ${category.label}'),
      ),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Không thể tải sản phẩm: $error')),
        data: (values) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(_resetPaging),
                decoration: const InputDecoration(
                  hintText: 'Tìm tên, hãng, socket, DDR, thông số...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            _filterBar(values),
            SwitchListTile.adaptive(
              dense: true,
              value: _showIncompatible,
              onChanged: (value) => setState(() {
                _showIncompatible = value;
                _resetPaging();
              }),
              title: const Text('Hiện linh kiện không tương thích'),
            ),
            const Divider(height: 1),
            Expanded(child: _list(build, values)),
          ],
        ),
      ),
    );
  }

  Widget _filterBar(List<ProductModel> values) {
    final brands =
        values
            .map((product) => product.brand.trim())
            .where((brand) => brand.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<_PartSort>(
            initialValue: _sort,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sắp xếp',
              isDense: true,
            ),
            items: _PartSort.values
                .map(
                  (sort) => DropdownMenuItem(
                    value: sort,
                    child: Text(_sortLabel(sort)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() {
              if (value != null) _sort = value;
              _resetPaging();
            }),
          ),
          if (brands.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: brands.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FilterChip(
                      label: const Text('Tất cả'),
                      selected: _brandFilters.isEmpty,
                      onSelected: (_) => setState(() {
                        _brandFilters.clear();
                        _resetPaging();
                      }),
                    );
                  }
                  final brand = brands[index - 1];
                  final selected = _brandFilters.contains(brand);
                  return _BrandLogoFilter(
                    brand: brand,
                    selected: selected,
                    logo: _brandLogo(brand),
                    onTap: () => setState(() {
                      selected
                          ? _brandFilters.remove(brand)
                          : _brandFilters.add(brand);
                      _resetPaging();
                    }),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _list(PcBuildModel build, List<ProductModel> values) {
    final query = _search.text.trim().toLowerCase();
    final baselineIssueKeys = _engine
        .evaluate(build)
        .issues
        .map(_issueKey)
        .toSet();
    final allCandidates =
        values
            .where(
              (product) => query.isEmpty || _matchesQuery(product, query),
            )
            .where(
              (product) =>
                  _brandFilters.isEmpty ||
                  _brandFilters.contains(product.brand),
            )
            .map(
              (product) {
                final evaluated = _engine.evaluate(
                  build.select(
                    category.id,
                    _compatibilityProduct(product),
                    multiple: category.multiple,
                  ),
                );
                return _Candidate(
                  product,
                  _candidateSummary(evaluated, baselineIssueKeys),
                  _queryScore(product, query),
                );
              },
            )
            .toList();
    final candidates =
        allCandidates
            .where(
              (candidate) =>
                  _showIncompatible ||
                  candidate.summary.severity !=
                      CompatibilitySeverity.incompatible,
            )
            .toList()
          ..sort(_compareCandidates);

    if (candidates.isEmpty) {
      return _emptyState(allCandidates);
    }

    final visibleCount = _visibleCount.clamp(0, candidates.length).toInt();
    final visible = candidates.take(visibleCount).toList();
    final hasMore = visibleCount < candidates.length;

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: visible.length + (hasMore || _isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= visible.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadMore(candidates);
          });
          return const _LoadingMoreFooter();
        }
        if (index >= visible.length - 6 && hasMore && !_isLoadingMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadMore(candidates);
          });
        }
        return _productTile(visible[index]);
      },
    );
  }

  Widget _emptyState(List<_Candidate> allCandidates) {
    final hiddenIncompatible = !_showIncompatible
        ? allCandidates
              .where(
                (candidate) =>
                    candidate.summary.severity ==
                    CompatibilitySeverity.incompatible,
              )
              .toList()
        : <_Candidate>[];
    final primaryIssue = _mostCommonIssue(hiddenIncompatible);
    final hasFilters =
        _search.text.trim().isNotEmpty || _brandFilters.isNotEmpty;

    final title = hiddenIncompatible.isNotEmpty
        ? 'Không có linh kiện tương thích'
        : 'Không có sản phẩm phù hợp.';
    final message = hiddenIncompatible.isNotEmpty
        ? primaryIssue?.message ??
              'Tất cả sản phẩm trong danh sách hiện tại đều không tương thích với cấu hình đã chọn.'
        : hasFilters
        ? 'Không tìm thấy sản phẩm theo bộ lọc hiện tại.'
        : 'Danh mục này chưa có sản phẩm để hiển thị.';
    final suggestion = hiddenIncompatible.isNotEmpty
        ? primaryIssue?.suggestion ??
              'Gợi ý: bật “Hiện linh kiện không tương thích” để xem toàn bộ lựa chọn, hoặc quay lại đổi linh kiện đang xung đột trong cấu hình.'
        : hasFilters
        ? 'Gợi ý: xoá từ khoá tìm kiếm hoặc chọn “Tất cả” thương hiệu.'
        : 'Gợi ý: kiểm tra lại dữ liệu sản phẩm trong Firebase.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hiddenIncompatible.isNotEmpty
                  ? Icons.info_outline
                  : Icons.search_off_outlined,
              color: hiddenIncompatible.isNotEmpty
                  ? AppColors.warning
                  : AppColors.textSecondary,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              suggestion,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  CompatibilityIssue? _mostCommonIssue(List<_Candidate> candidates) {
    final counts = <String, int>{};
    final issues = <String, CompatibilityIssue>{};
    for (final candidate in candidates) {
      final incompatibleIssues = candidate.summary.issues.where(
        (issue) => issue.severity == CompatibilitySeverity.incompatible,
      );
      for (final issue in incompatibleIssues) {
        final key = issue.code;
        counts[key] = (counts[key] ?? 0) + 1;
        issues.putIfAbsent(key, () => issue);
      }
    }
    if (counts.isEmpty) return null;
    final key = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return issues[key];
  }

  bool _matchesQuery(ProductModel product, String query) {
    final normalizedQuery = _normalizeSearch(query);
    if (normalizedQuery.isEmpty) return true;
    final text = _searchText(product);
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
    if (tokens.isEmpty) return true;
    return tokens.every(
      (token) => text.contains(token) || compactText.contains(token),
    );
  }

  int _queryScore(ProductModel product, String query) {
    final normalizedQuery = _normalizeSearch(query);
    if (normalizedQuery.isEmpty) return 0;
    final text = _searchText(product);
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

  String _searchText(ProductModel product) {
    final parts = <String>[
      product.name,
      product.brand,
      product.categoryId,
      product.categoryName,
      product.imageLabel,
      ..._categorySearchAliases(product.categoryId),
      _specLine(product),
      ...product.specs.keys,
      ...product.specs.values,
      ...product.compatibility.keys,
      ...product.compatibility.values.map(_value),
      ..._compatibilitySearchAliases(product.compatibility),
    ];
    for (final variant in product.variants) {
      parts
        ..add(variant.id)
        ..add(variant.name)
        ..addAll(variant.attributes.keys)
        ..addAll(variant.attributes.values.map(_value))
        ..addAll(_compatibilitySearchAliases(variant.attributes));
    }
    return _normalizeSearch(parts.join(' '));
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
      aliases.add('${_formatNumber(number)}gb');
      aliases.add('${_formatNumber(number)} gb');
      aliases.add('${_formatNumber(number)}gb $unitContext');
      if (number >= 1000) {
        final tb = number / 1000;
        aliases.add('${_formatNumber(tb)}tb');
        aliases.add('${_formatNumber(tb)} tb');
        aliases.add('${_formatNumber(tb)}tb $unitContext');
      }
    }

    void addSpeedAliases(Object? value) {
      final number = _numberFromValue(value);
      if (number == null) return;
      aliases.add('${_formatNumber(number)}mhz');
      aliases.add('${_formatNumber(number)} mhz');
      aliases.add('${_formatNumber(number)} mt s');
      aliases.add('${_formatNumber(number)}mts');
    }

    void addWattAliases(Object? value) {
      final number = _numberFromValue(value);
      if (number == null) return;
      aliases.add('${_formatNumber(number)}w');
      aliases.add('${_formatNumber(number)} w');
      aliases.add('${_formatNumber(number)}watt');
      aliases.add('${_formatNumber(number)} watts');
    }

    addCapacityAliases(data['ramCapacityGb'], unitContext: 'ram');
    addCapacityAliases(data['gpuVramGb'], unitContext: 'vram');
    addCapacityAliases(data['storageCapacityGb'], unitContext: 'storage');
    addSpeedAliases(data['ramSpeedMhz']);
    addWattAliases(data['psuWattage']);
    addWattAliases(data['gpuPowerWatts']);
    addWattAliases(data['estimatedPowerWatts']);

    final memoryType = _value(data['ramMemoryType']);
    if (memoryType.isNotEmpty) {
      aliases.add(memoryType);
      aliases.add(memoryType.replaceAll(' ', ''));
    }

    final socket = _value(data['cpuSocket'] ?? data['mbSocket']);
    if (socket.isNotEmpty) aliases.add(socket.replaceAll(' ', ''));

    final storageInterface = _value(data['storageInterface']);
    if (storageInterface.isNotEmpty) {
      aliases.add(storageInterface);
      aliases.add(storageInterface.replaceAll('.', ''));
      aliases.add(storageInterface.replaceAll(' ', ''));
    }

    return aliases;
  }

  num? _numberFromValue(Object? value) {
    if (value is num) return value;
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(_value(value));
    return match == null ? null : num.tryParse(match.group(0)!);
  }

  String _normalizeSearch(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  CompatibilitySummary _candidateSummary(
    CompatibilitySummary evaluated,
    Set<String> baselineIssueKeys,
  ) {
    return CompatibilitySummary(
      evaluated.issues
          .where((issue) => !baselineIssueKeys.contains(_issueKey(issue)))
          .toList(),
    );
  }

  String _issueKey(CompatibilityIssue issue) => '${issue.code}|${issue.message}';

  int _compareCandidates(_Candidate a, _Candidate b) {
    final productA = a.product;
    final productB = b.product;
    if (_search.text.trim().isNotEmpty) {
      final score = b.queryScore.compareTo(a.queryScore);
      if (score != 0) return score;
    }
    return switch (_sort) {
      _PartSort.compatibility => _thenByName(
        a.summary.severity.index.compareTo(b.summary.severity.index),
        productA,
        productB,
      ),
      _PartSort.priceLow => _thenByName(
        productA.price.compareTo(productB.price),
        productA,
        productB,
      ),
      _PartSort.priceHigh => _thenByName(
        productB.price.compareTo(productA.price),
        productA,
        productB,
      ),
      _PartSort.rating => _thenByName(
        productB.rating.compareTo(productA.rating),
        productA,
        productB,
      ),
      _PartSort.nameAsc => productA.name.compareTo(productB.name),
      _PartSort.nameDesc => productB.name.compareTo(productA.name),
    };
  }

  int _thenByName(int result, ProductModel a, ProductModel b) {
    return result != 0 ? result : a.name.compareTo(b.name);
  }

  String _sortLabel(_PartSort sort) => switch (sort) {
    _PartSort.compatibility => 'Tương thích nhất',
    _PartSort.priceLow => 'Giá thấp đến cao',
    _PartSort.priceHigh => 'Giá cao đến thấp',
    _PartSort.rating => 'Đánh giá cao nhất',
    _PartSort.nameAsc => 'Tên A-Z',
    _PartSort.nameDesc => 'Tên Z-A',
  };

  Widget _brandLogo(String brand) {
    final path = _brandLogoPath(brand);
    if (path == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 42,
        height: 26,
        color: Colors.transparent,
        child: path.endsWith('.svg')
            ? SvgPicture.asset(path, fit: BoxFit.contain)
            : Image.asset(
                path,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
      ),
    );
  }

  String? _brandLogoPath(String brand) {
    return switch (brand.trim().toLowerCase()) {
      'amd' => 'assets/images/brands/amd.png',
      'asus' => 'assets/images/brands/asus.png',
      'corsair' => 'assets/images/brands/corsair.svg',
      'crucial / micron' => 'assets/images/brands/crucial.svg',
      'g.skill' => 'assets/images/brands/gskill.svg',
      'intel' => 'assets/images/brands/intel.png',
      'logitech' => 'assets/images/brands/logitech.svg',
      'microsoft' => 'assets/images/brands/microsoft.png',
      'msi' => 'assets/images/brands/msi.png',
      'razer' => 'assets/images/brands/razer.png',
      'samsung' => 'assets/images/brands/samsung.png',
      _ => null,
    };
  }

  Widget _productTile(_Candidate candidate) {
    final product = candidate.product;
    final severity = candidate.summary.severity;
    final isIncompatible = severity == CompatibilitySeverity.incompatible;
    final isWarning = severity == CompatibilitySeverity.warning;
    final statusColor = isIncompatible
        ? AppColors.error
        : isWarning
        ? AppColors.warning
        : AppColors.success;
    final status = isIncompatible
        ? 'Không tương thích'
        : isWarning
        ? 'Lưu ý'
        : 'Tương thích';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImagePlaceholder(
            label: product.imageLabel.isEmpty
                ? product.brand
                : product.imageLabel,
            imageUrl: product.primaryImageUrl,
            width: 54,
            height: 54,
            radius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _specLine(product),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (product.variants.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${product.variants.length} tùy chọn',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      Formatter.price(product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Chọn sản phẩm',
            onPressed: () async {
              final selected = await _selectVariant(product);
              if (selected == null || !mounted) return;
              ref.read(pcBuildProvider.notifier).select(category, selected);
              context.go(AppRoutes.partPicker);
            },
            icon: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
    );
  }

  ProductModel _compatibilityProduct(ProductModel product) {
    if (product.variants.isEmpty) return product;
    final available = product.variants.where((variant) => variant.isAvailable);
    final variantId = product.id.contains(productListingVariantSeparator)
        ? product.id.split(productListingVariantSeparator).last
        : '';
    ProductVariant? routeVariant;
    for (final variant in product.variants) {
      if (variant.id == variantId) {
        routeVariant = variant;
        break;
      }
    }
    final variant =
        routeVariant ??
        (available.isEmpty ? product.variants.first : available.first);
    return product.withVariant(variant);
  }

  Future<ProductModel?> _selectVariant(ProductModel product) async {
    if (product.variants.isEmpty) return product;
    return showModalBottomSheet<ProductModel>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                product.categoryId == 'ram'
                    ? 'Chọn dung lượng và tốc độ'
                    : product.categoryId == 'storage'
                    ? 'Chọn dung lượng'
                    : 'Chọn phiên bản',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: product.variants.map((variant) {
                  return ListTile(
                    enabled: variant.isAvailable,
                    title: Text(variant.name),
                    subtitle: Text(
                      variant.isAvailable
                          ? Formatter.price(variant.price)
                          : 'Hết hàng',
                    ),
                    trailing: variant.isAvailable
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: variant.isAvailable
                        ? () => Navigator.pop(
                            context,
                            product.withVariant(variant),
                          )
                        : null,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _specLine(ProductModel product) {
    if (product.variants.isNotEmpty) {
      final variantLine = _variantSpecLine(product);
      if (variantLine.isNotEmpty) return variantLine;
    }

    final data = product.compatibility;
    final parts = switch (category.id) {
      'cpu' => [
        _labelValue('Socket', data['cpuSocket']),
        _numberSpec(data['cpuCores'], suffix: ' nhân'),
        _numberSpec(data['cpuThreads'], suffix: ' luồng'),
        _numberSpec(data['cpuTdpWatts'], prefix: 'TDP ', suffix: 'W'),
      ],
      'mainboard' => [
        _labelValue('Socket', data['mbSocket']),
        _value(data['mbMemoryType']),
        _value(data['mbFormFactor']),
        _numberSpec(data['mbRamSlots'], suffix: ' khe RAM'),
        _numberSpec(data['mbM2Slots'], suffix: ' khe M.2'),
      ],
      'ram' => [
        _numberSpec(data['ramCapacityGb'], suffix: 'GB'),
        _labelValue('Loại', data['ramMemoryType']),
        _numberSpec(data['ramModuleCount'], suffix: ' thanh'),
        _numberSpec(data['ramSpeedMhz'], suffix: 'MHz'),
      ],
      'storage' => [
        _storageCapacity(data['storageCapacityGb']),
        _value(data['storageInterface']),
        _value(data['storageFormFactor']),
        _numberSpec(data['storageReadSpeedRangeMbps'], suffix: 'MB/s đọc'),
      ],
      'gpu' => [
        _value(data['gpuChipset']),
        _numberSpec(data['gpuVramGb'], suffix: 'GB VRAM'),
        _numberSpec(data['gpuLengthMm'], suffix: 'mm'),
        _labelValue('Nguồn', data['gpuPowerConnectors']),
      ],
      'psu' => [
        _numberSpec(data['psuWattage'], suffix: 'W'),
        _value(data['psuEfficiency']),
        _value(data['psuFormFactor']),
        _labelValue('Cáp GPU', data['psuPowerConnectors']),
      ],
      'case' => [
        _labelValue('Mainboard', data['caseSupportedMotherboardFormFactors']),
        _numberSpec(
          data['caseMaxGpuLengthMm'],
          prefix: 'GPU tối đa ',
          suffix: 'mm',
        ),
        _numberSpec(
          data['caseMaxRadiatorSizeMm'],
          prefix: 'Radiator ',
          suffix: 'mm',
        ),
      ],
      'cooler' => [
        _value(data['coolerType']),
        _labelValue('Socket', data['coolerSupportedSockets']),
        _numberSpec(
          data['coolerRadiatorSizeMm'],
          prefix: 'Radiator ',
          suffix: 'mm',
        ),
        _numberSpec(data['coolerTdpRatingWatts'], prefix: 'Tản ', suffix: 'W'),
      ],
      'monitor' => [
        _numberSpec(data['monitorSizeInch'], suffix: '"'),
        _value(data['monitorResolution']),
        _numberSpec(data['monitorRefreshRateHz'], suffix: 'Hz'),
        _value(data['monitorPanelType']),
      ],
      'os' => [
        _labelValue('Windows', data['osVersion']),
        _value(data['osEdition']),
        _value(data['osArchitecture']),
      ],
      'keyboard' => [
        _value(data['keyboardSwitchType']),
        _value(data['keyboardLayout']),
        _value(data['keyboardConnection']),
      ],
      'mouse' => [
        _value(data['mouseSensor']),
        _numberSpec(data['mouseDpi'], suffix: ' DPI'),
        _value(data['mouseConnection']),
      ],
      _ => <String>[],
    };
    return parts.where((part) => part.isNotEmpty).join(' · ');
  }

  String _value(Object? value) {
    if (value == null) return '';
    if (value is Iterable) {
      return value.map((item) => item.toString()).join(', ');
    }
    return value.toString().trim();
  }

  String _labelValue(String label, Object? value) {
    final text = _value(value);
    return text.isEmpty ? '' : '$label $text';
  }

  String _numberSpec(Object? value, {String prefix = '', String suffix = ''}) {
    final text = _value(value);
    if (text.isEmpty) return '';
    final number = num.tryParse(text);
    return '$prefix${number == null ? text : _formatNumber(number)}$suffix';
  }

  String _storageCapacity(Object? value) {
    final text = _value(value);
    final gb = num.tryParse(text);
    if (gb == null) return text;
    if (gb >= 1000) return '${_formatNumber(gb / 1000)}TB';
    return '${_formatNumber(gb)}GB';
  }

  String _formatNumber(num value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  String _variantSpecLine(ProductModel product) {
    final variants = product.variants;
    if (variants.isEmpty) return '';

    final firstAvailable = variants.firstWhere(
      (variant) => variant.isAvailable,
      orElse: () => variants.first,
    );
    final data = {...product.compatibility, ...firstAvailable.attributes};

    final capacities = _variantNumbers(variants, switch (product.categoryId) {
      'ram' => 'ramCapacityGb',
      'storage' => 'storageCapacityGb',
      _ => '',
    });
    final speeds = _variantNumbers(variants, 'ramSpeedMhz');

    return switch (product.categoryId) {
      'ram' => [
        _rangeSpec(capacities, suffix: 'GB'),
        _labelValue('Loại', data['ramMemoryType']),
        _numberSpec(data['ramModuleCount'], suffix: ' thanh'),
        _rangeSpec(speeds, suffix: 'MHz'),
      ].where((part) => part.isNotEmpty).join(' · '),
      'storage' => [
        _storageCapacityRange(capacities),
        _value(data['storageInterface']),
        _value(data['storageFormFactor']),
      ].where((part) => part.isNotEmpty).join(' · '),
      _ => '',
    };
  }

  List<num> _variantNumbers(List<dynamic> variants, String key) {
    if (key.isEmpty) return const [];
    final values = <num>{};
    for (final variant in variants) {
      final value = variant.attributes[key];
      final number = num.tryParse(_value(value));
      if (number != null) values.add(number);
    }
    return values.toList()..sort();
  }

  String _rangeSpec(List<num> values, {String suffix = ''}) {
    if (values.isEmpty) return '';
    if (values.length == 1) return '${_formatNumber(values.first)}$suffix';
    return '${_formatNumber(values.first)}-${_formatNumber(values.last)}$suffix';
  }

  String _storageCapacityRange(List<num> values) {
    if (values.isEmpty) return '';
    if (values.length == 1) return _storageCapacity(values.first);
    return '${_storageCapacity(values.first)}-${_storageCapacity(values.last)}';
  }
}

class _Candidate {
  final ProductModel product;
  final CompatibilitySummary summary;
  final int queryScore;

  const _Candidate(this.product, this.summary, [this.queryScore = 0]);
}

class _BrandLogoFilter extends StatelessWidget {
  const _BrandLogoFilter({
    required this.brand,
    required this.logo,
    required this.selected,
    required this.onTap,
  });

  final String brand;
  final Widget logo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: brand,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minWidth: 106),
          height: 46,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x120F172A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              logo,
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.bodyText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingMoreFooter extends StatelessWidget {
  const _LoadingMoreFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Đang tải...',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
