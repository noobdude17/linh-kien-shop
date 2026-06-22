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
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // ponytail: 4s safety net — Firebase khôi phục session thực tế <1s
    _timer = Timer(const Duration(seconds: 4),
        () => _go(ref.read(authRepositoryProvider).currentUser != null));
  }

  /// Đã đăng nhập → Home; chưa → onboarding (chế độ khách).
  void _go(bool loggedIn) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _timer?.cancel();
    context.go(loggedIn ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Chờ Firebase khôi phục session (auth state hết loading) rồi mới điều hướng.
    final auth = ref.watch(authStateProvider);
    if (!auth.isLoading) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _go(auth.valueOrNull != null));
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GestureDetector(
        onTap: () => _go(ref.read(authRepositoryProvider).currentUser != null),
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
