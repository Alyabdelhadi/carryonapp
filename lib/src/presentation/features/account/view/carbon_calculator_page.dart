import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/router/route_args.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../model/carbon_calculator.dart';
import '../widgets/carbon_result_card.dart';

/// The "Carbon Calculator" (the original `offer` page): pick two airports
/// and a weight, see the CO₂, trees and money a CarryOn delivery saves
/// against traditional cargo. [args] pre-fills the route from an order.
class CarbonCalculatorPage extends StatefulWidget {
  const CarbonCalculatorPage({super.key, this.args});

  final CarbonCalculatorArgs? args;

  @override
  State<CarbonCalculatorPage> createState() => _CarbonCalculatorPageState();
}

class _CarbonCalculatorPageState extends State<CarbonCalculatorPage> {
  static const _other = 'other';

  String? _from;
  String? _to;
  String? _weight;
  final _customWeight = TextEditingController();

  CarbonEstimate? _result;
  String? _error;

  bool get _showCustom => _weight == _other;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    if (args == null) return;

    _from = CarbonCalculator.airportForCity(args.fromCity)?.code;
    _to = CarbonCalculator.airportForCity(args.toCity)?.code;

    final kg = args.weightKg;
    if (kg != null && kg > 0) {
      final preset = CarbonCalculator.presetWeightsKg
          .where((w) => w == kg)
          .firstOrNull;
      if (preset != null) {
        _weight = _weightKey(preset);
      } else {
        _weight = _other;
        _customWeight.text = _trimZeros(kg);
      }
    }
  }

  @override
  void dispose() {
    _customWeight.dispose();
    super.dispose();
  }

  static String _trimZeros(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static String _weightKey(double v) => _trimZeros(v);

  void _calculate() {
    FocusScope.of(context).unfocus();
    final weightText = _showCustom ? _customWeight.text : (_weight ?? '');
    final weight = double.tryParse(weightText.trim().replaceAll(',', '.'));

    final estimate = CarbonCalculator.estimate(
      from: CarbonCalculator.airportByCode(_from),
      to: CarbonCalculator.airportByCode(_to),
      weightKg: weight,
    );
    setState(() {
      _result = estimate;
      _error = estimate == null ? context.l10n.accInvalidCalculatorInput : null;
    });
  }

  void _reset() {
    setState(() {
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    final l10n = context.l10n;
    final airportItems = [
      for (final a in CarbonCalculator.airports)
        DropdownMenuItem(value: a.code, child: Text(a.name)),
    ];

    return Scaffold(
      backgroundColor: context.color.background.canvas,
      appBar: AppBar(
        title: Text(l10n.accCarbonCalculator),
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            tooltip: l10n.close,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            space.s16,
            space.s16,
            space.s16,
            space.s32,
          ),
          children: [
            const _CalculatorIntro(),
            Gap(space.s20),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _from,
                    isExpanded: true,
                    items: airportItems,
                    onChanged: (v) => setState(() => _from = v),
                    decoration: InputDecoration(
                      labelText: l10n.accFromAirport,
                      prefixIcon: const Icon(Icons.flight_takeoff_rounded),
                    ),
                  ),
                  Gap(space.s12),
                  DropdownButtonFormField<String>(
                    initialValue: _to,
                    isExpanded: true,
                    items: airportItems,
                    onChanged: (v) => setState(() => _to = v),
                    decoration: InputDecoration(
                      labelText: l10n.accToAirport,
                      prefixIcon: const Icon(Icons.flight_land_rounded),
                    ),
                  ),
                  Gap(space.s12),
                  DropdownButtonFormField<String>(
                    initialValue: _weight,
                    isExpanded: true,
                    items: [
                      for (final w in CarbonCalculator.presetWeightsKg)
                        DropdownMenuItem(
                          value: _weightKey(w),
                          child: Text(l10n.accKgValue(_weightKey(w))),
                        ),
                      DropdownMenuItem(
                        value: _other,
                        child: Text(l10n.accOtherWeight),
                      ),
                    ],
                    onChanged: (v) => setState(() => _weight = v),
                    decoration: InputDecoration(
                      labelText: l10n.accWeightKg,
                      prefixIcon: const Icon(Icons.scale_outlined),
                    ),
                  ),
                  if (_showCustom) ...[
                    Gap(space.s12),
                    TextField(
                      controller: _customWeight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      onSubmitted: (_) => _calculate(),
                      decoration: InputDecoration(
                        labelText: l10n.accCustomWeightKg,
                        prefixIcon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Gap(space.s16),
            FilledButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.eco_outlined),
              label: Text(l10n.accCalculateCo2),
            ),
            if (_error != null) ...[
              Gap(space.s16),
              _ErrorCard(message: _error!),
            ],
            if (_result != null) ...[
              Gap(space.s16),
              CarbonResultCard(estimate: _result!),
            ],
            if (_error != null || _result != null) ...[
              Gap(space.s16),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.accReset),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalculatorIntro extends StatelessWidget {
  const _CalculatorIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: context.dimensions.size.iconHero * 0.64,
          height: context.dimensions.size.iconHero * 0.64,
          decoration: BoxDecoration(
            color: context.color.accent.ecoTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.public_rounded,
            size: context.dimensions.size.iconDisplay,
            color: context.color.accent.eco,
          ),
        ),
        Gap(context.dimensions.space.s12),
        HeadingLevel1Text(
          context.l10n.accCo2Calculator,
          textAlign: TextAlign.center,
        ),
        Gap(context.dimensions.space.s4),
        BodySmallText.muted(
          context.l10n.accCalculatorIntro,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      color: context.color.status.dangerTint,
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: context.color.status.danger,
            size: context.dimensions.size.iconMedium,
          ),
          Gap(context.dimensions.space.s8),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(color: context.color.status.danger),
              child: BodySmallText(message),
            ),
          ),
        ],
      ),
    );
  }
}
