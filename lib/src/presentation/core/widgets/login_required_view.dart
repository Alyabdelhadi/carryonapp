import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/localization.dart';
import '../application_state/session_status_provider/session_status_provider.dart';
import '../router/routes.dart';
import 'empty_state.dart';

/// Renders [child] when a session exists, otherwise the sign-in prompt the
/// Ionic app showed ("Please login to access this page") with a button to
/// the login screen. Tabs that need an account wrap their body in this.
class LoginRequired extends ConsumerWidget {
  const LoginRequired({super.key, required this.child, this.message});

  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStatusProvider);
    return switch (session) {
      AsyncData(value: .authenticated) => child,
      AsyncData() => EmptyState(
        icon: Icons.lock_outline_rounded,
        title: context.l10n.coreSignInToContinue,
        message: message ?? context.l10n.coreLoginToAccessPage,
        actionLabel: context.l10n.login,
        onAction: () => context.pushNamed(Routes.login.name),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Runs [action] when signed in; otherwise shows the prompt toast and opens
/// the login screen (the home screen's behaviour for guests).
Future<void> requireLogin(
  BuildContext context,
  WidgetRef ref,
  VoidCallback action, {
  String? message,
}) async {
  final isLoggedIn = switch (ref.read(sessionStatusProvider)) {
    AsyncData(value: .authenticated) => true,
    _ => false,
  };
  if (isLoggedIn) {
    action();
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message ?? context.l10n.coreLoginToAccessPage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  await context.pushNamed(Routes.login.name);
}
