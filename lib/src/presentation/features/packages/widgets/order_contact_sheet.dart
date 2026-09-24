import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';

/// Digits only, without the `00` international prefix, as wa.me expects.
String whatsAppNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  return digits;
}

/// "Contact Options": call by phone or message on WhatsApp.
Future<void> showOrderContactSheet(
  BuildContext context, {
  required String phone,
  required String senderName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        OrderContactSheet(phone: phone, senderName: senderName),
  );
}

class OrderContactSheet extends StatelessWidget {
  const OrderContactSheet({
    super.key,
    required this.phone,
    required this.senderName,
  });

  final String phone;
  final String senderName;

  Future<void> _open(BuildContext context, Uri uri) async {
    Navigator.of(context).pop();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = Uri.encodeComponent(
      l10n.pkwWhatsAppGreeting(senderName, l10n.appTitle),
    );
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
              child: Column(
                children: [
                  HeadingLevel3Text(l10n.pkwContactOptions),
                  BodySmallText.muted(phone, textDirection: TextDirection.ltr),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.call_outlined),
              title: Text(l10n.pkwCallByPhone),
              onTap: () => _open(context, Uri(scheme: 'tel', path: phone)),
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: Text(l10n.pkwMessageByWhatsApp),
              onTap: () => _open(
                context,
                Uri.parse(
                  'https://wa.me/${whatsAppNumber(phone)}?text=$message',
                ),
              ),
            ),
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

/// Google Maps directions to a point.
Future<void> openDirections(double lat, double lng) {
  return launchUrl(
    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
    mode: LaunchMode.externalApplication,
  );
}
