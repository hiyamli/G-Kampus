import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';

class FloatingIconButton extends StatelessWidget {
  const FloatingIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 50,
    this.badgeCount,
    this.opacity,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final int? badgeCount;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: isDark
              ? Colors.white.withValues(alpha: opacity ?? 0.18)
              : Colors.white.withValues(alpha: opacity ?? 0.66),
          borderRadius: AppRadius.card20,
          child: InkWell(
            borderRadius: AppRadius.card20,
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: AppColors.ink, size: 20),
            ),
          ),
        ),
        if (badgeCount != null && badgeCount! > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.coral,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                '$badgeCount',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium!.copyWith(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
