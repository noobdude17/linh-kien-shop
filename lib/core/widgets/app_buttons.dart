import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Nút chính: full-width, 50px, nền primary, shadow xanh.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppDimens.brButton,
        boxShadow: onPressed == null ? null : AppDimens.primaryButtonShadow,
      ),
      child: SizedBox(
        height: AppDimens.buttonHeight,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          child: _content(label, icon),
        ),
      ),
    );
  }
}

/// Nút viền: viền 1.5px primary, chữ xanh, nền trong suốt.
class AppOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  const AppOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.buttonHeight,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppDimens.brButton),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: _content(label, icon),
      ),
    );
  }
}

/// Nút accent (CTA cam): "Mua ngay", "Thanh toán qua VNPay".
class AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AccentButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppDimens.brButton,
        boxShadow: onPressed == null ? null : AppDimens.accentButtonShadow,
      ),
      child: SizedBox(
        height: AppDimens.buttonHeight,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppDimens.brButton),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          child: _content(label, icon),
        ),
      ),
    );
  }
}

Widget _content(String label, IconData? icon) {
  if (icon == null) return Text(label);
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
  );
}
