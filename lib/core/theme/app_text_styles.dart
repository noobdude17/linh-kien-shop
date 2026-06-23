import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Thang typography — trích từ design handoff (Roboto 400/500/700/900).
class AppTextStyles {
  AppTextStyles._();

  static const _family = 'Inter';

  static const heroTitle = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const appBarTitle = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const sectionHeading = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const priceDetail = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const priceCard = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.bodyText,
  );

  static const meta = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const badge = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const oldPrice = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    color: AppColors.textTertiary,
    decoration: TextDecoration.lineThrough,
  );

  static const oldPriceDetail = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    color: AppColors.textTertiary,
    decoration: TextDecoration.lineThrough,
  );

  static const productCardName = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const productCardMeta = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const total = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}
