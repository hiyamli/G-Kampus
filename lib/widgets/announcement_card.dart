import 'package:flutter/material.dart';

import '../core/models/mock_models.dart';
import 'glass_card.dart';
import 'tag_badge.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.item, this.onTap});

  final AnnouncementItem item;
  final VoidCallback? onTap;

  String get _scopeLabel => switch (item.scope) {
    ScopeType.universite => 'Universite',
    ScopeType.fakulte => 'Fakulte',
    ScopeType.bolum => 'Bolum',
    ScopeType.ders => 'Ders',
  };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TagBadge(label: _scopeLabel, variant: TagBadgeVariant.accent),
                const SizedBox(width: 8),
                if (item.isNew)
                  const TagBadge(
                    label: 'Yeni',
                    variant: TagBadgeVariant.unread,
                  ),
                const Spacer(),
                Text(item.date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
