import 'package:flutter/material.dart';

/// Bảng màu chính thức — trích từ design handoff (Claude Design).
/// KHÔNG hard-code màu rời rạc trong widget; luôn tham chiếu qua đây.
class AppColors {
  AppColors._();

  // Primary
  static const primary = Color(0xFF0F172A);
  static const accentBlue = Color(0xFF2563EB);
  static const primaryGradMid = Color(0xFF111827);
  static const primaryGradLight = Color(0xFF2563EB);

  // Accent (CTA, admin)
  static const accent = Color(0xFFF97316);

  // Surfaces
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const inputFill = Color(0xFFF3F4F6);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const bodyText = Color(0xFF374151);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF); // placeholder, struck price

  // Status
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFDCFCE7);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEE2E2);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFEF3C7);
  static const shippingBg = Color(0xFFDBEAFE);
  static const doneBg = Color(0xFFF3F4F6);
  static const star = Color(0xFFF59E0B);

  // Dividers / borders
  static const divider = Color(0xFFF3F4F6);
  static const dividerAlt = Color(0xFFE5E7EB);
  static const border = Color(0xFFE5E7EB);

  // VNPay brand
  static const vnpBlue = Color(0xFF005BAA);
  static const vnpOrange = Color(0xFFF08200);
  static const vnpGatewayStart = Color(0xFF0A4D8C);
  static const vnpGatewayEnd = Color(0xFF2E7D32);

  // Admin stat accents
  static const adminAccent = Color(0xFF7C3AED);
  static const statPurple = adminAccent;

  /// 12 nền pastel cho icon danh mục (một màu / danh mục).
  static const categoryBgs = <Color>[
    inputFill,
    inputFill,
    inputFill,
    inputFill,
    inputFill,
    inputFill,
    inputFill,
    inputFill,
    inputFill,
    inputFill,
    inputFill,
    inputFill,
  ];

  // Gradients
  static const bannerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, Color(0x0011172A)],
  );

  static const vnpayGatewayGradient = LinearGradient(
    begin: Alignment(-0.9, -0.4),
    end: Alignment(0.9, 0.4),
    colors: [vnpGatewayStart, primary, vnpGatewayEnd],
  );
}
