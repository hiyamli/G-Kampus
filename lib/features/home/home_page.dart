import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/floating_icon_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/schedule_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/tag_badge.dart';
import '../assignments/assignment_detail_page.dart';
import '../announcements/announcement_detail_page.dart';
import '../groups/groups_sheet.dart';
import '../schedule/schedule_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int get unreadMessages => appRepository.unreadConversationCounts.values.fold(
    0,
    (sum, item) => sum + item,
  );

  Future<void> _openMessages() async {
    await showGroupsSheet(context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  HeroCard(
                    compact: true,
                    title: 'Gunaydin, ${appRepository.student.name}',
                    subtitle: '',
                    badges: const [
                      HeroCardBadge(label: 'Bugun 2 dersin var'),
                      HeroCardBadge(
                        label: '3 sinav yaklasiyor',
                        variant: TagBadgeVariant.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SectionHeader(
                    title: 'Bugunku Dersler',
                    subtitle: 'Takvimine gore siradaki akademik akisin',
                  ),
                  const SizedBox(height: 16),
                  ...appRepository.schedules
                      .take(2)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: ScheduleCard(
                            item: item,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ScheduleDetailPage(item: item),
                              ),
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 12),
                  const SectionHeader(
                    title: 'Gunluk Yemekhane',
                    subtitle: 'Bugunun sicak servis araligi ve menu listesi',
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.sunrise.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                CupertinoIcons.square_favorites_fill,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Merkez Yemekhane',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const TagBadge(
                              label: '11:30 - 14:00',
                              variant: TagBadgeVariant.unread,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...appRepository.menuItems.map(
                          (menu) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '• $menu',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Yaklasan Odevler',
                    subtitle: 'Oncelikli teslimler ve kalan gunler',
                  ),
                  const SizedBox(height: 16),
                  ...appRepository.assignments
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AssignmentDetailPage(item: item),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: item.isOverdue
                                          ? AppColors.coral.withValues(
                                              alpha: 0.16,
                                            )
                                          : AppColors.teal.withValues(
                                              alpha: 0.16,
                                            ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      item.isCompleted
                                          ? Icons.check_rounded
                                          : Icons.upload_file_rounded,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.deadline,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  TagBadge(
                                    label: item.timeLeft,
                                    variant: item.isOverdue
                                        ? TagBadgeVariant.warning
                                        : TagBadgeVariant.success,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Son Duyurular',
                    subtitle:
                        'Universite, fakulte ve ders kaynakli guncellemeler',
                  ),
                  const SizedBox(height: 16),
                  ...appRepository.announcements
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnnouncementCard(
                            item: item,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AnnouncementDetailPage(item: item),
                              ),
                            ),
                          ),
                        ),
                      ),
                ]),
              ),
            ),
          ],
        ),
        Positioned(
          top: 34,
          right: 8,
          child: FloatingIconButton(
            icon: CupertinoIcons.chat_bubble_text_fill,
            badgeCount: unreadMessages,
            opacity: 0.48,
            onTap: _openMessages,
          ),
        ),
      ],
    );
  }
}
