import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/router/route_args.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/section_card.dart';
import '../widgets/address_picker_form_fields.dart';
import '../widgets/address_picker_fullscreen_map.dart';
import '../widgets/address_picker_location_row.dart';
import '../widgets/address_picker_map_preview.dart';
import '../widgets/address_picker_saved_list.dart';
import '../widgets/order_form_submit_bar.dart';

/// The map address picker (Ionic `paddress`). The camera centre under the
/// fixed pin is the address point; a full-screen mode adds Places search
/// and the current-location button. Pops an [OrderAddress] on Continue
/// and null on close.
///
/// A new address opens on the form: the user's saved addresses first (one
/// tap fills everything), then the map preview centred on the device
/// position (Beirut when that fails) with the full-screen map one tap
/// away. Editing an address opens the same form pre-filled.
class AddressPickerPage extends ConsumerStatefulWidget {
  const AddressPickerPage({super.key, required this.args});

  final AddressPickerArgs args;

  @override
  ConsumerState<AddressPickerPage> createState() => _AddressPickerPageState();
}

class _AddressPickerPageState extends ConsumerState<AddressPickerPage> {
  /// The Ionic fallback when geolocation fails.
  static const GeoPoint _beirut = GeoPoint(33.8547, 35.8623);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _notesController = TextEditingController();

  bool _save = false;
  GeoPoint? _point;
  String? _city;
  String? _country;
  Address? _selectedSaved;

  bool _fullscreen = false;
  bool _initialising = false;
  bool _locating = false;
  bool _resolving = false;

  /// google_maps_flutter renders only on Android and iOS.
  bool get _canRenderMap =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    final initial = widget.args.initial;
    if (initial != null) {
      _nameController.text = initial.name;
      _streetController.text = initial.street;
      _buildingController.text = initial.building;
      _apartmentController.text = initial.apartment;
      _notesController.text = initial.notes ?? '';
      _save = initial.save;
      _point = GeoPoint(initial.lat, initial.lng);
      _city = initial.city;
      _country = initial.country.trim().isEmpty ? null : initial.country;
    } else {
      _point = ref.read(getCurrentPositionUseCaseProvider).lastKnown;
      _initialising = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startNewAddress());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _apartmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------- location

  Future<void> _startNewAddress() async {
    final located = await _locate(quiet: true);
    if (!mounted) return;
    final point = located ?? _point ?? _beirut;
    setState(() {
      _point = point;
      _initialising = false;
    });
    if (located != null) await _resolve(point);
  }

  /// The device position, or null when it cannot be obtained. Errors are
  /// reported unless [quiet].
  Future<GeoPoint?> _locate({bool quiet = false}) async {
    if (_locating) return null;
    setState(() => _locating = true);
    final result = await ref.read(getCurrentPositionUseCaseProvider).call();
    if (!mounted) return null;
    setState(() => _locating = false);
    switch (result) {
      case Success(:final data):
        return data;
      case Error(:final error):
        if (!quiet) AppFeedback.error(context, error);
        return null;
    }
  }

  Future<void> _useCurrentLocation() async {
    final point = await _locate();
    if (!mounted || point == null) return;
    setState(() => _point = point);
    await _resolve(point);
  }

  Future<void> _resolve(GeoPoint point) async {
    setState(() => _resolving = true);
    final result = await ref.read(reverseGeocodeUseCaseProvider).call(point);
    if (!mounted) return;
    setState(() => _resolving = false);
    switch (result) {
      case Success(:final data):
        setState(() {
          _city = data.city;
          _country = data.country;
        });
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  // --------------------------------------------------------- fullscreen

  Future<void> _openFullscreen() async {
    if (_point == null) {
      final located = await _locate();
      if (!mounted) return;
      _point = located ?? _beirut;
    }
    setState(() => _fullscreen = true);
  }

  void _closeFullscreen() {
    setState(() => _fullscreen = false);
  }

  Future<void> _confirmFullscreen(GeoPoint point) async {
    setState(() {
      _point = point;
      _fullscreen = false;
    });
    await _resolve(point);
  }

  // --------------------------------------------------------------- form

  /// A saved address is complete: hand it straight back, as the Ionic
  /// `setAddress()` did. To edit one, pick it and reopen the tile.
  void _applySaved(Address address) {
    context.pop(
      OrderAddress(
        name: address.name,
        city: address.city,
        country: address.country,
        lat: address.lat,
        lng: address.lng,
        street: address.street,
        building: address.building,
        apartment: address.apartment,
        notes: address.notes,
      ),
    );
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final point = _point;
    if (point == null) {
      AppFeedback.toast(context, context.l10n.pkgAddressPickLocation);
      return;
    }
    final notes = _notesController.text.trim();
    context.pop(
      OrderAddress(
        name: _nameController.text.trim(),
        city: _city,
        country: _country ?? '',
        lat: point.lat,
        lng: point.lng,
        street: _streetController.text.trim(),
        building: _buildingController.text.trim(),
        apartment: _apartmentController.text.trim(),
        notes: notes.isEmpty ? null : notes,
        save: _save,
      ),
    );
  }

  void _close() {
    if (_fullscreen) {
      _closeFullscreen();
      return;
    }
    context.pop();
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final point = _point;
    final showMap = _fullscreen && point != null && !_initialising;

    return PopScope(
      canPop: !_fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeFullscreen();
      },
      child: Scaffold(
        backgroundColor: context.color.background.canvas,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.args.title),
          actions: [
            IconButton(
              tooltip: context.l10n.close,
              icon: const Icon(Icons.close_rounded),
              onPressed: _close,
            ),
          ],
        ),
        body: _initialising
            ? const Center(child: CircularProgressIndicator())
            : showMap
            ? AddressPickerFullscreenMap(
                initial: point,
                canRenderMap: _canRenderMap,
                locating: _locating,
                onLocate: _locate,
                onCancel: _closeFullscreen,
                onConfirm: _confirmFullscreen,
              )
            : ListView(
                padding: EdgeInsets.all(context.dimensions.space.s16),
                children: [
                  if (userId != null)
                    AddressPickerSavedList(
                      userId: userId,
                      selected: _selectedSaved,
                      onSelect: _applySaved,
                    ),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AddressPickerMapPreview(
                          point: point,
                          canRenderMap: _canRenderMap,
                          onExpand: _openFullscreen,
                        ),
                        Gap(context.dimensions.space.s12),
                        AddressPickerLocationRow(
                          city: _city,
                          country: _country,
                          resolving: _resolving,
                          locating: _locating,
                          onLocate: _useCurrentLocation,
                        ),
                      ],
                    ),
                  ),
                  Gap(context.dimensions.space.s16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: AddressPickerFormFields(
                            nameController: _nameController,
                            streetController: _streetController,
                            buildingController: _buildingController,
                            apartmentController: _apartmentController,
                            notesController: _notesController,
                            save: _save,
                            onSaveChanged: (v) => setState(() => _save = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: _initialising || showMap
            ? null
            : OrderFormSubmitBar(
                label: context.l10n.continueLabel,
                loading: false,
                onPressed: _continue,
              ),
      ),
    );
  }
}
