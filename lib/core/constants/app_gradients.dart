import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFFFF4D67), Color(0xFFFF8599)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softBackground = LinearGradient(
    colors: [Color(0xFFFFF5F5), Color(0xFFFFE8E8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient card = LinearGradient(
    colors: [Color(0xFFFF4D67), Color(0xFFFF7A8F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
