import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/login_required_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../widgets/address_map_preview.dart';
import '../widgets/location_picker_map.dart';
import '../widgets/map_fullscreen_picker.dart';

/// Create or edit a saved address: drop a pin (device fix, place search
/// or drag), which fills city / country / coordinates, then name the
/// place and give the street details. A new address opens straight into
/// the full-screen picker, as the original did.
class AddressFormPage extends ConsumerStatefulWidget {
  const AddressFormPage({super.key, this.address});

  final Address? address;

  @override
  ConsumerState<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends ConsumerState<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _street;
  late final TextEditingController _building;
  late final TextEditingController _apartment;
  late final TextEditingController _notes;

  double? _lat;
  double? _lng;
  String _city = '';
  String _country = '';

  bool _expanded = false;
  bool _locating = false;
  bool _geocoding = false;
  bool _saving = false;
  GoogleMapController? _map;

  bool get _isEdit => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _name = TextEditingController(text: a?.name ?? '');
    _street = TextEditingController(text: a?.street ?? '');
    _building = TextEditingController(text: a?.building ?? '');
    _apartment = TextEditingController(text: a?.apartment ?? '');
    _notes = TextEditingController(text: a?.notes ?? '');

    if (a != null) {
      _lat = a.lat;
      _lng = a.lng;
      _city = a.city ?? '';
      _country = a.country;
    } else {
      _expanded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
    }
  }

  @override
  void dispose() {
    _map?.dispose();
    _name.dispose();
    _street.dispose();
    _building.dispose();
    _apartment.dispose();
    _notes.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ location

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await ref.read(getCurrentPositionUseCaseProvider).call();
    if (!mounted) return;
    setState(() => _locating = false);

    switch (result) {
      case Success(:final data):
        _moveTo(data.lat, data.lng);
        await _reverseGeocode();
      case Error(:final error):
        // The original fell back to 0,0 so the map still opened.
        if (_lat == null || _lng == null) {
          setState(() {
            _lat = 0;
            _lng = 0;
          });
        }
        AppFeedback.error(context, error);
    }
  }

  void _moveTo(double lat, double lng) {
    setState(() {
      _lat = lat;
      _lng = lng;
    });
    _map?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), LocationPickerMap.zoom),
    );
  }

  Future<void> _reverseGeocode() async {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) return;
    setState(() => _geocoding = true);
    final result = await ref
        .read(reverseGeocodeUseCaseProvider)
        .call(GeoPoint(lat, lng));
    if (!mounted) return;
    setState(() {
      _geocoding = false;
      if (result case Success(:final data)) {
        _city = data.city?.trim().isNotEmpty ?? false
            ? data.city!
            : context.l10n.accUnknownCity;
        _country = data.country ?? '';
      }
      // A failed lookup keeps whatever we had, as the original did.
    });
  }

  void _onPlaceSelected(PlaceInfo place) {
    final point = place.point;
    if (point != null) _moveTo(point.lat, point.lng);
    setState(() {
      if (place.city != null && place.city!.trim().isNotEmpty) {
        _city = place.city!;
      }
      if (place.country != null && place.country!.trim().isNotEmpty) {
        _country = place.country!;
      }
    });
    if (point != null && (place.city == null || place.country == null)) {
      _reverseGeocode();
    }
  }

  void _onCameraMove(CameraPosition position) {
    _lat = position.target.latitude;
    _lng = position.target.longitude;
  }

  void _onMapCreated(GoogleMapController controller) {
    _map?.dispose();
    _map = controller;
  }

  void _openPicker() {
    setState(() => _expanded = true);
  }

  Future<void> _closePicker() async {
    // Both Cancel and Confirm resolve the pin's current spot, as the
    // original's close handler did.
    setState(() => _expanded = false);
    await _reverseGeocode();
  }

  // ---------------------------------------------------------------- save

  Future<void> _save(int userId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) {
      AppFeedback.toast(context, l10n.accPickLocationFirst);
      return;
    }

    setState(() => _saving = true);
    final notes = _notes.text.trim();
    final result = await ref
        .read(saveAddressUseCaseProvider)
        .call(
          AddressInput(
            userId: userId,
            name: _name.text.trim(),
            country: _country,
            city: _city.isEmpty ? null : _city,
            lat: lat,
            lng: lng,
            street: _street.text.trim(),
            building: _building.text.trim(),
            apartment: _apartment.text.trim(),
            notes: notes.isEmpty ? null : notes,
            // The original address page always posted type 1.
            type: 1,
          ),
          addressId: widget.address?.id,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        AppFeedback.toast(
          context,
          _isEdit ? l10n.accAddressUpdated : l10n.accAddressAdded,
        );
        context.pop(true);
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return context.locale.isRequired;
    return null;
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final space = context.dimensions.space;
    final l10n = context.l10n;

    final Widget body;
    if (userId == null) {
      body = const LoginRequired(child: SizedBox.shrink());
    } else if (_expanded) {
      body = MapFullscreenPicker(
        lat: _lat,
        lng: _lng,
        locating: _locating,
        onMapCreated: _onMapCreated,
        onCameraMove: _onCameraMove,
        onPlaceSelected: _onPlaceSelected,
        onLocateMe: _locate,
        onCancel: _closePicker,
        onConfirm: _closePicker,
      );
    } else {
      body = Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            space.s16,
            space.s16,
            space.s16,
            space.s32,
          ),
          children: [
            AddressMapPreview(
              lat: _lat,
              lng: _lng,
              city: _city,
              country: _country,
              locating: _locating,
              geocoding: _geocoding,
              onExpand: _openPicker,
              onLocateMe: _locate,
            ),
            Gap(space.s16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabelText(l10n.accAddressDetails),
                  Gap(space.s12),
                  TextFormField(
                    controller: _name,
                    validator: _required,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.accAddressName,
                      hintText: l10n.accAddressNameHint,
                      prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                    ),
                  ),
                  Gap(space.s12),
                  TextFormField(
                    controller: _street,
                    validator: _required,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.accStreet,
                      prefixIcon: const Icon(Icons.signpost_outlined),
                    ),
                  ),
                  Gap(space.s12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _building,
                          validator: _required,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.accBuilding,
                            prefixIcon: const Icon(Icons.apartment_outlined),
                          ),
                        ),
                      ),
                      Gap(space.s12),
                      Expanded(
                        child: TextFormField(
                          controller: _apartment,
                          validator: _required,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.accApartment,
                            prefixIcon: const Icon(
                              Icons.door_front_door_outlined,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap(space.s12),
                  TextFormField(
                    controller: _notes,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 1,
                    onFieldSubmitted: (_) => _save(userId),
                    decoration: InputDecoration(
                      labelText: l10n.accNotes,
                      hintText: l10n.accNotesHint,
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Gap(space.s24),
            FilledButton(
              onPressed: _saving ? null : () => _save(userId),
              child: _saving ? const LoadingIndicator() : Text(l10n.save),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.color.background.canvas,
      appBar: AppBar(
        title: Text(_isEdit ? l10n.accEditAddress : l10n.accAddress),
        leading: IconButton(
          tooltip: _expanded && _isEdit ? l10n.accBackToForm : l10n.close,
          icon: Icon(
            _expanded && _isEdit
                ? Icons.arrow_back_rounded
                : Icons.close_rounded,
          ),
          onPressed: () {
            if (_expanded && _isEdit) {
              _closePicker();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(top: false, bottom: !_expanded, child: body),
    );
  }
}
