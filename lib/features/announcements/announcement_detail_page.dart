import 'package:flutter/material.dart';

import '../../core/models/mock_models.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';

class AnnouncementDetailPage extends StatelessWidget {
  const AnnouncementDetailPage({super.key, required this.item});

  final AnnouncementItem item;

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HeroCard(
                  title: item.title,
                  subtitle: item.date,
                  badges: const [HeroCardBadge(label: 'Detayli okuma')],
                ),
                const SizedBox(height: 18),
                GlassCard(
                  child: Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyLarge,
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
