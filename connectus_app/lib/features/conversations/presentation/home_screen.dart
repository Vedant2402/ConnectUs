import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/presentation/welcome_screen.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../user_search/presentation/user_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoggingOut = false;
  bool isLoadingConversations = true;

  String? conversationError;

  List<Map<String, dynamic>> conversations = [];

  String? get currentUserId {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  String get userEmail {
    return Supabase.instance.client.auth.currentUser?.email ?? 'ConnectUs user';
  }

  @override
  void initState() {
    super.initState();

    loadConversations();
  }

  Future<void> openUserSearch() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UserSearchScreen()));

    if (!mounted) {
      return;
    }

    await loadConversations();
  }

  Future<void> loadConversations() async {
    final activeUserId = currentUserId;

    if (activeUserId == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingConversations = false;
        conversationError = 'You are not logged in.';
        conversations = [];
      });

      return;
    }

    if (mounted) {
      setState(() {
        isLoadingConversations = true;
        conversationError = null;
      });
    }

    try {
      // Get all conversations that contain the logged-in user.
      final ownMembershipResponse = await Supabase.instance.client
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', activeUserId);

      final ownMemberships = List<Map<String, dynamic>>.from(
        ownMembershipResponse,
      );

      final conversationIds = ownMemberships
          .map((membership) => membership['conversation_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      if (conversationIds.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          conversations = [];
          isLoadingConversations = false;
        });

        return;
      }

      // Get conversation metadata.
      final conversationResponse = await Supabase.instance.client
          .from('conversations')
          .select('id, type, created_at, updated_at')
          .inFilter('id', conversationIds)
          .order('updated_at', ascending: false);

      final conversationRows = List<Map<String, dynamic>>.from(
        conversationResponse,
      );

      // Get the other person from every conversation.
      final otherMembershipResponse = await Supabase.instance.client
          .from('conversation_members')
          .select('conversation_id, user_id')
          .inFilter('conversation_id', conversationIds)
          .neq('user_id', activeUserId);

      final otherMemberships = List<Map<String, dynamic>>.from(
        otherMembershipResponse,
      );

      final otherUserIds = otherMemberships
          .map((membership) => membership['user_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      List<Map<String, dynamic>> profileRows = [];

      if (otherUserIds.isNotEmpty) {
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select(
              'id, username, display_name, avatar_url, '
              'is_online, last_seen_at',
            )
            .inFilter('id', otherUserIds);

        profileRows = List<Map<String, dynamic>>.from(profileResponse);
      }

      // Load all messages for these conversations.
      // They are ordered newest first so the first message
      // found for each conversation is its latest message.
      final messageResponse = await Supabase.instance.client
          .from('messages')
          .select(
            'id, conversation_id, sender_id, content, '
            'created_at, deleted_at',
          )
          .inFilter('conversation_id', conversationIds)
          .order('created_at', ascending: false);

      final messageRows = List<Map<String, dynamic>>.from(messageResponse);

      final membershipsByConversation = <String, Map<String, dynamic>>{};

      for (final membership in otherMemberships) {
        final conversationId = membership['conversation_id']?.toString();

        if (conversationId != null) {
          membershipsByConversation[conversationId] = membership;
        }
      }

      final profilesById = <String, Map<String, dynamic>>{};

      for (final profile in profileRows) {
        final profileId = profile['id']?.toString();

        if (profileId != null) {
          profilesById[profileId] = profile;
        }
      }

      final latestMessagesByConversation = <String, Map<String, dynamic>>{};

      for (final message in messageRows) {
        final conversationId = message['conversation_id']?.toString();

        if (conversationId == null) {
          continue;
        }

        latestMessagesByConversation.putIfAbsent(conversationId, () => message);
      }

      final loadedConversations = <Map<String, dynamic>>[];

      for (final conversation in conversationRows) {
        final conversationId = conversation['id']?.toString();

        if (conversationId == null || conversationId.isEmpty) {
          continue;
        }

        final otherMembership = membershipsByConversation[conversationId];

        final otherUserId = otherMembership?['user_id']?.toString();

        if (otherUserId == null || otherUserId.isEmpty) {
          continue;
        }

        final profile = profilesById[otherUserId];

        final username = profile?['username']?.toString() ?? 'unknown';

        final displayName = profile?['display_name']?.toString() ?? username;

        final latestMessage = latestMessagesByConversation[conversationId];

        loadedConversations.add({
          'conversation_id': conversationId,
          'other_user_id': otherUserId,
          'username': username,
          'display_name': displayName,
          'avatar_url': profile?['avatar_url']?.toString(),
          'is_online': profile?['is_online'] as bool? ?? false,
          'last_seen_at': profile?['last_seen_at'],
          'latest_message': latestMessage?['content'],
          'latest_message_sender_id': latestMessage?['sender_id'],
          'latest_message_time':
              latestMessage?['created_at'] ?? conversation['updated_at'],
          'has_messages': latestMessage != null,
        });
      }

      loadedConversations.sort((first, second) {
        final firstTime = DateTime.tryParse(
          first['latest_message_time']?.toString() ?? '',
        );

        final secondTime = DateTime.tryParse(
          second['latest_message_time']?.toString() ?? '',
        );

        if (firstTime == null && secondTime == null) {
          return 0;
        }

        if (firstTime == null) {
          return 1;
        }

        if (secondTime == null) {
          return -1;
        }

        return secondTime.compareTo(firstTime);
      });

      if (!mounted) {
        return;
      }

      setState(() {
        conversations = loadedConversations;
        isLoadingConversations = false;
        conversationError = null;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        conversations = [];
        isLoadingConversations = false;
        conversationError = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        conversations = [];
        isLoadingConversations = false;
        conversationError = 'Unable to load conversations: $error';
      });
    }
  }

  Future<void> openConversation(Map<String, dynamic> conversation) async {
    final conversationId = conversation['conversation_id']?.toString();

    final otherUserId = conversation['other_user_id']?.toString();

    if (conversationId == null ||
        conversationId.isEmpty ||
        otherUserId == null ||
        otherUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open this conversation.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversationId,
          otherUserId: otherUserId,
          username: conversation['username']?.toString() ?? 'unknown',
          displayName:
              conversation['display_name']?.toString() ?? 'ConnectUs user',
          avatarUrl: conversation['avatar_url']?.toString(),
          isOnline: conversation['is_online'] as bool? ?? false,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await loadConversations();
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
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
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

  String formatConversationTime(dynamic value) {
    if (value == null) {
      return '';
    }

    final dateTime = DateTime.tryParse(value.toString())?.toLocal();

    if (dateTime == null) {
      return '';
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final dayDifference = today.difference(messageDay).inDays;

    if (dayDifference == 0) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');

      final period = hour >= 12 ? 'PM' : 'AM';

      final displayHour = hour == 0
          ? 12
          : hour > 12
          ? hour - 12
          : hour;

      return '$displayHour:$minute $period';
    }

    if (dayDifference == 1) {
      return 'Yesterday';
    }

    if (dayDifference < 7) {
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      return weekdays[dateTime.weekday - 1];
    }

    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FF),
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadConversations,
                child: buildConversationContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavigation(),
    );
  }

  Widget buildHeader() {
    return Padding(
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
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Search users',
            onPressed: openUserSearch,
            icon: const Icon(Icons.search_rounded, size: 27),
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
                      Text(isLoggingOut ? 'Logging out...' : 'Log out'),
                    ],
                  ),
                ),
              ];
            },
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE3E1FF),
              child: Icon(Icons.person_rounded, color: Color(0xFF5B5FEF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildConversationContent() {
    if (isLoadingConversations) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 230),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (conversationError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 120, 20, 24),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 46,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load conversations',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  conversationError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: loadConversations,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 120, 20, 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 38,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B5FEF).withValues(alpha: 0.12),
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
                        onPressed: openUserSearch,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5B5FEF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.add_comment_rounded),
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
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final conversation = conversations[index];

        return buildConversationTile(conversation);
      },
    );
  }

  Widget buildConversationTile(Map<String, dynamic> conversation) {
    final username = conversation['username']?.toString() ?? 'unknown';

    final displayName = conversation['display_name']?.toString() ?? username;

    final avatarUrl = conversation['avatar_url']?.toString();

    final isOnline = conversation['is_online'] as bool? ?? false;

    final latestMessage = conversation['latest_message']?.toString();

    final latestMessageSenderId = conversation['latest_message_sender_id']
        ?.toString();

    final isLatestMessageMine = latestMessageSenderId == currentUserId;

    final latestMessageText =
        latestMessage == null || latestMessage.trim().isEmpty
        ? 'Start your conversation'
        : isLatestMessageMine
        ? 'You: $latestMessage'
        : latestMessage;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => openConversation(conversation),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 29,
                    backgroundColor: const Color(0xFFE3E1FF),
                    backgroundImage:
                        avatarUrl != null && avatarUrl.trim().isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.trim().isEmpty
                        ? Text(
                            getAvatarLetter(displayName, username),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5B5FEF),
                            ),
                          )
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF3F1FF),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      latestMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatConversationTime(conversation['latest_message_time']),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black45,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: _NavigationItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chats',
                  selected: true,
                  onTap: loadConversations,
                ),
              ),
              Expanded(
                child: _NavigationItem(
                  icon: Icons.people_outline_rounded,
                  label: 'People',
                  selected: false,
                  onTap: openUserSearch,
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
                        content: Text('Settings will be added later.'),
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
    final color = selected ? const Color(0xFF5B5FEF) : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF5B5FEF).withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
