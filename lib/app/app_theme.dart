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
    fontFamily: 'Arial',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.midnight,
      foregroundColor: AppColors.ivory,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.ivory,
      elevation: 2,
      shadowColor: AppColors.midnight.withValues(alpha: 0.07),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.warmBeige),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.ivory,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle: const TextStyle(color: AppColors.navy),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.warmBeige),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.warmBeige),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
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
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.midnight : AppColors.ivory,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.ivory,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size(0, 50),
        side: const BorderSide(color: AppColors.gold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
