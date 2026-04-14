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

class DirectMessagePage extends StatefulWidget {
  const DirectMessagePage({super.key});

  @override
  State<DirectMessagePage> createState() => _DirectMessagePageState();
}

class _DirectMessagePageState extends State<DirectMessagePage> {
  final TextEditingController messageController = TextEditingController();
  String? selectedStudent;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void _send() {
    if (selectedStudent == null || messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir kişi sec ve mesaj yaz.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mesaj ${selectedStudent!} kişina gönderildi.')),
    );
    final dm = GroupItem(
      name: selectedStudent!,
      memberCount: 'Direkt mesaj',
      muted: false,
      color: AppColors.teal,
      avatarIndex: appRepository.students
          .indexWhere((student) => student.name == selectedStudent!)
          .clamp(0, 3),
      isDirect: true,
    );

    appRepository.groupMembers[dm.name] = appRepository.students
        .where((student) => student.name == selectedStudent!)
        .toList();
    appRepository.conversationMessages[dm.name] = [
      ChatMessage(
        sender: 'Zeynep',
        message: messageController.text.trim(),
        time: TimeOfDay.now().format(context),
        isMe: true,
      ),
    ];
    appRepository.unreadConversationCounts[dm.name] = 0;

    Navigator.of(context).pop(dm);
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
                  title: 'Direkt Mesaj Baslat',
                  subtitle:
                      'Kişi secip ilk mesaji ayni ekrandan gönderebilirsin.',
                  badges: [HeroCardBadge(label: 'Hizli DM')],
                ),
                const SizedBox(height: 18),
                ...appRepository.students.map(
                  (student) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => selectedStudent = student.name),
                      child: GlassCard(
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.person_crop_circle),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('${student.name} • ${student.role}'),
                            ),
                            IgnorePointer(
                              child: Checkbox(
                                value: selectedStudent == student.name,
                                onChanged: (_) {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  child: InputField(
                    hint: 'Mesaj',
                    icon: CupertinoIcons.chat_bubble_text_fill,
                    controller: messageController,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Gönder', onTap: _send),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
