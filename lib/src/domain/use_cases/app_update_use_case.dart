import '../../core/base/result.dart';
import '../entities/catalog.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/session_repository.dart';

/// What the update check decided.
class AppUpdateDecision {
  const AppUpdateDecision({required this.currentVersion, this.latestVersion});

  final String currentVersion;

  /// Set when a newer store version exists and the user was not recently
  /// prompted or asked to be reminded later.
  final String? latestVersion;

  bool get shouldPrompt => latestVersion != null;
}

/// Store-version prompt with the original app's rules: at most once every
/// 24 hours, and never while a "remind me tomorrow" postponement is
/// active.
final class CheckAppUpdateUseCase {
  CheckAppUpdateUseCase(this.catalog, this.session);

  final CatalogRepository catalog;
  final SessionRepository session;

  static const _cooldown = Duration(hours: 24);

  Future<AppUpdateDecision> call({
    required String currentVersion,
    required bool isIos,
  }) async {
    final now = DateTime.now();
    final postponed = session.updatePostponedUntil;
    if (postponed != null && now.isBefore(postponed)) {
      return AppUpdateDecision(currentVersion: currentVersion);
    }
    final last = session.lastUpdateCheck;
    if (last != null && now.difference(last) < _cooldown) {
      return AppUpdateDecision(currentVersion: currentVersion);
    }

    final AppVersionInfo info;
    switch (await catalog.appVersion()) {
      case Success(:final data):
        info = data;
      case Error():
        return AppUpdateDecision(currentVersion: currentVersion);
    }
    final latest = isIos ? info.ios : info.android;
    await session.setLastUpdateCheck(now);
    if (latest == null || !isNewer(latest, currentVersion)) {
      return AppUpdateDecision(currentVersion: currentVersion);
    }
    return AppUpdateDecision(
      currentVersion: currentVersion,
      latestVersion: latest,
    );
  }

  Future<void> postpone() {
    return session.setUpdatePostponedUntil(DateTime.now().add(_cooldown));
  }

  Future<void> clearPostpone() => session.setUpdatePostponedUntil(null);

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
