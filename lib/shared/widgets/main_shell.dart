import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Bottom-navigation shell wrapping 3 tabs: Search, Reservations, Profile.
///
/// The AI Chat tab is a special case — tapping it pushes /chat as a
/// full-screen route (no bottom nav) instead of switching a branch.
///
/// Also provides a shared AppBar (Dawak logo/name + notifications icon).
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  /// Maps bottom nav index to shell branch index.
  /// Index 2 (AI Support) is handled separately — it pushes /chat.
  void _onTap(BuildContext context, int index) {
    if (index == 2) {
      // AI Support → full-screen push, not a shell branch
      context.push('/chat');
      return;
    }
    // Remap index: 0→0 (Search), 1→1 (Reservations), 3→2 (Profile)
    final branchIndex = index < 2 ? index : index - 1;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  /// Which bottom nav item is visually selected.
  /// Chat (index 2) is never "selected" since it's a push route.
  int get _selectedIndex {
    final branchIndex = navigationShell.currentIndex;
    return branchIndex < 2 ? branchIndex : branchIndex + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Image.asset(
          'assets/images/Dawak_logo.png',
          height: 48,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Dawak',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: AppColors.primary),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: AppColors.primary),
            label: 'Reservation',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent, color: AppColors.primary),
            label: 'AI Support',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
