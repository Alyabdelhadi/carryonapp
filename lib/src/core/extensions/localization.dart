import 'package:flutter/material.dart';

import '../gen/l10n/app_localizations.dart';

extension BuildContextLocalizationExtension on BuildContext {
  AppLocalizations get locale => AppLocalizations.of(this);

  /// Shorter alias of [locale]: `context.l10n.homeTitle`.
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Whether the current locale lays out right-to-left (Arabic).
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
