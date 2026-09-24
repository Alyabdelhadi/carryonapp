import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';

/// The signed-in user's address book. Invalidate after a save or delete.
final myAddressesProvider = FutureProvider.autoDispose
    .family<List<Address>, int>((ref, userId) async {
      final result = await ref.watch(getAddressesUseCaseProvider).call(userId);
      return switch (result) {
        Success(:final data) => data,
        Error(:final error) => throw error,
      };
    });
