import 'package:flutter/material.dart';

class AppThemeController {
  AppThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;

  static void toggle() {
    mode.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  static void setDark(bool enabled) {
    mode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}
