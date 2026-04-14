import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/colors.dart';

class BackgroundShell extends StatelessWidget {
  const BackgroundShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [AppColors.darkTop, AppColors.darkBottom]
              : const [AppColors.lightTop, AppColors.lightBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -90,
            child: _GlowOrb(color: AppColors.teal.withValues(alpha: 0.26)),
          ),
          Positioned(
            right: -110,
            bottom: -120,
            child: _GlowOrb(color: AppColors.sunrise.withValues(alpha: 0.22)),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.04)],
          ),
        ),
      ),
    );
  }
}
