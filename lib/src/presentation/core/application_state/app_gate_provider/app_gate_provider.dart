import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/use_cases/app_update_use_case.dart';
import '../../../../domain/use_cases/auth_use_case.dart';
import '../app_settings_provider/app_settings_provider.dart';
import '../session_status_provider/session_status_provider.dart';

export '../../../../domain/use_cases/auth_use_case.dart' show IdentityGate;

/// Whether the store has a newer version than this install. Checked at
/// launch and again on every return to the foreground (see
/// `AppGateRefresher`); a failed check never blocks.
final appUpdateProvider = FutureProvider<AppUpdateDecision>((ref) async {
  final String currentVersion;
  try {
    currentVersion = (await PackageInfo.fromPlatform()).version;
  } on Object {
    return const AppUpdateDecision(currentVersion: '');
  }
  return ref
      .read(checkAppUpdateUseCaseProvider)
      .call(currentVersion: currentVersion, isIos: Platform.isIOS);
});

/// What the identity check allows the signed-in user to do. Re-evaluated
/// on login, signup, logout, after a verification attempt, on an identity
/// push, and when the app resumes while under review.
final identityGateProvider = FutureProvider<IdentityGate>((ref) async {
  final session = await ref.watch(sessionStatusProvider.future);
  if (session != SessionStatus.authenticated) return IdentityGate.notRequired;
  final settings = await ref.watch(appSettingsProvider.future);
  return ref
      .read(resolveIdentityGateUseCaseProvider)
      .call(shuftiEnabled: settings.shuftiEnabled);
});

/// True while a signed-in user's check is still with Shufti: browsing is
/// allowed, sending, receiving and carrying packages are not.
final isUnderReviewProvider = Provider<bool>((ref) {
  return ref.watch(identityGateProvider).value == IdentityGate.underReview;
});

/// The "Verified" badge shows only while the admin has the check on.
final showVerifiedBadgeProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).value?.shuftiEnabled ?? false;
});
