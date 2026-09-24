import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/base/result.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/failure_view.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/login_required_view.dart';
import '../riverpod/order_actions_provider.dart';
import '../riverpod/package_lists_provider.dart';
import '../widgets/matching_filter_bar.dart';
import '../widgets/matching_package_tile.dart';
import '../../../core/extensions/place_names_extension.dart';

/// Carrier's matching packages (Ionic `list`): the orders whose route
/// matches one of the carrier's trips, with From / To filters.
class MatchingPackagesPage extends StatelessWidget {
  const MatchingPackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.pkgMatchingTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: context.l10n.close,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: const LoginRequired(child: _MatchingBody()),
    );
  }
}

class _MatchingBody extends ConsumerStatefulWidget {
  const _MatchingBody();

  @override
  ConsumerState<_MatchingBody> createState() => _MatchingBodyState();
}

class _MatchingBodyState extends ConsumerState<_MatchingBody> {
  String? _from;
  String? _to;

  String _fromKey(ParcelOrder o) => _place(o.sender);
  String _toKey(ParcelOrder o) => _place(o.receiver);

  String _place(OrderAddress a) {
    final lang = context.languageCode;
    final city = (a.cityFor(lang) ?? '').trim();
    if (city.isEmpty) return a.countryFor(lang);
    return context.l10n.pkgPlaceCityCountry(city, a.countryFor(lang));
  }

  List<String> _unique(Iterable<String> values) =>
      values.toSet().toList()..sort();

  /// A selection survives a refresh only while the list still offers it.
  String? _selected(String? value, Iterable<String> options) =>
      value != null && options.contains(value) ? value : null;

  bool _matches(String? value, Iterable<String> options, String key) {
    final selected = _selected(value, options);
    return selected == null || selected == key;
  }

  Future<void> _carry(ParcelOrder order, int userId) async {
    final l10n = context.l10n;
    final confirmed = await AppFeedback.confirm(
      context,
      title: l10n.pkgAcceptConfirmTitle,
      message: l10n.pkgAcceptConfirmMessage,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.pkgGoBack,
    );
    if (!confirmed || !mounted) return;

    final result = await ref
        .read(orderActionsProvider.notifier)
        .transition(
          action: ParcelOrderAction.accept,
          userId: userId,
          orderId: order.id,
        );
    if (!mounted) return;
    switch (result) {
      case Success():
        context.pushReplacementNamed(
          Routes.success.name,
          pathParameters: {'type': '${SuccessType.packageAccepted.code}'},
        );
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();
    final provider = matchingOrdersProvider(userId);
    final orders = ref.watch(provider);
    final busy = ref.watch(orderActionsProvider).isLoading;

    return Stack(
      children: [
        switch (orders) {
          AsyncData(:final value) when value.isEmpty => EmptyState(
            icon: Icons.search_rounded,
            title: context.l10n.pkgMatchingEmptyTitle,
            message: context.l10n.pkgAddTripMatchMessage,
            actionLabel: context.l10n.pkgAddNewTrip,
            onAction: () => context.pushNamed(Routes.tripForm.name),
          ),
          AsyncData(:final value) => _MatchingList(
            orders: value,
            fromOptions: _unique(value.map(_fromKey)),
            toOptions: _unique(value.map(_toKey)),
            selectedFrom: _selected(_from, value.map(_fromKey)),
            selectedTo: _selected(_to, value.map(_toKey)),
            onFromChanged: (v) => setState(() => _from = v),
            onToChanged: (v) => setState(() => _to = v),
            filtered: value
                .where((o) => _matches(_from, value.map(_fromKey), _fromKey(o)))
                .where((o) => _matches(_to, value.map(_toKey), _toKey(o)))
                .toList(),
            onRefresh: () => ref.refresh(provider.future),
            onCarry: (order) => _carry(order, userId),
          ),
          AsyncError(:final error) => FailureView(
            error: error,
            onRetry: () => ref.invalidate(provider),
          ),
          _ => const Center(child: LoadingIndicator()),
        },
        if (busy)
          ColoredBox(
            color: context.color.background.scrim,
            child: const Center(child: LoadingIndicator()),
          ),
      ],
    );
  }
}

class _MatchingList extends StatelessWidget {
  const _MatchingList({
    required this.orders,
    required this.filtered,
    required this.fromOptions,
    required this.toOptions,
    required this.selectedFrom,
    required this.selectedTo,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onRefresh,
    required this.onCarry,
  });

  final List<ParcelOrder> orders;
  final List<ParcelOrder> filtered;
  final List<String> fromOptions;
  final List<String> toOptions;
  final String? selectedFrom;
  final String? selectedTo;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;
  final Future<void> Function() onRefresh;
  final ValueChanged<ParcelOrder> onCarry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MatchingFilterBar(
          fromOptions: fromOptions,
          toOptions: toOptions,
          selectedFrom: selectedFrom,
          selectedTo: selectedTo,
          onFromChanged: onFromChanged,
          onToChanged: onToChanged,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: context.l10n.pkgMatchingFilterEmptyTitle,
                    message: context.l10n.pkgMatchingFilterEmptyMessage,
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      context.dimensions.space.s16,
                      context.dimensions.space.s8,
                      context.dimensions.space.s16,
                      context.dimensions.space.s32,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return MatchingPackageTile(
                        order: order,
                        onCarry: () => onCarry(order),
                        onTap: () => context.pushNamed(
                          Routes.orderDetail.name,
                          pathParameters: {'id': '${order.id}'},
                          extra: order,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
