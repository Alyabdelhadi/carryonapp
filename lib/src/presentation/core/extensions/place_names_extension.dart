import 'package:flutter/widgets.dart';

/// The language code the place-name helpers need (`Country.nameFor`,
/// `OrderAddress.cityFor`, `SliderImage.imageFor`, …).
extension LanguageCodeContext on BuildContext {
  String get languageCode => Localizations.localeOf(this).languageCode;
}
