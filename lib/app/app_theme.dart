import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: const ColorScheme.light(
      primary: AppColors.navy,
      onPrimary: AppColors.ivory,
      secondary: AppColors.gold,
      onSecondary: AppColors.midnight,
      tertiary: AppColors.warmBeige,
      onTertiary: AppColors.midnight,
      surface: AppColors.cream,
      onSurface: AppColors.navy,
      error: AppColors.error,
      onError: AppColors.ivory,
      outline: AppColors.gold,
      outlineVariant: AppColors.warmBeige,
      shadow: AppColors.midnight,
      scrim: AppColors.midnight,
      surfaceContainerHighest: AppColors.warmBeige,
      surfaceContainerHigh: AppColors.warmBeige,
      surfaceContainer: AppColors.warmBeige,
      surfaceContainerLow: AppColors.ivory,
      surfaceContainerLowest: AppColors.ivory,
    ),
    fontFamily: 'DMSans',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.midnight,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.midnight,
        letterSpacing: -0.3,
      ),
      displaySmall: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.midnight,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.midnight,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.midnight,
      ),
      titleLarge: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.midnight,
      ),
      titleMedium: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.midnight,
      ),
      titleSmall: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.midnight,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.navy,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.navy,
      ),
      labelLarge: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      labelSmall: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.midnight,
      foregroundColor: AppColors.ivory,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ivory,
        letterSpacing: 0.2,
      ),
      iconTheme: IconThemeData(color: AppColors.ivory),
    ),
    cardTheme: CardThemeData(
      color: AppColors.ivory,
      elevation: 1.5,
      shadowColor: AppColors.midnight.withValues(alpha: 0.06),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.warmBeige, width: 1.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.ivory,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle: const TextStyle(
        fontFamily: 'DMSans',
        color: AppColors.navy,
        fontSize: 13.5,
      ),
      hintStyle: TextStyle(
        fontFamily: 'DMSans',
        color: AppColors.navy.withValues(alpha: 0.55),
        fontSize: 13.5,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.warmBeige, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.warmBeige, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: AppColors.midnight,
      indicatorColor: AppColors.gold,
      elevation: 4,
      shadowColor: AppColors.midnight.withValues(alpha: 0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.midnight : AppColors.ivory,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.midnight : AppColors.ivory,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.ivory,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size(0, 50),
        side: const BorderSide(color: AppColors.gold, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.midnight,
      contentTextStyle: const TextStyle(
        fontFamily: 'DMSans',
        color: AppColors.ivory,
        fontSize: 13.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
