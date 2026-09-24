import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../domain/failures/business_failure.dart';

/// The signed-in user's saved addresses, for the "Select from saved
/// address" dropdown of the picker (`paddress`).
final addressPickerSavedAddressesProvider = FutureProvider.autoDispose
    .family<List<Address>, int>((ref, userId) async {
      final result = await ref.watch(getAddressesUseCaseProvider).call(userId);
      return switch (result) {
        Success(:final data) => data,
        Error(:final error) => throw error,
      };
    });

/// Places autocomplete for the full-screen map search bar. Debounces the
/// keystrokes and drops results that arrive for an outdated query.
class AddressPickerSearch extends Notifier<AsyncValue<List<PlaceSuggestion>>> {
  static const _debounce = Duration(milliseconds: 350);

  Timer? _timer;
  int _requestId = 0;

  @override
  AsyncValue<List<PlaceSuggestion>> build() {
    ref.onDispose(() => _timer?.cancel());
    return const AsyncValue.data([]);
  }

  void search(String query) {
    _timer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clear();
      return;
    }
    _timer = Timer(_debounce, () => _run(trimmed));
  }

  void clear() {
    _timer?.cancel();
    _requestId++;
    state = const AsyncValue.data([]);
  }

  Future<void> _run(String query) async {
    final id = ++_requestId;
    state = const AsyncValue.loading();
    final result = await ref.read(searchPlacesUseCaseProvider).call(query);
    if (!ref.mounted || id != _requestId) return;
    state = switch (result) {
      Success(:final data) => AsyncValue.data(data),
      Error(:final error) => AsyncValue.error(error, StackTrace.current),
    };
  }

  /// Resolves a suggestion to its coordinates and city / country.
  Future<Result<PlaceInfo, BusinessFailure>> details(String placeId) {
    return ref.read(searchPlacesUseCaseProvider).details(placeId);
  }
}

final addressPickerSearchProvider =
    NotifierProvider.autoDispose<
      AddressPickerSearch,
      AsyncValue<List<PlaceSuggestion>>
    >(AddressPickerSearch.new);
