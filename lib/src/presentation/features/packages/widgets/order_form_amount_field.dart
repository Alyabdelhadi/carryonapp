import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';
import 'order_form_choice_chip.dart';

/// A labelled numeric field with a unit affix and a row of quick-pick
/// amounts underneath. Tapping a chip writes its number into the field;
/// the chip whose number matches the field reads as selected.
class OrderFormAmountField extends StatelessWidget {
  const OrderFormAmountField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.quickPicks,
    this.prefixText,
    this.suffixText,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  /// Plain numbers, e.g. `['0.5', '1', '2']`; their chips read with the
  /// same [prefixText] / [suffixText] as the field.
  final List<String> quickPicks;
  final String? prefixText;
  final String? suffixText;
  final TextInputAction textInputAction;

  /// Parses a field or chip text; null when it is not a number.
  static double? parse(String text) => double.tryParse(text.trim());

  /// A number as the form stores it: "2", "0.5", "2.5" (no trailing zeros).
  static String format(double amount) {
    if (amount == amount.roundToDouble()) return amount.toStringAsFixed(0);
    var text = amount.toStringAsFixed(3);
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  String _chipLabel(String option) =>
      '${prefixText ?? ''}$option'
      '${suffixText == null ? '' : ' $suffixText'}';

  void _pick(String option) {
    controller.value = TextEditingValue(
      text: option,
      selection: TextSelection.collapsed(offset: option.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabelText(label),
        Gap(context.dimensions.space.s8),
        // Amounts read left-to-right in every locale: the prefix ("$") stays
        // in front of the digits and the unit ("kg") after them.
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: textInputAction,
            textAlign: TextAlign.start,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
            ],
            decoration: InputDecoration(
              hintText: hint,
              prefixText: prefixText == null ? null : '$prefixText ',
              suffixText: suffixText,
            ),
          ),
        ),
        Gap(context.dimensions.space.s8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final current = parse(value.text);
            return Wrap(
              spacing: context.dimensions.space.s8,
              runSpacing: context.dimensions.space.s8,
              children: [
                for (final option in quickPicks)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: OrderFormChoiceChip(
                      label: _chipLabel(option),
                      selected: current != null && current == parse(option),
                      onTap: () => _pick(option),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
