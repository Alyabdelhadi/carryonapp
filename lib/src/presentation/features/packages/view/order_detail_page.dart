import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/base/result.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/router/route_args.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/login_required_view.dart';
import '../riverpod/order_actions_provider.dart';
import '../widgets/order_action_bar.dart';
import '../widgets/order_carrier_card.dart';
import '../widgets/order_contact_sheet.dart';
import '../widgets/order_environmental_impact_card.dart';
import '../widgets/order_extend_date_card.dart';
import '../widgets/order_overview_card.dart';
import '../widgets/order_party_card.dart';
import '../widgets/order_payment_card.dart';
import '../widgets/order_status_action_sheet.dart';
import '../widgets/order_status_timeline.dart';
import '../widgets/rate_carrier_sheet.dart';

/// "Review Package" (Ionic `order-detail`): status timeline, package,
/// carrier, sender and receiver details, environmental impact and every
/// action the creator or the carrier can take at the current status.
///
/// The order arrives as the route extra; there is no fetch-by-id endpoint,
/// so a missing extra renders an explanatory empty state.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId, this.order});

  final int orderId;
  final ParcelOrder? order;

  @override
  Widget build(BuildContext context) {
    final order = this.order;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.pkgDetailTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: context.l10n.close,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: order == null
          ? EmptyState(
              icon: Icons.inventory_2_outlined,
              title: context.l10n.pkgDetailNotLoaded(orderId),
              message: context.l10n.pkgDetailNotLoadedMessage,
              actionLabel: context.l10n.pkgGoToPackages,
              onAction: () => context.goNamed(Routes.packages.name),
            )
          : LoginRequired(child: _OrderDetailBody(initial: order)),
    );
  }
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  const _OrderDetailBody({required this.initial});

  final ParcelOrder initial;

  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  late ParcelOrder _order = widget.initial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  /// The Ionic page marked every opened order as read for the signed-in
  /// user; only carriers browsing matches need it here.
  void _markRead() {
    if (!mounted) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _order.isCreatedBy(userId)) return;
    if (_order.isRead ?? false) return;
    // ignore: unawaited_futures
    ref
        .read(orderActionsProvider.notifier)
        .markRead(carrierId: userId, orderId: _order.id);
  }

  // ------------------------------------------------------------ actions

  Future<void> _transition(
    ParcelOrderAction action, {
    required int userId,
    String? successToast,
    bool popAfter = false,
    SuccessType? successScreen,
  }) async {
    final result = await ref
        .read(orderActionsProvider.notifier)
        .transition(action: action, userId: userId, orderId: _order.id);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() => _order = data);
        if (successToast != null) AppFeedback.toast(context, successToast);
        if (successScreen != null) {
          context.pushReplacementNamed(
            Routes.success.name,
            pathParameters: {'type': '${successScreen.code}'},
          );
        } else if (popAfter) {
          context.pop();
        }
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  Future<void> _accept(int userId) async {
    final l10n = context.l10n;
    final ok = await AppFeedback.confirm(
      context,
      title: l10n.pkgAcceptConfirmTitle,
      message: l10n.pkgAcceptConfirmMessage,
      confirmLabel: l10n.yes,
    );
    if (!ok) return;
    await _transition(
      ParcelOrderAction.accept,
      userId: userId,
      successScreen: SuccessType.packageAccepted,
    );
  }

  Future<void> _cancel(int userId) async {
    final l10n = context.l10n;
    final ok = await AppFeedback.confirm(
      context,
      title: l10n.areYouSure,
      message: l10n.pkgCancelConfirmMessage,
      confirmLabel: l10n.yes,
      destructive: true,
    );
    if (!ok) return;
    await _transition(
      ParcelOrderAction.cancel,
      userId: userId,
      successToast: l10n.pkgCancelledToast,
      popAfter: true,
    );
  }

  /// Creator unassigns the carrier, or the carrier drops the package. The
  /// backend unassigns by carrier id in both cases.
  Future<void> _drop({required bool byCreator}) async {
    final carrierId = _order.carrierId;
    if (carrierId == null) return;
    final l10n = context.l10n;
    final ok = await AppFeedback.confirm(
      context,
      title: l10n.pkgDropConfirmTitle,
      message: l10n.pkgDropConfirmMessage,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.pkgGoBack,
      destructive: true,
    );
    if (!ok) return;
    await _transition(
      ParcelOrderAction.drop,
      userId: carrierId,
      successToast: byCreator ? l10n.pkgUnassignedToast : l10n.pkgDroppedToast,
      popAfter: true,
    );
  }

  Future<void> _changeStatus(int userId) async {
    if (_order.awaitingPayment) {
      AppFeedback.toast(context, context.l10n.payPickupBlocked);
      return;
    }
    final action = await showOrderStatusActionSheet(
      context,
      status: _order.status,
    );
    if (action == null || !mounted) return;
    await _transition(action, userId: userId);
  }

  /// The creator pays a card order through the Stripe sheet.
  Future<void> _pay(int userId) async {
    final l10n = context.l10n;
    final outcome = await ref
        .read(orderActionsProvider.notifier)
        .pay(
          userId: userId,
          orderId: _order.id,
          style: Theme.of(context).brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
        );
    if (!mounted) return;
    switch (outcome) {
      case PaymentCompleted(:final order):
        setState(() => _order = order);
        AppFeedback.toast(
          context,
          order.isPaid ? l10n.paySuccessToast : l10n.payProcessingToast,
        );
      case PaymentDismissed(:final order):
        if (order != null) setState(() => _order = order);
        AppFeedback.toast(context, l10n.payCancelledToast);
      case PaymentSheetError(:final message):
        AppFeedback.toast(context, message ?? l10n.payFailedNotice);
      case PaymentFailed(:final failure):
        AppFeedback.error(context, failure);
    }
  }

  Future<void> _extend(int userId) async {
    final l10n = context.l10n;
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2),
      helpText: l10n.pkgExtendDate,
    );
    if (picked == null || !mounted) return;
    final ok = await AppFeedback.confirm(
      context,
      title: l10n.areYouSure,
      message: l10n.pkgExtendConfirmMessage(Formatters.monthDayYear(picked)),
      confirmLabel: l10n.yes,
    );
    if (!ok || !mounted) return;

    final result = await ref
        .read(orderActionsProvider.notifier)
        .extend(userId: userId, orderId: _order.id, neededBefore: picked);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() => _order = data);
        AppFeedback.toast(context, l10n.pkgExtendedToast);
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  Future<void> _rate() async {
    final carrierId = _order.carrierId;
    if (carrierId == null) return;
    final rated = await showRateCarrierSheet(
      context,
      carrierId: carrierId,
      orderId: _order.id,
    );
    if (rated && mounted) setState(() {});
  }

  void _edit() {
    context.pushNamed(
      Routes.orderForm.name,
      extra: OrderFormArgs(
        flow: _order.type == 2 ? ParcelFlow.receive : ParcelFlow.send,
        order: _order,
      ),
    );
  }

  Future<void> _call(String phone) {
    final me = ref.read(currentUserProvider);
    return showOrderContactSheet(
      context,
      phone: phone,
      senderName: me?.name ?? '',
    );
  }

  /// The label of the carrier's next step, matching [nextCarrierStep].
  String _carrierStepLabel(ParcelOrderStatus status) => switch (status) {
    .assigned => context.l10n.pkgPickupPackage,
    .picked => context.l10n.pkgMarkTransit,
    _ => context.l10n.pkgMarkDelivered,
  };

  List<OrderAction> _actions(int userId) {
    final l10n = context.l10n;
    final isCreator = _order.isCreatedBy(userId);
    final isCarrier = _order.isCarriedBy(userId);
    return switch (_order.status) {
      .unassigned when !isCreator => [
        OrderAction(
          label: l10n.pkgCarryPackage,
          icon: Icons.flight_takeoff_rounded,
          onPressed: () => _accept(userId),
        ),
      ],
      .unassigned => [
        OrderAction(
          label: l10n.edit,
          icon: Icons.edit_outlined,
          secondary: true,
          onPressed: _edit,
        ),
        OrderAction(
          label: l10n.pkgCancelPackage,
          icon: Icons.cancel_outlined,
          destructive: true,
          onPressed: () => _cancel(userId),
        ),
      ],
      .assigned when isCreator && _order.canPayNow => [
        OrderAction(
          label: l10n.pkgUnassignShort,
          destructive: true,
          secondary: true,
          onPressed: () => _drop(byCreator: true),
        ),
        OrderAction(
          label: l10n.payNow,
          icon: Icons.credit_card_rounded,
          onPressed: () => _pay(userId),
        ),
      ],
      .assigned when isCreator => [
        OrderAction(
          label: l10n.pkgUnassignPackage,
          icon: Icons.person_remove_outlined,
          destructive: true,
          onPressed: () => _drop(byCreator: true),
        ),
      ],
      .assigned when isCarrier && _order.awaitingPayment => [
        OrderAction(
          label: l10n.pkgDropPackage,
          icon: Icons.remove_circle_outline,
          destructive: true,
          secondary: true,
          onPressed: () => _drop(byCreator: false),
        ),
        OrderAction(
          label: l10n.payAwaiting,
          icon: Icons.hourglass_top_rounded,
          onPressed: () => _changeStatus(userId),
        ),
      ],
      .assigned when isCarrier => [
        OrderAction(
          label: l10n.pkgDropPackage,
          icon: Icons.remove_circle_outline,
          destructive: true,
          secondary: true,
          onPressed: () => _drop(byCreator: false),
        ),
        OrderAction(
          label: l10n.pkgPickupPackage,
          icon: Icons.inventory_2_outlined,
          onPressed: () => _changeStatus(userId),
        ),
      ],
      .picked || .transit when isCarrier => [
        OrderAction(
          label: _carrierStepLabel(_order.status),
          icon: nextCarrierStep(_order.status)!.icon,
          onPressed: () => _changeStatus(userId),
        ),
      ],
      .expired when isCreator => [
        OrderAction(
          label: l10n.pkgExtendDate,
          icon: Icons.calendar_month_outlined,
          onPressed: () => _extend(userId),
        ),
      ],
      _ => const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();
    final busy = ref.watch(orderActionsProvider).isLoading;
    final rated = ref.watch(ratedOrderIdsProvider).contains(_order.id);
    final order = _order;
    final isCreator = order.isCreatedBy(userId);
    final isCarrier = order.isCarriedBy(userId);
    final showsContact = order.status != .unassigned || isCreator;
    final impact = EnvironmentalImpact.of(order);
    final gap = Gap(context.dimensions.space.s12);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.dimensions.space.s16,
                  context.dimensions.space.s8,
                  context.dimensions.space.s16,
                  context.dimensions.space.s32,
                ),
                children: [
                  OrderStatusTimeline(
                    order: order,
                    action: isCarrier && order.status != .delivered
                        ? OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () => _changeStatus(userId),
                            icon: const Icon(Icons.swap_horiz_rounded),
                            label: Text(context.l10n.pkgChangeStatus),
                          )
                        : null,
                  ),
                  if (order.status == .expired && isCreator) ...[
                    gap,
                    OrderExtendDateCard(onPickDate: () => _extend(userId)),
                  ],
                  gap,
                  OrderOverviewCard(order: order),
                  if (order.isOnlinePayment || isCreator) ...[
                    gap,
                    OrderPaymentCard(
                      order: order,
                      isCreator: isCreator,
                      isCarrier: isCarrier,
                      onPayNow: busy ? null : () => _pay(userId),
                    ),
                  ],
                  if (order.carrierPhone != null) ...[
                    gap,
                    OrderCarrierCard(
                      order: order,
                      canRate:
                          isCreator && order.status == .delivered && !rated,
                      onCall: _call,
                      onRate: _rate,
                    ),
                  ],
                  gap,
                  OrderPartyCard(
                    title: context.l10n.pkgSenderDetails,
                    icon: Icons.outbox_outlined,
                    name: order.senderName,
                    phone: order.senderPhone,
                    address: order.sender,
                    showContact: showsContact,
                    onCall: _call,
                    onDirections: () =>
                        openDirections(order.sender.lat, order.sender.lng),
                  ),
                  gap,
                  OrderPartyCard(
                    title: context.l10n.pkgReceiverDetails,
                    icon: Icons.move_to_inbox_outlined,
                    name: order.receiverName,
                    phone: order.receiverPhone,
                    address: order.receiver,
                    showContact: showsContact,
                    onCall: _call,
                    onDirections: () =>
                        openDirections(order.receiver.lat, order.receiver.lng),
                  ),
                  if (impact != null && impact.treesSaved > 0) ...[
                    gap,
                    OrderEnvironmentalImpactCard(impact: impact),
                  ],
                ],
              ),
            ),
            OrderActionBar(actions: _actions(userId), enabled: !busy),
          ],
        ),
        if (busy)
          ColoredBox(
            color: context.color.background.scrim,
            child: const Center(child: LoadingIndicator()),
          ),
      ],
    );
  }
}
