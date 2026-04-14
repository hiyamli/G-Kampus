import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/models/mock_models.dart';
import '../../theme/colors.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/info_strip.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/tag_badge.dart';

class AssignmentDetailPage extends StatefulWidget {
  const AssignmentDetailPage({super.key, required this.item});

  final AssignmentItem item;

  @override
  State<AssignmentDetailPage> createState() => _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends State<AssignmentDetailPage> {
  final TextEditingController noteController = TextEditingController();
  late AssignmentItem currentItem;
  bool submitted = false;
  bool editingCompleted = false;

  @override
  void initState() {
    super.initState();
    currentItem = widget.item;
    noteController.text = currentItem.submissionNote ?? '';
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void _uploadDocument() {
    if (currentItem.isOverdue && !currentItem.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarihi gecmis odev duzenlenemez.')),
      );
      return;
    }

    setState(() {
      currentItem = currentItem.copyWith(
        documentInfo:
            '${currentItem.title.replaceAll(' ', '_').toLowerCase()}.pdf',
      );
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dokuman eklendi.')));
  }

  void _submitAssignment() {
    if (currentItem.isOverdue && !currentItem.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarihi gecmis odev gonderilemez.')),
      );
      return;
    }

    if (currentItem.documentInfo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Once bir dokuman yukle.')));
      return;
    }

    final updated = currentItem.copyWith(
      isCompleted: true,
      isOverdue: currentItem.isOverdue,
      status: 'Tamamlandi',
      timeLeft: 'Teslim edildi',
      submissionNote: noteController.text.trim(),
    );

    setState(() {
      currentItem = updated;
      submitted = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Odev gonderildi.')));

    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = currentItem.isOverdue;
    final canEditCompleted = currentItem.isCompleted && !currentItem.isOverdue;
    final fieldsEnabled = !isLocked && (!canEditCompleted || editingCompleted);

    return CampusScaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 28, 0, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HeroCard(
                  title: currentItem.title,
                  subtitle: '${currentItem.course} • ${currentItem.deadline}',
                  badges: [
                    HeroCardBadge(
                      label: currentItem.course,
                      variant: TagBadgeVariant.accent,
                    ),
                    HeroCardBadge(
                      label: currentItem.timeLeft,
                      variant: currentItem.isOverdue
                          ? TagBadgeVariant.warning
                          : TagBadgeVariant.unread,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aciklama',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentItem.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teslim paneli',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      InfoStrip(
                        icon: currentItem.documentInfo == null
                            ? CupertinoIcons.doc_text_fill
                            : CupertinoIcons.check_mark_circled_solid,
                        text:
                            currentItem.documentInfo ??
                            'Henuz dokuman yuklenmedi.',
                        color: currentItem.documentInfo == null
                            ? AppColors.sunrise
                            : AppColors.teal,
                      ),
                      const SizedBox(height: 14),
                      InputField(
                        hint: 'Teslim notu ekle',
                        icon: CupertinoIcons.pencil,
                        controller: noteController,
                        maxLines: 4,
                        enabled: fieldsEnabled,
                      ),
                      if ((currentItem.submissionNote ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        InfoStrip(
                          icon: CupertinoIcons.doc_plaintext,
                          text: currentItem.submissionNote!,
                          color: AppColors.teal,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: fieldsEnabled ? _uploadDocument : null,
                              icon: const Icon(CupertinoIcons.paperclip),
                              label: const Text('Dokuman Yukle'),
                            ),
                          ),
                        ],
                      ),
                      if (canEditCompleted) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => editingCompleted = true),
                                icon: const Icon(CupertinoIcons.pencil_outline),
                                label: const Text('Odevi Duzenle'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: fieldsEnabled ? 1 : 0.45,
                        child: IgnorePointer(
                          ignoring: !fieldsEnabled,
                          child: PrimaryButton(
                            label: canEditCompleted
                                ? 'Guncellemeyi Kaydet'
                                : 'Odevi Gonder',
                            onTap: _submitAssignment,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (submitted)
                        const InfoStrip(
                          icon: CupertinoIcons.check_mark_circled_solid,
                          text: 'Odev basariyla gonderildi.',
                          color: AppColors.teal,
                        )
                      else if (currentItem.isOverdue)
                        const InfoStrip(
                          icon: CupertinoIcons.exclamationmark_triangle_fill,
                          text:
                              'Bu teslim gecikti. Gonderim yapildiginda gec teslim olarak isaretlenecektir.',
                          color: AppColors.coral,
                        )
                      else
                        const InfoStrip(
                          icon: CupertinoIcons.check_mark_circled_solid,
                          text:
                              'Belgeler tamam oldugunda dogrudan bu panelden teslim edebilirsin.',
                          color: AppColors.teal,
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
}
