import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';

/// The country list behind the phone code picker. A failed fetch surfaces
/// as `AsyncError` carrying the `BusinessFailure`.
final countriesProvider = FutureProvider.autoDispose<List<Country>>((
  ref,
) async {
  final result = await ref.read(getCountriesUseCaseProvider).call();
  return switch (result) {
    Success(:final data) => data,
    Error(:final error) => throw error,
  };
});
