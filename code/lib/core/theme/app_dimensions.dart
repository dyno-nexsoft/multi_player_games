import 'package:flutter/material.dart';

class AppDimensions extends ThemeExtension<AppDimensions> {
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;

  const AppDimensions({
    this.radiusSm = 8.0,
    this.radiusMd = 12.0,
    this.radiusLg = 16.0,
    this.spacingSm = 8.0,
    this.spacingMd = 16.0,
    this.spacingLg = 24.0,
  });

  @override
  AppDimensions copyWith({
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
  }) {
    return AppDimensions(
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
    );
  }

  @override
  AppDimensions lerp(ThemeExtension<AppDimensions>? other, double t) {
    if (other is! AppDimensions) return this;
    return AppDimensions(
      radiusSm: (radiusSm + (other.radiusSm - radiusSm) * t),
      radiusMd: (radiusMd + (other.radiusMd - radiusMd) * t),
      radiusLg: (radiusLg + (other.radiusLg - radiusLg) * t),
      spacingSm: (spacingSm + (other.spacingSm - spacingSm) * t),
      spacingMd: (spacingMd + (other.spacingMd - spacingMd) * t),
      spacingLg: (spacingLg + (other.spacingLg - spacingLg) * t),
    );
  }
}
