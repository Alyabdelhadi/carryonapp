import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/trip.dart';

/// The carrier's declared routes, keyed by the signed-in user's id.
///
/// A [BusinessFailure] is thrown so the page receives it as an `AsyncError`
/// and renders it through `FailureView`.
final myTripsProvider = FutureProvider.autoDispose.family<List<Trip>, int>((
  ref,
  carrierId,
) async {
  final result = await ref.watch(getMyTripsUseCaseProvider).call(carrierId);
  return switch (result) {
    Success(:final data) => data,
    Error(:final error) => throw error,
  };
});
