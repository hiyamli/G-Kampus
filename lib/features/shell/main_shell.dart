import 'package:flutter/material.dart';

import '../../core/data/repository_provider.dart';
import '../../core/models/mock_models.dart';
import '../../widgets/campus_scaffold.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../announcements/announcements_page.dart';
import '../assignments/assignments_page.dart';
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
  int index = 0;
  int assignmentBadge = 3;
  int announcementBadge = 2;
  StudentProfile profile = appRepository.student;
  int avatarIndex = 0;

  void _onSelected(int value) {
    setState(() {
      index = value;
      if (value == 1) assignmentBadge = 0;
      if (value == 3) announcementBadge = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const AssignmentsPage(),
      const SchedulePage(),
      const AnnouncementsPage(),
      ProfilePage(
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
        onLogout: widget.onLogout,
        profile: profile,
        avatarIndex: avatarIndex,
        onProfileChanged: (updatedProfile, updatedAvatar) {
          setState(() {
            profile = updatedProfile;
            avatarIndex = updatedAvatar;
          });
        },
      ),
    ];

    return CampusScaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
      ),
      bottomNavigationBar: CustomBottomNav(
        index: index,
        onSelected: _onSelected,
        assignmentBadge: assignmentBadge,
        announcementBadge: announcementBadge,
      ),
    );
  }
}
