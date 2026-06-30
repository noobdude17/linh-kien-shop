import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../routes/app_routes.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_scaffold.dart';

class AdminReviewListScreen extends ConsumerStatefulWidget {
  const AdminReviewListScreen({super.key});

  @override
  ConsumerState<AdminReviewListScreen> createState() =>
      _AdminReviewListScreenState();
}

class _AdminReviewListScreenState extends ConsumerState<AdminReviewListScreen> {
  final _search = TextEditingController();
  bool? _hidden;

  AdminReviewQuery get _query =>
      AdminReviewQuery(search: _search.text.trim(), hidden: _hidden, limit: 80);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(adminReviewsProvider(_query));
    return AdminScaffold(
      title: 'Quản lý đánh giá',
      backRoute: AppRoutes.admin,
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: reviews.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AdminError(
                message: 'Không tải được đánh giá',
                onRetry: () => ref.invalidate(adminReviewsProvider),
              ),
              data: (page) => page.items.isEmpty
                  ? const AdminEmpty(
                      message: 'Không có đánh giá',
                      icon: Icons.rate_review_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimens.screenPadding),
                      itemCount: page.items.length,
                      itemBuilder: (_, i) => _row(page.items[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Tìm sản phẩm, người viết, nội dung',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _hidden == null,
                onSelected: (_) => setState(() => _hidden = null),
              ),
              ChoiceChip(
                label: const Text('Đang hiện'),
                selected: _hidden == false,
                onSelected: (_) => setState(() => _hidden = false),
              ),
              ChoiceChip(
                label: const Text('Đã ẩn'),
                selected: _hidden == true,
                onSelected: (_) => setState(() => _hidden = true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(AdminReviewRecord record) {
    final review = record.review;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brCard,
        boxShadow: AppDimens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Switch(
                value: review.isHidden,
                activeThumbColor: AppColors.error,
                onChanged: (v) => _confirmHide(record, v),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: AppColors.star),
              const SizedBox(width: 4),
              Text(
                '${review.rating.toStringAsFixed(1)} · ${review.userName} · ${Formatter.date(review.createdAt)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: const TextStyle(fontSize: 13)),
          if (review.isHidden)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Đã ẩn khỏi app khách hàng',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmHide(AdminReviewRecord record, bool hidden) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hidden ? 'Ẩn đánh giá?' : 'Hiện lại đánh giá?'),
        content: Text(record.productName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(adminRepositoryProvider)
        .setReviewHidden(
          productId: record.review.productId,
          reviewId: record.review.id,
          hidden: hidden,
        );
    invalidateAdminData(ref);
  }
}
