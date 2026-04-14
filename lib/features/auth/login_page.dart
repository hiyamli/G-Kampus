import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/info_strip.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import 'forgot_password_sheet.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool saveInfo = true;
  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.height < 760;

    return CampusScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: compact ? 8 : 20),
            child: Column(
              children: [
                Container(
                  width: compact ? 72 : 84,
                  height: compact ? 72 : 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.ink, AppColors.teal],
                    ),
                    borderRadius: BorderRadius.circular(compact ? 22 : 26),
                  ),
                  child: const Icon(
                    CupertinoIcons.building_2_fill,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                SizedBox(height: compact ? 14 : 20),
                Text(
                  'G Kampüs',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                SizedBox(height: compact ? 14 : 20),
                const HeroCard(
                  compact: true,
                  title: 'Hos geldin',
                  subtitle: 'Dersler, ödevler ve gruplar tek akista.',
                  badges: [],
                ),
                SizedBox(height: compact ? 12 : 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giriş yap',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: compact ? 12 : 16),
                      const InputField(
                        hint: 'Öğrenci No veya E-posta',
                        icon: CupertinoIcons.person_crop_circle,
                      ),
                      SizedBox(height: compact ? 10 : 14),
                      InputField(
                        hint: 'Şifre',
                        icon: CupertinoIcons.lock_fill,
                        obscureText: hidePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => hidePassword = !hidePassword);
                          },
                          icon: Icon(
                            hidePassword
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => showForgotPasswordSheet(context),
                          child: const Text('Şifremi Unuttum'),
                        ),
                      ),
                      const InfoStrip(
                        icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                        text:
                            'Face ID hazir. Sonraki girislerde tek dokunus kullanilabilir.',
                        color: AppColors.teal,
                      ),
                      SizedBox(height: compact ? 10 : 12),
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
                      SizedBox(height: compact ? 8 : 12),
                      PrimaryButton(
                        label: 'Giriş Yap',
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
