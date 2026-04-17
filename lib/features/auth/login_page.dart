import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../../theme/colors.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/info_strip.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import 'forgot_password_sheet.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _studentLoginDomain = 'students.gkampus.local';

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool saveInfo = true;
  bool hidePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showError('Lütfen tüm alanları doldurun.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _resolveLoginEmail(identifier);
      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Beklenmedik bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _resolveLoginEmail(String identifier) {
    if (identifier.contains('@')) return identifier.toLowerCase();
    return '${identifier.toLowerCase()}@$_studentLoginDomain';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                      InputField(
                        controller: _identifierController,
                        hint: 'Okul Numarası',
                        icon: CupertinoIcons.person_crop_circle,
                      ),
                      SizedBox(height: compact ? 10 : 14),
                      InputField(
                        controller: _passwordController,
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
                        label: _isLoading ? 'Giriş Yapılıyor...' : 'Giriş Yap',
                        icon: _isLoading ? null : CupertinoIcons.arrow_right,
                        onTap: _isLoading ? null : _handleLogin,
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
