import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/info_strip.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/tag_badge.dart';
import 'forgot_password_sheet.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool saveInfo = true;

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.ink, AppColors.teal],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    CupertinoIcons.building_2_fill,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Kampusapp',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Text(
                  '${appRepository.student.department} • premium kampus deneyimi',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const HeroCard(
                  compact: true,
                  title: 'Hos geldin',
                  subtitle: 'Dersler, odevler ve gruplar tek akista.',
                  badges: [
                    HeroCardBadge(label: 'Face ID hazir'),
                    HeroCardBadge(
                      label: 'iOS hissi',
                      variant: TagBadgeVariant.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giris yap',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 18),
                      const InputField(
                        hint: 'Ogrenci No veya E-posta',
                        icon: CupertinoIcons.person_crop_circle,
                      ),
                      const SizedBox(height: 14),
                      const InputField(
                        hint: 'Sifre',
                        icon: CupertinoIcons.lock_fill,
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => showForgotPasswordSheet(context),
                          child: const Text('Sifremi Unuttum'),
                        ),
                      ),
                      const InfoStrip(
                        icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                        text:
                            'Face ID hazir. Sonraki girislerde tek dokunus kullanilabilir.',
                        color: AppColors.teal,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Save login info',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Switch(
                            value: saveInfo,
                            onChanged: (value) =>
                                setState(() => saveInfo = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Giris Yap',
                        icon: CupertinoIcons.arrow_right,
                        onTap: widget.onLogin,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
