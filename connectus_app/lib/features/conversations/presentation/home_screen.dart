import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme_controller.dart';
import '../../authentication/presentation/welcome_screen.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../user_search/presentation/user_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool isLoggingOut = false;
  bool isLoadingConversations = true;
  String conversationQuery = '';
  String conversationFilter = 'All';
  int selectedTab = 2;

  String? conversationError;

  List<Map<String, dynamic>> conversations = [];
  RealtimeChannel? homeChannel;
  Timer? reloadTimer;
  Timer? presenceHeartbeat;
  late final PageController pageController;

  String? get currentUserId {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: selectedTab);
    WidgetsBinding.instance.addObserver(this);
    setPresence(true);
    presenceHeartbeat = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setPresence(true),
    );
    subscribeToHomeUpdates();
    loadConversations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    reloadTimer?.cancel();
    presenceHeartbeat?.cancel();
    pageController.dispose();
    final channel = homeChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    setPresence(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setPresence(state == AppLifecycleState.resumed);
  }

  Future<void> setPresence(bool isOnline) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'is_online': isOnline,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);
    } catch (error) {
      debugPrint('Unable to update presence: $error');
    }
  }

  void subscribeToHomeUpdates() {
    homeChannel = Supabase.instance.client
        .channel('home:${currentUserId ?? 'anonymous'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => scheduleConversationReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversation_members',
          callback: (_) => scheduleConversationReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (_) => scheduleConversationReload(),
        )
        .subscribe();
  }

  void scheduleConversationReload() {
    reloadTimer?.cancel();
    reloadTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) loadConversations(showLoading: false);
    });
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

  Future<void> loadConversations({bool showLoading = true}) async {
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

    if (mounted && showLoading) {
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

      final unreadCountResponse = await Supabase.instance.client.rpc(
        'get_unread_conversation_counts',
      );

      final unreadCountRows = List<Map<String, dynamic>>.from(
        unreadCountResponse as List,
      );

      final unreadCountsByConversation = <String, int>{};

      for (final unreadRow in unreadCountRows) {
        final conversationId = unreadRow['conversation_id']?.toString();
        final unreadValue = unreadRow['unread_count'];

        if (conversationId == null) {
          continue;
        }

        unreadCountsByConversation[conversationId] = unreadValue is int
            ? unreadValue
            : int.tryParse(unreadValue?.toString() ?? '') ?? 0;
      }

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
          'unread_count': unreadCountsByConversation[conversationId] ?? 0,
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
      await setPresence(false);
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
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: pageController,
        onPageChanged: (index) => setState(() => selectedTab = index),
        children: [
          buildUpdatesTab(),
          buildCallsTab(),
          buildChatsTab(),
          buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: buildBottomNavigation(),
    );
  }

  Widget buildChatsTab() {
    return SafeArea(
      child: Column(
        children: [
          buildHeader(),
          if (conversations.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: TextField(
                onChanged: (value) =>
                    setState(() => conversationQuery = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'Ask ConnectUs or Search',
                  prefixIcon: Icon(Icons.search_rounded, size: 21),
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: ['All', 'Unread', 'Favorites'].map((filter) {
                  final selected = conversationFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) =>
                          setState(() => conversationFilter = filter),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadConversations,
              child: buildConversationContent(),
            ),
          ),
        ],
      ),
    );
  }

  void selectTab(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Widget buildUpdatesTab() {
    return buildSimpleTab(
      title: 'Updates',
      icon: Icons.data_usage_rounded,
      heading: 'Stay connected',
      description:
          'Status updates from your contacts will appear here in a future milestone.',
      actionLabel: 'Find people',
      onAction: openUserSearch,
    );
  }

  Widget buildCallsTab() {
    return buildSimpleTab(
      title: 'Calls',
      icon: Icons.call_outlined,
      heading: 'Your calls',
      description: 'Your secure voice and video call history will appear here.',
      actionLabel: 'Find someone',
      onAction: openUserSearch,
    );
  }

  Widget buildSimpleTab({
    required String title,
    required IconData icon,
    required String heading,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      icon,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    heading,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.person_search_rounded),
                    label: Text(actionLabel),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget buildSettingsTab() {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text(
                'Profile',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(email),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                if (mounted) {
                  await loadConversations(showLoading: false);
                }
              },
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: AppThemeController.mode,
              builder: (context, mode, _) {
                return SwitchListTile(
                  secondary: Icon(
                    mode == ThemeMode.dark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                  ),
                  title: const Text(
                    'Dark mode',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Light mode is the default'),
                  value: mode == ThemeMode.dark,
                  onChanged: AppThemeController.setDark,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(isLoggingOut ? 'Logging out…' : 'Log out'),
              onTap: isLoggingOut ? null : logout,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PopupMenuButton<String>(
                tooltip: 'More options',
                onSelected: (value) {
                  if (value == 'theme') {
                    AppThemeController.toggle();
                  } else if (value == 'logout') {
                    logout();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(
                          AppThemeController.isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppThemeController.isDark
                              ? 'Light mode'
                              : 'Dark mode',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded),
                        const SizedBox(width: 12),
                        Text(isLoggingOut ? 'Logging out…' : 'Log out'),
                      ],
                    ),
                  ),
                ],
                child: _HeaderCircle(
                  icon: Icons.more_horiz_rounded,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const Spacer(),
              _HeaderCircle(
                icon: Icons.camera_alt_rounded,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Camera sharing is coming soon.'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              _HeaderCircle(
                icon: Icons.add_rounded,
                color: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                onTap: openUserSearch,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Chats',
            style: TextStyle(
              fontSize: 36,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: const [
          _ConversationLoadingTile(),
          SizedBox(height: 12),
          _ConversationLoadingTile(),
          SizedBox(height: 12),
          _ConversationLoadingTile(),
          SizedBox(height: 12),
          _ConversationLoadingTile(),
        ],
      );
    }

    if (conversationError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 120, 20, 110),
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
        padding: const EdgeInsets.fromLTRB(20, 120, 20, 110),
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
                        color: const Color(0xFF6F927E).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        size: 44,
                        color: Color(0xFF6F927E),
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
                          backgroundColor: const Color(0xFF6F927E),
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

    final normalizedQuery = conversationQuery.toLowerCase();
    var visibleConversations = normalizedQuery.isEmpty
        ? conversations
        : conversations.where((conversation) {
            final name = conversation['display_name']?.toString().toLowerCase();
            final username = conversation['username']?.toString().toLowerCase();
            final message = conversation['latest_message']
                ?.toString()
                .toLowerCase();
            return (name?.contains(normalizedQuery) ?? false) ||
                (username?.contains(normalizedQuery) ?? false) ||
                (message?.contains(normalizedQuery) ?? false);
          }).toList();

    if (conversationFilter == 'Unread') {
      visibleConversations = visibleConversations
          .where(
            (conversation) => (conversation['unread_count'] as int? ?? 0) > 0,
          )
          .toList();
    } else if (conversationFilter == 'Online') {
      visibleConversations = visibleConversations
          .where((conversation) => conversation['is_online'] == true)
          .toList();
    }

    if (visibleConversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF6F927E)),
          SizedBox(height: 12),
          Center(child: Text('No matching conversations')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      itemCount: visibleConversations.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, indent: 88, color: Theme.of(context).dividerColor),
      itemBuilder: (context, index) {
        final conversation = visibleConversations[index];

        return buildConversationTile(conversation);
      },
    );
  }

  Widget buildConversationTile(Map<String, dynamic> conversation) {
    final username = conversation['username']?.toString() ?? 'unknown';

    final displayName = conversation['display_name']?.toString() ?? username;

    final avatarUrl = conversation['avatar_url']?.toString();

    final isOnline = conversation['is_online'] as bool? ?? false;
    final lastSeen = DateTime.tryParse(
      conversation['last_seen_at']?.toString() ?? '',
    )?.toLocal();
    final isRecentlyActive =
        lastSeen != null && DateTime.now().difference(lastSeen).inSeconds < 75;
    final showAsOnline = isOnline && isRecentlyActive;

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

    final unreadCount = conversation['unread_count'] as int? ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openConversation(conversation),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFDDEEE3),
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
                              color: Color(0xFF6F927E),
                            ),
                          )
                        : null,
                  ),
                  if (showAsOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5FAF7B),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
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
                    const SizedBox(height: 2),
                    Text(
                      showAsOnline ? 'online' : formatLastSeen(lastSeen),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: showAsOnline
                            ? const Color(0xFF4B8F68)
                            : Colors.grey.shade600,
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
                  if (unreadCount > 0)
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6F927E),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.outline,
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
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.data_usage_rounded,
                    label: 'Updates',
                    selected: selectedTab == 0,
                    onTap: () => selectTab(0),
                  ),
                ),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.call_outlined,
                    label: 'Calls',
                    selected: selectedTab == 1,
                    onTap: () => selectTab(1),
                  ),
                ),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chats',
                    selected: selectedTab == 2,
                    onTap: () => selectTab(2),
                  ),
                ),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    selected: selectedTab == 3,
                    onTap: () => selectTab(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatLastSeen(DateTime? value) {
    if (value == null) return 'last seen unavailable';

    final difference = DateTime.now().difference(value);

    if (difference.inMinutes < 1) return 'last seen just now';
    if (difference.inHours < 1) {
      return 'last seen ${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return 'last seen ${difference.inHours}h ago';
    }
    if (difference.inDays == 1) return 'last seen yesterday';

    return 'last seen ${value.month}/${value.day}/${value.year}';
  }
}

class _HeaderCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? foregroundColor;
  final VoidCallback? onTap;

  const _HeaderCircle({
    required this.icon,
    required this.color,
    this.foregroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(
          icon,
          size: 25,
          color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
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
    final color = selected ? const Color(0xFF6F927E) : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 18 : 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
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

class _ConversationLoadingTile extends StatelessWidget {
  const _ConversationLoadingTile();

  @override
  Widget build(BuildContext context) {
    final placeholder = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);

    return Semantics(
      label: 'Loading conversation',
      child: ExcludeSemantics(
        child: Container(
          height: 82,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: placeholder,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.48,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: placeholder,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FractionallySizedBox(
                      widthFactor: 0.78,
                      child: Container(
                        height: 11,
                        decoration: BoxDecoration(
                          color: placeholder,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
