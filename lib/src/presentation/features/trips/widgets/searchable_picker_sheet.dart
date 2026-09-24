import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/failure_view.dart';
import '../../../core/widgets/text/typography.dart';
import '../../../core/widgets/flag_text.dart';

/// Opens [SearchablePickerSheet] as a modal bottom sheet and resolves with
/// the tapped item, or null when dismissed.
Future<T?> showSearchablePicker<T>(
  BuildContext context, {
  required String title,
  required String searchHint,
  required FutureProvider<List<T>> items,
  required String Function(T item) labelOf,
  bool Function(T item, String query)? matches,
  String? Function(T item)? leadingOf,
  bool Function(T item)? isSelected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SearchablePickerSheet<T>(
      title: title,
      searchHint: searchHint,
      items: items,
      labelOf: labelOf,
      matches: matches,
      leadingOf: leadingOf,
      isSelected: isSelected,
    ),
  );
}

/// The Ionic full-screen "country-modal": a search field over a long list
/// (countries, cities) that filters as the user types.
class SearchablePickerSheet<T> extends ConsumerStatefulWidget {
  const SearchablePickerSheet({
    super.key,
    required this.title,
    required this.searchHint,
    required this.items,
    required this.labelOf,
    this.matches,
    this.leadingOf,
    this.isSelected,
  });

  final String title;
  final String searchHint;

  /// The provider that yields the full list; watched so a retry refreshes
  /// the sheet in place.
  final FutureProvider<List<T>> items;
  final String Function(T item) labelOf;

  /// Custom search test (e.g. English and Arabic names); defaults to a
  /// case-insensitive match on [labelOf].
  final bool Function(T item, String query)? matches;

  /// Optional glyph in front of a row (a country's emoji flag).
  final String? Function(T item)? leadingOf;
  final bool Function(T item)? isSelected;

  @override
  ConsumerState<SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T>
    extends ConsumerState<SearchablePickerSheet<T>> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<T> _filter(List<T> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (item) =>
              widget.matches?.call(item, q) ??
              widget.labelOf(item).toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(widget.items);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final fullHeight = MediaQuery.sizeOf(context).height * 0.9;
    final height = math.max(fullHeight - insets, fullHeight * 0.5);

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.color.background.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.dimensions.radius.extraLarge),
          ),
          boxShadow: context.dimensions.elevation.screen,
        ),
        child: Column(
          children: [
            Gap(context.dimensions.space.s12),
            Container(
              width: context.dimensions.space.s32,
              height: context.dimensions.space.s4,
              decoration: BoxDecoration(
                color: context.color.border.defaultValue,
                borderRadius: BorderRadius.circular(
                  context.dimensions.radius.full,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                context.dimensions.space.s20,
                context.dimensions.space.s12,
                context.dimensions.space.s8,
                context.dimensions.space.s4,
              ),
              child: Row(
                children: [
                  Expanded(child: HeadingLevel3Text(widget.title)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: context.l10n.close,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.dimensions.space.s16,
                vertical: context.dimensions.space.s8,
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
              ),
            ),
            Expanded(
              child: switch (async) {
                AsyncValue(hasValue: true, value: final all?) => _PickerList<T>(
                  items: _filter(all),
                  labelOf: widget.labelOf,
                  leadingOf: widget.leadingOf,
                  isSelected: widget.isSelected,
                ),
                AsyncError(:final error) => FailureView(
                  error: error,
                  onRetry: () => ref.invalidate(widget.items),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerList<T> extends StatelessWidget {
  const _PickerList({
    required this.items,
    required this.labelOf,
    required this.leadingOf,
    required this.isSelected,
  });

  final List<T> items;
  final String Function(T item) labelOf;
  final String? Function(T item)? leadingOf;
  final bool Function(T item)? isSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: context.l10n.tripPickerNoMatches,
        message: context.l10n.tripPickerNoMatchesMessage,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.space.s8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final leading = leadingOf?.call(item);
        final selected = isSelected?.call(item) ?? false;
        return ListTile(
          leading: leading == null || leading.isEmpty
              ? null
              : FlagText(leading),
          title: LabelText(labelOf(item)),
          trailing: selected
              ? Icon(Icons.check_rounded, color: context.color.primary.strong)
              : null,
          selected: selected,
          selectedTileColor: context.color.primary.tint,
          onTap: () => Navigator.of(context).pop(item),
        );
      },
    );
  }
}
