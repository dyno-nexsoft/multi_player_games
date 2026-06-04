import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color neonPurple;
  final Color neonPink;
  final Color neonCyan;
  final Color bgDeep;
  final Color bgSurface;

  const AppColors({
    required this.neonPurple,
    required this.neonPink,
    required this.neonCyan,
    required this.bgDeep,
    required this.bgSurface,
  });

  @override
  AppColors copyWith({
    Color? neonPurple,
    Color? neonPink,
    Color? neonCyan,
    Color? bgDeep,
    Color? bgSurface,
  }) {
    return AppColors(
      neonPurple: neonPurple ?? this.neonPurple,
      neonPink: neonPink ?? this.neonPink,
      neonCyan: neonCyan ?? this.neonCyan,
      bgDeep: bgDeep ?? this.bgDeep,
      bgSurface: bgSurface ?? this.bgSurface,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      neonPurple: Color.lerp(neonPurple, other.neonPurple, t)!,
      neonPink: Color.lerp(neonPink, other.neonPink, t)!,
      neonCyan: Color.lerp(neonCyan, other.neonCyan, t)!,
      bgDeep: Color.lerp(bgDeep, other.bgDeep, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
    );
  }
}
