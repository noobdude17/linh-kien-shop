import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Chip pill. Selected = nền primary + chữ trắng; bình thường = nền xám + viền.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool trending; // nền cam nhạt + chữ cam

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.trending = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;
    if (selected) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else if (trending) {
      bg = const Color(0xFFFFF3E0);
      fg = AppColors.accent;
    } else {
      bg = AppColors.background;
      fg = const Color(0xFF616161);
      border = Border.all(color: AppColors.border);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppDimens.brChip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppDimens.brChip,
          border: border,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
