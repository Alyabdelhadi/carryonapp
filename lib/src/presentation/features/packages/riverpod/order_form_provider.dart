import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../domain/failures/business_failure.dart';

/// Reference data the order form (`pview` / `pview1`) needs: package
/// categories, countries for the phone-code picker and payment methods.
/// Written by hand (no code generation) with the Riverpod 3 builders.

final orderFormCategoriesProvider =
    FutureProvider.autoDispose<List<ParcelCategory>>((ref) async {
      final result = await ref.watch(getParcelCategoriesUseCaseProvider).call();
      return switch (result) {
        Success(:final data) => data,
        Error(:final error) => throw error,
      };
    });

final orderFormCountriesProvider = FutureProvider.autoDispose<List<Country>>((
  ref,
) async {
  final result = await ref.watch(getCountriesUseCaseProvider).call();
  return switch (result) {
    Success(:final data) => data,
    Error(:final error) => throw error,
  };
});

final orderFormPaymentMethodsProvider =
    FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
      final result = await ref.watch(getPaymentMethodsUseCaseProvider).call();
      return switch (result) {
        Success(:final data) => data,
        Error(:final error) => throw error,
      };
    });

/// The create / update write. The state carries the loading flag the
/// submit button renders; the method also returns the outcome so the page
/// can navigate on success.
class OrderFormSubmit extends Notifier<AsyncValue<ParcelOrder?>> {
  @override
  AsyncValue<ParcelOrder?> build() => const AsyncValue.data(null);

  Future<Result<ParcelOrder, BusinessFailure>?> submit(
    ParcelOrderDraft draft,
  ) async {
    if (state.isLoading) return null;
    state = const AsyncValue.loading();

    final result = await ref.read(saveParcelOrderUseCaseProvider).call(draft);
    if (!ref.mounted) return result;

    state = switch (result) {
      Success(:final data) => AsyncValue.data(data),
      Error(:final error) => AsyncValue.error(error, StackTrace.current),
    };
    return result;
  }
}

final orderFormSubmitProvider =
    NotifierProvider.autoDispose<OrderFormSubmit, AsyncValue<ParcelOrder?>>(
      OrderFormSubmit.new,
    );
