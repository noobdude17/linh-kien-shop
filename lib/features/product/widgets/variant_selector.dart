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
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: variants.map((variant) {
            final isSelected = selected?.id == variant.id;
            final isUnavailable = !variant.isAvailable;

            return GestureDetector(
              onTap: isUnavailable ? null : () => onSelect(variant),
              child: AnimatedContainer(
                width: itemWidth,
                constraints: const BoxConstraints(minHeight: 58),
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isUnavailable
                      ? AppColors.inputFill
                      : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.radiusChip),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      variant.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
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
                      Formatter.price(variant.price),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white70
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
      },
    );
  }
}
