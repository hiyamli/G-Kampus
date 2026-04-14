import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/app_filter_chip.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/tag_badge.dart';
import 'announcement_detail_page.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  String filter = 'Tumu';

  @override
  Widget build(BuildContext context) {
    final items = appRepository.announcements.where((item) {
      if (filter == 'Tumu') return true;
      final scopeMap = <String, ScopeType>{
        'Universite': ScopeType.universite,
        'Fakulte': ScopeType.fakulte,
        'Bolum': ScopeType.bolum,
        'Ders': ScopeType.ders,
      };
      return item.scope == scopeMap[filter];
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const HeroCard(
                compact: true,
                title: 'Duyurular',
                subtitle:
                    'Resmi akislari scope bazli filtrele ve yeni guncellemeleri kacirma.',
                badges: [
                  HeroCardBadge(label: '2 yeni'),
                  HeroCardBadge(
                    label: 'Ders + bolum',
                    variant: TagBadgeVariant.accent,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Tumu', 'Universite', 'Fakulte', 'Bolum', 'Ders']
                      .map(
                        (scope) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: AppFilterChip(
                            label: scope,
                            selected: scope == filter,
                            onTap: () => setState(() => filter = scope),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 18),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnnouncementCard(
                    item: item,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AnnouncementDetailPage(item: item),
                      ),
                    ),
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
