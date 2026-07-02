import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/widgets/image_placeholder.dart';

class ProductImageGallery extends StatefulWidget {
  final List<String> images;
  final String fallbackLabel;
  final double height;

  /// Tag Hero khớp với ProductCard để ảnh bay từ grid sang trang chi tiết.
  final String? heroTag;

  const ProductImageGallery({
    super.key,
    required this.images,
    required this.fallbackLabel,
    this.height = 300,
    this.heroTag,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _current = 0;
  final _controller = PageController();
  List<String> _lastPrecachedUrls = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheVisibleAndAdjacentImages();
  }

  @override
  void didUpdateWidget(covariant ProductImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images ||
        oldWidget.height != widget.height) {
      _current = 0;
      _lastPrecachedUrls = const [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _precacheVisibleAndAdjacentImages();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _urls =>
      widget.images.map((u) => u.trim()).where((u) => u.isNotEmpty).toList();

  void _precacheVisibleAndAdjacentImages() {
    final urls = _urls;
    if (urls.isEmpty) return;

    final indexes = <int>{
      _current,
      if (_current > 0) _current - 1,
      if (_current < urls.length - 1) _current + 1,
    };
    final urlsToCache = indexes
        .where((i) => i >= 0 && i < urls.length)
        .map((i) => urls[i])
        .toList(growable: false);

    if (_lastPrecachedUrls.length == urlsToCache.length &&
        _lastPrecachedUrls.indexed.every(
          (entry) => entry.$2 == urlsToCache[entry.$1],
        )) {
      return;
    }
    _lastPrecachedUrls = urlsToCache;

    final ratio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (widget.height * ratio).clamp(384, 1200).round();
    for (final url in urlsToCache) {
      precacheImage(
        CachedNetworkImageProvider(
          optimizedProductImageUrl(url, cacheSize),
          maxWidth: cacheSize,
          maxHeight: cacheSize,
        ),
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;
    final count = urls.isEmpty ? 1 : urls.length;

    Widget gallery = SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            allowImplicitScrolling: true,
            itemCount: count,
            onPageChanged: (i) {
              setState(() => _current = i);
              _precacheVisibleAndAdjacentImages();
            },
            itemBuilder: (_, i) {
              if (urls.isEmpty) {
                return ImagePlaceholder(
                  label: widget.fallbackLabel,
                  height: widget.height,
                  radius: 0,
                );
              }
              return ImagePlaceholder(
                imageUrl: urls[i],
                label: widget.fallbackLabel,
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.contain,
                radius: 0,
              );
            },
          ),
          if (count > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(count, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );

    if (widget.heroTag != null) {
      gallery = Hero(tag: widget.heroTag!, child: gallery);
    }
    return gallery;
  }
}
