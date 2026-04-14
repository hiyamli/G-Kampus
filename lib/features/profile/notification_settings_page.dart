import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final Map<String, bool> toggles = {
    'Yeni duyurular': true,
    'Yaklasan dersler': true,
    'Yaklasan odevler': true,
    'Grup mesajlari': true,
    'Yemekhane menusu': false,
    'Etkinlik hatirlatmalari': true,
  };

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
                  title: 'Bildirim Ayarlari',
                  subtitle: 'Akademik ve sosyal akislari kanal bazinda yonet.',
                  badges: [HeroCardBadge(label: '6 kanal')],
                ),
                const SizedBox(height: 18),
                ...toggles.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.bell_fill),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Switch(
                            value: entry.value,
                            onChanged: (value) =>
                                setState(() => toggles[entry.key] = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
