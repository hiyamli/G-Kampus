import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.index,
    required this.onSelected,
    required this.dmBadge,
    required this.assignmentBadge,
    required this.announcementBadge,
  });

  final int index;
  final ValueChanged<int> onSelected;
  final int dmBadge;
  final int assignmentBadge;
  final int announcementBadge;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onSelected,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_rounded),
          label: 'Ana Sayfa',
        ),
        NavigationDestination(
          icon: _NavIcon(icon: Icons.chat_bubble_rounded, badge: dmBadge),
          label: 'DM Kutusu',
        ),
        NavigationDestination(
          icon: Icon(Icons.view_week_rounded),
          label: 'Program',
        ),
        NavigationDestination(
          icon: _NavIcon(
            icon: Icons.assignment_rounded,
            badge: assignmentBadge,
          ),
          label: 'Ödevler',
        ),
        NavigationDestination(
          icon: _NavIcon(
            icon: Icons.campaign_rounded,
            badge: announcementBadge,
          ),
          label: 'Duyurular',
        ),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.badge});

  final IconData icon;
  final int badge;

  @override
  Widget build(BuildContext context) {
    if (badge <= 0) {
      return Icon(icon);
    }

    return Badge(label: Text('$badge'), child: Icon(icon));
  }
}
