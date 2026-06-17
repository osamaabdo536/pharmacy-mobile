import 'package:flutter/material.dart';

/// Reference design width (most mockups are designed at ~375px).
/// Used to scale sizes proportionally on smaller/larger screens.
const double _baseWidth = 375.0;

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  bool get isTablet => screenWidth >= 600;
  double scale(double value, {double min = 0.85, double max = 1.25}) {
    final factor = (screenWidth / _baseWidth).clamp(min, max);
    return value * factor;
  }
  double get pagePadding {
    if (screenWidth < 360) return 16;
    if (screenWidth < 600) return 20;
    return 32;
  }
  double get maxContentWidth => isTablet ? 480 : double.infinity;
}