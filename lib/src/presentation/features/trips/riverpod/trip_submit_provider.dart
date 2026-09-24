import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/trip.dart';

/// The message `TripRepositoryImpl` puts on the failure when a create or
/// update answer carries no trip id. It is a marker, not user copy: the
/// form swaps it for `l10n.tripNotSaved` before showing the error.
const tripNotSavedMarker = 'trip_not_saved';

/// Runs the trip form's write operations (create, update, cancel) and
/// exposes their progress as an [AsyncValue] so the page can disable the
/// buttons and surface a failure with `AppFeedback.error`.
class TripSubmit extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Creates a trip, or updates it when [tripId] is given. Resolves true on
  /// success; on failure the error lands in [state].
  Future<bool> save(TripInput input, {int? tripId}) async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();

    final result = await ref
        .read(saveTripUseCaseProvider)
        .call(input, tripId: tripId);
    if (!ref.mounted) return false;

    switch (result) {
      case Success():
        state = const AsyncValue.data(null);
        return true;
      case Error(:final error):
        state = AsyncValue.error(error, StackTrace.current);
        return false;
    }
  }

  /// Cancels (deletes) a trip. Resolves true on success.
  Future<bool> delete(int tripId) async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();

    final result = await ref.read(deleteTripUseCaseProvider).call(tripId);
    if (!ref.mounted) return false;

    switch (result) {
      case Success():
        state = const AsyncValue.data(null);
        return true;
      case Error(:final error):
        state = AsyncValue.error(error, StackTrace.current);
        return false;
    }
  }
}

final tripSubmitProvider = AsyncNotifierProvider.autoDispose<TripSubmit, void>(
  TripSubmit.new,
);
