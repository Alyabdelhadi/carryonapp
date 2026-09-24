import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/theme.dart';

/// "I agree to the Terms & Conditions" with the terms as a tappable link
/// that opens the CarryOn site, as in the original form.
class TermsCheckbox extends StatefulWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.agreeLabel,
    required this.termsLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String agreeLabel;
  final String termsLabel;

  @override
  State<TermsCheckbox> createState() => _TermsCheckboxState();
}

class _TermsCheckboxState extends State<TermsCheckbox> {
  static final Uri _termsUri = Uri.parse(
    'https://carryonapp.com/terms-conditions',
  );

  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = _openTerms;

  @override
  void dispose() {
    _termsTap.dispose();
    super.dispose();
  }

  Future<void> _openTerms() async {
    await launchUrl(_termsUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = widget.onChanged;
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged(!widget.value),
      borderRadius: BorderRadius.circular(context.dimensions.radius.small),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.dimensions.space.s4),
        child: Row(
          children: [
            Checkbox(
              value: widget.value,
              onChanged: onChanged == null
                  ? null
                  : (v) => onChanged(v ?? false),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '${widget.agreeLabel} ',
                  children: [
                    TextSpan(
                      text: widget.termsLabel,
                      style: TextStyle(
                        color: context.color.primary.strong,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: _termsTap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
