import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../data/models/product_variant.dart';

class VariantSelector extends StatelessWidget {
  final List<ProductVariant> variants;
  final ProductVariant? selected;
  final ValueChanged<ProductVariant> onSelect;

  const VariantSelector({
    super.key,
    required this.variants,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: variants.map((v) {
        final isSelected = selected?.id == v.id;
        final isUnavailable = !v.isAvailable;

        return GestureDetector(
          onTap: isUnavailable ? null : () => onSelect(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isUnavailable
                      ? AppColors.inputFill
                      : AppColors.surface,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusChip),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  v.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : isUnavailable
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                    decoration: isUnavailable
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
                Text(
                  Formatter.price(v.price),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white70
                        : isUnavailable
                            ? AppColors.textSecondary
                            : AppColors.textSecondary,
                  ),
                ),
                if (isUnavailable)
                  const Text(
                    'Hết hàng',
                    style: TextStyle(fontSize: 9, color: AppColors.error),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
