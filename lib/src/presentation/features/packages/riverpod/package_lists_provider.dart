import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';

/// Orders the user posted ("My Packages" segment).
final myCreatedOrdersProvider = FutureProvider.autoDispose
    .family<List<ParcelOrder>, int>((ref, userId) async {
      final result = await ref
          .watch(getMyCreatedOrdersUseCaseProvider)
          .call(userId);
      return switch (result) {
        Success(:final data) => data,
        Error(:final error) => throw error,
      };
    });

/// Orders the user accepted to carry ("Carried Packages" segment).
final myCarriedOrdersProvider = FutureProvider.autoDispose
    .family<List<ParcelOrder>, int>((ref, userId) async {
      final result = await ref
          .watch(getMyCarriedOrdersUseCaseProvider)
          .call(userId);
      return switch (result) {
        Success(:final data) => data,
        Error(:final error) => throw error,
      };
    });

/// Unassigned orders matching one of the carrier's trips.
final matchingOrdersProvider = FutureProvider.autoDispose
    .family<List<ParcelOrder>, int>((ref, carrierId) async {
      final result = await ref
          .watch(getMatchingOrdersUseCaseProvider)
          .call(carrierId);
      return switch (result) {
        Success(:final data) => data,
        Error(:final error) => throw error,
      };
    });

/// Drops every cached package list so the Packages tab and the matching
/// page refetch after an order changed.
void invalidatePackageLists(Ref ref) {
  ref
    ..invalidate(myCreatedOrdersProvider)
    ..invalidate(myCarriedOrdersProvider)
    ..invalidate(matchingOrdersProvider);
}
