import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../routes/app_routes.dart';

class WishlistEmptyScreen extends StatelessWidget {
  const WishlistEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.wishlist)),
        title: const Text('Sản phẩm yêu thích'),
      ),
      body: EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Chưa có sản phẩm yêu thích',
        message: 'Nhấn ♡ trên sản phẩm để lưu vào đây',
        actionLabel: 'Khám phá sản phẩm',
        onAction: () => context.go(AppRoutes.home),
      ),
    );
  }
}
