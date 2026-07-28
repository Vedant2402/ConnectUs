import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../conversations/presentation/home_screen.dart';

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final displayNameController = TextEditingController();

  bool isSaving = false;

  @override
  void dispose() {
    usernameController.dispose();
    displayNameController.dispose();
    super.dispose();
  }

  String? validateUsername(String? value) {
    final username = value?.trim() ?? '';

    if (username.isEmpty) {
      return 'Please choose a username.';
    }

    if (username.length < 3) {
      return 'Username must contain at least 3 characters.';
    }

    if (username.length > 30) {
      return 'Username cannot exceed 30 characters.';
    }

    final usernamePattern = RegExp(r'^[A-Za-z0-9_]+$');

    if (!usernamePattern.hasMatch(username)) {
      return 'Use only letters, numbers, and underscores.';
    }

    return null;
  }

  String? validateDisplayName(String? value) {
    final displayName = value?.trim() ?? '';

    if (displayName.isEmpty) {
      return 'Please enter your display name.';
    }

    if (displayName.length > 50) {
      return 'Display name cannot exceed 50 characters.';
    }

    return null;
  }

  Future<void> saveProfile() async {
    FocusScope.of(context).unfocus();

    final isValid = formKey.currentState?.validate() ?? false;

    if (!isValid || isSaving) {
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'username': usernameController.text.trim(),
            'display_name': displayNameController.text.trim(),
          })
          .eq('id', currentUser.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.code == '23505'
          ? 'That username is already taken.'
          : error.message;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save your profile. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6F927E),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Create your profile',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose a unique username so other people '
                      'can find you on ConnectUs.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 34),
                    TextFormField(
                      controller: displayNameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: validateDisplayName,
                      decoration: InputDecoration(
                        labelText: 'Display name',
                        hintText: 'Vedant Kankate',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: usernameController,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      validator: validateUsername,
                      onFieldSubmitted: (_) => saveProfile(),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'vedant2402',
                        prefixText: '@',
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                        helperText: 'Letters, numbers, and underscores only.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: isSaving ? null : saveProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6F927E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
