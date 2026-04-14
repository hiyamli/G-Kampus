import 'package:flutter/material.dart';

import 'colors.dart';
import 'radius.dart';
import 'typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.teal,
        onPrimary: Colors.white,
        secondary: AppColors.sunrise,
        onSecondary: AppColors.ink,
        error: AppColors.coral,
        onError: Colors.white,
        surface: AppColors.glass(isDark),
        onSurface: AppColors.textPrimary(isDark),
        surfaceContainerHighest: AppColors.strongGlass(isDark),
        onSurfaceVariant: AppColors.textSecondary(isDark),
        outline: AppColors.line,
        shadow: AppColors.shadow(isDark),
        scrim: Colors.black54,
        inverseSurface: AppColors.ink,
        onInverseSurface: Colors.white,
        tertiary: AppColors.coral,
        onTertiary: Colors.white,
      ),
      textTheme: AppTypography.textTheme(brightness),
    );

    return base.copyWith(
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary(isDark),
        centerTitle: false,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? const Color(0xF0141B28)
            : const Color(0xF9FFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card30),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glass(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card24),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: isDark
            ? const Color(0xCC131B28)
            : const Color(0xCCFFFFFF),
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.teal.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.textSecondary(isDark),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => base.textTheme.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.textSecondary(isDark),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.strongGlass(isDark),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.card22,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.card22,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.card22,
          borderSide: BorderSide(color: AppColors.teal.withValues(alpha: 0.5)),
        ),
        hintStyle: base.textTheme.bodyMedium,
      ),
    );
  }
}
