import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/tag_badge.dart';

class GroupInfoPage extends StatefulWidget {
  const GroupInfoPage({super.key, required this.group});

  final GroupItem group;

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  late GroupItem group;

  void _addSystemMessage(String text) {
    final existing =
        appRepository.conversationMessages[group.name] ?? <ChatMessage>[];
    appRepository.conversationMessages[group.name] = [
      ...existing,
      ChatMessage(
        sender: 'Sistem',
        message: text,
        time: TimeOfDay.now().format(context),
        isMe: false,
        isSystem: true,
      ),
    ];
  }

  void _persistGroup({String? oldName}) {
    final targetName = oldName ?? group.name;
    final index = appRepository.groups.indexWhere(
      (item) => item.name == targetName,
    );
    if (index != -1) {
      appRepository.groups[index] = group;
    }
  }

  @override
  void initState() {
    super.initState();
    group = widget.group;
  }

  void _syncGroupCount() {
    final members = appRepository.groupMembers[group.name] ?? [];
    group = group.copyWith(memberCount: '${members.length} uye');
  }

  void _showRenameSheet() {
    final controller = TextEditingController(text: group.name);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Isim Degistir',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              InputField(
                hint: 'Grup adi',
                icon: CupertinoIcons.person_3_fill,
                controller: controller,
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Kaydet',
                onTap: () {
                  final oldName = group.name;
                  final newName = controller.text.trim();
                  if (newName.isEmpty) return;
                  setState(() {
                    group = group.copyWith(name: newName);
                    appRepository.groupMembers[newName] =
                        appRepository.groupMembers.remove(oldName) ?? [];
                    appRepository.conversationMessages[newName] =
                        appRepository.conversationMessages.remove(oldName) ??
                        [];
                    appRepository.unreadConversationCounts[newName] =
                        appRepository.unreadConversationCounts.remove(
                          oldName,
                        ) ??
                        0;
                    _persistGroup(oldName: oldName);
                    _addSystemMessage(
                      'Grup adi "$oldName" yerine "$newName" oldu.',
                    );
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoSheet() {
    int selected = group.avatarIndex;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grup Fotoğrafıni Sec',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
                        child: GestureDetector(
                          onTap: () => setModalState(() => selected = index),
                          child: Container(
                            height: 62,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: selected == index
                                  ? Border.all(
                                      color: const Color(0xFF31A8AD),
                                      width: 2,
                                    )
                                  : null,
                              gradient: LinearGradient(
                                colors: switch (index) {
                                  1 => const [
                                    Color(0xFFFABB59),
                                    Color(0xFFED7568),
                                  ],
                                  2 => const [
                                    Color(0xFFED7568),
                                    Color(0xFF1A2942),
                                  ],
                                  3 => const [
                                    Color(0xFF31A8AD),
                                    Color(0xFFFABB59),
                                  ],
                                  _ => const [
                                    Color(0xFF1A2942),
                                    Color(0xFF31A8AD),
                                  ],
                                },
                              ),
                            ),
                            child: Icon(
                              group.isDirect
                                  ? CupertinoIcons.person_fill
                                  : CupertinoIcons.person_3_fill,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Fotoğrafı Kaydet',
                  onTap: () {
                    setState(() {
                      group = group.copyWith(avatarIndex: selected);
                      _persistGroup();
                      _addSystemMessage('Grup fotografi secimi güncellendi.');
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPersonSheet() {
    if (group.isDirect) return;
    String? selectedNumber;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişi Ekle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                ...appRepository.students.map(
                  (student) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedNumber = student.number),
                      child: GlassCard(
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.person_crop_circle),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${student.name} • ${student.number}',
                              ),
                            ),
                            IgnorePointer(
                              child: Checkbox(
                                value: selectedNumber == student.number,
                                onChanged: (_) {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                PrimaryButton(
                  label: 'Üyeyi Ekle',
                  onTap: () {
                    if (selectedNumber != null) {
                      final member = appRepository.students.firstWhere(
                        (student) => student.number == selectedNumber,
                      );
                      final List<StudentOption> members = [
                        ...(appRepository.groupMembers[group.name] ??
                            <StudentOption>[]),
                      ];
                      if (!members.any(
                        (student) => student.number == member.number,
                      )) {
                        members.add(member);
                      }
                      setState(() {
                        appRepository.groupMembers[group.name] = members;
                        _syncGroupCount();
                        _addSystemMessage('${member.name} gruba eklendi.');
                      });
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMuteOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('8 saat sessize al'),
              onTap: () => _applyMute('8 saat'),
            ),
            ListTile(
              title: const Text('3 gun sessize al'),
              onTap: () => _applyMute('3 gun'),
            ),
            ListTile(
              title: const Text('1 hafta sessize al'),
              onTap: () => _applyMute('1 hafta'),
            ),
            if (group.muted)
              ListTile(
                title: const Text('Sessizi kaldir'),
                onTap: () {
                  setState(() {
                    group = group.copyWith(muted: false, mutedUntil: null);
                    _addSystemMessage('Sohbet sessizden cikarildi.');
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _applyMute(String duration) {
    setState(() {
      group = group.copyWith(muted: true, mutedUntil: duration);
      _addSystemMessage('Sohbet $duration boyunca sessize alindi.');
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final members = appRepository.groupMembers[group.name] ?? [];

    return CampusScaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 28, 0, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HeroCard(
                  title: group.name,
                  subtitle: group.isDirect
                      ? 'Direkt mesaj ayrintilari'
                      : '${group.memberCount} • grup ayarlari ve uye listesi',
                  badges: [HeroCardBadge(label: group.memberCount)],
                ),
                const SizedBox(height: 18),
                if (!group.isDirect) ...[
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showRenameSheet,
                          child: GlassCard(
                            child: Center(
                              child: Text(
                                'Isim Degistir',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showAddPersonSheet,
                          child: GlassCard(
                            child: Center(
                              child: Text(
                                'Kişi Ekle',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showPhotoSheet,
                          child: GlassCard(
                            child: Center(
                              child: Text(
                                'Profil Fotoğrafı',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                GestureDetector(
                  onTap: _showMuteOptions,
                  child: GlassCard(
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.bell),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            group.muted && group.mutedUntil != null
                                ? '${group.mutedUntil} boyunca sessizde'
                                : 'Sohbeti Sessize Al',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TagBadge(
                          label: group.muted ? 'Sessizde' : 'Aktif',
                          variant: TagBadgeVariant.accent,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!group.isDirect) ...[
                  const SizedBox(height: 18),
                  ...members.map(
                    (student) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1A2942),
                                    Color(0xFF31A8AD),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    student.number,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            TagBadge(
                              label: student.role,
                              variant: TagBadgeVariant.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
