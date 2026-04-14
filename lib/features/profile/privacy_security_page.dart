import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool publicProfile = true;
  bool showNumber = false;
  bool biometric = true;

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 28, 0, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const HeroCard(
                  title: 'Gizlilik ve Guvenlik',
                  subtitle: 'Profil görünurlugu ve oturum guvenligini yonet.',
                  badges: [HeroCardBadge(label: 'Gizlilik')],
                ),
                const SizedBox(height: 18),
                _toggle(
                  context,
                  'Public profile acik',
                  publicProfile,
                  (value) => setState(() => publicProfile = value),
                ),
                const SizedBox(height: 10),
                _toggle(
                  context,
                  'Numarami goster',
                  showNumber,
                  (value) => setState(() => showNumber = value),
                ),
                const SizedBox(height: 10),
                _toggle(
                  context,
                  'Face ID / biyometrik giris',
                  biometric,
                  (value) => setState(() => biometric = value),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(CupertinoIcons.lock_shield_fill),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
