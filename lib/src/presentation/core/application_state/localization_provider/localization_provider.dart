import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/dependency_injection.dart';

part 'localization_provider.g.dart';

/// The languages the app ships. Arabic lays out right-to-left; Flutter
/// derives the [TextDirection] from the locale.
abstract final class AppLanguages {
  static const english = Locale('en');
  static const arabic = Locale('ar');
  static const all = [english, arabic];

  static bool isSupported(String code) =>
      all.any((l) => l.languageCode == code);
}

@Riverpod(keepAlive: true)
class Localization extends _$Localization {
  @override
  Locale build() {
    Intl.defaultLocale = AppLanguages.english.languageCode;
    return AppLanguages.english;
  }

  Future<void> changeLocale(Locale locale) async {
    final useCase = ref.read(setCurrentLocaleUseCaseProvider);
    await useCase(locale.languageCode);
    _apply(locale);
  }

  Future<void> setCurrentLocal() async {
    final useCase = ref.read(getCurrentLocaleUseCaseProvider);
    final language = await useCase();
    _apply(
      AppLanguages.isSupported(language)
          ? Locale(language)
          : AppLanguages.english,
    );
  }

  void _apply(Locale locale) {
    Intl.defaultLocale = locale.languageCode;
    state = locale;
  }
}
