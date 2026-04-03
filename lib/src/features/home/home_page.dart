import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';
import '../../app/router.dart';
import '../../application/auth/auth_providers.dart';
import '../../application/auth/auth_state.dart';
import '../../application/service/service_providers.dart';
import '../../application/user/user_providers.dart';
import '../../domain/enums/active_mode.dart';
import '../../domain/enums/category_id.dart';
import '../../domain/models/service.dart';

// ---------------------------------------------------------------------------
// Category filter state — local to this page subtree
// ---------------------------------------------------------------------------

final _selectedCategoryProvider = StateProvider<CategoryId?>((ref) => null);

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final activeMode = ref.watch(activeModeProvider);

    final displayName = authAsync.valueOrNull is AuthAuthenticated
        ? (authAsync.valueOrNull as AuthAuthenticated).user.displayName
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Outalma'),
        actions: [
          _ModeBadge(
            activeMode: activeMode,
            onTap: () => context.push(AppRoutes.switchMode),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Se déconnecter',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              displayName.isNotEmpty
                  ? 'Bonjour $displayName'
                  : 'Bonjour',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Que recherchez-vous ?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
            ),
          ),
          // Category chips
          const _CategoryChipsRow(),
          const SizedBox(height: 8),
          // Service grid
          const Expanded(child: _ServiceGrid()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category chips row
// ---------------------------------------------------------------------------

class _CategoryChipsRow extends ConsumerWidget {
  const _CategoryChipsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedCategoryProvider);

    final items = <(String label, CategoryId? value)>[
      ('Tout', null),
      ('Ménage', CategoryId.menage),
      ('Plomberie', CategoryId.plomberie),
      ('Jardinage', CategoryId.jardinage),
      ('Autre', CategoryId.autre),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, value) = items[i];
          final isActive = selected == value;
          return _CategoryChip(
            label: label,
            isActive: isActive,
            onTap: () => ref
                .read(_selectedCategoryProvider.notifier)
                .state = value,
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isActive ? AppColors.surface : AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Service grid
// ---------------------------------------------------------------------------

class _ServiceGrid extends ConsumerWidget {
  const _ServiceGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final servicesAsync = ref.watch(serviceListProvider);

    return servicesAsync.when(
      loading: () => const _ServiceGridLoading(),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.invalidate(serviceListProvider),
      ),
      data: (services) {
        final filtered = selectedCategory == null
            ? services
            : services
                .where((s) => s.categoryId == selectedCategory)
                .toList();

        if (filtered.isEmpty) {
          return const _EmptyState();
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            return _ServiceCard(service: filtered[i]);
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Service card
// ---------------------------------------------------------------------------

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    final priceLabel = service.priceType.name == 'hourly'
        ? '${(service.price / 100).toStringAsFixed(0)} €/h'
        : '${(service.price / 100).toStringAsFixed(0)} €';

    return GestureDetector(
      onTap: () => context.push(AppRoutes.serviceDetail(service.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 110,
                width: double.infinity,
                color: AppColors.border,
                child: const Icon(
                  Icons.home_repair_service_outlined,
                  size: 36,
                  color: AppColors.icons,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _categoryLabel(service.categoryId),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(CategoryId id) {
    switch (id) {
      case CategoryId.menage:
        return 'Ménage';
      case CategoryId.plomberie:
        return 'Plomberie';
      case CategoryId.jardinage:
        return 'Jardinage';
      case CategoryId.autre:
        return 'Autre';
    }
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _ServiceGridLoading extends StatelessWidget {
  const _ServiceGridLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty + error states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 56,
              color: AppColors.icons,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun service disponible\npour le moment',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 56,
              color: AppColors.icons,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode badge
// ---------------------------------------------------------------------------

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.activeMode, required this.onTap});

  final ActiveMode activeMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isClient = activeMode == ActiveMode.client;
    final label = isClient ? 'Client' : 'Prestataire';
    final color = isClient ? AppColors.primary : AppColors.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.swap_horiz_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
