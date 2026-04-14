import 'package:flutter/material.dart';

import '../../core/models/mock_models.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/tag_badge.dart';

class ScheduleDetailPage extends StatelessWidget {
  const ScheduleDetailPage({super.key, required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final examCards = switch (item.course) {
      'Mobil Programlama' => const [
        ('Vize', '78'),
        ('Final', '86'),
        ('But', '-'),
      ],
      'UI Design Studio' => const [
        ('Vize', '84'),
        ('Final', '91'),
        ('But', '-'),
      ],
      _ => const [('Vize', '81'), ('Final', '76'), ('But', '-')],
    };

    Widget infoCard(String title, String value) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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

    return CampusScaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HeroCard(
                  title: item.course,
                  subtitle: '${item.time} • ${item.location}',
                  badges: [
                    HeroCardBadge(label: item.badge),
                    HeroCardBadge(
                      label: item.instructor,
                      variant: TagBadgeVariant.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: infoCard('Sınıf', item.location),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: infoCard('Ogretim Gorevlisi', item.instructor),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: infoCard(
                        'Kredi / AKTS',
                        '${item.credit} / ${item.ects}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...examCards.expand(
                      (exam) => [
                        SizedBox(
                          width: double.infinity,
                          child: infoCard(exam.$1, exam.$2),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: infoCard('Harf Notu', item.letter),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
