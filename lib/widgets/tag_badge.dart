import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';

enum TagBadgeVariant { accent, unread, warning, success, neutral }

class TagBadge extends StatelessWidget {
  const TagBadge({
    super.key,
    required this.label,
    this.variant = TagBadgeVariant.accent,
    this.icon,
  });

  final String label;
  final TagBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = switch (variant) {
      TagBadgeVariant.accent => (
        AppColors.teal.withValues(alpha: 0.16),
        AppColors.teal,
      ),
      TagBadgeVariant.unread => (
        AppColors.sunrise.withValues(alpha: 0.18),
        AppColors.ink,
      ),
      TagBadgeVariant.warning => (
        AppColors.coral.withValues(alpha: 0.16),
        AppColors.coral,
      ),
      TagBadgeVariant.success => (
        const Color(0x1425B86F),
        const Color(0xFF25B86F),
      ),
      TagBadgeVariant.neutral => (const Color(0x14263B53), AppColors.ink),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: scheme.$1, borderRadius: AppRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: scheme.$2),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium!.copyWith(color: scheme.$2),
          ),
        ],
      ),
    );
  }
}
