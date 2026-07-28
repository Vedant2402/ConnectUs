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
  @override
  void initState() {
    super.initState();
    restoreSession();
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
            .single();
        final username = profile['username']?.toString().trim() ?? '';
        destination = username.isEmpty
            ? const UsernameSetupScreen()
            : const HomeScreen();
      } catch (_) {
        destination = const WelcomeScreen();
      }
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF3F1FF),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
