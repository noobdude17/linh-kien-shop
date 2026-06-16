import 'package:flutter/material.dart';

/// Bảng màu chính thức — trích từ design handoff (Claude Design).
/// KHÔNG hard-code màu rời rạc trong widget; luôn tham chiếu qua đây.
class AppColors {
  AppColors._();

  // Primary
  static const primary = Color(0xFF1565C0);
  static const primaryGradMid = Color(0xFF1976D2);
  static const primaryGradLight = Color(0xFF42A5F5);

  // Accent (CTA, admin)
  static const accent = Color(0xFFFF6F00);

  // Surfaces
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textTertiary = Color(0xFF9AA5B1); // placeholder, struck price

  // Status
  static const success = Color(0xFF2E7D32);
  static const successBg = Color(0xFFE8F5E9);
  static const error = Color(0xFFC62828);
  static const errorBg = Color(0xFFFFEBEE);
  static const star = Color(0xFFFFB300);

  // Dividers / borders
  static const divider = Color(0xFFECEFF1);
  static const dividerAlt = Color(0xFFF0F2F5);
  static const border = Color(0xFFE0E0E0);

  // VNPay brand
  static const vnpBlue = Color(0xFF005BAA);
  static const vnpOrange = Color(0xFFF08200);
  static const vnpGatewayStart = Color(0xFF0A4D8C);
  static const vnpGatewayEnd = Color(0xFF2E7D32);

  // Admin stat accents
  static const statPurple = Color(0xFF7B1FA2);

  /// 12 nền pastel cho icon danh mục (một màu / danh mục).
  static const categoryBgs = <Color>[
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFE8F5E9),
    Color(0xFFFFF3E0),
    Color(0xFFFCE4EC),
    Color(0xFFE0F2F1),
    Color(0xFFE8EAF6),
    Color(0xFFE1F5FE),
    Color(0xFFFFF8E1),
    Color(0xFFE0F7FA),
    Color(0xFFEDE7F6),
    Color(0xFFF1F8E9),
  ];

  // Gradients
  static const bannerGradient = LinearGradient(
    begin: Alignment(-0.8, -0.6),
    end: Alignment(1, 0.6),
    colors: [primary, primaryGradMid, accent],
  );

  static const vnpayGatewayGradient = LinearGradient(
    begin: Alignment(-0.9, -0.4),
    end: Alignment(0.9, 0.4),
    colors: [vnpGatewayStart, primary, vnpGatewayEnd],
  );
}
