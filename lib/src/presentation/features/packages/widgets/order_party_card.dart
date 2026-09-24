import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import 'order_overview_card.dart';
import '../../../core/extensions/place_names_extension.dart';

/// Strips the stray quotes some legacy rows carry around names and phones
/// (the Ionic `removeIfContains`).
String cleanPartyText(String value) => value.replaceAll(RegExp('["\']'), '');

/// "Sender Details" / "Receiver Details": name and phone (hidden from
/// other carriers while the order is unassigned), address, notes and a
/// directions link.
class OrderPartyCard extends StatelessWidget {
  const OrderPartyCard({
    super.key,
    required this.title,
    required this.icon,
    required this.name,
    required this.phone,
    required this.address,
    required this.showContact,
    required this.onCall,
    required this.onDirections,
  });

  final String title;
  final IconData icon;
  final String name;
  final String phone;
  final OrderAddress address;
  final bool showContact;
  final ValueChanged<String> onCall;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cleanName = cleanPartyText(name);
    final cleanPhone = cleanPartyText(phone);
    final lang = context.languageCode;
    final city = (address.cityFor(lang) ?? '').trim();
    final country = address.countryFor(lang);
    final place = city.isEmpty ? country : '$city, $country';
    final summary = address.summaryFor(lang);
    final notes = (address.notes ?? '').trim();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.color.text.muted),
              Gap(context.dimensions.space.s8),
              Expanded(child: HeadingLevel3Text(title)),
            ],
          ),
          Gap(context.dimensions.space.s12),
          if (showContact) ...[
            if (cleanName.isNotEmpty)
              OrderDetailLine(label: l10n.pkwName, value: cleanName),
            if (cleanPhone.isNotEmpty)
              OrderDetailLine(
                label: l10n.pkwPhone,
                value: cleanPhone,
                icon: Icons.call_outlined,
                onTap: () => onCall(cleanPhone),
              ),
          ],
          OrderDetailLine(label: l10n.pkwAddress, value: place),
          if (summary != place && summary.isNotEmpty)
            OrderDetailLine(label: l10n.pkwDetails, value: summary),
          if (notes.isNotEmpty)
            OrderDetailLine(label: l10n.pkwNotes, value: notes),
          OrderDetailLine(
            label: l10n.pkwLocation,
            value: l10n.pkwGetDirections,
            icon: Icons.directions_outlined,
            onTap: onDirections,
          ),
        ],
      ),
    );
  }
}
