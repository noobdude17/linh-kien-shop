import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../routes/app_routes.dart';

class EmptyResultsScreen extends StatelessWidget {
  const EmptyResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        title: const Text('Kết quả tìm kiếm'),
      ),
      body: EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy sản phẩm',
        message: 'Thử từ khóa khác hoặc kiểm tra lại chính tả',
        actionLabel: 'Thử từ khóa khác',
        onAction: () => context.go(AppRoutes.search),
      ),
    );
  }
}
