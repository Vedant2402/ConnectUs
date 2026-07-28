import 'package:flutter/material.dart';

import '../features/authentication/presentation/welcome_screen.dart';

class ConnectUsApp extends StatelessWidget {
  const ConnectUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ConnectUs',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B5FEF),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}