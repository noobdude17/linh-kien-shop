import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_buttons.dart';

class FilterOptions {
  final RangeValues priceRange;
  final double minRating;
  final bool inStockOnly;

  const FilterOptions({
    this.priceRange = const RangeValues(0, 50000000),
    this.minRating = 0,
    this.inStockOnly = false,
  });

  FilterOptions copyWith({
    RangeValues? priceRange,
    double? minRating,
    bool? inStockOnly,
  }) => FilterOptions(
    priceRange: priceRange ?? this.priceRange,
    minRating: minRating ?? this.minRating,
    inStockOnly: inStockOnly ?? this.inStockOnly,
  );

  bool get isDefault =>
      priceRange.start == 0 &&
      priceRange.end == 50000000 &&
      minRating == 0 &&
      !inStockOnly;
}

class FilterSheet extends StatefulWidget {
  final FilterOptions initial;
  const FilterSheet({super.key, required this.initial});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FilterOptions _opts;

  @override
  void initState() {
    super.initState();
    _opts = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Bộ lọc',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _opts = const FilterOptions()),
                  child: const Text(
                    'Đặt lại',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Khoảng giá',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            RangeSlider(
              values: _opts.priceRange,
              min: 0,
              max: 50000000,
              divisions: 50,
              activeColor: AppColors.accentBlue,
              labels: RangeLabels(
                Formatter.price(_opts.priceRange.start),
                Formatter.price(_opts.priceRange.end),
              ),
              onChanged: (v) =>
                  setState(() => _opts = _opts.copyWith(priceRange: v)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    Formatter.price(_opts.priceRange.start),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    Formatter.price(_opts.priceRange.end),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Đánh giá tối thiểu',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(5, (i) {
                final star = (i + 1).toDouble();
                return GestureDetector(
                  onTap: () => setState(
                    () => _opts = _opts.copyWith(
                      minRating: _opts.minRating == star ? 0 : star,
                    ),
                  ),
                  child: Icon(
                    star <= _opts.minRating ? Icons.star : Icons.star_border,
                    size: 28,
                    color: AppColors.star,
                  ),
                );
              }),
            ),
            if (_opts.minRating > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Từ ${_opts.minRating.toInt()} sao trở lên',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Chỉ hiện còn hàng',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Switch(
                  value: _opts.inStockOnly,
                  onChanged: (v) =>
                      setState(() => _opts = _opts.copyWith(inStockOnly: v)),
                  activeThumbColor: AppColors.accentBlue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Áp dụng',
              onPressed: () => Navigator.of(context).pop(_opts),
            ),
          ],
        ),
      ),
    );
  }
}
