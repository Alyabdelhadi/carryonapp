import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../core/gen/l10n/app_localizations.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/extensions/localized_labels.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';

/// The label the Ionic form gave each frequency radio ("One-Time Trip",
/// "Frequent Route"); the values it never offered keep their generic label.
String frequencyOptionLabel(TripFrequency frequency, AppLocalizations l10n) =>
    switch (frequency) {
      .oneTime => l10n.tripFrequencyOptionOneTime,
      .daily => l10n.tripFrequentRoute,
      .weekdays || .weekends => frequency.label(l10n),
    };

IconData _frequencyIcon(TripFrequency frequency) => switch (frequency) {
  .oneTime => Icons.event_rounded,
  .daily => Icons.repeat_rounded,
  .weekdays => Icons.work_outline_rounded,
  .weekends => Icons.weekend_outlined,
};

/// The Ionic radio group as a row of selectable tiles, one per option.
class FrequencySelector extends StatelessWidget {
  const FrequencySelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<TripFrequency> options;
  final TripFrequency value;
  final ValueChanged<TripFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, option) in options.indexed) ...[
          if (index > 0) Gap(context.dimensions.space.s12),
          Expanded(
            child: _FrequencyTile(
              frequency: option,
              selected: option == value,
              onTap: () => onChanged(option),
            ),
          ),
        ],
      ],
    );
  }
}

class _FrequencyTile extends StatelessWidget {
  const _FrequencyTile({
    required this.frequency,
    required this.selected,
    required this.onTap,
  });

  final TripFrequency frequency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.dimensions.radius.large);
    final accent = context.color.primary.strong;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: kThemeChangeDuration,
          padding: EdgeInsets.symmetric(
            vertical: context.dimensions.space.s16,
            horizontal: context.dimensions.space.s12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? context.color.primary.tint
                : context.color.background.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected ? accent : context.color.border.defaultValue,
              width: selected
                  ? context.dimensions.border.lg
                  : context.dimensions.border.xs,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _frequencyIcon(frequency),
                size: context.dimensions.size.iconLarge,
                color: selected ? accent : context.color.text.muted,
              ),
              Gap(context.dimensions.space.s8),
              LabelText(
                frequencyOptionLabel(frequency, context.l10n),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
