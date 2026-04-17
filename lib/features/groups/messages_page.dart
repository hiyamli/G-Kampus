import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
import '../../core/supabase/supabase_service.dart';
import '../../theme/colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/tag_badge.dart';
import 'chat_page.dart';
import 'create_group_page.dart';
import 'direct_message_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, this.onDataChanged});

  final VoidCallback? onDataChanged;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool expanded = false;
  bool _loadingPreviews = false;
  Timer? _pendingDeleteTimer;
  _ConversationSnapshot? _pendingSnapshot;

  @override
  void initState() {
    super.initState();
    _ensurePreviewsLoaded();
  }

  @override
  void dispose() {
    _pendingDeleteTimer?.cancel();
    super.dispose();
  }

  Future<void> _ensurePreviewsLoaded() async {
    if (_loadingPreviews) return;
    _loadingPreviews = true;
    await SupabaseService.loadAllConversationPreviews();
    _loadingPreviews = false;
    if (!mounted) return;
    setState(() {});
    widget.onDataChanged?.call();
  }

  List<GroupItem> _sortedGroups() {
    final list = List<GroupItem>.from(appRepository.groups);
    list.sort((a, b) {
      final aPinned = MockData.conversationPinned[a.name] ?? false;
      final bPinned = MockData.conversationPinned[b.name] ?? false;
      if (aPinned != bPinned) return bPinned ? 1 : -1;

      final aLast = MockData.conversationLastActivity[a.name] ?? 0;
      final bLast = MockData.conversationLastActivity[b.name] ?? 0;
      if (aLast != bLast) return bLast.compareTo(aLast);

      return b.name.compareTo(a.name);
    });
    return list;
  }

  Future<void> _openChat(GroupItem group) async {
    try {
      await SupabaseService.markConversationRead(group.name);
    } catch (_) {
      // Ignore read-mark errors.
    }
    try {
      await SupabaseService.loadConversationForGroup(group.name);
    } catch (_) {
      // Ignore preload errors.
    }

    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatPage(group: group)));

    await SupabaseService.refreshMessagesData();
    if (!mounted) return;
    setState(() {});
    widget.onDataChanged?.call();
  }

  Future<void> _showConversationActions(GroupItem group) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.pin),
              title: Text(
                (MockData.conversationPinned[group.name] ?? false)
                    ? 'Sabitlemeyi Kaldır'
                    : 'Sabitle',
              ),
              onTap: () => Navigator.of(context).pop('pin'),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.bell_slash),
              title: Text(group.muted ? 'Sessizi Kaldır' : 'Sessize Al'),
              onTap: () => Navigator.of(context).pop('mute'),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.delete),
              title: const Text('Sohbeti Sil'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;

    if (selected == 'pin') {
      setState(() {
        SupabaseService.toggleConversationPinned(group.name);
      });
      return;
    }

    if (selected == 'mute') {
      final willMute = !group.muted;
      await SupabaseService.setConversationMuted(
        groupName: group.name,
        muted: willMute,
        mutedUntil: willMute ? 'Süresiz' : null,
      );
      await SupabaseService.refreshMessagesData();
      if (!mounted) return;
      setState(() {});
      return;
    }

    if (selected == 'delete') {
      await _deleteConversationWithUndo(group);
    }
  }

  Future<void> _deleteConversationWithUndo(GroupItem group) async {
    _pendingDeleteTimer?.cancel();
    _pendingSnapshot = _ConversationSnapshot.fromGroup(group);

    setState(() {
      SupabaseService.removeConversationLocal(group.name);
    });
    widget.onDataChanged?.call();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Sohbet silindi.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () {
            _pendingDeleteTimer?.cancel();
            final snapshot = _pendingSnapshot;
            _pendingSnapshot = null;
            if (snapshot != null && mounted) {
              setState(() => snapshot.restore());
              widget.onDataChanged?.call();
            }
          },
        ),
      ),
    );

    _pendingDeleteTimer = Timer(const Duration(seconds: 5), () async {
      final snapshot = _pendingSnapshot;
      _pendingSnapshot = null;
      if (snapshot == null) return;
      await SupabaseService.hardDeleteConversation(snapshot.group);
      if (!mounted) return;
      setState(() {});
      widget.onDataChanged?.call();
    });
  }

  Future<void> _openDirectMessage() async {
    final created = await Navigator.of(context).push<GroupItem>(
      MaterialPageRoute(builder: (_) => const DirectMessagePage()),
    );
    if (created != null && mounted) {
      await SupabaseService.loadAllConversationPreviews();
      setState(() {});
      widget.onDataChanged?.call();
    }
  }

  Future<void> _openCreateGroup() async {
    final created = await Navigator.of(context).push<GroupItem>(
      MaterialPageRoute(builder: (_) => const CreateGroupPage()),
    );
    if (created != null && mounted) {
      await SupabaseService.loadAllConversationPreviews();
      setState(() {});
      widget.onDataChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasGroups = appRepository.groups.isNotEmpty;
    final hasPreview = appRepository.groups.any(
      (group) =>
          MockData.conversationLastMessage[group.name]?.isNotEmpty ?? false,
    );
    if (hasGroups && !hasPreview && !_loadingPreviews) {
      Future<void>(() => _ensurePreviewsLoaded());
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
          children: [
            const SectionHeader(
              title: 'DM Kutusu',
              subtitle: 'Gruplar ve direkt mesajlar',
            ),
            const SizedBox(height: 14),
            ..._sortedGroups().map(
              (group) => _GroupCard(
                group: group,
                onTap: () => _openChat(group),
                onLongPress: () => _showConversationActions(group),
              ),
            ),
          ],
        ),
        Positioned(
          right: 0,
          bottom: 74,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (expanded) ...[
                _ActionBubble(label: 'Mesaj Gönder', onTap: _openDirectMessage),
                const SizedBox(height: 10),
                _ActionBubble(label: 'Grup Olustur', onTap: _openCreateGroup),
                const SizedBox(height: 10),
              ],
              FloatingActionButton(
                onPressed: () => setState(() => expanded = !expanded),
                child: Icon(
                  expanded ? CupertinoIcons.xmark : CupertinoIcons.add,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConversationSnapshot {
  _ConversationSnapshot({
    required this.group,
    required this.members,
    required this.messages,
    required this.unread,
    required this.pinned,
    required this.lastActivity,
    required this.lastMessage,
  });

  final GroupItem group;
  final List<StudentOption> members;
  final List<ChatMessage> messages;
  final int? unread;
  final bool? pinned;
  final int? lastActivity;
  final String? lastMessage;

  factory _ConversationSnapshot.fromGroup(GroupItem group) {
    return _ConversationSnapshot(
      group: group,
      members: List<StudentOption>.from(
        appRepository.groupMembers[group.name] ?? const <StudentOption>[],
      ),
      messages: List<ChatMessage>.from(
        appRepository.conversationMessages[group.name] ?? const <ChatMessage>[],
      ),
      unread: appRepository.unreadConversationCounts[group.name],
      pinned: MockData.conversationPinned[group.name],
      lastActivity: MockData.conversationLastActivity[group.name],
      lastMessage: MockData.conversationLastMessage[group.name],
    );
  }

  void restore() {
    appRepository.groups.insert(0, group);
    appRepository.groupMembers[group.name] = members;
    appRepository.conversationMessages[group.name] = messages;
    if (unread != null) {
      appRepository.unreadConversationCounts[group.name] = unread!;
    }
    if (pinned != null) {
      MockData.conversationPinned[group.name] = pinned!;
    }
    if (lastActivity != null) {
      MockData.conversationLastActivity[group.name] = lastActivity!;
    }
    if (lastMessage != null) {
      MockData.conversationLastMessage[group.name] = lastMessage!;
    }
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onLongPress,
  });

  final GroupItem group;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  List<Color> _avatarColors() {
    return switch (group.avatarIndex) {
      1 => const [AppColors.sunrise, AppColors.coral],
      2 => const [AppColors.coral, AppColors.ink],
      3 => const [AppColors.teal, AppColors.sunrise],
      _ => const [AppColors.ink, AppColors.teal],
    };
  }

  @override
  Widget build(BuildContext context) {
    final lastMessage =
        (appRepository.conversationMessages[group.name] ?? <ChatMessage>[])
            .lastOrNull;
    final lastMessageText =
        lastMessage?.message ??
        MockData.conversationLastMessage[group.name] ??
        'Henüz mesaj yok';
    final unreadCount = appRepository.unreadConversationCounts[group.name] ?? 0;
    final pinned = MockData.conversationPinned[group.name] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _avatarColors()),
                  borderRadius: BorderRadius.circular(18),
                  image:
                      (group.avatarPath != null && group.avatarPath!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(group.avatarPath!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (group.avatarPath == null || group.avatarPath!.isEmpty)
                    ? Icon(
                        group.isDirect
                            ? CupertinoIcons.person_fill
                            : CupertinoIcons.person_3_fill,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0) ...[
                TagBadge(
                  label: '$unreadCount',
                  variant: TagBadgeVariant.warning,
                ),
                const SizedBox(width: 8),
              ],
              if (pinned) ...[
                const Icon(CupertinoIcons.pin_fill, size: 16),
                const SizedBox(width: 8),
              ],
              if (group.muted)
                const Icon(CupertinoIcons.bell_slash_fill, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBubble extends StatelessWidget {
  const _ActionBubble({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
