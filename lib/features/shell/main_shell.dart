import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../core/data/mock_data.dart';
import '../../core/supabase/supabase_service.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../announcements/announcements_page.dart';
import '../assignments/assignments_page.dart';
import '../groups/messages_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../schedule/schedule_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLogout,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PageController _pageController = PageController();
  int index = 0;
  int dmBadge = 0;
  int assignmentBadge = 0;
  int announcementBadge = 0;
  int avatarIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshAllBadges();
  }

  void _refreshDmBadge() {
    dmBadge = appRepository.unreadConversationCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );
  }

  void _refreshAllBadges() {
    _refreshDmBadge();
    assignmentBadge = appRepository.assignments
        .where((item) => !item.isCompleted && !item.isOverdue)
        .length;
    announcementBadge = appRepository.announcements
        .where((item) => item.isNew)
        .length;
  }

  void _applyBadgeRules(int value) {
    if (value == 1) dmBadge = 0;
    if (value == 3) assignmentBadge = 0;
    if (value == 4) announcementBadge = 0;
  }

  void _onSelected(int value) {
    setState(() {
      index = value;
      _applyBadgeRules(value);
    });
    _pageController.animateToPage(
      value,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int value) {
    setState(() {
      index = value;
      _applyBadgeRules(value);
    });
  }

  List<Color> _avatarColors(int selectedIndex) {
    return switch (selectedIndex) {
      1 => const [Color(0xFFFABB59), Color(0xFFED7568)],
      2 => const [Color(0xFFED7568), Color(0xFF1A2942)],
      3 => const [Color(0xFF31A8AD), Color(0xFFFABB59)],
      _ => const [Color(0xFF1A2942), Color(0xFF31A8AD)],
    };
  }

  Future<void> _openMorePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CampusScaffold(
          body: ProfilePage(
            themeMode: widget.themeMode,
            onThemeChanged: widget.onThemeChanged,
            onLogout: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              setState(() => index = 0);
              widget.onLogout();
            },
            profile: appRepository.student,
            avatarIndex: avatarIndex,
            onProfileChanged: (updatedProfile, updatedAvatar) {
              setState(() {
                MockData.setStudent(updatedProfile);
                avatarIndex = updatedAvatar;
              });
              unawaited(
                SupabaseService.updateCurrentProfileFields({
                  'bio': updatedProfile.bio,
                  if (updatedProfile.avatarPath != null)
                    'avatar_path': updatedProfile.avatarPath,
                }),
              );
            },
          ),
          showBackButton: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      MessagesPage(
        onDataChanged: () => setState(() {
          _refreshAllBadges();
        }),
      ),
      const SchedulePage(),
      const AssignmentsPage(),
      const AnnouncementsPage(),
    ];

    return CampusScaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: PageView(
              key: const ValueKey('main-shell-page-view'),
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: pages,
            ),
          ),
          Positioned(
            top: 8,
            right: 0,
            child: GestureDetector(
              onTap: _openMorePage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: _avatarColors(avatarIndex)),
                  image:
                      (appRepository.student.avatarPath != null &&
                          appRepository.student.avatarPath!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(
                            appRepository.student.avatarPath!,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                child:
                    (appRepository.student.avatarPath == null ||
                        appRepository.student.avatarPath!.isEmpty)
                    ? const Icon(Icons.person, size: 20, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
      showBackButton: false,
      bottomNavigationBar: CustomBottomNav(
        index: index,
        onSelected: _onSelected,
        dmBadge: dmBadge,
        assignmentBadge: assignmentBadge,
        announcementBadge: announcementBadge,
      ),
    );
  }
}
