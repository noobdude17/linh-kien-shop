import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Spacing, radius, shadow, kích thước chuẩn — trích từ design handoff.
class AppDimens {
  AppDimens._();

  // Spacing
  static const screenPadding = 20.0;
  static const formPadding = 20.0;
  static const cardPadding = 16.0;
  static const cardPaddingLg = 16.0;
  static const gap = 12.0;

  // Radius
  static const radiusCard = 16.0;
  static const radiusInfoCard = 12.0;
  static const radiusButton = 14.0;
  static const radiusInput = 12.0;
  static const radiusPill = 25.0;
  static const radiusChip = 18.0;

  // Sizes / hit targets
  static const buttonHeight = 52.0;
  static const buttonHeightSm = 44.0;
  static const inputHeight = 52.0;
  static const fabSize = 56.0;
  static const minTapTarget = 44.0;
  static const navIconSize = 21.0;
  static const productImageHeight = 140.0;
  static const heroImageHeight = 300.0;

  // Shadows
  static const cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const primaryButtonShadow = <BoxShadow>[
    BoxShadow(color: Color(0x2617232A), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const accentButtonShadow = <BoxShadow>[
    BoxShadow(color: Color(0x29F97316), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const bottomBarShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, -2)),
  ];
  static const bannerShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const fabShadow = <BoxShadow>[
    BoxShadow(color: Color(0x267C3AED), blurRadius: 10, offset: Offset(0, 3)),
  ];

  // Shorthand BorderRadius
  static final brCard = BorderRadius.circular(radiusCard);
  static final brInfoCard = BorderRadius.circular(radiusInfoCard);
  static final brButton = BorderRadius.circular(radiusButton);
  static final brInput = BorderRadius.circular(radiusInput);
  static final brPill = BorderRadius.circular(radiusPill);
  static final brChip = BorderRadius.circular(radiusChip);

  static final cardBorder = Border.all(color: AppColors.divider);
}
