import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';

/// The admin runtime switches (`/appSettings`), fetched once per app run.
/// Failures fall back to the defaults so the UI never blocks on them.
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final result = await ref.watch(getAppSettingsUseCaseProvider).call();
  return switch (result) {
    Success(:final data) => data,
    Error() => const AppSettings(),
  };
});

/// Card-payment rules with defaults while the settings load.
final paymentRulesProvider = Provider<PaymentRules>((ref) {
  return ref.watch(appSettingsProvider).value?.payments ?? const PaymentRules();
});
