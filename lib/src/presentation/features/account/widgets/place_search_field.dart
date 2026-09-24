import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';

/// Google Places autocomplete: a search box with a suggestion list under
/// it. Picking a row resolves the place and hands back its [PlaceInfo]
/// (coordinates, city, country); the box then clears. [hint] defaults to
/// the localized "Search for a place".
class PlaceSearchField extends ConsumerStatefulWidget {
  const PlaceSearchField({super.key, required this.onSelected, this.hint});

  final void Function(PlaceInfo place) onSelected;
  final String? hint;

  @override
  ConsumerState<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends ConsumerState<PlaceSearchField> {
  static const _debounce = Duration(milliseconds: 350);

  final _controller = TextEditingController();
  Timer? _timer;
  int _requestId = 0;
  List<PlaceSuggestion> _suggestions = const [];
  bool _resolving = false;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = const []);
      return;
    }
    _timer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;
    final result = await ref.read(searchPlacesUseCaseProvider).call(query);
    if (!mounted || id != _requestId) return;
    setState(() {
      _suggestions = switch (result) {
        Success(:final data) => data,
        // A failed lookup just shows no rows, as the original did.
        Error() => const [],
      };
    });
  }

  void _clear() {
    _timer?.cancel();
    _requestId++;
    _controller.clear();
    setState(() => _suggestions = const []);
  }

  Future<void> _select(PlaceSuggestion suggestion) async {
    setState(() => _resolving = true);
    final result = await ref
        .read(searchPlacesUseCaseProvider)
        .details(suggestion.placeId);
    if (!mounted) return;
    setState(() => _resolving = false);

    switch (result) {
      case Success(:final data):
        _clear();
        FocusScope.of(context).unfocus();
        widget.onSelected(data);
      case Error():
        AppFeedback.toast(context, context.l10n.accNoResultsFound);
    }
  }

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hint ?? context.l10n.accSearchPlaceHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _resolving
                ? Padding(
                    padding: EdgeInsets.all(space.s12),
                    child: SizedBox(
                      width: context.dimensions.size.iconMedium,
                      height: context.dimensions.size.iconMedium,
                      child: const CircularProgressIndicator.adaptive(),
                    ),
                  )
                : (_controller.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _clear,
                          tooltip: context.l10n.accClear,
                          icon: const Icon(Icons.close_rounded),
                        )),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          Gap(space.s8),
          SectionCard(
            padding: EdgeInsets.symmetric(vertical: space.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in _suggestions)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place_outlined,
                      color: context.color.text.muted,
                      size: context.dimensions.size.iconMedium,
                    ),
                    title: BodySmallText(
                      s.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: _resolving ? null : () => _select(s),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
