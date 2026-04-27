import 'package:flutter/material.dart';

class AppAnimations {
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Curve pageTransitionCurve = Curves.easeInOutCubic;

  static const Duration cardEntrance = Duration(milliseconds: 400);
  static const Duration cardStaggerDelay = Duration(milliseconds: 100);

  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration successCheckmark = Duration(milliseconds: 800);
  static const Duration sosPulse = Duration(milliseconds: 1500);
  
  static const Duration bottomSheetTransition = Duration(milliseconds: 300);
  static const Duration navigationSlide = Duration(milliseconds: 200);
}
