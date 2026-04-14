import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../widgets/app_filter_chip.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/schedule_card.dart';
import '../../widgets/tag_badge.dart';
import 'academic_calendar_page.dart';
import 'schedule_detail_page.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String selectedDay = 'Pzt';

  static const _daySchedules = {
    'Pzt': [0, 1],
    'Sal': [2],
    'Car': [1],
    'Per': [0, 2],
    'Cum': [1, 2],
  };

  @override
  Widget build(BuildContext context) {
    final visibleSchedules = (_daySchedules[selectedDay] ?? const <int>[])
        .map((index) => appRepository.schedules[index])
        .toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const HeroCard(
                compact: true,
                title: 'Program',
                subtitle:
                    'Haftalik ders akışı, sinav takvimi ve akademik ajanda tek yerde.',
                badges: [
                  HeroCardBadge(label: 'Bu hafta 8 oturum'),
                  HeroCardBadge(
                    label: '1 sinav eklendi',
                    variant: TagBadgeVariant.accent,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AcademicCalendarPage(),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Akademik Takvim',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Donem tarihleri ve önemli araliklar',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sinav Tarihleri',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '12-19 Mayis ara sinav haftasi',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: ['Pzt', 'Sal', 'Car', 'Per', 'Cum']
                    .map(
                      (day) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: day == 'Cum' ? 0 : 8),
                          child: AppFilterChip(
                            label: day,
                            selected: selectedDay == day,
                            onTap: () => setState(() => selectedDay = day),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              ...visibleSchedules.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ScheduleCard(
                    item: item,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScheduleDetailPage(item: item),
                      ),
                    ),
                  ),
                ),
              ),
              if (visibleSchedules.isEmpty)
                GlassCard(
                  child: Text(
                    'Secili gunde planlanmis ders bulunmuyor.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}
