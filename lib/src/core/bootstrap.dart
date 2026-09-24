import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'base/global_error_handlers.dart';
import 'di/dependency_injection.dart';
import 'logger/log.dart';
import 'logger/riverpod_log.dart';

/// Process-level setup, kept out of `main` so the entry point stays a
/// single expression.
///
/// Builds the app's one [ProviderContainer] and installs the process-wide
/// error handlers against it, so the `CrashReporter` the handlers use and
/// the one the widget tree injects are the same instance.
///
/// Firebase is initialised here because push topic subscriptions need it
/// before the first frame. A missing platform config (no
/// `google-services.json` / `GoogleService-Info.plist`) must not take the
/// app down: the failure is logged and `firebaseReadyProvider` stays
/// false, which makes every push call fail softly.
///
/// Provider retry is disabled: Riverpod 3 retries failed providers with
/// backoff by default, which breaks fail-fast semantics for the startup
/// gate. Opt back in per provider where a retry is genuinely wanted.
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  // `--dart-define=CARRYON_DISABLE_PUSH=true` keeps the iOS notification
  // permission alert out of integration-test runs (it blanks screenshots).
  const pushDisabled = bool.fromEnvironment('CARRYON_DISABLE_PUSH');
  if (pushDisabled) {
    Log.warning('Push disabled by CARRYON_DISABLE_PUSH');
  } else {
    try {
      await Firebase.initializeApp();
      firebaseReady = true;
    } on Object catch (e) {
      Log.warning('Firebase not initialised, push disabled: $e');
    }
  }

  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    observers: [RiverpodObserver()],
    overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
  );
  installGlobalErrorHandlers(container.read(crashReporterProvider));

  return container;
}
