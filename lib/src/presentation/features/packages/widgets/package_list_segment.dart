import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/entities.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/failure_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import 'package_list_tile.dart';

/// The body of one Packages segment: the async list with pull-to-refresh,
/// the failure view and the segment's empty state.
class PackageListSegment extends ConsumerWidget {
  const PackageListSegment({
    super.key,
    required this.provider,
    required this.emptyTitle,
    this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final FutureProvider<List<ParcelOrder>> provider;
  final String emptyTitle;
  final String? emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(provider);
    return switch (orders) {
      AsyncData(:final value) when value.isEmpty => RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: EmptyState(
                icon: Icons.search_rounded,
                title: emptyTitle,
                message: emptyMessage,
                actionLabel: emptyActionLabel,
                onAction: onEmptyAction,
              ),
            ),
          ),
        ),
      ),
      AsyncData(:final value) => RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            context.dimensions.space.s16,
            context.dimensions.space.s8,
            context.dimensions.space.s16,
            context.dimensions.space.s32 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: value.length,
          itemBuilder: (context, index) {
            final order = value[index];
            return PackageListTile(
              order: order,
              onTap: () => context.pushNamed(
                Routes.orderDetail.name,
                pathParameters: {'id': '${order.id}'},
                extra: order,
              ),
            );
          },
        ),
      ),
      AsyncError(:final error) => FailureView(
        error: error,
        onRetry: () => ref.invalidate(provider),
      ),
      _ => const Center(child: LoadingIndicator()),
    };
  }
}
