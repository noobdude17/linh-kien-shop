import 'package:flutter/material.dart';

/// Bảng màu chính thức — trích từ design handoff (Claude Design).
/// KHÔNG hard-code màu rời rạc trong widget; luôn tham chiếu qua đây.
class AppColors {
  AppColors._();

  // Primary — app brand accent is orange (matches admin's old orange palette)
  static const primary = Color(0xFFEA580C); // orange-600 (CTA/brand)
  static const accentBlue = Color(0xFFF97316); // secondary accent, orange-500
  static const primaryGradMid = Color(0xFF111827);
  static const primaryGradLight = Color(0xFFF97316);

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
  static const favorite = Color(0xFFEF4444); // tim yêu thích
  static const wishlistChipBg = Color(0xCCFFFFFF); // nền chip tim trên ảnh
  static const overlayScrim = Colors.black26; // phủ mờ ảnh hết hàng

  // Soft backgrounds (nền nhạt cho chip/icon tròn/hộp thông tin)
  static const accentBlueBg = Color(0xFFFFF7ED); // orange-50 (paired soft bg)
  static const accentSoftBg = Color(0xFFFFF7ED); // orange-50
  static const accentSoftBorder = Color(0xFFFB923C); // orange-400
  static const dotInactive = Color(0xFFD1D5DB); // gray-300

  // Dividers / borders
  static const divider = Color(0xFFF3F4F6);
  static const dividerAlt = Color(0xFFE5E7EB);
  static const border = Color(0xFFE5E7EB);

  // ── Dark mode surfaces ──────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF0A0F1A);
  static const darkSurface = Color(0xFF111827);
  static const darkElevated = Color(0xFF1E293B);
  static const darkInputFill = Color(0xFF1E293B);

  // Dark mode text
  static const darkTextPrimary = Color(0xFFF1F5F9);
  static const darkBodyText = Color(0xFFCBD5E1);
  static const darkTextSecond = Color(0xFF94A3B8);
  static const darkTextTertiary = Color(0xFF64748B);

  // Dark mode borders / dividers
  static const darkBorder = Color(0xFF1E293B);
  static const darkDivider = Color(0xFF1E293B);

  // ── VNPay brand
  static const vnpBlue = Color(0xFF005BAA);
  static const vnpOrange = Color(0xFFF08200);
  static const vnpGatewayStart = Color(0xFF0A4D8C);
  static const vnpGatewayEnd = Color(0xFF2E7D32);

  // ── Admin console theme (xanh dương) ──
  static const adminAccent = Color(0xFF3B82F6); // blue-500
  static const adminPrimary = Color(0xFF2563EB); // blue-600
  static const adminPrimaryDark = Color(0xFF1E40AF); // blue-800
  static const adminBg = Color(0xFFEFF6FF); // nền xanh rất nhạt
  static const adminSurfaceTint = Color(0xFFDBEAFE); // chip/nền phụ
  static const statPurple = Color(0xFF7C3AED); // giữ tím cho 1 ô thống kê

  static const adminHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [adminPrimary, adminPrimaryDark],
  );

  /// 12 nền pastel cho icon danh mục (một màu / danh mục).
  static const categoryBgs = <Color>[
    Color(0xFFEFF6FF), // blue
    Color(0xFFF0FDF4), // green
    Color(0xFFFEF2F2), // red
    Color(0xFFFFF7ED), // orange
    Color(0xFFF5F3FF), // violet
    Color(0xFFFEFCE8), // yellow
    Color(0xFFECFEFF), // cyan
    Color(0xFFFDF2F8), // pink
    Color(0xFFEEF2FF), // indigo
    Color(0xFFF0FDFA), // teal
    Color(0xFFFFFBEB), // amber
    Color(0xFFF8FAFC), // slate
  ];

  // Banner (đen)
  static const bannerDark = Color(0xFF0F172A);

  // Gradients
  static const bannerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [bannerDark, Color(0x0011172A)],
  );

  static const vnpayGatewayGradient = LinearGradient(
    begin: Alignment(-0.9, -0.4),
    end: Alignment(0.9, 0.4),
    colors: [vnpGatewayStart, primary, vnpGatewayEnd],
  );
}
