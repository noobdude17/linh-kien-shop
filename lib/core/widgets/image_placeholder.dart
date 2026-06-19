import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Placeholder ảnh sản phẩm: nền sọc xanh-xám nhạt + caption.
/// Thay bằng CachedNetworkImage khi có ảnh thật.
class ImagePlaceholder extends StatelessWidget {
  final String label;
  final double? height;
  final double radius;

  const ImagePlaceholder({
    super.key,
    this.label = '',
    this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        color: AppColors.background,
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
