import 'package:flutter/material.dart';

import '../../core/models/mock_models.dart';
import '../../theme/colors.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/tag_badge.dart';

class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({
    super.key,
    required this.profile,
    required this.avatarIndex,
    this.compactDirect = false,
    this.commonCourses = const [],
  });

  final StudentProfile profile;
  final int avatarIndex;
  final bool compactDirect;
  final List<String> commonCourses;

  List<Color> _avatarColors() {
    return switch (avatarIndex) {
      1 => const [AppColors.sunrise, AppColors.coral],
      2 => const [AppColors.coral, AppColors.ink],
      3 => const [AppColors.teal, AppColors.sunrise],
      _ => const [AppColors.ink, AppColors.teal],
    };
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
                if (!compactDirect) ...[
                  const HeroCard(
                    title: 'Public Profile',
                    subtitle:
                        'Kampus icinde gorunen profil ozeti ve iletisim aksiyonlari.',
                    badges: [HeroCardBadge(label: 'Acik profil')],
                  ),
                  const SizedBox(height: 18),
                ],
                GlassCard(
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: _avatarColors()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      TagBadge(
                        label: profile.role,
                        variant: TagBadgeVariant.accent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.bio,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (compactDirect) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _InfoCard(
                                title: 'Numara',
                                value: profile.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _InfoCard(
                                title: 'Sinif',
                                value: profile.grade,
                              ),
                            ),
                          ],
                        ),
                        if (commonCourses.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Ortak Dersler',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: commonCourses
                                .map(
                                  (course) => TagBadge(
                                    label: course,
                                    variant: TagBadgeVariant.unread,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ] else
                        PrimaryButton(
                          label: 'Mesaj Gonder',
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Direkt mesaj akisi baslatildi.',
                                  ),
                                ),
                              ),
                        ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
