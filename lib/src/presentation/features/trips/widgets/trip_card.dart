import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/extensions/localized_labels.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/text/typography.dart';
import '../../../core/extensions/place_names_extension.dart';

/// One route in the carrier's trip list: the destination's city image as a
/// banner, "From ✈ To", the frequency and (for one-time trips) the date.
/// Tapping opens the trip for editing, as in the Ionic list.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = context.languageCode;
    final countries = [
      trip.from.countryNameFor(lang),
      trip.to.countryNameFor(lang),
    ].whereType<String>().where((c) => c.trim().isNotEmpty).toList();

    return SectionCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DestinationBanner(
            image: trip.to.image ?? trip.destinationImage,
            frequency: trip.frequency,
          ),
          Padding(
            padding: EdgeInsets.all(context.dimensions.space.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: HeadingLevel3Text(
                        trip.from.nameFor(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.dimensions.space.s12,
                      ),
                      child: Icon(
                        Icons.flight_takeoff_rounded,
                        size: context.dimensions.size.iconMedium,
                        color: context.color.primary.strong,
                      ),
                    ),
                    Expanded(
                      child: HeadingLevel3Text(
                        trip.to.nameFor(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                if (countries.isNotEmpty) ...[
                  Gap(context.dimensions.space.s4),
                  _CountriesLine(countries: countries),
                ],
                Gap(context.dimensions.space.s12),
                Row(
                  children: [
                    if (trip.date != null)
                      TagChip(
                        label: Formatters.monthDayYear(trip.date),
                        icon: Icons.event_rounded,
                        foreground: trip.isUpcoming
                            ? context.color.accent.sky
                            : context.color.text.muted,
                        background: trip.isUpcoming
                            ? context.color.accent.skyTint
                            : context.color.border.subtle,
                      )
                    else
                      TagChip(
                        label: context.l10n.tripFrequentRoute,
                        icon: Icons.repeat_rounded,
                        foreground: context.color.accent.eco,
                        background: context.color.accent.ecoTint,
                      ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.color.text.muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The destination image (or a tinted placeholder) with a "One-time
/// trip" pill (recurring trips show none) and an airplane badge, echoing
/// the Ionic card's background photo.
class _DestinationBanner extends StatelessWidget {
  const _DestinationBanner({required this.image, required this.frequency});

  final String? image;
  final TripFrequency frequency;

  @override
  Widget build(BuildContext context) {
    final height = context.dimensions.size.iconHero;
    final hasImage = image != null && image!.trim().isNotEmpty;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            AppNetworkImage(
              file: image,
              kind: UploadKind.cities,
              height: height,
              fallbackIcon: Icons.flight_takeoff_rounded,
            )
          else
            ColoredBox(
              color: context.color.primary.tint,
              child: Icon(
                Icons.flight_takeoff_rounded,
                size: context.dimensions.size.iconDisplay,
                color: context.color.primary.strong,
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  context.color.background.scrim.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          if (!frequency.isRecurring)
            PositionedDirectional(
              top: context.dimensions.space.s12,
              end: context.dimensions.space.s12,
              child: TagChip(
                label: frequency.label(context.l10n),
                icon: Icons.looks_one_outlined,
                foreground: context.color.text.strong,
                background: context.color.background.surface,
              ),
            ),
          PositionedDirectional(
            start: context.dimensions.space.s16,
            bottom: context.dimensions.space.s12,
            child: Container(
              padding: EdgeInsets.all(context.dimensions.space.s8),
              decoration: BoxDecoration(
                color: context.color.background.surface,
                shape: BoxShape.circle,
                boxShadow: context.dimensions.elevation.card,
              ),
              child: Icon(
                Icons.airplanemode_active_rounded,
                size: context.dimensions.size.iconMedium,
                color: context.color.primary.strong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Lebanon → United Arab Emirates" under the city names. Built from
/// widgets rather than a joined string so the arrow points along the
/// reading direction (it mirrors in RTL) whatever script the names use.
class _CountriesLine extends StatelessWidget {
  const _CountriesLine({required this.countries});

  final List<String> countries;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, country) in countries.indexed) ...[
          if (index > 0)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.dimensions.space.s8,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: context.dimensions.size.iconSmall,
                color: context.color.text.muted,
              ),
            ),
          Flexible(
            child: BodySmallText.muted(
              country,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
