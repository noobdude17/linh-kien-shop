import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../routes/app_routes.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/admin_search_field.dart';

class AdminReviewListScreen extends ConsumerStatefulWidget {
  const AdminReviewListScreen({super.key});

  @override
  ConsumerState<AdminReviewListScreen> createState() =>
      _AdminReviewListScreenState();
}

class _AdminReviewListScreenState extends ConsumerState<AdminReviewListScreen> {
  static const _pageSize = 30;

  final _search = TextEditingController();
  final _scrollController = ScrollController();
  bool? _hidden;
  List<AdminReviewRecord> _items = [];
  Object? _cursor;
  bool _hasMore = true;
  bool _loading = true;
  Object? _error;

  AdminReviewQuery get _query => AdminReviewQuery(
    search: _search.text.trim(),
    hidden: _hidden,
    limit: _pageSize,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearBottom);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadReviews());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Quản lý đánh giá',
      backRoute: AppRoutes.admin,
      body: Column(
        children: [
          _filters(),
          Expanded(child: _reviewList()),
        ],
      ),
    );
  }

  Widget _reviewList() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return AdminError(
        message: 'Không tải được đánh giá',
        onRetry: _reloadReviews,
      );
    }
    if (_items.isEmpty) {
      return const AdminEmpty(
        message: 'Không có đánh giá',
        icon: Icons.rate_review_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _reloadReviews,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _row(_items[i]);
        },
      ),
    );
  }

  Widget _filters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          AdminSearchField(
            controller: _search,
            hintText: 'Tìm sản phẩm, người viết, nội dung...',
            onChanged: (_) => _reloadReviews(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _hidden == null,
                onSelected: (_) => _setHiddenFilter(null),
              ),
              ChoiceChip(
                label: const Text('Đang hiện'),
                selected: _hidden == false,
                onSelected: (_) => _setHiddenFilter(false),
              ),
              ChoiceChip(
                label: const Text('Đã ẩn'),
                selected: _hidden == true,
                onSelected: (_) => _setHiddenFilter(true),
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
              Expanded(
                child: Text(
                  '${review.rating.toStringAsFixed(1)} · ${review.userName} · ${Formatter.date(review.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
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
    await _reloadReviews();
  }

  void _setHiddenFilter(bool? hidden) {
    if (_hidden == hidden) return;
    setState(() => _hidden = hidden);
    _reloadReviews();
  }

  void _loadMoreNearBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMoreReviews();
    }
  }

  Future<void> _reloadReviews() async {
    final query = _query;
    setState(() {
      _loading = true;
      _error = null;
      _hasMore = true;
      _cursor = null;
    });
    try {
      final page = await ref.read(adminRepositoryProvider).getReviews(query);
      if (!mounted || query != _query) return;
      setState(() {
        _items = page.items;
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || query != _query) return;
      setState(() {
        _error = e;
        _items = [];
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_loading || !_hasMore) return;
    final query = AdminReviewQuery(
      search: _search.text.trim(),
      hidden: _hidden,
      limit: _pageSize,
      cursor: _cursor,
    );
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(adminRepositoryProvider).getReviews(query);
      if (!mounted ||
          query.search != _query.search ||
          query.hidden != _hidden) {
        return;
      }
      final seen = _items
          .map((r) => '${r.review.productId}:${r.review.id}')
          .toSet();
      setState(() {
        _items = [
          ..._items,
          ...page.items.where(
            (r) => seen.add('${r.review.productId}:${r.review.id}'),
          ),
        ];
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }
}
