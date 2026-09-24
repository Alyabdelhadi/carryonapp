import 'package:intl/intl.dart';

/// Display formatting shared by every screen, so dates and money read the
/// same everywhere.
///
/// Dates follow the active locale (`Intl.defaultLocale`, set by the
/// localization provider) for month and weekday names, but digits are
/// always Western (0-9): that is how numbers are written in the app's
/// markets, and it keeps amounts, phone numbers and ids readable next to
/// Latin text in Arabic layouts.
abstract final class Formatters {
  // Skeleton formats: each locale orders day, month and year its own way
  // ("Jun 24, 2025" in English, "24 يونيو 2025" in Arabic).

  /// "Jun 24" / "24 يونيو"
  static String monthDay(DateTime? d) =>
      d == null ? '' : westernDigits(DateFormat.MMMd().format(d));

  /// "Jun 24, 2025" / "24 يونيو 2025"
  static String monthDayYear(DateTime? d) =>
      d == null ? '' : westernDigits(DateFormat.yMMMd().format(d));

  /// "Tue, Jun 24" / "الثلاثاء، 24 يونيو"
  static String weekdayMonthDay(DateTime? d) =>
      d == null ? '' : westernDigits(DateFormat.MMMEd().format(d));

  /// "2025-06-24" — wire format, never localized.
  static String isoDay(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd', 'en_US').format(d);

  /// Reward text as the app shows it: "$20" or [free] ("Free").
  static String reward(String? amount, {String free = 'Free'}) {
    final a = (amount ?? '').trim();
    if (a.isEmpty || a.toLowerCase() == 'free') return free;
    if (a.startsWith(r'$')) return a;
    return '\$$a';
  }

  /// "4.5" or [fresh] ("New") when no ratings yet.
  static String rating(double? value, {int? count, String fresh = 'New'}) {
    if (value == null || (count ?? 1) == 0) return fresh;
    return value.toStringAsFixed(1);
  }

  /// "0.06" style compact decimals for impact stats.
  static String compact(double? value, {int fractionDigits = 2}) {
    if (value == null) return '0';
    return value.toStringAsFixed(fractionDigits);
  }

  /// "2,138 km"; pass the localized unit as [unit].
  static String distanceKm(double? km, {String unit = 'km'}) {
    if (km == null) return '';
    final n = NumberFormat.decimalPattern('en_US').format(km.round());
    return '${westernDigits(n)} $unit';
  }

  /// Initials for avatars: "Farag Tabaja" → "FT".
  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase());
    final out = letters.join();
    return out.isEmpty ? '?' : out;
  }

  static const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  static const _easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';

  /// Rewrites Arabic-Indic digits (٠..٩ and ۰..۹) as 0..9.
  static String westernDigits(String s) {
    final b = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      var i = _arabicIndic.indexOf(ch);
      if (i < 0) i = _easternArabicIndic.indexOf(ch);
      b.write(i < 0 ? ch : i.toString());
    }
    return b.toString();
  }
}
