import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  Future<void> _openDirectMessage() async {
    final created = await Navigator.of(context).push<GroupItem>(
      MaterialPageRoute(builder: (_) => const DirectMessagePage()),
    );
    if (created != null && mounted) {
      await SupabaseService.refreshMessagesData();
      setState(() {});
      widget.onDataChanged?.call();
    }
  }

  Future<void> _openCreateGroup() async {
    final created = await Navigator.of(context).push<GroupItem>(
      MaterialPageRoute(builder: (_) => const CreateGroupPage()),
    );
    if (created != null && mounted) {
      await SupabaseService.refreshMessagesData();
      setState(() {});
      widget.onDataChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            ...appRepository.groups.map((group) => _GroupCard(group: group)),
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

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final GroupItem group;

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
    final unreadCount = appRepository.unreadConversationCounts[group.name] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: InkWell(
          onTap: () async {
            await SupabaseService.markConversationRead(group.name);
            if (!context.mounted) return;
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => ChatPage(group: group)));
            if (context.mounted) {
              await SupabaseService.refreshMessagesData();
            }
          },
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _avatarColors()),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  group.isDirect
                      ? CupertinoIcons.person_fill
                      : CupertinoIcons.person_3_fill,
                  color: Colors.white,
                ),
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
                      lastMessage?.message ?? group.memberCount,
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
