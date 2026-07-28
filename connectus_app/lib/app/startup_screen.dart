import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/authentication/presentation/welcome_screen.dart';
import '../features/conversations/presentation/home_screen.dart';
import '../features/profile/presentation/username_setup_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  Timer? fallbackTimer;
  bool hasNavigated = false;

  @override
  void initState() {
    super.initState();
    fallbackTimer = Timer(
      const Duration(seconds: 5),
      () => openScreen(const WelcomeScreen()),
    );
    restoreSession();
  }

  @override
  void dispose() {
    fallbackTimer?.cancel();
    super.dispose();
  }

  void openScreen(Widget destination) {
    if (!mounted || hasNavigated) return;

    hasNavigated = true;
    fallbackTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
    });
  }

  Future<void> restoreSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    Widget destination = const WelcomeScreen();

    if (user != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .single()
            .timeout(const Duration(seconds: 4));
        final username = profile['username']?.toString().trim() ?? '';
        destination = username.isEmpty
            ? const UsernameSetupScreen()
            : const HomeScreen();
      } catch (_) {
        destination = const WelcomeScreen();
      }
    }

    openScreen(destination);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8F3E7),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
