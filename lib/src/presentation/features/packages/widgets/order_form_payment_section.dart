import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/order_form_provider.dart';
import 'order_form_section_card.dart';

/// "Payment": the admin's payment methods, one selected. The Ionic form
/// hard-coded `payment = 1` (cash on delivery) with its chooser commented
/// out; the list is shown here so the default is visible and changeable.
class OrderFormPaymentSection extends ConsumerWidget {
  const OrderFormPaymentSection({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  final int selectedId;
  final ValueChanged<PaymentMethod> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(orderFormPaymentMethodsProvider);
    return OrderFormSectionCard(
      icon: Icons.payments_outlined,
      title: context.l10n.pkwPayment,
      subtitle: context.l10n.pkwPaymentSubtitle,
      child: switch (methods) {
        AsyncData(:final value) when value.isNotEmpty => Column(
          children: [
            for (final method in value)
              _PaymentRow(
                method: method,
                selected: method.id == selectedId,
                onTap: () => onSelect(method),
              ),
          ],
        ),
        AsyncData() => const _PaymentRow.fallback(),
        AsyncError() => Row(
          children: [
            const Expanded(child: _PaymentRow.fallback()),
            TextButton(
              onPressed: () => ref.invalidate(orderFormPaymentMethodsProvider),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  /// Shown when the list is unavailable: the hard-coded Ionic default.
  const _PaymentRow.fallback() : method = null, selected = true, onTap = null;

  final PaymentMethod? method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = method?.name ?? context.l10n.pkwCashOnDelivery;
    final isCash = method?.isCash ?? true;
    final radius = BorderRadius.circular(context.dimensions.radius.medium);
    return Padding(
      padding: EdgeInsets.only(bottom: context.dimensions.space.s8),
      child: Material(
        color: selected
            ? context.color.primary.tint
            : context.color.background.canvas,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.dimensions.space.s12,
              vertical: context.dimensions.space.s12,
            ),
            child: Row(
              children: [
                Icon(
                  isCash ? Icons.payments_outlined : Icons.credit_card_outlined,
                  size: context.dimensions.size.iconMedium,
                  color: context.color.text.muted,
                ),
                Gap(context.dimensions.space.s12),
                Expanded(child: BodySmallText(name)),
                if (method != null) ...[
                  LabelText.muted(method!.currency),
                  Gap(context.dimensions.space.s8),
                ],
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: context.dimensions.size.iconLarge,
                  color: selected
                      ? context.color.primary.strong
                      : context.color.text.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
