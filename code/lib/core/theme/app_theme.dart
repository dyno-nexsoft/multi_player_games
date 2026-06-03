import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const neonPurple = Color(0xFF6C63FF);
  static const neonPink = Color(0xFFFF6584);
  static const neonCyan = Color(0xFF00D9FF);
  static const bgDeep = Color(0xFF11111B);
  static const bgSurface = Color(0xFF1E1E2E);

  // ── Glow helpers ───────────────────────────────────────────────────────────
  /// Returns a `List<BoxShadow>` that creates a neon glow effect.
  static List<BoxShadow> glowShadow(
    Color color, {
    double spread = 0,
    double blur = 14,
  }) => [
    BoxShadow(
      color: color.withValues(alpha: 0.55),
      blurRadius: blur,
      spreadRadius: spread,
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: blur * 2,
      spreadRadius: spread,
    ),
  ];

  /// BoxDecoration for a glassmorphism surface.
  static BoxDecoration glassmorphism({
    Color? borderColor,
    double borderRadius = 16,
    double bgOpacity = 0.72,
  }) {
    final b = borderColor ?? neonPurple;
    return BoxDecoration(
      color: bgSurface.withValues(alpha: bgOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: b.withValues(alpha: 0.35), width: 1.5),
      boxShadow: [BoxShadow(color: b.withValues(alpha: 0.10), blurRadius: 12)],
    );
  }

  // ── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: neonPurple,
      onPrimary: Colors.white,
      secondary: neonPink,
      onSecondary: Colors.white,
      tertiary: neonCyan,
      onTertiary: Colors.black,
      error: Color(0xFFCF6679),
      onError: Colors.white,
      surface: bgSurface,
      onSurface: Color(0xFFCDD6F4),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgDeep,
      textTheme: GoogleFonts.nunitoTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: neonPurple.withValues(alpha: 0.2), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonPurple.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonPurple.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonPurple, width: 1.5),
        ),
      ),
    );
  }
}
