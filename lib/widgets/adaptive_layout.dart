import 'package:flutter/material.dart';

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontal = width >= 1100
            ? 120.0
            : width >= 700
            ? 36.0
            : 20.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
