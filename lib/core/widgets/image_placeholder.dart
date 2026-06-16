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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8EEF3), Color(0xFFD6E0EA)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
