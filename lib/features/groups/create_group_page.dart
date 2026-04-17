import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
                  subtitle: 'Konu belirle, uyeleri sec ve akışı hemen baslat.',
                  badges: [HeroCardBadge(label: 'Study group')],
                ),
                const SizedBox(height: 18),
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(
                          4,
                          (index) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index == 3 ? 0 : 8,
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedAvatar = index),
                                child: Container(
                                  height: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: selectedAvatar == index
                                        ? Border.all(
                                            color: AppColors.teal,
                                            width: 2,
                                          )
                                        : null,
                                    gradient: LinearGradient(
                                      colors: switch (index) {
                                        1 => const [
                                          AppColors.sunrise,
                                          AppColors.coral,
                                        ],
                                        2 => const [
                                          AppColors.coral,
                                          AppColors.ink,
                                        ],
                                        3 => const [
                                          AppColors.teal,
                                          AppColors.sunrise,
                                        ],
                                        _ => const [
                                          AppColors.ink,
                                          AppColors.teal,
                                        ],
                                      },
                                    ),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.person_3_fill,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
