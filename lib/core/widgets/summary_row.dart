import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Hàng trong card tổng kết: label trái (xám), value phải.
/// [isTotal] in đậm xanh; [valueColor] override (xanh lá "Miễn phí", đỏ giảm giá).
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: isTotal
                  ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)
                  : AppTextStyles.meta.copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: isTotal
                  ? AppTextStyles.total
                  : AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: valueColor ?? AppColors.textPrimary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
