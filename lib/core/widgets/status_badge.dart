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
        return (AppColors.warning, AppColors.warningBg);
      case AppConstants.statusShipping:
        return (AppColors.accentBlue, AppColors.shippingBg);
      case AppConstants.statusConfirmed:
      default:
        return (AppColors.bodyText, AppColors.doneBg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors(status);
    final label = OrderStatusLabel.map[status] ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
