import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/countries_provider.dart';
import 'country_picker_sheet.dart';

/// The flag + phone code control in front of the phone field. Opens the
/// searchable [CountryPickerSheet]; shows a spinner while the country list
/// loads and a retry glyph when it failed.
class CountryCodeButton extends ConsumerWidget {
  const CountryCodeButton({
    super.key,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final Country? selected;
  final ValueChanged<Country> onSelected;
  final bool enabled;

  Future<void> _open(BuildContext context, List<Country> countries) async {
    final picked = await CountryPickerSheet.show(context, countries);
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries = ref.watch(countriesProvider);
    final radius = BorderRadius.circular(context.dimensions.radius.medium);
    final space = context.dimensions.space;

    final child = switch (countries) {
      // "+961" must keep its sign in front even in an RTL layout.
      AsyncData() => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeadingLevel3Text(selected?.flag ?? ''),
            Gap(space.s4),
            LabelText(selected?.phoneCode ?? '+'),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: context.dimensions.size.iconMedium,
            ),
          ],
        ),
      ),
      AsyncError() => Icon(
        Icons.refresh_rounded,
        size: context.dimensions.size.iconMedium,
      ),
      _ => SizedBox(
        width: context.dimensions.size.iconSmall,
        height: context.dimensions.size.iconSmall,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    };

    final onTap = switch (countries) {
      AsyncData(:final value) when enabled => () => _open(context, value),
      AsyncError() when enabled => () => ref.invalidate(countriesProvider),
      _ => null,
    };

    return Material(
      color: context.color.background.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: context.color.border.defaultValue,
          width: context.dimensions.border.xs,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: context.dimensions.size.control,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: space.s12),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
