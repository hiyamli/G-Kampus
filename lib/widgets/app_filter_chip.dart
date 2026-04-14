import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.ink
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
