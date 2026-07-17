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
    if (_isGroupedRamSelector) {
      return _GroupedRamVariantSelector(
        variants: variants,
        selected: selected,
        onSelect: onSelect,
      );
    }

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

  bool get _isGroupedRamSelector {
    if (variants.length < 2) return false;
    return variants.any((variant) {
      final attrs = variant.attributes;
      return attrs.containsKey('ramCapacityLabel') &&
          attrs.containsKey('ramSpeedLabel') &&
          attrs.containsKey('ramOptionLabel');
    });
  }
}

class _GroupedRamVariantSelector extends StatelessWidget {
  final List<ProductVariant> variants;
  final ProductVariant? selected;
  final ValueChanged<ProductVariant> onSelect;

  const _GroupedRamVariantSelector({
    required this.variants,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final current = selected ?? _firstAvailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _choiceSection(
          label: 'Capacity',
          selectedValue: _attr(current, 'ramCapacityLabel'),
          attributeKey: 'ramCapacityLabel',
        ),
        const SizedBox(height: 16),
        _choiceSection(
          label: 'Speed',
          selectedValue: _attr(current, 'ramSpeedLabel'),
          attributeKey: 'ramSpeedLabel',
        ),
        const SizedBox(height: 16),
        _choiceSection(
          label: 'CAS Latency | Color',
          selectedValue: _attr(current, 'ramTimingColorLabel'),
          attributeKey: 'ramTimingColorLabel',
        ),
      ],
    );
  }

  ProductVariant get _firstAvailable {
    return variants.firstWhere(
      (variant) => variant.isAvailable,
      orElse: () => variants.first,
    );
  }

  Widget _choiceSection({
    required String label,
    required String selectedValue,
    required String attributeKey,
  }) {
    final values = _orderedValues(attributeKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            children: [
              TextSpan(text: '$label:  '),
              TextSpan(
                text: selectedValue,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxChipWidth = constraints.maxWidth < 1
                ? double.infinity
                : constraints.maxWidth;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.map((value) {
                final matching = _bestVariantFor(attributeKey, value);
                final isUnavailable = !_hasAvailableCombination(
                  attributeKey,
                  value,
                );
                final isSelected = value == selectedValue;
                return GestureDetector(
                  onTap: isUnavailable || matching == null
                      ? null
                      : () => onSelect(matching),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxChipWidth),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentBlue.withValues(alpha: 0.08)
                            : isUnavailable
                            ? AppColors.inputFill
                            : AppColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentBlue
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusChip,
                        ),
                      ),
                      child: Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 13,
                          color: isUnavailable
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          decoration: isUnavailable
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  List<String> _orderedValues(String key) {
    final values = <String>[];
    for (final variant in variants) {
      final value = _attr(variant, key);
      if (value.isNotEmpty && !values.contains(value)) values.add(value);
    }
    return values;
  }

  // A chip greys out when its value, combined with the current selection on
  // the other two axes, has no in-stock variant.
  bool _hasAvailableCombination(String changedKey, String changedValue) {
    final current = selected ?? _firstAvailable;
    final others = {
      'ramCapacityLabel',
      'ramSpeedLabel',
      'ramTimingColorLabel',
    }..remove(changedKey);
    return variants.any((variant) {
      if (!variant.isAvailable) return false;
      if (_attr(variant, changedKey) != changedValue) return false;
      return others.every((key) => _attr(variant, key) == _attr(current, key));
    });
  }

  ProductVariant? _bestVariantFor(String changedKey, String changedValue) {
    // Keep the changed axis pinned to changedValue, then pick the candidate
    // that preserves the most of the *other* current axes. This stops an
    // exact-match miss from resetting unrelated axes (e.g. changing capacity
    // shouldn't make CAS latency jump). Available variants always win.
    final current = selected ?? _firstAvailable;
    final others = {
      'ramCapacityLabel',
      'ramSpeedLabel',
      'ramTimingColorLabel',
    }..remove(changedKey);
    final currentOthers = {
      for (final key in others) key: _attr(current, key),
    };

    ProductVariant? best;
    var bestScore = -1;
    for (final variant in variants) {
      if (_attr(variant, changedKey) != changedValue) continue;
      var score = currentOthers.entries
          .where((e) => _attr(variant, e.key) == e.value)
          .length;
      if (variant.isAvailable) score += 10; // available beats any axis match
      if (score > bestScore) {
        bestScore = score;
        best = variant;
      }
    }
    return best;
  }

  String _attr(ProductVariant? variant, String key) {
    if (variant == null) return '';
    if (key == 'ramTimingColorLabel') {
      final latency = variant.attributes['ramCasLatency'];
      final color = variant.attributes['ramColor']?.toString().trim() ?? '';
      final parts = [
        if (latency != null && latency.toString().trim().isNotEmpty)
          'CL$latency',
        if (color.isNotEmpty) color,
      ];
      if (parts.isNotEmpty) return parts.join(' | ');
      final fallback = variant.attributes['ramOptionLabel']?.toString() ?? '';
      return fallback
          .replaceAll(RegExp(r'\s*\|\s*(Yes|No)\s*$', caseSensitive: false), '')
          .trim();
    }
    return variant.attributes[key]?.toString().trim() ?? '';
  }
}
