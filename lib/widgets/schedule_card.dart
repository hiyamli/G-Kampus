import 'package:flutter/material.dart';

import '../core/models/mock_models.dart';
import '../theme/radius.dart';
import 'glass_card.dart';
import 'tag_badge.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({super.key, required this.item, this.onTap});

  final ScheduleItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.card24,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 84,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.card20,
                ),
                child: Text(
                  item.time,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 4,
                height: 70,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: AppRadius.pill,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.course,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.location}  •  ${item.instructor}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    TagBadge(
                      label: item.badge,
                      variant: TagBadgeVariant.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
