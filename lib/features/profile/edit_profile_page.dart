import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/supabase/supabase_service.dart';
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
    this.initialAvatarPath,
  });

  final String initialBio;
  final int initialAvatarIndex;
  final String? initialAvatarPath;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController bioController;
  late int selectedAvatar;
  final ImagePicker _imagePicker = ImagePicker();
  String? avatarPath;
  bool uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    bioController = TextEditingController(text: widget.initialBio);
    selectedAvatar = widget.initialAvatarIndex;
    avatarPath = widget.initialAvatarPath;
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
        avatarPath: avatarPath,
      ),
    );
  }

  Future<void> _uploadProfilePhoto() async {
    if (uploadingPhoto) return;

    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (selected == null) return;

    setState(() => uploadingPhoto = true);
    try {
      final bytes = await selected.readAsBytes();
      final ext = selected.name.split('.').last;
      final uploadedUrl = await SupabaseService.uploadProfilePhoto(
        bytes: bytes,
        fileExt: ext,
      );

      if (!mounted) return;
      setState(() => avatarPath = uploadedUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fotoğraf yüklenemedi: $error')));
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
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
                  title: 'Profili Düzenle',
                  subtitle: 'Profil fotoğrafını yükle ve biyografini güncelle.',
                  badges: [HeroCardBadge(label: 'Supabase storage')],
                ),
                const SizedBox(height: 18),
                GlassCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage:
                            (avatarPath != null && avatarPath!.isNotEmpty)
                            ? NetworkImage(avatarPath!)
                            : null,
                        child: (avatarPath == null || avatarPath!.isEmpty)
                            ? const Icon(CupertinoIcons.person_fill)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          uploadingPhoto
                              ? 'Fotoğraf yükleniyor...'
                              : 'Profil fotoğrafını galeriden seç',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: PrimaryButton(
                          label: uploadingPhoto ? 'Bekle' : 'Yükle',
                          onTap: uploadingPhoto
                              ? null
                              : () => unawaited(_uploadProfilePhoto()),
                        ),
                      ),
                    ],
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
