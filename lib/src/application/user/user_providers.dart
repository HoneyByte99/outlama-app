import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/active_mode.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_state.dart';

/// Derived read-only provider — single source of truth is [AuthNotifier].
/// To switch mode, call [AuthNotifier.switchMode] — never write here directly.
final activeModeProvider = Provider<ActiveMode>((ref) {
  final authState = ref.watch(authNotifierProvider).valueOrNull;
  if (authState is AuthAuthenticated) return authState.user.activeMode;
  return ActiveMode.client;
});
