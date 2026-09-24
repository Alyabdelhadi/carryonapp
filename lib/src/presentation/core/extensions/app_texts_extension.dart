import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/app_texts.dart';
import '../application_state/app_texts_provider/app_texts_provider.dart';
import '../application_state/localization_provider/localization_provider.dart';

/// `ref.texts.get('key', context.l10n.fallback)` — the admin-managed copy,
/// watched so the widget rebuilds when the server copy arrives.
///
/// The server holds English copy only, so in any other language the
/// bundled translation (the fallback) is used instead.
extension AppTextsRef on WidgetRef {
  AppTexts get texts {
    final locale = watch(localizationProvider);
    final server = watch(appTextsStateProvider);
    return locale.languageCode == 'en' ? server : const AppTexts.empty();
  }
}
