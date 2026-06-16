import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({super.key});

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) context.go(AppRoutes.success);
    });
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(width: 48, height: 48, child: CircularProgressIndicator(color: AppColors.primary)),
            SizedBox(height: 24),
            Text('Đang xử lý thanh toán...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Vui lòng không tắt ứng dụng', style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 32),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'VN', style: TextStyle(color: AppColors.vnpBlue, fontWeight: FontWeight.w900)),
              TextSpan(text: 'PAY', style: TextStyle(color: AppColors.vnpOrange, fontWeight: FontWeight.w900)),
            ])),
          ],
        ),
      ),
    );
  }
}
