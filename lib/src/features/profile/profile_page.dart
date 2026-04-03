import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../application/auth/auth_providers.dart';
import '../../application/auth/auth_state.dart';
import '../../application/theme/theme_provider.dart';
import '../../application/user/user_providers.dart';
import '../../domain/enums/active_mode.dart';
import '../../domain/models/app_user.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oc = context.oc;
    final authAsync = ref.watch(authNotifierProvider);
    final user = authAsync.valueOrNull is AuthAuthenticated
        ? (authAsync.valueOrNull as AuthAuthenticated).user
        : null;

    return Scaffold(
      backgroundColor: oc.background,
      appBar: AppBar(
        title: const Text('Profil & Paramètres'),
        backgroundColor: oc.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) _UserHeader(user: user),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Mode actif'),
            const SizedBox(height: 12),
            const _ModeToggle(),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Apparence'),
            const SizedBox(height: 12),
            const _ThemeSelector(),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Compte'),
            const SizedBox(height: 12),
            _AccountSection(user: user),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User header
// ---------------------------------------------------------------------------

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final oc = context.oc;
    final initials = _initials(user.displayName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: oc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: oc.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: oc.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: oc.secondaryText,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.country.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: oc.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.country.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: oc.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
}

// ---------------------------------------------------------------------------
// Mode toggle
// ---------------------------------------------------------------------------

class _ModeToggle extends ConsumerStatefulWidget {
  const _ModeToggle();

  @override
  ConsumerState<_ModeToggle> createState() => _ModeToggleState();
}

class _ModeToggleState extends ConsumerState<_ModeToggle> {
  bool _saving = false;

  Future<void> _select(ActiveMode mode) async {
    if (ref.read(activeModeProvider) == mode) return;
    setState(() => _saving = true);
    try {
      await ref.read(authNotifierProvider.notifier).switchMode(mode);
    } catch (_) {
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
    final oc = context.oc;
    final activeMode = ref.watch(activeModeProvider);

    if (_saving) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: oc.primary,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _ModeTile(
            icon: Icons.search_rounded,
            label: 'Client',
            subtitle: 'Réserver des services',
            isActive: activeMode == ActiveMode.client,
            color: oc.primary,
            onTap: () => _select(ActiveMode.client),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeTile(
            icon: Icons.handyman_rounded,
            label: 'Prestataire',
            subtitle: 'Gérer mes missions',
            isActive: activeMode == ActiveMode.provider,
            color: oc.success,
            onTap: () => _select(ActiveMode.provider),
          ),
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final oc = context.oc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.08) : oc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : oc.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isActive ? color : oc.icons, size: 22),
                if (isActive)
                  Icon(Icons.check_circle_rounded, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive ? color : oc.primaryText,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: oc.secondaryText,
                    height: 1.3,
                  ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme selector
// ---------------------------------------------------------------------------

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oc = context.oc;
    final current = ref.watch(themeModeProvider);

    final options = [
      (ThemeMode.system, Icons.brightness_auto_outlined, 'Système'),
      (ThemeMode.light, Icons.light_mode_outlined, 'Clair'),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'Sombre'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: oc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: oc.border),
      ),
      child: Column(
        children: options.asMap().entries.map((entry) {
          final i = entry.key;
          final (mode, icon, label) = entry.value;
          final isSelected = current == mode;

          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(14) : Radius.zero,
                  bottom: i == options.length - 1
                      ? const Radius.circular(14)
                      : Radius.zero,
                ),
                onTap: () =>
                    ref.read(themeModeProvider.notifier).setThemeMode(mode),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected ? oc.primary : oc.icons,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: isSelected
                                    ? oc.primary
                                    : oc.primaryText,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_rounded,
                            color: oc.primary, size: 18),
                    ],
                  ),
                ),
              ),
              if (i < options.length - 1)
                Divider(
                    height: 1, indent: 50, color: oc.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account section
// ---------------------------------------------------------------------------

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oc = context.oc;

    return Container(
      decoration: BoxDecoration(
        color: oc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: oc.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.logout_outlined, size: 20, color: oc.error),
              const SizedBox(width: 14),
              Text(
                'Se déconnecter',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: oc.error,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.oc.secondaryText,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }
}
