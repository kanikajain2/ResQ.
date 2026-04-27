import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDark {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.system) {
      // If it's system, we check the platform brightness and toggle away from it
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  void setDark() {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  void setLight() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }
}
