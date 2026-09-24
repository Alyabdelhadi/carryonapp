import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/text/typography.dart';
import '../../../core/widgets/flag_text.dart';
import '../../../core/extensions/place_names_extension.dart';

/// The Ionic `country-modal`: a searchable list of countries with their
/// flag and phone code. Resolves with the tapped country, or null.
class OrderFormCountryPickerSheet extends StatefulWidget {
  const OrderFormCountryPickerSheet({
    super.key,
    required this.countries,
    this.selected,
  });

  final List<Country> countries;
  final Country? selected;

  static Future<Country?> show(
    BuildContext context, {
    required List<Country> countries,
    Country? selected,
  }) {
    return showModalBottomSheet<Country>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: OrderFormCountryPickerSheet(
          countries: countries,
          selected: selected,
        ),
      ),
    );
  }

  @override
  State<OrderFormCountryPickerSheet> createState() =>
      _OrderFormCountryPickerSheetState();
}

class _OrderFormCountryPickerSheetState
    extends State<OrderFormCountryPickerSheet> {
  final _search = TextEditingController();
  late List<Country> _filtered = widget.countries;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(String term) {
    final needle = term.trim().toLowerCase();
    setState(() {
      _filtered = needle.isEmpty
          ? widget.countries
          : widget.countries
                .where(
                  (c) =>
                      c.matches(needle) || (c.phoneCode ?? '').contains(needle),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.dimensions.space.s16,
          ),
          child: TextField(
            controller: _search,
            autofocus: true,
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: context.l10n.pkwSearchCountryHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _search.clear();
                        _filter('');
                      },
                    ),
            ),
          ),
        ),
        Gap(context.dimensions.space.s8),
        Expanded(
          child: _filtered.isEmpty
              ? EmptyState(
                  icon: Icons.public_off_rounded,
                  title: context.l10n.pkwNoCountryFound,
                )
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final country = _filtered[index];
                    final isSelected = country.id == widget.selected?.id;
                    return ListTile(
                      leading: FlagText(country.flag),
                      title: BodySmallText(
                        country.nameFor(context.languageCode),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LabelText.muted(
                            country.phoneCode ?? '',
                            textDirection: TextDirection.ltr,
                          ),
                          if (isSelected) ...[
                            Gap(context.dimensions.space.s8),
                            Icon(
                              Icons.check_rounded,
                              size: context.dimensions.size.iconMedium,
                              color: context.color.primary.strong,
                            ),
                          ],
                        ],
                      ),
                      selected: isSelected,
                      onTap: () => Navigator.of(context).pop(country),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
