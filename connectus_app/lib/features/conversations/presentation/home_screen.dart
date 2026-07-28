import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/presentation/welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoggingOut = false;

  String get userEmail {
    return Supabase.instance.client.auth.currentUser?.email ??
        'ConnectUs user';
  }

  Future<void> logout() async {
    if (isLoggingOut) {
      return;
    }

    setState(() {
      isLoggingOut = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to log out. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  void showSearchMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Username search will be added next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showNewChatMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New chat creation will be added next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5FEF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ConnectUs',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Your conversations',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search users',
                    onPressed: showSearchMessage,
                    icon: const Icon(
                      Icons.search_rounded,
                      size: 27,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Account options',
                    onSelected: (value) {
                      if (value == 'logout') {
                        logout();
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<String>(
                          enabled: false,
                          child: SizedBox(
                            width: 220,
                            child: Text(
                              userEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(Icons.logout_rounded),
                              const SizedBox(width: 12),
                              Text(
                                isLoggingOut
                                    ? 'Logging out...'
                                    : 'Log out',
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                    icon: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFE3E1FF),
                      child: Icon(
                        Icons.person_rounded,
                        color: Color(0xFF5B5FEF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 430,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 38,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B5FEF)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.forum_outlined,
                              size: 44,
                              color: Color(0xFF5B5FEF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No conversations yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Search for someone by their username '
                            'and start your first conversation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: showNewChatMessage,
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF5B5FEF),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_comment_rounded,
                              ),
                              label: const Text(
                                'Start a new chat',
                                style: TextStyle(
                                  fontSize: 16,
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 7,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chats',
                    selected: true,
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.people_outline_rounded,
                    label: 'People',
                    selected: false,
                    onTap: showSearchMessage,
                  ),
                ),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    selected: false,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Settings will be added later.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFF5B5FEF)
        : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF5B5FEF)
                        .withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 23,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}