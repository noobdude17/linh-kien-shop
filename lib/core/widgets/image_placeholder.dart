import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Product image widget with a text placeholder fallback.
class ImagePlaceholder extends StatelessWidget {
  final String label;
  final String imageUrl;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  const ImagePlaceholder({
    super.key,
    this.label = '',
    this.imageUrl = '',
    this.width,
    this.height,
    this.radius = 8,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    final cacheSize = _cacheSize(context);
    final optimizedUrl = optimizedProductImageUrl(url, cacheSize);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: url.isEmpty
            ? _Fallback(label: label)
            : CachedNetworkImage(
                imageUrl: optimizedUrl,
                width: width,
                height: height,
                fit: fit,
                memCacheWidth: cacheSize,
                memCacheHeight: cacheSize,
                maxWidthDiskCache: cacheSize,
                maxHeightDiskCache: cacheSize,
                fadeInDuration: const Duration(milliseconds: 120),
                filterQuality: FilterQuality.medium,
                placeholder: (_, _) => _Fallback(label: label),
                errorWidget: (_, _, _) => _Fallback(label: label),
              ),
      ),
    );
  }

  int _cacheSize(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final logicalSize = [width, height]
        .whereType<double>()
        .where((value) => value.isFinite)
        .fold<double>(0, (max, value) => value > max ? value : max);

    final target = logicalSize > 0 ? logicalSize * ratio : 600;
    return target.clamp(256, 1000).round();
  }
}

String optimizedProductImageUrl(String url, int cacheSize) {
  if (url.isEmpty || !url.contains('res.cloudinary.com')) return url;
  if (!url.contains('/upload/')) return url;

  final transform = 'f_auto,q_auto,c_pad,w_$cacheSize,h_$cacheSize';
  if (url.contains('/upload/$transform/')) return url;

  return url.replaceFirst('/upload/', '/upload/$transform/');
}

class _Fallback extends StatelessWidget {
  final String label;

  const _Fallback({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
