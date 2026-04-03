import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';
import '../../application/auth/auth_providers.dart';
import '../../application/auth/auth_state.dart';
import '../../application/user/user_providers.dart';
import '../../domain/enums/active_mode.dart';

class SwitchModePage extends ConsumerStatefulWidget {
  const SwitchModePage({super.key});

  @override
  ConsumerState<SwitchModePage> createState() => _SwitchModePageState();
}

class _SwitchModePageState extends ConsumerState<SwitchModePage> {
  bool _saving = false;

  Future<void> _selectMode(ActiveMode mode) async {
    final currentMode = ref.read(activeModeProvider);
    if (currentMode == mode) {
      context.pop();
      return;
    }

    setState(() => _saving = true);

    try {
      // Update in-memory state immediately.
      ref.read(activeModeProvider.notifier).state = mode;

      // Persist to Firestore via the user repository.
      final authState = ref.read(authNotifierProvider).valueOrNull;
      if (authState is AuthAuthenticated) {
        final updatedUser = authState.user.copyWith(activeMode: mode);
        await ref.read(userRepositoryProvider).upsert(updatedUser);
      }

      if (mounted) context.pop();
    } catch (_) {
      // Revert on failure.
      ref.read(activeModeProvider.notifier).state = currentMode;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible de changer de mode. Réessayez.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMode = ref.watch(activeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _saving
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre mode actif',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Passez du mode client au mode prestataire à tout moment.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                    const SizedBox(height: 32),
                    _ModeCard(
                      mode: ActiveMode.client,
                      isActive: activeMode == ActiveMode.client,
                      icon: Icons.search_rounded,
                      title: 'Mode Client',
                      subtitle:
                          'Recherchez et réservez des services à domicile.',
                      accentColor: AppColors.primary,
                      onTap: () => _selectMode(ActiveMode.client),
                    ),
                    const SizedBox(height: 16),
                    _ModeCard(
                      mode: ActiveMode.provider,
                      isActive: activeMode == ActiveMode.provider,
                      icon: Icons.handyman_rounded,
                      title: 'Mode Prestataire',
                      subtitle: 'Proposez vos services et gérez vos missions.',
                      accentColor: AppColors.success,
                      onTap: () => _selectMode(ActiveMode.provider),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.isActive,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final ActiveMode mode;
  final bool isActive;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? accentColor : AppColors.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isActive
                              ? accentColor
                              : AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isActive)
              Icon(Icons.check_circle_rounded, color: accentColor, size: 24)
            else
              const Icon(Icons.circle_outlined, color: AppColors.border, size: 24),
          ],
        ),
      ),
    );
  }
}
