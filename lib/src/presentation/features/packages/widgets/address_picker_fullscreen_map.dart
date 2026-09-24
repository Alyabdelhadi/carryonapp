import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../core/base/result.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/address_picker_provider.dart';
import 'address_picker_pin.dart';
import 'address_picker_search_bar.dart';

/// The full-screen map of the Ionic picker: a draggable map under a fixed
/// pin, the Places search bar, a "my location" button and Cancel /
/// Confirm. [onConfirm] receives the camera centre.
class AddressPickerFullscreenMap extends ConsumerStatefulWidget {
  const AddressPickerFullscreenMap({
    super.key,
    required this.initial,
    required this.canRenderMap,
    required this.locating,
    required this.onLocate,
    required this.onCancel,
    required this.onConfirm,
  });

  final GeoPoint initial;
  final bool canRenderMap;
  final bool locating;

  /// Resolves the device position; null when it could not be obtained.
  final Future<GeoPoint?> Function() onLocate;
  final VoidCallback onCancel;
  final ValueChanged<GeoPoint> onConfirm;

  static const double zoom = 16;

  @override
  ConsumerState<AddressPickerFullscreenMap> createState() =>
      _AddressPickerFullscreenMapState();
}

class _AddressPickerFullscreenMapState
    extends ConsumerState<AddressPickerFullscreenMap> {
  final _searchController = TextEditingController();
  GoogleMapController? _map;
  late GeoPoint _center = widget.initial;
  bool _resolvingPlace = false;

  @override
  void dispose() {
    _searchController.dispose();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _moveTo(GeoPoint point) async {
    setState(() => _center = point);
    await _map?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(point.lat, point.lng),
        AddressPickerFullscreenMap.zoom,
      ),
    );
  }

  Future<void> _locate() async {
    final point = await widget.onLocate();
    if (!mounted || point == null) return;
    await _moveTo(point);
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    ref.read(addressPickerSearchProvider.notifier).clear();
    final l10n = context.l10n;
    setState(() => _resolvingPlace = true);
    final result = await ref
        .read(addressPickerSearchProvider.notifier)
        .details(suggestion.placeId);
    if (!mounted) return;
    setState(() => _resolvingPlace = false);
    switch (result) {
      case Success(:final data) when data.point != null:
        await _moveTo(data.point!);
      case Success():
        AppFeedback.toast(context, l10n.pkwNoResultsFound);
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(addressPickerSearchProvider);
    final busy = widget.locating || _resolvingPlace;
    final space = context.dimensions.space;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.canRenderMap)
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.initial.lat, widget.initial.lng),
              zoom: AddressPickerFullscreenMap.zoom,
            ),
            onMapCreated: (c) => _map = c,
            onCameraMove: (position) {
              _center = GeoPoint(
                position.target.latitude,
                position.target.longitude,
              );
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          )
        else
          _NoMapPanel(center: _center),
        if (widget.canRenderMap) const AddressPickerPin(),
        PositionedDirectional(
          top: space.s12,
          start: space.s16,
          end: space.s16,
          bottom: space.s80,
          child: AddressPickerSearchBar(
            controller: _searchController,
            results: results,
            onChanged: (q) {
              setState(() {});
              ref.read(addressPickerSearchProvider.notifier).search(q);
            },
            onClear: () {
              _searchController.clear();
              ref.read(addressPickerSearchProvider.notifier).clear();
              setState(() {});
            },
            onSelect: _selectSuggestion,
          ),
        ),
        PositionedDirectional(
          end: space.s16,
          bottom: space.s80 + space.s24,
          child: FloatingActionButton.small(
            heroTag: 'address_picker_locate',
            tooltip: context.l10n.pkwUseMyLocation,
            backgroundColor: context.color.background.surface,
            foregroundColor: context.color.primary.strong,
            onPressed: busy ? null : _locate,
            child: busy
                ? SizedBox(
                    width: context.dimensions.size.iconMedium,
                    height: context.dimensions.size.iconMedium,
                    child: const CircularProgressIndicator(),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: context.color.background.surface,
              boxShadow: context.dimensions.elevation.navigation,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(space.s16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.close_rounded),
                        label: Text(context.l10n.cancel),
                      ),
                    ),
                    Gap(space.s12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => widget.onConfirm(_center),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(context.l10n.confirm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Stands in for the map on platforms that cannot show one: the search
/// bar and the location button still move [center].
class _NoMapPanel extends StatelessWidget {
  const _NoMapPanel({required this.center});

  final GeoPoint center;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.color.background.canvas,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(context.dimensions.space.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: context.dimensions.size.iconDisplay,
                color: context.color.text.muted,
              ),
              Gap(context.dimensions.space.s8),
              BodySmallText.muted(
                context.l10n.pkwMapUnavailable,
                textAlign: TextAlign.center,
              ),
              Gap(context.dimensions.space.s8),
              LabelText(
                '${center.lat.toStringAsFixed(5)}, '
                '${center.lng.toStringAsFixed(5)}',
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
