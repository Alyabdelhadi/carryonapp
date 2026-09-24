/// Admin-editable UI copy fetched from `getTexts`. The Ionic app read every
/// label from this map; the Flutter app keeps that behaviour while falling
/// back to built-in English when a key is missing or the fetch failed.
class AppTexts {
  const AppTexts(this._values);

  const AppTexts.empty() : _values = const {};

  final Map<String, String> _values;

  bool get isEmpty => _values.isEmpty;

  /// The server value for [key], or [fallback] when absent or blank.
  String get(String key, String fallback) {
    final value = _values[key];
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }

  String? operator [](String key) => _values[key];

  Map<String, String> toMap() => Map.unmodifiable(_values);
}
