import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Bộ tăng/giảm số lượng (− value +). Min mặc định = 1.
class QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final int min;

  const QuantityStepper({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn('−', () => onChanged?.call(value > min ? value - 1 : value)),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        _btn('+', () => onChanged?.call(value + 1)),
      ],
    );
  }

  Widget _btn(String glyph, VoidCallback onTap) {
    return InkWell(
      onTap: onChanged == null ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          glyph,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1,
          ),
        ),
      ),
    );
  }
}
