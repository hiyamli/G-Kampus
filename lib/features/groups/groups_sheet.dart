import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
import '../../theme/colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/tag_badge.dart';
import 'chat_page.dart';
import 'create_group_page.dart';
import 'direct_message_page.dart';

Future<void> showGroupsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _GroupsSheet(),
  );
}

class _GroupsSheet extends StatefulWidget {
  const _GroupsSheet();

  @override
  State<_GroupsSheet> createState() => _GroupsSheetState();
}

class _GroupsSheetState extends State<_GroupsSheet> {
  bool expanded = false;

  Future<void> _openDirectMessage() async {
    final created = await Navigator.of(context).push<GroupItem>(
      MaterialPageRoute(builder: (_) => const DirectMessagePage()),
    );
    if (created != null) {
      setState(() => appRepository.groups.insert(0, created));
    }
  }

  Future<void> _openCreateGroup() async {
    final created = await Navigator.of(context).push<GroupItem>(
      MaterialPageRoute(builder: (_) => const CreateGroupPage()),
    );
    if (created != null) {
      setState(() => appRepository.groups.insert(0, created));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.86,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            ListView(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: SectionHeader(
                        title: 'Mesaj Kutusu',
                        subtitle: 'Gruplar ve direkt mesajlar',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...appRepository.groups.map(
                  (group) => _GroupCard(group: group),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (expanded) ...[
                    _ActionBubble(
                      label: 'Mesaj Gonder',
                      onTap: _openDirectMessage,
                    ),
                    const SizedBox(height: 10),
                    _ActionBubble(
                      label: 'Grup Olustur',
                      onTap: _openCreateGroup,
                    ),
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
        ),
      ),
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
            appRepository.unreadConversationCounts[group.name] = 0;
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => ChatPage(group: group)));
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
              const TagBadge(label: 'Aksiyon', variant: TagBadgeVariant.accent),
              const SizedBox(width: 10),
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
