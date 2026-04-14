import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
import '../../widgets/app_filter_chip.dart';
import '../../widgets/assignment_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/tag_badge.dart';
import 'assignment_detail_page.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  String filter = 'Aktif';

  @override
  Widget build(BuildContext context) {
    final items = appRepository.assignments.where((item) {
      if (filter == 'Aktif') return !item.isCompleted && !item.isOverdue;
      if (filter == 'Tamamlandi') return item.isCompleted || item.isOverdue;
      return true;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const HeroCard(
                compact: true,
                title: 'Odevler',
                subtitle:
                    'Aktif, tamamlanan ve geciken teslimleri tek listede yonet.',
                badges: [
                  HeroCardBadge(label: '3 acik is'),
                  HeroCardBadge(
                    label: '1 geciken',
                    variant: TagBadgeVariant.warning,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Tumu', 'Aktif', 'Tamamlandi']
                    .map(
                      (item) => AppFilterChip(
                        label: item,
                        selected: filter == item,
                        onTap: () => setState(() => filter = item),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AssignmentCard(
                    item: item,
                    onTap: () async {
                      final updated = await Navigator.of(context)
                          .push<AssignmentItem>(
                            MaterialPageRoute(
                              builder: (_) => AssignmentDetailPage(item: item),
                            ),
                          );

                      if (updated == null || !mounted) return;
                      setState(() {
                        final assignmentIndex = appRepository.assignments
                            .indexOf(item);
                        if (assignmentIndex != -1) {
                          appRepository.assignments[assignmentIndex] = updated;
                        }
                      });
                    },
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
