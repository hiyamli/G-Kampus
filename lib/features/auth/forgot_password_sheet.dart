import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/info_strip.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';

Future<void> showForgotPasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _ForgotPasswordSheet(),
  );
}

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  bool sent = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeroCard(
              compact: true,
              title: 'Sifre yenile',
              subtitle:
                  'Kurumsal e-posta adresine guvenli bir sifirlama baglantisi gonderelim.',
              badges: [HeroCardBadge(label: 'Kurumsal hesap')],
            ),
            const SizedBox(height: 16),
            const GlassCard(
              child: InputField(
                hint: 'kurumsal e-posta',
                icon: CupertinoIcons.mail_solid,
              ),
            ),
            const SizedBox(height: 14),
            if (sent) ...[
              const InfoStrip(
                icon: CupertinoIcons.check_mark_circled_solid,
                text:
                    'Baglanti gonderildi. Gelen kutusu ve spam klasorunu kontrol et.',
                color: AppColors.teal,
              ),
              const SizedBox(height: 14),
            ],
            PrimaryButton(
              label: 'Baglanti Gonder',
              onTap: () => setState(() => sent = true),
            ),
          ],
        ),
      ),
    );
  }
}
