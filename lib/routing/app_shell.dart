import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../widgets/bms_nav_icons.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: BmsHomeNavIcon(selected: false),
            selectedIcon: BmsHomeNavIcon(selected: true),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined, color: AppTokens.textSecondary),
            selectedIcon: Icon(Icons.videocam_rounded, color: AppTokens.primaryRed),
            label: 'Movies',
          ),
          NavigationDestination(
            icon: BmsTicketNavIcon(selected: false),
            selectedIcon: BmsTicketNavIcon(selected: true),
            label: 'Live Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: AppTokens.textSecondary),
            selectedIcon: Icon(Icons.person_rounded, color: AppTokens.primaryRed),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
