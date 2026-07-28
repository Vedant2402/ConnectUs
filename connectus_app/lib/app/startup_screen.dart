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
    return Scaffold(
      backgroundColor: const Color(0xFF6F927E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/connectus_app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'ConnectUs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
