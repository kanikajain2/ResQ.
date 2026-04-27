import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF4D67);
  static const Color primaryDark = Color(0xFFE63E56);
  static const Color primaryLight = Color(0xFFFF7A8F);
  static const Color accent = Color(0xFFFF8599);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A2E); 
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF00D97E);
  static const Color warning = Color(0xFFFFA502);
  static const Color info = Color(0xFF1E90FF);
  static const Color danger = Color(0xFFFF4D67);
  static const Color overlay = Color(0x26FF4D67); 

  /// Returns a color based on severity level (1=low/green → 5=critical/red)
  static Color getSeverityColor(int severity) {
    switch (severity) {
      case 1: return const Color(0xFF2ED573); // success green
      case 2: return const Color(0xFF7BED9F); // light green
      case 3: return const Color(0xFFFFA502); // warning amber
      case 4: return const Color(0xFFFF6348); // orange
      case 5: return const Color(0xFFFF4757); // danger red
      default: return const Color(0xFFFFA502);
    }
  }
}
