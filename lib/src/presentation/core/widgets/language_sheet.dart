import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/extensions/localization.dart';
import '../application_state/localization_provider/localization_provider.dart';
import '../theme/theme.dart';
import 'text/typography.dart';

/// Picker for the app language. Each option is written in its own
/// language so a user who cannot read the current one still finds theirs.
class LanguageSheet extends ConsumerWidget {
  const LanguageSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: context.color.background.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.radius.extraLarge),
        ),
      ),
      builder: (_) => const LanguageSheet(),
    );
  }

  static const _names = {'en': 'English', 'ar': 'العربية'};

  /// The native name of [locale], for menu rows.
  static String nativeName(Locale locale) =>
      _names[locale.languageCode] ?? locale.languageCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localizationProvider);
    final space = context.dimensions.space;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: space.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: space.s16),
            child: HeadingLevel3Text(
              context.l10n.language,
              textAlign: TextAlign.center,
            ),
          ),
          Gap(space.s8),
          for (final locale in AppLanguages.all)
            ListTile(
              leading: Icon(
                locale == current
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: locale == current
                    ? context.color.primary.strong
                    : context.color.text.muted,
              ),
              title: Text(nativeName(locale)),
              onTap: () async {
                await ref
                    .read(localizationProvider.notifier)
                    .changeLocale(locale);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
