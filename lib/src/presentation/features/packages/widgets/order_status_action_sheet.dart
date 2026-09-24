import 'package:flutter/material.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../core/gen/l10n/app_localizations.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/order_actions_provider.dart';

/// The next carrier step for a status, or null when there is none. Pass
/// `context.l10n` so the label is localized; without it the label is the
/// English text (kept only so existing call sites keep compiling).
({ParcelOrderAction action, String label, IconData icon})? nextCarrierStep(
  ParcelOrderStatus status, [
  AppLocalizations? l10n,
]) => switch (status) {
  .assigned => (
    action: ParcelOrderAction.pickup,
    label: l10n?.pkwActionPickup ?? 'Pickup Package',
    icon: Icons.inventory_2_outlined,
  ),
  .picked => (
    action: ParcelOrderAction.transit,
    label: l10n?.pkwActionTransit ?? 'Transit',
    icon: Icons.flight_takeoff_rounded,
  ),
  .transit => (
    action: ParcelOrderAction.deliver,
    label: l10n?.pkwActionDeliver ?? 'Package Delivered',
    icon: Icons.check_circle_outline_rounded,
  ),
  _ => null,
};

/// "Change Order Status": the carrier's next step. Resolves with the
/// chosen action, or null when dismissed.
Future<ParcelOrderAction?> showOrderStatusActionSheet(
  BuildContext context, {
  required ParcelOrderStatus status,
}) {
  return showModalBottomSheet<ParcelOrderAction>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) => OrderStatusActionSheet(status: status),
  );
}

class OrderStatusActionSheet extends StatelessWidget {
  const OrderStatusActionSheet({super.key, required this.status});

  final ParcelOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final step = nextCarrierStep(status, l10n);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: context.dimensions.space.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.dimensions.space.s24,
                vertical: context.dimensions.space.s8,
              ),
              child: HeadingLevel3Text(l10n.pkwChangeOrderStatus),
            ),
            if (step != null)
              ListTile(
                leading: Icon(step.icon),
                title: Text(step.label),
                onTap: () => Navigator.of(context).pop(step.action),
              )
            else
              ListTile(title: BodySmallText.muted(l10n.pkwNothingToChange)),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: Text(l10n.cancel),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
