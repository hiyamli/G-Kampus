import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
import '../../theme/colors.dart';
import '../../widgets/floating_icon_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/tag_badge.dart';
import 'edit_profile_page.dart';
import 'general_settings_page.dart';
import 'notification_settings_page.dart';
import 'privacy_security_page.dart';
import 'profile_edit_result.dart';
import 'reminder_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLogout,
    required this.profile,
    required this.avatarIndex,
    required this.onProfileChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onLogout;
  final StudentProfile profile;
  final int avatarIndex;
  final void Function(StudentProfile profile, int avatarIndex) onProfileChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late StudentProfile profileState;
  late int avatarIndexState;

  @override
  void initState() {
    super.initState();
    profileState = widget.profile;
    avatarIndexState = widget.avatarIndex;
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile ||
        oldWidget.avatarIndex != widget.avatarIndex) {
      profileState = widget.profile;
      avatarIndexState = widget.avatarIndex;
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final result = await Navigator.of(context).push<ProfileEditResult>(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          initialBio: profileState.bio,
          initialAvatarIndex: avatarIndexState,
          initialAvatarPath: profileState.avatarPath,
        ),
      ),
    );

    if (result == null) return;
    final updated = profileState.copyWith(
      bio: result.bio,
      avatarPath: result.avatarPath,
    );
    setState(() {
      profileState = updated;
      avatarIndexState = result.avatarIndex;
    });
    widget.onProfileChanged(updated, result.avatarIndex);
  }

  List<Color> _avatarColors(int index) {
    return switch (index) {
      1 => const [AppColors.sunrise, AppColors.coral],
      2 => const [AppColors.coral, AppColors.ink],
      3 => const [AppColors.teal, AppColors.sunrise],
      _ => const [AppColors.ink, AppColors.teal],
    };
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _avatarColors(avatarIndexState),
                            ),
                            image:
                                (profileState.avatarPath != null &&
                                    profileState.avatarPath!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(
                                      profileState.avatarPath!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profileState.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              TagBadge(
                                label: profileState.role,
                                variant: TagBadgeVariant.accent,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                profileState.department,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '${profileState.grade} • ${profileState.number}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'GNO ${profileState.gpa}',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                        FloatingIconButton(
                          icon: CupertinoIcons.pencil,
                          onTap: () => _editProfile(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profileState.bio,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TagBadge(
                          label:
                              '${appRepository.student.courseCount} kayıtli ders',
                          variant: TagBadgeVariant.unread,
                        ),
                        const TagBadge(
                          label: 'Bildirimler acik',
                          variant: TagBadgeVariant.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _ThemeOption(
                      label: 'System',
                      icon: CupertinoIcons.circle_lefthalf_fill,
                      selected: widget.themeMode == ThemeMode.system,
                      onTap: () => widget.onThemeChanged(ThemeMode.system),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemeOption(
                      label: 'Light',
                      icon: CupertinoIcons.sun_max_fill,
                      selected: widget.themeMode == ThemeMode.light,
                      onTap: () => widget.onThemeChanged(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemeOption(
                      label: 'Dark',
                      icon: CupertinoIcons.moon_fill,
                      selected: widget.themeMode == ThemeMode.dark,
                      onTap: () => widget.onThemeChanged(ThemeMode.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Kayıtli Dersler',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...appRepository.courses.map(
                (course) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Text(
                      course,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('Ayarlar', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _SettingsTile(
                title: 'Bildirim Ayarlari',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsPage(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _SettingsTile(
                title: 'Ders Hatırlatmalari',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReminderSettingsPage(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _SettingsTile(
                title: 'Gizlilik ve Guvenlik',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacySecurityPage(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _SettingsTile(
                title: 'Genel Ayarlar',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GeneralSettingsPage(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Çıkış Yap'),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.teal : AppColors.ink),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
