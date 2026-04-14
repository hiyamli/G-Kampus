import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';

class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  bool lessons = true;
  bool assignments = true;
  bool exams = true;
  String leadTime = '30 dk once';

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
                  title: 'Ders Hatirlatmalari',
                  subtitle:
                      'Ders, odev ve sinav hatirlatma zamanlarini belirle.',
                  badges: [HeroCardBadge(label: 'Kisisel rutin')],
                ),
                const SizedBox(height: 18),
                _toggleCard(
                  context,
                  'Ders baslangici',
                  lessons,
                  (value) => setState(() => lessons = value),
                ),
                const SizedBox(height: 10),
                _toggleCard(
                  context,
                  'Odev teslimi',
                  assignments,
                  (value) => setState(() => assignments = value),
                ),
                const SizedBox(height: 10),
                _toggleCard(
                  context,
                  'Sinav gunleri',
                  exams,
                  (value) => setState(() => exams = value),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.clock_fill),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hatirlatma suresi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      DropdownButton<String>(
                        value: leadTime,
                        underline: const SizedBox.shrink(),
                        items: const ['10 dk once', '30 dk once', '1 saat once']
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => leadTime = value!),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleCard(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(CupertinoIcons.check_mark_circled_solid),
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
