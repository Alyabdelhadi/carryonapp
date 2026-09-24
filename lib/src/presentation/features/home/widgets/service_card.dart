import 'package:flutter/material.dart';

import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';

/// One of the home actions (send, receive, carry): the admin's square
/// image with the service name centred underneath. Laid out three per
/// row by [ServiceGrid].
class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, required this.onTap});

  final AppService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = service.image;
    final dims = context.dimensions;
    return SectionCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: image != null && image.isNotEmpty
                ? AppNetworkImage(
                    file: image,
                    kind: UploadKind.services,
                    fallbackIcon: Icons.local_shipping_outlined,
                  )
                : ColoredBox(
                    color: context.color.primary.tint,
                    child: Icon(
                      Icons.local_shipping_outlined,
                      size: dims.size.iconDisplay,
                      color: context.color.primary.strong,
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dims.space.s8,
              vertical: dims.space.s8,
            ),
            child: LabelText(
              service.nameFor(Localizations.localeOf(context).languageCode),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The service tiles, three per row (one row for the three services).
class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key, required this.services, required this.onTap});

  final List<AppService> services;
  final ValueChanged<AppService> onTap;

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    final gap = context.dimensions.space.s12;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth - gap * (_columns - 1)) / _columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final service in services)
              SizedBox(
                width: tileWidth,
                child: ServiceCard(
                  service: service,
                  onTap: () => onTap(service),
                ),
              ),
          ],
        );
      },
    );
  }
}
