import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';

/// The promotional banners at the top of the home screen (`sliders`).
final homeSlidersProvider = FutureProvider.autoDispose<List<SliderImage>>((
  ref,
) async {
  final result = await ref.watch(getSlidersUseCaseProvider).call();
  return switch (result) {
    Success(:final data) => _bySortNo(data, (s) => s.sortNo),
    Error(:final error) => throw error,
  };
});

/// The second banner row below the service cards (`sliders2`).
final homeSecondarySlidersProvider =
    FutureProvider.autoDispose<List<SliderImage>>((ref) async {
      final result = await ref
          .watch(getSlidersUseCaseProvider)
          .call(secondary: true);
      return switch (result) {
        Success(:final data) => _bySortNo(data, (s) => s.sortNo),
        Error(:final error) => throw error,
      };
    });

/// The send / carry / receive actions, in the admin's order.
final homeServicesProvider = FutureProvider.autoDispose<List<AppService>>((
  ref,
) async {
  final result = await ref.watch(getServicesUseCaseProvider).call();
  return switch (result) {
    Success(:final data) => _bySortNo(data, (s) => s.sortNo),
    Error(:final error) => throw error,
  };
});

/// Where the device is right now, for the header label. Null when the
/// location is unavailable (permission denied, no fix, geocoder failure):
/// the original page logged the error and showed nothing.
final homePlaceProvider = FutureProvider.autoDispose<PlaceInfo?>((ref) async {
  final result = await ref.watch(getCurrentPlaceUseCaseProvider).call();
  return switch (result) {
    Success(:final data) => data,
    Error() => null,
  };
});

/// How many packages match the signed-in carrier's trips (the header
/// stat). Zero for non-carriers.
final homeMatchingPackagesCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  final isCarrier = ref.watch(isCarrierProvider);
  if (userId == null || !isCarrier) return 0;

  final result = await ref.watch(getMatchingOrdersUseCaseProvider).call(userId);
  return switch (result) {
    Success(:final data) => data.length,
    Error() => 0,
  };
});

/// True when the signed-in carrier has packages matching their trips.
final homeHasMatchingPackagesProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  return await ref.watch(homeMatchingPackagesCountProvider.future) > 0;
});

/// How many of the carrier's trips are still upcoming (the badge on the
/// airplane icon). Zero for non-carriers.
final homeUpcomingTripsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  final isCarrier = ref.watch(isCarrierProvider);
  if (userId == null || !isCarrier) return 0;

  final result = await ref.watch(getMyTripsUseCaseProvider).call(userId);
  return switch (result) {
    Success(:final data) => data.where((t) => t.isUpcoming).length,
    Error() => 0,
  };
});

List<T> _bySortNo<T>(List<T> items, int Function(T) sortNo) {
  return [...items]..sort((a, b) => sortNo(a).compareTo(sortNo(b)));
}
