import 'package:flutter/material.dart';

/// Extension to get theme-aware colors from any BuildContext.
/// Use `context.tc.cardColor` instead of `Colors.white` etc.
extension ThemeColorsExt on BuildContext {
  _ThemeColors get tc => _ThemeColors(Theme.of(this));
}

class _ThemeColors {
  final ThemeData _theme;
  _ThemeColors(this._theme);

  bool get isDark => _theme.brightness == Brightness.dark;

  /// Card/surface background
  Color get cardColor => isDark ? const Color(0xFF1E1E2E) : Colors.white;

  /// Main scaffold/page background
  Color get bgColor =>
      isDark ? const Color(0xFF121218) : const Color(0xFFFFF5F5);

  /// Softer background for inputs/secondary areas
  Color get inputBg =>
      isDark ? const Color(0xFF2A2A3A) : const Color(0xFFFFF5F5);

  /// Primary text
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF2D2D2D);

  /// Secondary/dimmed text
  Color get textSecondary => isDark ? Colors.white60 : const Color(0xFF8A8A8A);

  /// Border/divider color
  Color get border => isDark ? Colors.white12 : Colors.grey.shade300;

  /// Shadow for cards
  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ]
      : [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ];
}
