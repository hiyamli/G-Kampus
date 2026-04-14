import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  bool lowDataMode = false;
  bool wifiOnlyDownloads = true;
  String language = 'Turkce';
  String weekStarts = 'Pazartesi';

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
                  title: 'Genel Ayarlar',
                  subtitle:
                      'Kampüs uygulamasinin temel davranislarini kişilestir.',
                  badges: [HeroCardBadge(label: 'Uygulama tercihleri')],
                ),
                const SizedBox(height: 18),
                _toggle(
                  context,
                  'Dusuk veri modu',
                  lowDataMode,
                  (value) => setState(() => lowDataMode = value),
                ),
                const SizedBox(height: 10),
                _toggle(
                  context,
                  'Sadece Wi-Fi ile indir',
                  wifiOnlyDownloads,
                  (value) => setState(() => wifiOnlyDownloads = value),
                ),
                const SizedBox(height: 10),
                _dropdown(context, 'Dil', language, const [
                  'Turkce',
                  'English',
                ], (value) => setState(() => language = value!)),
                const SizedBox(height: 10),
                _dropdown(
                  context,
                  'Hafta baslangici',
                  weekStarts,
                  const ['Pazartesi', 'Pazar'],
                  (value) => setState(() => weekStarts = value!),
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
          const Icon(CupertinoIcons.settings),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _dropdown(
    BuildContext context,
    String title,
    String current,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(CupertinoIcons.gear_alt_fill),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          DropdownButton<String>(
            value: current,
            underline: const SizedBox.shrink(),
            items: values
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
