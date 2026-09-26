import '../../core/base/result.dart';
import '../entities/catalog.dart';
import '../repositories/catalog_repository.dart';

/// What the update check decided.
class AppUpdateDecision {
  const AppUpdateDecision({required this.currentVersion, this.latestVersion});

  final String currentVersion;

  /// Set when the store has a newer version than the installed one. The
  /// update is mandatory: the app shows only the update screen.
  final String? latestVersion;

  bool get updateRequired => latestVersion != null;
}

/// Compares the installed version with the one the admin published
/// (`/appVersions`). There is no "remind me later": a newer version blocks
/// the app until the user updates. A failed check never blocks.
final class CheckAppUpdateUseCase {
  CheckAppUpdateUseCase(this.catalog);

  final CatalogRepository catalog;

  Future<AppUpdateDecision> call({
    required String currentVersion,
    required bool isIos,
  }) async {
    final AppVersionInfo info;
    switch (await catalog.appVersion()) {
      case Success(:final data):
        info = data;
      case Error():
        return AppUpdateDecision(currentVersion: currentVersion);
    }
    final latest = isIos ? info.ios : info.android;
    if (latest == null || !isNewer(latest, currentVersion)) {
      return AppUpdateDecision(currentVersion: currentVersion);
    }
    return AppUpdateDecision(
      currentVersion: currentVersion,
      latestVersion: latest,
    );
  }

  /// Semantic comparison on the numeric parts only ("50.0.0" > "26.0").
  static bool isNewer(String latest, String current) {
    final a = _parts(latest);
    final b = _parts(current);
    for (var i = 0; i < 3; i++) {
      if (a[i] > b[i]) return true;
      if (a[i] < b[i]) return false;
    }
    return false;
  }

  static List<int> _parts(String version) {
    final nums = version
        .replaceAll(RegExp(r'[^\d.]'), '')
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    while (nums.length < 3) {
      nums.add(0);
    }
    return nums;
  }
}
