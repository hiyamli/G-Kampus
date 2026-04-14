import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
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

  @override
  void dispose() {
    nameController.dispose();
    topicController.dispose();
    super.dispose();
  }

  void _create() {
    if (nameController.text.trim().isEmpty || selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup adi ve en az bir uye sec.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${nameController.text.trim()} olusturuldu.')),
    );
    final created = GroupItem(
      name: nameController.text.trim(),
      memberCount: '${selectedStudents.length + 1} uye',
      muted: false,
      color: AppColors.teal,
      avatarIndex: selectedAvatar,
      isDirect: false,
    );

    final members = appRepository.students
        .where((student) => selectedStudents.contains(student.number))
        .toList();
    appRepository.groupMembers[created.name] = members;
    appRepository.conversationMessages[created.name] = [
      ChatMessage(
        sender: 'Zeynep',
        message:
            '${topicController.text.trim().isEmpty ? 'Yeni grup' : topicController.text.trim()} olusturuldu.',
        time: TimeOfDay.now().format(context),
        isMe: true,
      ),
    ];
    appRepository.unreadConversationCounts[created.name] = 0;

    Navigator.of(context).pop(created);
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
                  subtitle: 'Konu belirle, uyeleri sec ve akisi hemen baslat.',
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
                ...appRepository.students.map(
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
                PrimaryButton(label: 'Olustur', onTap: _create),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
