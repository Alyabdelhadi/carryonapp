import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';

/// The Places search field of the full-screen map with its suggestion
/// list underneath (the Ionic `fullscreen-search-bar` + autocomplete).
class AddressPickerSearchBar extends StatelessWidget {
  const AddressPickerSearchBar({
    super.key,
    required this.controller,
    required this.results,
    required this.onChanged,
    required this.onClear,
    required this.onSelect,
  });

  final TextEditingController controller;
  final AsyncValue<List<PlaceSuggestion>> results;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<PlaceSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.dimensions.radius.large);
    final suggestions = results.value ?? const <PlaceSuggestion>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: context.dimensions.elevation.raised,
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.l10n.pkwSearchPlaceHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.l10n.pkwClear,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: onClear,
                    ),
            ),
          ),
        ),
        if (results.isLoading) ...[
          Gap(context.dimensions.space.s4),
          const LinearProgressIndicator(),
        ],
        if (suggestions.isNotEmpty) ...[
          Gap(context.dimensions.space.s8),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: context.color.background.surface,
                borderRadius: radius,
                boxShadow: context.dimensions.elevation.raised,
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                separatorBuilder: (_, _) => Divider(
                  height: context.dimensions.layout.hairline,
                  color: context.color.border.subtle,
                ),
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place_outlined,
                      color: context.color.text.muted,
                    ),
                    title: BodySmallText(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelect(item),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
