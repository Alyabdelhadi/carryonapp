import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/link_text.dart';
import 'order_form_section_card.dart';

/// Instructions for the carrier, and the terms acknowledgement line with
/// its link (`text.acc_term` + `text.term`).
class OrderFormNotesSection extends StatelessWidget {
  const OrderFormNotesSection({
    super.key,
    required this.notesController,
    required this.termsText,
    required this.termsLinkText,
    required this.onOpenTerms,
  });

  final TextEditingController notesController;
  final String termsText;
  final String termsLinkText;
  final VoidCallback onOpenTerms;

  @override
  Widget build(BuildContext context) {
    return OrderFormSectionCard(
      icon: Icons.sticky_note_2_outlined,
      title: context.l10n.pkwNotes,
      subtitle: context.l10n.optional,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: notesController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: context.l10n.pkwNotesHintCarrier,
              alignLabelWithHint: true,
            ),
          ),
          Gap(context.dimensions.space.s12),
          LinkText(
            text: '$termsText ',
            linkText: termsLinkText,
            onTap: onOpenTerms,
          ),
        ],
      ),
    );
  }
}
