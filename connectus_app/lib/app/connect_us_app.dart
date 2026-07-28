import 'package:flutter/material.dart';

import '../core/theme/app_theme_controller.dart';
import 'startup_screen.dart';

class ConnectUsApp extends StatelessWidget {
  const ConnectUsApp({super.key});

  ThemeData buildTheme(Brightness brightness) {
    const sage = Color(0xFF6F927E);
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF0B0D0C)
        : const Color(0xFFFFFFFF);
    final surface = isDark ? const Color(0xFF202321) : const Color(0xFFF4F5F4);
    final text = isDark ? const Color(0xFFF5F7F5) : const Color(0xFF18201C);

    final scheme = ColorScheme.fromSeed(seedColor: sage, brightness: brightness)
        .copyWith(
          primary: isDark ? const Color(0xFF7FC39B) : sage,
          surface: background,
          onSurface: text,
          surfaceContainerHighest: surface,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: isDark ? const Color(0xFF252826) : const Color(0xFFE8EAE8),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: isDark ? const Color(0xFF102117) : Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: scheme.primary, width: 1.3),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF303431)
            : const Color(0xFF25332C),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ConnectUs',
          themeMode: mode,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: const StartupScreen(),
        );
      },
    );
  }
}
