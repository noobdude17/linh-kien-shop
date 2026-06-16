import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Pill trạng thái đơn hàng, màu theo status.
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  static (Color, Color) _colors(String status) {
    switch (status) {
      case AppConstants.statusDelivered:
        return (AppColors.success, AppColors.successBg);
      case AppConstants.statusCancelled:
        return (AppColors.error, AppColors.errorBg);
      case AppConstants.statusPending:
        return (AppColors.accent, Color(0xFFFFF3E0));
      case AppConstants.statusShipping:
      case AppConstants.statusConfirmed:
      default:
        return (AppColors.primary, Color(0xFFE3F2FD));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors(status);
    final label = OrderStatusLabel.map[status] ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
