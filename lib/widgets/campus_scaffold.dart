import 'package:flutter/material.dart';

import 'adaptive_layout.dart';
import 'background_shell.dart';

class CampusScaffold extends StatelessWidget {
  const CampusScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showBackButton,
  });

  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool? showBackButton;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final shouldShowBackButton = showBackButton ?? canPop;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: BackgroundShell(
        child: SafeArea(
          child: Stack(
            children: [
              AdaptiveLayout(child: body),
              if (shouldShowBackButton)
                const Positioned(top: 6, left: 8, child: _BackButton()),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
    );
  }
}
