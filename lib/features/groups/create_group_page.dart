import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
import '../../core/supabase/supabase_service.dart';
import '../../theme/colors.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController topicController = TextEditingController();
  final Set<String> selectedStudents = {};
  int selectedAvatar = 0;
  final ImagePicker _imagePicker = ImagePicker();
  String? groupPhotoUrl;
  bool photoUploading = false;
  bool isCreating = false;

  @override
  void dispose() {
    nameController.dispose();
    topicController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (isCreating) return;
    if (nameController.text.trim().isEmpty || selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup adi ve en az bir uye sec.')),
      );
      return;
    }

    setState(() => isCreating = true);
    try {
      final members = appRepository.students
          .where((student) => selectedStudents.contains(student.number))
          .toList();
      final groupName = nameController.text.trim();
      await SupabaseService.createGroup(
        name: groupName,
        topic: topicController.text.trim(),
        avatarIndex: selectedAvatar,
        members: members,
        avatarPath: groupPhotoUrl,
      );

      final created = appRepository.groups.firstWhere(
        (group) => group.name == groupName,
        orElse: () => GroupItem(
          name: groupName,
          memberCount: '${selectedStudents.length + 1} uye',
          muted: false,
          color: AppColors.teal,
          avatarIndex: selectedAvatar,
          isDirect: false,
          avatarPath: groupPhotoUrl,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$groupName oluşturuldu.')));
      Navigator.of(context).pop(created);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Grup oluşturulamadı: $error')));
    } finally {
      if (mounted) setState(() => isCreating = false);
    }
  }

  Future<void> _pickGroupPhoto() async {
    if (photoUploading) return;
    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (selected == null) return;

    setState(() => photoUploading = true);
    try {
      final bytes = await selected.readAsBytes();
      final ext = selected.name.split('.').last;
      final uploaded = await SupabaseService.uploadGroupPhoto(
        bytes: bytes,
        fileExt: ext,
      );

      if (!mounted) return;
      setState(() => groupPhotoUrl = uploaded);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Grup fotoğrafı yüklendi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grup fotoğrafı yüklenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => photoUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 28, 0, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const HeroCard(
                  title: 'Grup Olustur',
                  subtitle: 'Konu belirle, üyeleri seç ve grup fotoğrafı ekle.',
                  badges: [HeroCardBadge(label: 'Study group')],
                ),
                const SizedBox(height: 18),
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage:
                                (groupPhotoUrl != null &&
                                    groupPhotoUrl!.isNotEmpty)
                                ? NetworkImage(groupPhotoUrl!)
                                : null,
                            backgroundColor: AppColors.ink.withValues(
                              alpha: 0.18,
                            ),
                            child:
                                (groupPhotoUrl == null ||
                                    groupPhotoUrl!.isEmpty)
                                ? const Icon(CupertinoIcons.person_3_fill)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              photoUploading
                                  ? 'Fotoğraf yükleniyor...'
                                  : 'Grup fotoğrafı eklemek için yükle',
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: PrimaryButton(
                              label: photoUploading ? 'Bekle' : 'Yükle',
                              onTap: photoUploading
                                  ? null
                                  : () => unawaited(_pickGroupPhoto()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InputField(
                        hint: 'Grup adi',
                        icon: CupertinoIcons.person_3_fill,
                        controller: nameController,
                      ),
                      const SizedBox(height: 12),
                      InputField(
                        hint: 'Kategori / konu',
                        icon: CupertinoIcons.tag_fill,
                        controller: topicController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...appRepository.students
                    .where(
                      (student) =>
                          student.number != appRepository.student.number ||
                          student.name != appRepository.student.name,
                    )
                    .map(
                      (student) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selectedStudents.contains(student.number)) {
                                selectedStudents.remove(student.number);
                              } else {
                                selectedStudents.add(student.number);
                              }
                            });
                          },
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
                                    value: selectedStudents.contains(
                                      student.number,
                                    ),
                                    onChanged: (_) {},
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Olustur',
                  onTap: () {
                    _create();
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
