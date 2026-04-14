import 'package:flutter/material.dart';

import '../theme/radius.dart';
import 'tag_badge.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badges,
    this.compact = false,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> badges;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleLarge!
        : Theme.of(context).textTheme.headlineMedium!;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        borderRadius: compact ? AppRadius.card24 : AppRadius.card30,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2942), Color(0xFF31A8AD)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: compact ? 92 : 120,
              height: compact ? 92 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(spacing: 8, runSpacing: 8, children: badges),
                  ),
                  ...?trailing == null ? null : [trailing!],
                ],
              ),
              SizedBox(height: compact ? 12 : 28),
              Text(title, style: titleStyle.copyWith(color: Colors.white)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class HeroCardBadge extends StatelessWidget {
  const HeroCardBadge({
    super.key,
    required this.label,
    this.variant = TagBadgeVariant.unread,
  });

  final String label;
  final TagBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    return TagBadge(label: label, variant: variant);
  }
}
