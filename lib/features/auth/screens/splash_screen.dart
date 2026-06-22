import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _go);
  }

  /// Đã đăng nhập → vào thẳng Home; chưa → xem onboarding (chế độ khách).
  void _go() {
    if (!mounted) return;
    final loggedIn = ref.read(authRepositoryProvider).currentUser != null;
    context.go(loggedIn ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GestureDetector(
        onTap: _go,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⚡', style: TextStyle(fontSize: 52, color: AppColors.accentBlue)),
              SizedBox(height: 12),
              Text('Linh Kiện Shop',
                  style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
              SizedBox(height: 8),
              Text('Linh kiện chính hãng - Giá tốt nhất',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    color: AppColors.accentBlue, strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
