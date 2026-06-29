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
      bg = const Color(0xFFEFF6FF);
      fg = AppColors.accentBlue;
    } else {
      bg = AppColors.inputFill;
      fg = AppColors.bodyText;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppDimens.brChip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppDimens.brChip,
          border: border,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
