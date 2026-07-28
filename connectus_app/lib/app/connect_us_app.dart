import 'package:flutter/material.dart';

import 'startup_screen.dart';

class ConnectUsApp extends StatelessWidget {
  const ConnectUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const sage = Color(0xFF6F927E);
    const warmCream = Color(0xFFF8F3E7);
    const softMint = Color(0xFFDDEEE3);
    const charcoal = Color(0xFF25332C);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: sage,
          brightness: Brightness.light,
        ).copyWith(
          primary: sage,
          onPrimary: Colors.white,
          primaryContainer: softMint,
          onPrimaryContainer: charcoal,
          surface: warmCream,
          onSurface: charcoal,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ConnectUs',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: warmCream,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: charcoal,
          surfaceTintColor: Colors.transparent,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: sage,
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.72),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: sage, width: 1.5),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: charcoal,
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const StartupScreen(),
    );
  }
}
