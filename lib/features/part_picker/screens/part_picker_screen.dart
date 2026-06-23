import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../data/models/product_model.dart';
import '../../../routes/app_routes.dart';
import '../models/compatibility_result.dart';
import '../models/pc_build_model.dart';
import '../providers/pc_build_provider.dart';
import '../services/compatibility_engine.dart';
import '../services/wattage_calculator.dart';

class PartPickerScreen extends ConsumerStatefulWidget {
  const PartPickerScreen({super.key});

  @override
  ConsumerState<PartPickerScreen> createState() => _PartPickerScreenState();
}

class _PartPickerScreenState extends ConsumerState<PartPickerScreen> {
  static const _engine = CompatibilityEngine();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_saveScrollOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreScrollOffset());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_saveScrollOffset);
    _scrollController.dispose();
    super.dispose();
  }

  void _saveScrollOffset() {
    if (!_scrollController.hasClients) return;
    ref.read(partPickerScrollOffsetProvider.notifier).state =
        _scrollController.offset;
  }

  void _restoreScrollOffset() {
    if (!_scrollController.hasClients) return;
    final savedOffset = ref.read(partPickerScrollOffsetProvider);
    final maxOffset = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(savedOffset.clamp(0, maxOffset).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final build = ref.watch(pcBuildProvider);
    final summary = _engine.evaluate(build);
    final estimated = WattageCalculator.estimated(build);
    final recommended = WattageCalculator.recommended(build);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        title: const Text('Lắp PC'),
        actions: [
          IconButton(
            tooltip: 'Xóa cấu hình',
            onPressed: build.selections.isEmpty
                ? null
                : () => _confirmClear(context, ref),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _statusBanner(summary, estimated),
          _summaryBand(build, estimated, recommended),
          const Divider(height: 1),
          for (final category in partPickerCategories)
            _categorySection(context, ref, build, category),
          if (summary.issues.isNotEmpty) _issues(summary),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _statusBanner(CompatibilitySummary summary, int estimated) {
    final severity = summary.severity;
    final color = switch (severity) {
      CompatibilitySeverity.compatible => AppColors.success,
      CompatibilitySeverity.warning => AppColors.warning,
      CompatibilitySeverity.incompatible => AppColors.error,
    };
    final icon = severity == CompatibilitySeverity.compatible
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;
    final text = switch (severity) {
      CompatibilitySeverity.compatible => 'Không phát hiện vấn đề tương thích',
      CompatibilitySeverity.warning => 'Có một số lưu ý cần kiểm tra',
      CompatibilitySeverity.incompatible => 'Có linh kiện không tương thích',
    };
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.bolt, color: Colors.white),
          Text(
            '${estimated}W',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBand(PcBuildModel build, int estimated, int recommended) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: _metric('Tổng giá', Formatter.price(build.totalPrice)),
          ),
          Expanded(child: _metric('Công suất', '${estimated}W')),
          Expanded(child: _metric('Nguồn đề xuất', '${recommended}W')),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _categorySection(
    BuildContext context,
    WidgetRef ref,
    PcBuildModel build,
    PartCategorySpec category,
  ) {
    final items = build.items(category.id);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.dividerAlt)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Icon(
                  _icon(category.id),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              Expanded(
                child: Text(
                  category.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.icon(
                onPressed: () =>
                    context.go('${AppRoutes.partPickerSelect}/${category.id}'),
                icon: Icon(
                  items.isEmpty || category.multiple
                      ? Icons.add
                      : Icons.swap_horiz,
                  size: 18,
                ),
                label: Text(
                  items.isEmpty || category.multiple ? 'Chọn' : 'Đổi',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(92, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          for (final product in items) _selectedProduct(ref, category, product),
        ],
      ),
    );
  }

  Widget _selectedProduct(
    WidgetRef ref,
    PartCategorySpec category,
    ProductModel product,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.brand} · ${Formatter.price(product.price)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xóa linh kiện',
            onPressed: () => ref
                .read(pcBuildProvider.notifier)
                .remove(category.id, product.id),
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _issues(CompatibilitySummary summary) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết tương thích',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final issue in summary.issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    issue.severity == CompatibilitySeverity.incompatible
                        ? Icons.cancel_outlined
                        : Icons.warning_amber_rounded,
                    size: 19,
                    color: issue.severity == CompatibilitySeverity.incompatible
                        ? AppColors.error
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue.message,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cấu hình?'),
        content: const Text('Toàn bộ linh kiện đã chọn sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) ref.read(pcBuildProvider.notifier).clear();
  }

  IconData _icon(String categoryId) => switch (categoryId) {
    'cpu' => Icons.memory,
    'cooler' => Icons.ac_unit,
    'mainboard' => Icons.developer_board,
    'ram' => Icons.view_module_outlined,
    'storage' => Icons.storage,
    'gpu' => Icons.videogame_asset_outlined,
    'case' => Icons.desktop_windows_outlined,
    'psu' => Icons.electrical_services,
    'os' => Icons.window,
    'monitor' => Icons.monitor,
    'keyboard' => Icons.keyboard,
    'mouse' => Icons.mouse,
    _ => Icons.category_outlined,
  };
}
