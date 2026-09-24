import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../../../core/extensions/place_names_extension.dart';

/// One saved address: a pin disc, the name and a one-line summary, with
/// edit and delete actions. Tapping the card edits, as does the pencil.
class AddressTile extends StatelessWidget {
  const AddressTile({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final summary = address.summaryFor(context.languageCode);

    return SectionCard(
      onTap: onEdit,
      padding: EdgeInsets.symmetric(
        horizontal: context.dimensions.space.s16,
        vertical: context.dimensions.space.s12,
      ),
      child: Row(
        children: [
          Container(
            width: context.dimensions.size.touch,
            height: context.dimensions.size.touch,
            decoration: BoxDecoration(
              color: context.color.primary.tint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: context.color.primary.strong,
              size: context.dimensions.size.iconLarge,
            ),
          ),
          Gap(context.dimensions.space.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabelText(
                  address.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (summary.isNotEmpty) ...[
                  Gap(context.dimensions.space.s2),
                  BodySmallText.muted(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: context.l10n.edit,
            icon: Icon(
              Icons.edit_outlined,
              color: context.color.text.muted,
              size: context.dimensions.size.iconMedium,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: context.l10n.delete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: context.color.status.danger,
              size: context.dimensions.size.iconMedium,
            ),
          ),
        ],
      ),
    );
  }
}
