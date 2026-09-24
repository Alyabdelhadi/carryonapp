import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../core/gen/l10n/app_localizations.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/text/typography.dart';

/// "Request a payout": amount, method and where to send it. Resolves with
/// the draft, or null when dismissed.
Future<PayoutDraft?> showPayoutRequestSheet(
  BuildContext context, {
  required WalletOverview overview,
}) {
  return showModalBottomSheet<PayoutDraft>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PayoutRequestSheet(overview: overview),
  );
}

/// The input fields a payout method needs, keyed by the detail name sent
/// to the backend.
List<(String key, String Function(AppLocalizations) label, TextInputType type)>
_fieldsFor(String method) => switch (method) {
  'bank_transfer' => [
    ('account_name', (l) => l.walFieldAccountName, TextInputType.name),
    ('iban', (l) => l.walFieldIban, TextInputType.text),
    ('bank_name', (l) => l.walFieldBankName, TextInputType.text),
  ],
  'paypal' => [
    ('full_name', (l) => l.walFieldFullName, TextInputType.name),
    ('email', (l) => l.walFieldEmail, TextInputType.emailAddress),
  ],
  'omt' || 'whish' => [
    ('full_name', (l) => l.walFieldFullName, TextInputType.name),
    ('phone', (l) => l.walFieldPhone, TextInputType.phone),
  ],
  _ => [
    ('full_name', (l) => l.walFieldFullName, TextInputType.name),
    ('details', (l) => l.walFieldDetails, TextInputType.text),
  ],
};

class PayoutRequestSheet extends StatefulWidget {
  const PayoutRequestSheet({super.key, required this.overview});

  final WalletOverview overview;

  @override
  State<PayoutRequestSheet> createState() => _PayoutRequestSheetState();
}

class _PayoutRequestSheetState extends State<PayoutRequestSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: Formatters.westernDigits(
      widget.overview.summary.available.toStringAsFixed(2),
    ),
  );
  final Map<String, TextEditingController> _details = {};
  String? _method;

  @override
  void initState() {
    super.initState();
    final methods = widget.overview.rules.payoutMethods;
    if (methods.isNotEmpty) _method = methods.first.code;
  }

  @override
  void dispose() {
    _amount.dispose();
    for (final c in _details.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key) =>
      _details.putIfAbsent(key, TextEditingController.new);

  void _submit() {
    final l10n = context.l10n;
    final method = _method;
    if (method == null) {
      AppFeedback.toast(context, l10n.walMethodRequired);
      return;
    }
    final amount = double.tryParse(
      Formatters.westernDigits(_amount.text.trim()).replaceAll(',', '.'),
    );
    final s = widget.overview.summary;
    final minimum = widget.overview.rules.payoutMinimum;
    if (amount == null ||
        amount <= 0 ||
        amount > s.available ||
        amount < minimum) {
      AppFeedback.toast(context, l10n.walAmountInvalid);
      return;
    }
    final details = <String, String>{};
    for (final (key, _, _) in _fieldsFor(method)) {
      final value = _controller(key).text.trim();
      if (value.isEmpty) {
        AppFeedback.toast(context, l10n.walDetailsRequired);
        return;
      }
      details[key] = value;
    }
    Navigator.of(context)
        .pop(PayoutDraft(amount: amount, method: method, details: details));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final space = context.dimensions.space;
    final s = widget.overview.summary;
    final methods = widget.overview.rules.payoutMethods;
    final fields = _method == null ? const [] : _fieldsFor(_method!);

    return Padding(
      padding: EdgeInsets.only(
        left: space.s24,
        right: space.s24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + space.s24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeadingLevel3Text(l10n.walSheetTitle),
            Gap(space.s4),
            BodySmallText.muted(
              l10n.walMinimumHint(
                Formatters.money(
                  widget.overview.rules.payoutMinimum,
                  s.currency,
                ),
              ),
            ),
            Gap(space.s16),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l10n.walAmount(s.currency),
                suffixIcon: TextButton(
                  onPressed: () => _amount.text = Formatters.westernDigits(
                    s.available.toStringAsFixed(2),
                  ),
                  child: Text(l10n.walAmountAll),
                ),
              ),
            ),
            Gap(space.s16),
            BodySmallText.muted(l10n.walMethod),
            Gap(space.s8),
            Wrap(
              spacing: space.s8,
              runSpacing: space.s8,
              children: [
                for (final m in methods)
                  ChoiceChip(
                    label: Text(m.name),
                    selected: _method == m.code,
                    onSelected: (_) => setState(() => _method = m.code),
                  ),
              ],
            ),
            Gap(space.s8),
            for (final (key, label, type) in fields)
              Padding(
                padding: EdgeInsets.only(top: space.s8),
                child: TextField(
                  controller: _controller(key),
                  keyboardType: type,
                  textDirection:
                      type == TextInputType.phone ||
                          type == TextInputType.emailAddress ||
                          key == 'iban'
                      ? TextDirection.ltr
                      : null,
                  decoration: InputDecoration(labelText: label(l10n)),
                ),
              ),
            Gap(space.s24),
            FilledButton(onPressed: _submit, child: Text(l10n.walSubmit)),
          ],
        ),
      ),
    );
  }
}
