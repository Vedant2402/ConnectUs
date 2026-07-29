import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isOnline = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  late final Stream<List<Map<String, dynamic>>> messagesStream;

  late final Stream<List<Map<String, dynamic>>> receiptsStream;
  late final Stream<List<Map<String, dynamic>>> otherProfileStream;
  late final RealtimeChannel typingChannel;

  final Set<String> markedAsReadMessageIds = {};

  bool isSending = false;
  bool isOtherUserTyping = false;
  bool isUpdatingLastRead = false;
  bool hasPendingLastReadUpdate = false;
  String? lastMarkedReadMessageId;
  String? pendingLastReadMessageId;
  Timer? typingTimer;

  String? get currentUserId {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  void initState() {
    super.initState();

    messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true);

    receiptsStream = Supabase.instance.client
        .from('message_receipts')
        .stream(primaryKey: ['message_id', 'user_id'])
        .eq('user_id', widget.otherUserId);

    otherProfileStream = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', widget.otherUserId);

    typingChannel = Supabase.instance.client
        .channel('typing:${widget.conversationId}')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            if (payload['user_id']?.toString() != widget.otherUserId ||
                !mounted) {
              return;
            }
            setState(() {
              isOtherUserTyping = payload['is_typing'] == true;
            });
          },
        )
        .subscribe();

    messageController.addListener(handleTypingChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      markConversationAsRead();
    });
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    messageController.removeListener(handleTypingChanged);
    unawaited(
      typingChannel.sendBroadcastMessage(
        event: 'typing',
        payload: {'user_id': currentUserId, 'is_typing': false},
      ),
    );
    Supabase.instance.client.removeChannel(typingChannel);
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void handleTypingChanged() {
    final isTyping = messageController.text.trim().isNotEmpty;
    unawaited(
      typingChannel.sendBroadcastMessage(
        event: 'typing',
        payload: {'user_id': currentUserId, 'is_typing': isTyping},
      ),
    );

    typingTimer?.cancel();
    if (isTyping) {
      typingTimer = Timer(const Duration(milliseconds: 1400), () {
        unawaited(
          typingChannel.sendBroadcastMessage(
            event: 'typing',
            payload: {'user_id': currentUserId, 'is_typing': false},
          ),
        );
      });
    }
  }

  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    final senderId = currentUserId;

    if (message.isEmpty || senderId == null || isSending) {
      return;
    }

    setState(() {
      isSending = true;
    });

    messageController.clear();

    try {
      await Supabase.instance.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': senderId,
        'content': message,
        'message_type': 'text',
      });

      scrollToBottom();
    } on PostgrestException catch (error) {
      messageController.text = message;

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
      messageController.text = message;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send the message. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  Future<void> markIncomingMessagesAsRead(
    List<Map<String, dynamic>> messages,
  ) async {
    final activeUserId = currentUserId;

    if (activeUserId == null) {
      return;
    }

    final unreadMessages = messages.where((message) {
      final messageId = message['id']?.toString();
      final senderId = message['sender_id']?.toString();

      if (messageId == null || messageId.isEmpty) {
        return false;
      }

      if (senderId == activeUserId) {
        return false;
      }

      return !markedAsReadMessageIds.contains(messageId);
    }).toList();

    if (unreadMessages.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();

    final receiptRows = unreadMessages.map((message) {
      return {
        'message_id': message['id'].toString(),
        'user_id': activeUserId,
        'delivered_at': now,
        'read_at': now,
      };
    }).toList();

    try {
      await Supabase.instance.client
          .from('message_receipts')
          .upsert(receiptRows, onConflict: 'message_id,user_id');

      for (final message in unreadMessages) {
        final messageId = message['id']?.toString();

        if (messageId != null) {
          markedAsReadMessageIds.add(messageId);
        }
      }
    } on PostgrestException catch (error) {
      debugPrint(
        'Unable to mark messages as read: '
        '${error.message}',
      );
    } catch (error) {
      debugPrint('Unable to mark messages as read: $error');
    }
  }

  Future<void> markConversationAsRead({String? newestIncomingMessageId}) async {
    if (newestIncomingMessageId != null) {
      if (newestIncomingMessageId.isEmpty ||
          newestIncomingMessageId == lastMarkedReadMessageId) {
        return;
      }

      pendingLastReadMessageId = newestIncomingMessageId;
    }

    hasPendingLastReadUpdate = true;

    if (isUpdatingLastRead) {
      return;
    }

    isUpdatingLastRead = true;

    try {
      while (hasPendingLastReadUpdate) {
        hasPendingLastReadUpdate = false;
        final messageIdBeingMarked = pendingLastReadMessageId;

        try {
          await Supabase.instance.client.rpc(
            'mark_conversation_as_read',
            params: {'requested_conversation_id': widget.conversationId},
          );

          if (messageIdBeingMarked != null) {
            lastMarkedReadMessageId = messageIdBeingMarked;
          }
        } on PostgrestException catch (error) {
          debugPrint(
            'Unable to update the last-read message: ${error.message}',
          );
        } catch (error) {
          debugPrint('Unable to update the last-read message: $error');
        }
      }
    } finally {
      isUpdatingLastRead = false;
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String formatMessageTime(dynamic value) {
    if (value == null) {
      return '';
    }

    final dateTime = DateTime.tryParse(value.toString())?.toLocal();

    if (dateTime == null) {
      return '';
    }

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

  String formatLastSeen(DateTime? value) {
    if (value == null) return '@${widget.username}';

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

  DateTime? parseMessageDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  }

  bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${date.month}/${date.day}/${date.year}';
  }

  String getAvatarLetter() {
    final cleanedName = widget.displayName.trim();

    if (cleanedName.isNotEmpty) {
      return cleanedName.substring(0, 1).toUpperCase();
    }

    final cleanedUsername = widget.username.trim();

    if (cleanedUsername.isNotEmpty) {
      return cleanedUsername.substring(0, 1).toUpperCase();
    }

    return '?';
  }

  Map<String, Map<String, dynamic>> createReceiptMap(
    List<Map<String, dynamic>> receipts,
  ) {
    final receiptMap = <String, Map<String, dynamic>>{};

    for (final receipt in receipts) {
      final messageId = receipt['message_id']?.toString();

      if (messageId != null) {
        receiptMap[messageId] = receipt;
      }
    }

    return receiptMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 78,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: _ChatHeaderButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        titleSpacing: 0,
        title: StreamBuilder<List<Map<String, dynamic>>>(
          stream: otherProfileStream,
          builder: (context, snapshot) {
            final profile = snapshot.data?.isNotEmpty == true
                ? snapshot.data!.first
                : <String, dynamic>{};
            final lastActivity =
                profile['last_seen_at'] ??
                profile['updated_at'] ??
                profile['created_at'];
            final lastSeen = DateTime.tryParse(
              lastActivity?.toString() ?? '',
            )?.toLocal();
            final storedOnline =
                profile['is_online'] as bool? ?? widget.isOnline;
            final isRecentlyActive =
                lastSeen != null &&
                DateTime.now().difference(lastSeen).inSeconds < 75;
            final showAsOnline = storedOnline && isRecentlyActive;

            return Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFDDEEE3),
                        backgroundImage:
                            widget.avatarUrl != null &&
                                widget.avatarUrl!.trim().isNotEmpty
                            ? NetworkImage(widget.avatarUrl!)
                            : null,
                        child:
                            widget.avatarUrl == null ||
                                widget.avatarUrl!.trim().isEmpty
                            ? Text(
                                getAvatarLetter(),
                                style: const TextStyle(
                                  color: Color(0xFF6F927E),
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      if (showAsOnline)
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5FAF7B),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          showAsOnline ? 'online' : formatLastSeen(lastSeen),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: showAsOnline
                                ? const Color(0xFF4B8F68)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 10, 3, 10),
            child: _ChatHeaderButton(
              icon: Icons.videocam_outlined,
              tooltip: 'Video call',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video calling will be added later.'),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 10, 10, 10),
            child: _ChatHeaderButton(
              icon: Icons.call_outlined,
              tooltip: 'Voice call',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voice calling will be added later.'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: receiptsStream,
                builder: (context, receiptSnapshot) {
                  final receiptMap = createReceiptMap(
                    receiptSnapshot.data ?? [],
                  );

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: messagesStream,
                    builder: (context, messageSnapshot) {
                      if (messageSnapshot.hasError) {
                        return _ChatErrorState(
                          message: messageSnapshot.error.toString(),
                        );
                      }

                      if (messageSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !messageSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = messageSnapshot.data ?? [];

                      if (messages.isEmpty) {
                        return _EmptyChatState(displayName: widget.displayName);
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        markIncomingMessagesAsRead(messages);

                        final activeUserId = currentUserId;
                        String? newestIncomingMessageId;

                        if (activeUserId != null) {
                          for (final message in messages.reversed) {
                            if (message['sender_id']?.toString() ==
                                activeUserId) {
                              continue;
                            }

                            newestIncomingMessageId = message['id']?.toString();
                            break;
                          }
                        }

                        if (newestIncomingMessageId != null) {
                          markConversationAsRead(
                            newestIncomingMessageId: newestIncomingMessageId,
                          );
                        }

                        scrollToBottom();
                      });

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];

                          final messageId = message['id']?.toString() ?? '';

                          final senderId = message['sender_id']?.toString();

                          final isMine = senderId == currentUserId;

                          final content = message['content']?.toString() ?? '';

                          final createdAt = message['created_at'];

                          final receipt = receiptMap[messageId];

                          final deliveredAt = receipt?['delivered_at'];

                          final readAt = receipt?['read_at'];

                          final messageDate = parseMessageDate(createdAt);
                          final previousMessage = index > 0
                              ? messages[index - 1]
                              : null;
                          final previousDate = parseMessageDate(
                            previousMessage?['created_at'],
                          );
                          final showDate =
                              messageDate != null &&
                              (previousDate == null ||
                                  !isSameDay(messageDate, previousDate));
                          final previousSender = previousMessage?['sender_id']
                              ?.toString();
                          final isGrouped =
                              previousSender == senderId &&
                              messageDate != null &&
                              previousDate != null &&
                              messageDate.difference(previousDate).inMinutes <
                                  5;

                          return Column(
                            children: [
                              if (showDate)
                                _DateSeparator(
                                  label: formatDateLabel(messageDate),
                                ),
                              _MessageBubble(
                                content: content,
                                time: formatMessageTime(createdAt),
                                isMine: isMine,
                                isDelivered: deliveredAt != null,
                                isRead: readAt != null,
                                isGrouped: isGrouped,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isOtherUserTyping
                  ? Padding(
                      key: const ValueKey('typing'),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${widget.displayName} is typing…',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('not-typing')),
            ),
            _MessageComposer(
              controller: messageController,
              isSending: isSending,
              onSend: sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final String label;

  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final String displayName;

  const _EmptyChatState({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDDEEE3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    size: 36,
                    color: Color(0xFF6F927E),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Start chatting with $displayName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Send the first message and begin '
                  'your conversation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.45, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatErrorState extends StatelessWidget {
  final String message;

  const _ChatErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 14),
              const Text(
                'Unable to load messages',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ChatHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: CircleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final String time;
  final bool isMine;
  final bool isDelivered;
  final bool isRead;
  final bool isGrouped;

  const _MessageBubble({
    required this.content,
    required this.time,
    required this.isMine,
    required this.isDelivered,
    required this.isRead,
    required this.isGrouped,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: IntrinsicWidth(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.76,
          ),
          margin: EdgeInsets.only(bottom: isGrouped ? 3 : 9),
          padding: const EdgeInsets.fromLTRB(15, 11, 11, 7),
          decoration: BoxDecoration(
            color: isMine
                ? (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF436B56)
                      : const Color(0xFF668D77))
                : (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C302E)
                      : const Color(0xFFE5E9E6)),
            border: Border.all(
              color: isMine
                  ? const Color(0xFF527762)
                  : Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMine ? 20 : 5),
              bottomRight: Radius.circular(isMine ? 5 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                content,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.35,
                  color: isMine
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.72)
                          : Colors.grey.shade600,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isDelivered || isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 15,
                      color: isRead
                          ? const Color(0xFFA9D9C0)
                          : Colors.white.withValues(alpha: 0.78),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Add attachment',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attachments will be added later.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF6F927E),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: Color(0xFF6F927E),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: isSending ? 0.92 : 1,
            child: IconButton.filled(
              tooltip: 'Send message',
              onPressed: isSending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF6F927E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFF6F927E,
                ).withValues(alpha: 0.55),
              ),
              icon: isSending
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
