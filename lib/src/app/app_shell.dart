import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth/auth_providers.dart';
import '../application/user/user_providers.dart';
import '../domain/enums/active_mode.dart';
import 'app_theme.dart';

/// Shell scaffold with mode-aware bottom navigation.
///
/// Client mode  → Tab 0: Accueil  | Tab 1: Réservations
/// Provider mode → Tab 0: Tableau de bord | Tab 1: Demandes
///
/// The router has 4 branches (0=home, 1=bookings, 2=provider, 3=inbox).
/// In client mode we expose branches 0+1; in provider mode branches 2+3.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize FCM token registration (no-op if not yet authenticated).
    ref.watch(notificationInitProvider);

    final isProvider =
        ref.watch(activeModeProvider) == ActiveMode.provider;

    // Map logical tab (0/1) to actual branch index.
    final branchOffset = isProvider ? 2 : 0;
    final currentLogical = (shell.currentIndex - branchOffset).clamp(0, 1);

    void onTap(int logicalIndex) {
      final branchIndex = logicalIndex + branchOffset;
      shell.goBranch(
        branchIndex,
        initialLocation: branchIndex == shell.currentIndex,
      );
    }

    final items = isProvider ? _providerItems : _clientItems;

    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentLogical,
        onTap: onTap,
        backgroundColor: AppColors.surface,
        selectedItemColor:
            isProvider ? AppColors.success : AppColors.primary,
        unselectedItemColor: AppColors.icons,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 8,
        items: items,
      ),
    );
  }
}

const _clientItems = [
  BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home_rounded),
    label: 'Accueil',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.calendar_today_outlined),
    activeIcon: Icon(Icons.calendar_today_rounded),
    label: 'Réservations',
  ),
];

const _providerItems = [
  BottomNavigationBarItem(
    icon: Icon(Icons.dashboard_outlined),
    activeIcon: Icon(Icons.dashboard_rounded),
    label: 'Tableau de bord',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.inbox_outlined),
    activeIcon: Icon(Icons.inbox_rounded),
    label: 'Demandes',
  ),
];
