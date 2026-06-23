import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatter.dart';
import '../../../data/models/product_model.dart';
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
  final _search = TextEditingController();
  final Set<String> _brandFilters = {};
  bool _showIncompatible = true;
  _PartSort _sort = _PartSort.compatibility;

  PartCategorySpec get category => partPickerCategories.firstWhere(
    (item) => item.id == widget.categoryId,
    orElse: () => PartCategorySpec(widget.categoryId, widget.categoryId),
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Tìm theo tên hoặc thương hiệu',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            _filterBar(values),
            SwitchListTile.adaptive(
              dense: true,
              value: _showIncompatible,
              onChanged: (value) => setState(() => _showIncompatible = value),
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
            }),
          ),
          if (brands.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: brands.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FilterChip(
                      label: const Text('Tất cả'),
                      selected: _brandFilters.isEmpty,
                      onSelected: (_) => setState(_brandFilters.clear),
                    );
                  }
                  final brand = brands[index - 1];
                  final selected = _brandFilters.contains(brand);
                  return FilterChip(
                    labelPadding: const EdgeInsets.only(left: 3, right: 8),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _brandLogo(brand),
                        const SizedBox(width: 8),
                        Text(brand),
                      ],
                    ),
                    selected: selected,
                    onSelected: (value) => setState(() {
                      if (value) {
                        _brandFilters.add(brand);
                      } else {
                        _brandFilters.remove(brand);
                      }
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
    final candidates =
        values
            .where(
              (product) =>
                  query.isEmpty ||
                  product.name.toLowerCase().contains(query) ||
                  product.brand.toLowerCase().contains(query),
            )
            .where(
              (product) =>
                  _brandFilters.isEmpty ||
                  _brandFilters.contains(product.brand),
            )
            .map(
              (product) => _Candidate(
                product,
                _engine.evaluate(
                  build.select(
                    category.id,
                    product,
                    multiple: category.multiple,
                  ),
                ),
              ),
            )
            .where(
              (candidate) =>
                  _showIncompatible ||
                  candidate.summary.severity !=
                      CompatibilitySeverity.incompatible,
            )
            .toList()
          ..sort(_compareCandidates);

    if (candidates.isEmpty) {
      return const Center(child: Text('Không có sản phẩm phù hợp.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: candidates.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _productTile(candidates[index]),
    );
  }

  int _compareCandidates(_Candidate a, _Candidate b) {
    final productA = a.product;
    final productB = b.product;
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
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 28,
        height: 28,
        color: Colors.white,
        padding: const EdgeInsets.all(3),
        child: Image.asset(
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
      'crucial / micron' => 'assets/images/brands/crucial.png',
      'intel' => 'assets/images/brands/intel.png',
      'logitech' => 'assets/images/brands/logitech.png',
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
    final statusColor = switch (severity) {
      CompatibilitySeverity.compatible => AppColors.success,
      CompatibilitySeverity.warning => AppColors.warning,
      CompatibilitySeverity.incompatible => AppColors.error,
    };
    final status = switch (severity) {
      CompatibilitySeverity.compatible => 'Tương thích',
      CompatibilitySeverity.warning => 'Cần kiểm tra',
      CompatibilitySeverity.incompatible => 'Không tương thích',
    };
    final firstIssue = candidate.summary.issues.isEmpty
        ? null
        : candidate.summary.issues.first.message;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.imageLabel.isEmpty ? product.brand : product.imageLabel,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
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
                if (firstIssue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    firstIssue,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Chọn sản phẩm',
            onPressed: () {
              ref.read(pcBuildProvider.notifier).select(category, product);
              context.go(AppRoutes.partPicker);
            },
            icon: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
    );
  }

  String _specLine(ProductModel product) {
    final data = product.compatibility;
    final keys = switch (category.id) {
      'cpu' => ['cpuSocket', 'cpuCores', 'cpuTdpWatts'],
      'mainboard' => ['mbSocket', 'mbMemoryType', 'mbFormFactor'],
      'ram' => [
        'ramMemoryType',
        'ramCapacityGb',
        'ramModuleCount',
        'ramSpeedMhz',
      ],
      'storage' => [
        'storageInterface',
        'storageFormFactor',
        'storageCapacityGb',
      ],
      'gpu' => [
        'gpuChipset',
        'gpuVramGb',
        'gpuLengthMm',
        'gpuPowerConnectors',
        'gpuPcieVersion',
      ],
      'psu' => [
        'psuWattage',
        'psuEfficiency',
        'psuFormFactor',
        'psuPowerConnectors',
      ],
      'case' => ['caseSupportedMotherboardFormFactors', 'caseMaxGpuLengthMm'],
      'cooler' => ['coolerType', 'coolerSupportedSockets'],
      'monitor' => [
        'monitorSizeInch',
        'monitorResolution',
        'monitorRefreshRateHz',
      ],
      'os' => ['osVersion', 'osEdition', 'osArchitecture'],
      _ => <String>[],
    };
    return keys
        .map((key) => data[key])
        .where((value) => value != null && value.toString().isNotEmpty)
        .map((value) => value is Iterable ? value.join(', ') : value.toString())
        .join(' · ');
  }
}

class _Candidate {
  final ProductModel product;
  final CompatibilitySummary summary;

  const _Candidate(this.product, this.summary);
}
