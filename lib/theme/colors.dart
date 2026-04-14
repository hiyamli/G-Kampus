import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color ink = Color(0xFF1A2942);
  static const Color teal = Color(0xFF31A8AD);
  static const Color sunrise = Color(0xFFFABB59);
  static const Color coral = Color(0xFFED7568);

  static const Color lightTop = Color(0xFFF2F6FB);
  static const Color lightBottom = Color(0xFFFFF0E8);
  static const Color darkTop = Color(0xFF09111C);
  static const Color darkBottom = Color(0xFF141B28);

  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF7F7F3);
  static const Color mist = Color(0xFFD7E1EC);
  static const Color slate = Color(0xFF627089);
  static const Color muted = Color(0xFF94A0B3);
  static const Color line = Color(0x1A1A2942);

  static Color glass(bool isDark) =>
      isDark ? const Color(0x1AFFFFFF) : const Color(0xCCFFFFFF);

  static Color strongGlass(bool isDark) =>
      isDark ? const Color(0x26354352) : const Color(0xE6FFFFFF);

  static Color textPrimary(bool isDark) => isDark ? offWhite : ink;
  static Color textSecondary(bool isDark) =>
      isDark ? const Color(0xB3F7F7F3) : slate;
  static Color shadow(bool isDark) =>
      isDark ? const Color(0x30000000) : const Color(0x141A2942);
}
