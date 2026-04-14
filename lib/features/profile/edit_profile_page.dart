import 'package:flutter/cupertino.dart';

import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import 'profile_edit_result.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.initialBio,
    required this.initialAvatarIndex,
  });

  final String initialBio;
  final int initialAvatarIndex;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController bioController;
  late int selectedAvatar;

  @override
  void initState() {
    super.initState();
    bioController = TextEditingController(text: widget.initialBio);
    selectedAvatar = widget.initialAvatarIndex;
  }

  @override
  void dispose() {
    bioController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      ProfileEditResult(
        bio: bioController.text.trim().isEmpty
            ? widget.initialBio
            : bioController.text.trim(),
        avatarIndex: selectedAvatar,
      ),
    );
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
                  title: 'Profili Duzenle',
                  subtitle:
                      'Avatar sec, biyografini guncelle ve profil tonunu ayarla.',
                  badges: [HeroCardBadge(label: '4 avatar secenegi')],
                ),
                const SizedBox(height: 18),
                Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 3 ? 0 : 12),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedAvatar = index),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: selectedAvatar == index
                                      ? Border.all(
                                          color: const Color(0xFF31A8AD),
                                          width: 3,
                                        )
                                      : null,
                                  gradient: LinearGradient(
                                    colors: [
                                      index.isEven
                                          ? const Color(0xFF1A2942)
                                          : const Color(0xFFFABB59),
                                      index.isEven
                                          ? const Color(0xFF31A8AD)
                                          : const Color(0xFFED7568),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                GlassCard(
                  child: InputField(
                    hint: 'Bio',
                    icon: CupertinoIcons.pencil_circle_fill,
                    controller: bioController,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Kaydet', onTap: _save),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
