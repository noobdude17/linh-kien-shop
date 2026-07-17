import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../routes/app_routes.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/admin_search_field.dart';

class AdminOrderManagementScreen extends ConsumerStatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  ConsumerState<AdminOrderManagementScreen> createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState
    extends ConsumerState<AdminOrderManagementScreen> {
  static const _pageSize = 30;

  final _search = TextEditingController();
  final _scrollController = ScrollController();
  String? _status;
  List<OrderModel> _items = [];
  Object? _cursor;
  bool _hasMore = true;
  bool _loading = true;
  Object? _error;

  static const _statuses = <(String, String?)>[
    ('Tất cả', null),
    ('Chờ xác nhận', AppConstants.statusPending),
    ('Đã xác nhận', AppConstants.statusConfirmed),
    ('Đang giao', AppConstants.statusShipping),
    ('Hoàn thành', AppConstants.statusDelivered),
    ('Đã hủy', AppConstants.statusCancelled),
  ];

  AdminOrderQuery get _query => AdminOrderQuery(
    search: _search.text.trim(),
    status: _status,
    limit: _pageSize,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearBottom);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadOrders());
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
      title: 'Quản lý đơn hàng',
      backRoute: AppRoutes.admin,
      body: Column(
        children: [
          _filters(),
          Expanded(child: _orderList()),
        ],
      ),
    );
  }

  Widget _orderList() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return AdminError(
        message: 'Không tải được đơn hàng',
        onRetry: _reloadOrders,
      );
    }
    if (_items.isEmpty) {
      return const AdminEmpty(
        message: 'Không có đơn hàng',
        icon: Icons.receipt_long_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _reloadOrders,
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
            hintText: 'Tìm mã đơn, khách hàng, địa chỉ...',
            onChanged: (_) => _reloadOrders(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final item = _statuses[i];
                return ChoiceChip(
                  label: Text(item.$1),
                  selected: _status == item.$2,
                  onSelected: (_) => _setStatusFilter(item.$2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(OrderModel o) => InkWell(
    onTap: () => context.push('${AppRoutes.adminOrderDetail}/${o.id}'),
    borderRadius: AppDimens.brCard,
    child: Container(
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
                  o.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: o.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${o.customerName} · ${Formatter.date(o.createdAt)} · ${o.itemCount} SP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng tiền',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  Formatter.price(o.totalAmount),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.adminPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _setStatusFilter(String? status) {
    if (_status == status) return;
    setState(() => _status = status);
    _reloadOrders();
  }

  void _loadMoreNearBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMoreOrders();
    }
  }

  Future<void> _reloadOrders() async {
    final query = _query;
    setState(() {
      _loading = true;
      _error = null;
      _hasMore = true;
      _cursor = null;
    });
    try {
      final page = await ref.read(adminRepositoryProvider).getOrders(query);
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

  Future<void> _loadMoreOrders() async {
    if (_loading || !_hasMore) return;
    final query = AdminOrderQuery(
      search: _search.text.trim(),
      status: _status,
      limit: _pageSize,
      cursor: _cursor,
    );
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(adminRepositoryProvider).getOrders(query);
      if (!mounted ||
          query.search != _query.search ||
          query.status != _status) {
        return;
      }
      final seen = _items.map((o) => o.id).toSet();
      setState(() {
        _items = [..._items, ...page.items.where((o) => seen.add(o.id))];
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
