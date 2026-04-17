import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
import '../../core/supabase/supabase_service.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

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
    unawaited(_refreshMembers());
  }

  Future<void> _refreshMembers() async {
    await SupabaseService.refreshMessagesData();
    await SupabaseService.loadMembersForGroup(group.name);
    if (!mounted) return;
    setState(() {
      group = appRepository.groups.firstWhere(
        (item) => item.name == group.name,
        orElse: () => group,
      );
    });
  }

  void _syncGroupCount() {
    final members = appRepository.groupMembers[group.name] ?? [];
    group = group.copyWith(memberCount: '${members.length} uye');
  }

  List<StudentOption> _availableStudentsForAdd() {
    final existingNumbers =
        (appRepository.groupMembers[group.name] ?? <StudentOption>[])
            .map((member) => member.number)
            .toSet();
    final existingNames =
        (appRepository.groupMembers[group.name] ?? <StudentOption>[])
            .map((member) => member.name)
            .toSet();

    return appRepository.students
        .where(
          (student) =>
              student.number != appRepository.student.number &&
              !existingNumbers.contains(student.number) &&
              !existingNames.contains(student.name),
        )
        .toList();
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
    Uint8List? previewBytes;
    String? previewUrl = group.avatarPath;
    bool saving = false;

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
                  'Grup Fotoğrafı',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x1A1A2942),
                      image: previewBytes != null
                          ? DecorationImage(
                              image: MemoryImage(previewBytes!),
                              fit: BoxFit.cover,
                            )
                          : (previewUrl != null && previewUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(previewUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        (previewBytes == null &&
                            (previewUrl == null || previewUrl!.isEmpty))
                        ? const Icon(CupertinoIcons.person_3_fill, size: 34)
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Fotoğraf Seç',
                  onTap: saving
                      ? null
                      : () async {
                          final selected = await _imagePicker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (selected == null) return;
                          final bytes = await selected.readAsBytes();
                          setModalState(() {
                            previewBytes = bytes;
                          });
                        },
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Fotoğrafı Sil',
                  onTap: saving
                      ? null
                      : () {
                          setModalState(() {
                            previewBytes = null;
                            previewUrl = '';
                          });
                        },
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: saving ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet',
                  onTap: saving
                      ? null
                      : () async {
                          setModalState(() => saving = true);
                          try {
                            String? finalUrl = previewUrl;
                            if (previewBytes != null) {
                              final url =
                                  await SupabaseService.uploadGroupPhoto(
                                    bytes: previewBytes!,
                                    fileExt: 'jpg',
                                  );
                              finalUrl = url;
                            }

                            final persisted =
                                await SupabaseService.setGroupAvatarPath(
                                  groupName: group.name,
                                  avatarPath:
                                      (finalUrl == null || finalUrl.isEmpty)
                                      ? null
                                      : finalUrl,
                                );

                            if (!mounted) return;
                            setState(() {
                              group = group.copyWith(
                                avatarPath:
                                    (finalUrl == null || finalUrl.isEmpty)
                                    ? ''
                                    : finalUrl,
                              );
                              _persistGroup();
                            });
                            if (!persisted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fotoğraf yerelde güncellendi. Supabase groups tablosunda avatar_path kolonu ve update izni gerekli.',
                                  ),
                                ),
                              );
                            }
                            Navigator.pop(context);
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Grup fotoğrafı kaydedilemedi.'),
                              ),
                            );
                            setModalState(() => saving = false);
                          }
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
                ..._availableStudentsForAdd().map(
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
                  onTap: () async {
                    if (selectedNumber == null) {
                      Navigator.pop(context);
                      return;
                    }
                    final available = _availableStudentsForAdd();
                    StudentOption? member;
                    for (final item in available) {
                      if (item.number == selectedNumber) {
                        member = item;
                        break;
                      }
                    }
                    if (member == null) {
                      Navigator.pop(context);
                      return;
                    }

                    try {
                      await SupabaseService.addMemberToGroup(
                        groupName: group.name,
                        member: member,
                      );
                      await _refreshMembers();
                      if (!mounted) return;
                      setState(() {
                        _syncGroupCount();
                        _addSystemMessage('${member!.name} gruba eklendi.');
                      });
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Üye eklenemedi: $error')),
                      );
                    }
                    if (mounted) Navigator.pop(context);
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

  Future<void> _leaveGroup() async {
    try {
      await SupabaseService.leaveGroup(group);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gruptan ayrılamadı: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<StudentOption> members;
    try {
      members = appRepository.groupMembers[group.name] ?? <StudentOption>[];
    } catch (_) {
      members = <StudentOption>[];
    }

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
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A2942), Color(0xFF31A8AD)],
                      ),
                      image:
                          (group.avatarPath != null &&
                              group.avatarPath!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(group.avatarPath!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        (group.avatarPath == null || group.avatarPath!.isEmpty)
                        ? const Icon(
                            CupertinoIcons.person_3_fill,
                            color: Colors.white,
                          )
                        : null,
                  ),
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
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Gruptan Ayrıl', onTap: _leaveGroup),
                ],
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
