import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';

/// The "Enter ... / Add ..." pair the Ionic form shows under a chip row
/// when the "Other" option is active: a text field and a confirm button.
class OrderFormCustomInput extends StatelessWidget {
  const OrderFormCustomInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.buttonLabel,
    required this.onAdd,
    this.keyboardType = TextInputType.text,
    this.textDirection,
  });

  final TextEditingController controller;
  final String hint;
  final String buttonLabel;
  final VoidCallback onAdd;
  final TextInputType keyboardType;

  /// Force left-to-right for numeric input (amounts) in an RTL locale.
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.dimensions.space.s12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: TextInputAction.done,
              textDirection: textDirection,
              textAlign: TextAlign.start,
              onSubmitted: (_) => onAdd(),
              decoration: InputDecoration(hintText: hint),
            ),
          ),
          Gap(context.dimensions.space.s8),
          SizedBox(
            height: context.dimensions.size.control,
            child: FilledButton(onPressed: onAdd, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }
}
