import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../chat/presentation/chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController searchController = TextEditingController();

  Timer? debounceTimer;

  List<Map<String, dynamic>> users = [];

  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    debounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged(String value) {
    debounceTimer?.cancel();

    debounceTimer = Timer(const Duration(milliseconds: 450), () {
      searchUsers(value);
    });

    setState(() {});
  }

  Future<void> searchUsers(String value) async {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        users = [];
        isLoading = false;
        errorMessage = null;
      });

      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      final response = await Supabase.instance.client
          .from('profiles')
          .select(
            'id, username, username_normalized, display_name, '
            'bio, avatar_url, is_online',
          )
          .ilike('username_normalized', '$query%')
          .limit(20);

      final results = List<Map<String, dynamic>>.from(response);

      if (!mounted) {
        return;
      }

      setState(() {
        users = results
            .where((profile) => profile['id'] != currentUserId)
            .toList();
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = error.message;
        users = [];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Unable to search users. Please try again.';
        users = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void openUserProfile(Map<String, dynamic> user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => UserPreviewScreen(user: user)),
    );
  }

  String getAvatarLetter(String displayName, String username) {
    final cleanedDisplayName = displayName.trim();

    if (cleanedDisplayName.isNotEmpty) {
      return cleanedDisplayName.substring(0, 1).toUpperCase();
    }

    final cleanedUsername = username.trim();

    if (cleanedUsername.isNotEmpty) {
      return cleanedUsername.substring(0, 1).toUpperCase();
    }

    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FF),
      appBar: AppBar(
        title: const Text('Find people'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: TextField(
                controller: searchController,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by username',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: buildSearchContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchContent() {
    if (isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 42,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 14),
                Text(errorMessage!, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    if (searchController.text.trim().isEmpty) {
      return Center(
        key: const ValueKey('initial'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_search_rounded,
                  size: 54,
                  color: Color(0xFF5B5FEF),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Find someone',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter a username to search for '
                  'people on ConnectUs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.45, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 50,
                  color: Color(0xFF5B5FEF),
                ),
                const SizedBox(height: 18),
                const Text(
                  'No users found',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try another username.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('results'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];

        final username = user['username']?.toString() ?? 'unknown';

        final displayName = user['display_name']?.toString() ?? username;

        final avatarUrl = user['avatar_url']?.toString();

        final isOnline = user['is_online'] as bool? ?? false;

        return GlassCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => openUserProfile(user),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFE3E1FF),
                    backgroundImage:
                        avatarUrl != null && avatarUrl.trim().isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.trim().isEmpty
                        ? Text(
                            getAvatarLetter(displayName, username),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5B5FEF),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '@$username',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  if (isOnline)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF34C759),
                        shape: BoxShape.circle,
                      ),
                    ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class UserPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserPreviewScreen({super.key, required this.user});

  @override
  State<UserPreviewScreen> createState() => _UserPreviewScreenState();
}

class _UserPreviewScreenState extends State<UserPreviewScreen> {
  bool isOpeningChat = false;

  Future<void> openConversation() async {
    if (isOpeningChat) {
      return;
    }

    final otherUserId = widget.user['id']?.toString();

    if (otherUserId == null || otherUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify this user.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      isOpeningChat = true;
    });

    try {
      final result = await Supabase.instance.client.rpc(
        'create_or_get_direct_conversation',
        params: {'other_user_id': otherUserId},
      );

      final conversationId = result?.toString();

      if (conversationId == null ||
          conversationId.isEmpty ||
          conversationId == 'null') {
        throw Exception('Conversation ID was not returned.');
      }

      if (!mounted) {
        return;
      }

      final username = widget.user['username']?.toString() ?? 'unknown';

      final displayName = widget.user['display_name']?.toString() ?? username;

      final avatarUrl = widget.user['avatar_url']?.toString();

      final isOnline = widget.user['is_online'] as bool? ?? false;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherUserId: otherUserId,
            username: username,
            displayName: displayName,
            avatarUrl: avatarUrl,
            isOnline: isOnline,
          ),
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open the conversation: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpeningChat = false;
        });
      }
    }
  }

  String getAvatarLetter(String displayName, String username) {
    final cleanedDisplayName = displayName.trim();

    if (cleanedDisplayName.isNotEmpty) {
      return cleanedDisplayName.substring(0, 1).toUpperCase();
    }

    final cleanedUsername = username.trim();

    if (cleanedUsername.isNotEmpty) {
      return cleanedUsername.substring(0, 1).toUpperCase();
    }

    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user['username']?.toString() ?? 'unknown';

    final displayName = widget.user['display_name']?.toString() ?? username;

    final bio = widget.user['bio']?.toString();

    final avatarUrl = widget.user['avatar_url']?.toString();

    final isOnline = widget.user['is_online'] as bool? ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FF),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFFE3E1FF),
                          backgroundImage:
                              avatarUrl != null && avatarUrl.trim().isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.trim().isEmpty
                              ? Text(
                                  getAvatarLetter(displayName, username),
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF5B5FEF),
                                  ),
                                )
                              : null,
                        ),
                        if (isOnline)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 17,
                              height: 17,
                              decoration: BoxDecoration(
                                color: const Color(0xFF34C759),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF3F1FF),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '@$username',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOnline ? 'Online' : 'ConnectUs user',
                      style: TextStyle(
                        color: isOnline
                            ? const Color(0xFF2A9D55)
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (bio != null && bio.trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: isOpeningChat ? null : openConversation,
                        icon: isOpeningChat
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.chat_bubble_rounded),
                        label: Text(
                          isOpeningChat ? 'Opening chat...' : 'Message',
                          style: const TextStyle(
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
    );
  }
}
