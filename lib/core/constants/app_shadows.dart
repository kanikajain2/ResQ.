import 'package:flutter/material.dart';

class AppShadows {
  static const BoxShadow card = BoxShadow(
    color: Color(0x26FF6B6B), // rgba(255,107,107,0.15)
    blurRadius: 20,
    offset: Offset(0, 8),
    spreadRadius: 0,
  );

  static const BoxShadow button = BoxShadow(
    color: Color(0x66FF4757), // rgba(255,71,87,0.4)
    blurRadius: 15,
    offset: Offset(0, 6),
  );

  static const BoxShadow soft = BoxShadow(
    color: Color(0x14000000), // rgba(0,0,0,0.08)
    blurRadius: 12,
    offset: Offset(0, 4),
  );
}
