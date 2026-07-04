import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';

class AppBackScope extends StatefulWidget {
  const AppBackScope({super.key, required this.child});

  final Widget child;

  @override
  State<AppBackScope> createState() => _AppBackScopeState();
}

class _AppBackScopeState extends State<AppBackScope> {
  DateTime? _lastExitPromptAt;

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        _handleBack();
        return true;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBack();
        },
        child: widget.child,
      ),
    );
  }

  void _handleBack() {
    // Pushed route on the stack — pop it and return to wherever we came from.
    if (context.canPop()) {
      context.pop();
      return;
    }

    final router = GoRouter.of(context);
    final path = router.routerDelegate.currentConfiguration.uri.path;

    if (path == AppRoutes.checkout) {
      context.go(AppRoutes.cart);
      return;
    }

    final accountFallback = _accountFallback(path);
    if (accountFallback != null) {
      context.go(accountFallback);
      return;
    }

    if (path.startsWith('${AppRoutes.partPickerSelect}/')) {
      context.go(AppRoutes.partPicker);
      return;
    }

    if (_isExitRoute(path)) {
      _exitOnSecondBack();
      return;
    }

    context.go(AppRoutes.home);
  }

  String? _accountFallback(String path) {
    if (path.startsWith('${AppRoutes.orderDetail}/')) return AppRoutes.orders;
    if (path == AppRoutes.addAddress) return AppRoutes.addresses;
    if (path == AppRoutes.wishlistEmpty) return AppRoutes.wishlist;

    if (path.startsWith('${AppRoutes.adminProductEdit}/')) {
      return AppRoutes.adminProducts;
    }
    if (path == AppRoutes.adminProductEdit) return AppRoutes.adminProducts;
    if (path.startsWith('${AppRoutes.adminOrderDetail}/')) {
      return AppRoutes.adminOrders;
    }
    if (path == AppRoutes.adminProducts ||
        path == AppRoutes.adminOrders ||
        path == AppRoutes.adminUsers ||
        path == AppRoutes.adminReviews) {
      return AppRoutes.admin;
    }
    if (path == AppRoutes.admin) return AppRoutes.profile;

    if (path == AppRoutes.editProfile ||
        path == AppRoutes.orders ||
        path == AppRoutes.addresses ||
        path == AppRoutes.wishlist ||
        path == AppRoutes.notifications) {
      return AppRoutes.profile;
    }

    return null;
  }

  bool _isExitRoute(String path) {
    return path == AppRoutes.home ||
        path == AppRoutes.login ||
        path == AppRoutes.onboarding;
  }

  void _exitOnSecondBack() {
    final now = DateTime.now();
    final shouldExit =
        _lastExitPromptAt != null &&
        now.difference(_lastExitPromptAt!) < const Duration(seconds: 2);

    if (shouldExit) {
      SystemNavigator.pop();
      return;
    }

    _lastExitPromptAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Chạm một lần nữa để thoát')),
      );
  }
}
