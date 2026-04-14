import 'package:flutter/material.dart';

import '../core/models/mock_models.dart';
import '../theme/colors.dart';
import 'glass_card.dart';
import 'tag_badge.dart';

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({super.key, required this.item, this.onTap});

  final AssignmentItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badgeVariant = item.isCompleted
        ? TagBadgeVariant.success
        : item.isOverdue
        ? TagBadgeVariant.warning
        : TagBadgeVariant.unread;

    return GlassCard(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TagBadge(label: item.course, variant: TagBadgeVariant.accent),
                TagBadge(
                  label: item.deadline,
                  variant: TagBadgeVariant.neutral,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (item.documentInfo != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1425B86F),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF25B86F),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.documentInfo!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: item.isOverdue ? AppColors.coral : AppColors.teal,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.timeLeft,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                TagBadge(label: item.status, variant: badgeVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
