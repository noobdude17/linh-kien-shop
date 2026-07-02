import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../data/mock_data.dart';
import '../../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;

  void _next() {
    if (_index < MockData.onboarding.length - 1) {
      setState(() => _index++);
    } else {
      context.go(AppRoutes.home); // vào thẳng app ở chế độ khách
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = MockData.onboarding[_index];
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text(
                    'Bỏ qua',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(40),
                ),
                alignment: Alignment.center,
                child: Text(
                  slide['illust']!,
                  style: const TextStyle(fontSize: 96),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                slide['title']!,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide['desc']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(MockData.onboarding.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.dotInactive,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Tiếp tục', onPressed: _next),
            ],
          ),
        ),
      ),
    );
  }
}
