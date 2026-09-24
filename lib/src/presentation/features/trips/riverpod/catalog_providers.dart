import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/catalog.dart';

/// Every country the admin manages (~250 rows), for the route pickers.
final countriesProvider = FutureProvider.autoDispose<List<Country>>((
  ref,
) async {
  final result = await ref.watch(getCountriesUseCaseProvider).call();
  return switch (result) {
    Success(:final data) => data,
    Error(:final error) => throw error,
  };
});

/// The cities of one country, fetched once a country is chosen.
final citiesByCountryProvider = FutureProvider.autoDispose
    .family<List<City>, int>((ref, countryId) async {
      final result = await ref.watch(getCitiesUseCaseProvider).call(countryId);
      return switch (result) {
        Success(:final data) => data,
        Error(:final error) => throw error,
      };
    });
