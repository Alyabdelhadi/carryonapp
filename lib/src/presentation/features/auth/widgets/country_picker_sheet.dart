import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../domain/entities/entities.dart';
import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';
import '../../../core/widgets/flag_text.dart';
import '../../../core/extensions/place_names_extension.dart';

/// The searchable country list behind the phone code picker. Pops with the
/// chosen [Country], or null when dismissed.
class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({super.key, required this.countries});

  final List<Country> countries;

  static Future<Country?> show(BuildContext context, List<Country> countries) {
    return showModalBottomSheet<Country>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.color.background.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.radius.extraLarge),
        ),
      ),
      builder: (_) => CountryPickerSheet(countries: countries),
    );
  }

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  String _term = '';

  List<Country> get _filtered {
    final term = _term.trim().toLowerCase();
    if (term.isEmpty) return widget.countries;
    return widget.countries.where((c) => c.matches(term)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    final countries = _filtered;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              space.s16,
              space.s16,
              space.s8,
              space.s8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    onChanged: (value) => setState(() => _term = value),
                    decoration: InputDecoration(
                      hintText: context.l10n.authSearchCountry,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                Gap(space.s4),
                IconButton(
                  tooltip: context.l10n.close,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: countries.isEmpty
                ? Center(
                    child: BodySmallText.muted(context.l10n.authNoCountryFound),
                  )
                : ListView.separated(
                    controller: scrollController,
                    itemCount: countries.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) => _CountryRow(
                      country: countries[index],
                      onTap: () => Navigator.of(context).pop(countries[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({required this.country, required this.onTap});

  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: FlagText(country.flag),
      title: Text(country.nameFor(context.languageCode)),
      // Phone codes read left-to-right whatever the locale.
      trailing: Directionality(
        textDirection: TextDirection.ltr,
        child: LabelText.muted(country.phoneCode ?? ''),
      ),
    );
  }
}
