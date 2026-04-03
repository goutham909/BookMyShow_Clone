import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ticketing UI tokens aligned to common consumer booking apps (generic clone styling).
abstract final class AppTokens {
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 22;

  static const Color canvas = Color(0xFFFFFFFF);
  static const Color canvasMuted = Color(0xFFF5F7FA);
  static const Color canvasSearch = Color(0xFFF4F7F9);
  static const Color surfaceMuted = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color searchFill = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF757575);
  /// Primary action red (Book Now, selected tab).
  static const Color primaryRed = Color(0xFFF84464);
  static const Color primaryRedDark = Color(0xFFD32F2F);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color likeGreen = Color(0xFF2E7D32);
  static const Color trendingBlue = Color(0xFF1976D2);
  static const Color scrim = Color(0x66000000);

  static const Color fastFilling = Color(0xFFF28B6D);
  static const Color showtimeGold = Color(0xFFFABB05);
  static const Color seatAvailableGreen = Color(0xFF4CAF50);
  static const Color seatSoldGrey = Color(0xFFE0E0E0);
  static const Color tagNavy = Color(0xFF2D3B5E);
  static const Color interestedBg = Color(0xFFE8EAF6);
  static const Color infoBarCream = Color(0xFFFFF8E1);
  static const Color liveEventsLavender = Color(0xFFF0F0FA);
  static const Color liveEventsIndigo = Color(0xFF373B6E);
  static const Color ticketAccentRose = Color(0xFFC54B5D);
  static const Color eventHeaderGrey = Color(0xFFEBEBEB);
  static const Color nearlyFullYellow = Color(0xFFF9A825);

  static const Color surfaceElevated = surfaceMuted;
  static const Color accent = primaryRed;
  static const Color onAccent = Color(0xFFFFFFFF);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.light(
    primary: AppTokens.primaryRed,
    onPrimary: Colors.white,
    secondary: AppTokens.accentPink,
    onSecondary: Colors.white,
    surface: AppTokens.canvas,
    onSurface: const Color(0xFF212121),
    onSurfaceVariant: AppTokens.textSecondary,
    outline: AppTokens.divider,
    outlineVariant: AppTokens.divider,
  );

  final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: const Color(0xFF212121),
        displayColor: const Color(0xFF212121),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppTokens.canvas,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppTokens.canvas,
      foregroundColor: const Color(0xFF212121),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 20),
    ),
    cardTheme: CardThemeData(
      color: AppTokens.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppTokens.surfaceMuted,
      selectedColor: AppTokens.primaryRed.withValues(alpha: 0.12),
      labelStyle: textTheme.labelLarge,
      side: const BorderSide(color: AppTokens.divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppTokens.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black26,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppTokens.primaryRed : AppTokens.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? AppTokens.primaryRed : AppTokens.textSecondary,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppTokens.primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTokens.primaryRed,
        side: const BorderSide(color: AppTokens.primaryRed),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppTokens.divider, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTokens.searchFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        borderSide: BorderSide.none,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppTokens.textSecondary),
    ),
  );
}
