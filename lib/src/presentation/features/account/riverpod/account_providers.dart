import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';

/// The fresh profile (stats included) for the account screen. The use
/// case also refreshes the stored user, so the page invalidates
/// `currentUserProvider` once this resolves.
///
/// Declared by hand (no build_runner in feature code): the failure is
/// thrown so the page's `AsyncError` carries the `BusinessFailure` that
/// `FailureView` knows how to render.
final accountProfileProvider = FutureProvider.autoDispose.family<AppUser, int>((
  ref,
  userId,
) async {
  final result = await ref.watch(fetchUserUseCaseProvider).call(userId);
  return switch (result) {
    Success(:final data) => data,
    Error(:final error) => throw error,
  };
});

/// How many trips the signed-in carrier has declared — the "Trips" tile.
final accountTripsCountProvider = FutureProvider.autoDispose.family<int, int>((
  ref,
  userId,
) async {
  final result = await ref.watch(getMyTripsUseCaseProvider).call(userId);
  return switch (result) {
    Success(:final data) => data.length,
    Error(:final error) => throw error,
  };
});

/// The installed build's version string ("1.0.0"), for the footer line.
final accountAppVersionProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});
