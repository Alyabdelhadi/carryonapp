import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/base/unit.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../domain/failures/business_failure.dart';
import '../../../../domain/use_cases/parcel_order_use_case.dart';
import 'package_lists_provider.dart';

export '../../../../domain/use_cases/parcel_order_use_case.dart'
    show ParcelOrderAction;

/// The write side of the order detail screen. The state is the last order
/// an action returned (null before any action); its loading flag drives
/// the busy overlay while a request is in flight. Every successful action
/// invalidates the package lists.
class OrderActions extends AsyncNotifier<ParcelOrder?> {
  @override
  Future<ParcelOrder?> build() async => null;

  /// Accept / drop / pickup / transit / deliver / cancel.
  Future<Result<ParcelOrder, BusinessFailure>> transition({
    required ParcelOrderAction action,
    required int userId,
    required int orderId,
  }) {
    return _run(
      () => ref
          .read(transitionParcelOrderUseCaseProvider)
          .call(action: action, userId: userId, orderId: orderId),
    );
  }

  /// Moves the "needed before" date of an expired order.
  Future<Result<ParcelOrder, BusinessFailure>> extend({
    required int userId,
    required int orderId,
    required DateTime neededBefore,
  }) {
    return _run(
      () => ref
          .read(extendParcelOrderUseCaseProvider)
          .call(userId: userId, orderId: orderId, neededBefore: neededBefore),
    );
  }

  /// Tells the backend the carrier opened a matching order, so the "NEW"
  /// badge clears. Best effort and silent, as in the Ionic app; does not
  /// touch [state].
  Future<void> markRead({required int carrierId, required int orderId}) async {
    final result = await ref
        .read(markMatchingOrderReadUseCaseProvider)
        .call(carrierId: carrierId, orderId: orderId);
    if (!ref.mounted) return;
    if (result case Success<Unit, BusinessFailure>()) {
      ref.invalidate(matchingOrdersProvider);
    }
  }

  Future<Result<ParcelOrder, BusinessFailure>> _run(
    Future<Result<ParcelOrder, BusinessFailure>> Function() operation,
  ) async {
    state = const AsyncValue.loading();
    final result = await operation();
    if (!ref.mounted) return result;
    switch (result) {
      case Success(:final data):
        state = AsyncValue.data(data);
        invalidatePackageLists(ref);
      case Error(:final error):
        state = AsyncValue.error(error, StackTrace.current);
    }
    return result;
  }
}

final orderActionsProvider =
    AsyncNotifierProvider.autoDispose<OrderActions, ParcelOrder?>(
      OrderActions.new,
    );

/// The carrier's live profile for the rating sheet (the Ionic modal
/// fetched `userInfo` on open).
final carrierProfileProvider = FutureProvider.autoDispose.family<AppUser, int>((
  ref,
  carrierId,
) async {
  final result = await ref.watch(fetchUserUseCaseProvider).call(carrierId);
  return switch (result) {
    Success(:final data) => data,
    Error(:final error) => throw error,
  };
});

/// Rates the carrier of a delivered order. The backend's `user_id` is the
/// carrier being rated, as the Ionic rate modal sent it.
class RateCarrier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<Result<Unit, BusinessFailure>> submit({
    required int carrierId,
    required int orderId,
    required double rating,
  }) async {
    state = const AsyncValue.loading();
    final result = await ref
        .read(rateOrderUseCaseProvider)
        .call(userId: carrierId, orderId: orderId, rating: rating);
    if (!ref.mounted) return result;
    switch (result) {
      case Success():
        state = const AsyncValue.data(true);
        ref.read(ratedOrderIdsProvider.notifier).add(orderId);
      case Error(:final error):
        state = AsyncValue.error(error, StackTrace.current);
    }
    return result;
  }
}

final rateCarrierProvider =
    AsyncNotifierProvider.autoDispose<RateCarrier, bool>(RateCarrier.new);

/// Orders rated during this app session. The Ionic app kept the same list
/// in `sessionStorage`; the backend does not report whether an order was
/// rated, so this lives as long as the process.
class RatedOrderIds extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void add(int orderId) => state = {...state, orderId};
}

final ratedOrderIdsProvider = NotifierProvider<RatedOrderIds, Set<int>>(
  RatedOrderIds.new,
);
