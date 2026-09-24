import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';

/// The client-side estimate the Ionic page computed: great-circle distance
/// between sender and receiver, the CO2 a courier would have emitted for
/// that weight, and the tree equivalent.
class EnvironmentalImpact {
  const EnvironmentalImpact({
    required this.distanceKm,
    required this.weightKg,
    required this.co2SavedKg,
    required this.treesSaved,
  });

  final double distanceKm;
  final double weightKg;
  final double co2SavedKg;
  final double treesSaved;

  static const _co2PerKgKm = 0.0006;
  static const _kgCo2PerTree = 21;
  static const _earthRadiusKm = 6371;

  /// Null when the order lacks coordinates or a parsable weight.
  static EnvironmentalImpact? of(ParcelOrder order) {
    final s = order.sender;
    final r = order.receiver;
    if (s.lat == 0 && s.lng == 0) return null;
    if (r.lat == 0 && r.lng == 0) return null;
    final match = RegExp(r'[\d.]+').firstMatch(order.weight ?? '');
    final weight = double.tryParse(match?.group(0) ?? '') ?? 0;
    if (weight <= 0) return null;

    final distance = _haversine(s.lat, s.lng, r.lat, r.lng);
    final co2 = weight * distance * _co2PerKgKm;
    return EnvironmentalImpact(
      distanceKm: distance,
      weightKg: weight,
      co2SavedKg: co2,
      treesSaved: co2 / _kgCo2PerTree,
    );
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return _earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

/// "Environmental Impact": distance, CO2 and trees saved, in eco green.
class OrderEnvironmentalImpactCard extends StatelessWidget {
  const OrderEnvironmentalImpactCard({super.key, required this.impact});

  final EnvironmentalImpact impact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trees = Formatters.compact(impact.treesSaved);
    return SectionCard(
      color: context.color.accent.ecoTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, color: context.color.accent.ecoStrong),
              Gap(context.dimensions.space.s8),
              Expanded(child: HeadingLevel3Text(l10n.pkwEnvironmentalImpact)),
            ],
          ),
          Gap(context.dimensions.space.s16),
          Row(
            children: [
              Expanded(
                child: OrderImpactStat(
                  icon: Icons.route_outlined,
                  value: Formatters.distanceKm(
                    impact.distanceKm,
                    unit: l10n.kmUnit,
                  ),
                  label: l10n.pkwDistance,
                ),
              ),
              Expanded(
                child: OrderImpactStat(
                  icon: Icons.co2_rounded,
                  value: l10n.pkwKgAmount(
                    Formatters.compact(impact.co2SavedKg),
                  ),
                  label: l10n.pkwCo2Saved,
                ),
              ),
              Expanded(
                child: OrderImpactStat(
                  icon: Icons.park_outlined,
                  value: trees,
                  label: l10n.pkwTreesSaved,
                ),
              ),
            ],
          ),
          Gap(context.dimensions.space.s16),
          Container(
            padding: EdgeInsets.all(context.dimensions.space.s12),
            decoration: BoxDecoration(
              color: context.color.background.surface,
              borderRadius: BorderRadius.circular(
                context.dimensions.radius.medium,
              ),
              border: BorderDirectional(
                start: BorderSide(
                  color: context.color.accent.eco,
                  width: context.dimensions.border.lg,
                ),
              ),
            ),
            child: BodySmallText(l10n.pkwImpactMessage(l10n.appTitle, trees)),
          ),
        ],
      ),
    );
  }
}

class OrderImpactStat extends StatelessWidget {
  const OrderImpactStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: context.color.accent.ecoStrong,
          size: context.dimensions.size.iconLarge,
        ),
        Gap(context.dimensions.space.s4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: context.textStyle.body.strong.copyWith(
            color: context.color.accent.ecoStrong,
          ),
        ),
        BodySmallText.muted(label, textAlign: TextAlign.center),
      ],
    );
  }
}
