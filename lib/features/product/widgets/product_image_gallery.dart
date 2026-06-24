import 'package:flutter/material.dart';
import '../../../core/widgets/image_placeholder.dart';

class ProductImageGallery extends StatefulWidget {
  final List<String> images;
  final String fallbackLabel;
  final double height;

  const ProductImageGallery({
    super.key,
    required this.images,
    required this.fallbackLabel,
    this.height = 300,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _current = 0;
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.images.where((u) => u.isNotEmpty).toList();
    final count = urls.isEmpty ? 1 : urls.length;

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: count,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              if (urls.isEmpty) {
                return ImagePlaceholder(
                  label: widget.fallbackLabel,
                  height: widget.height,
                  radius: 0,
                );
              }
              return Image.network(
                urls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => ImagePlaceholder(
                  label: widget.fallbackLabel,
                  height: widget.height,
                  radius: 0,
                ),
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
  }
}
