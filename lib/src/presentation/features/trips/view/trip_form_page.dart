import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/catalog.dart';
import '../../../../domain/failures/business_failure.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/login_required_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/catalog_providers.dart';
import '../riverpod/trip_submit_provider.dart';
import '../widgets/frequency_selector.dart';
import '../widgets/picker_field.dart';
import '../widgets/searchable_picker_sheet.dart';
import '../../../core/extensions/place_names_extension.dart';

/// Create or edit a trip (Ionic `trip`): frequency, departure country and
/// city, arrival country and city, and the date for one-time trips. Pops
/// `true` after a successful create, update or cancellation.
class TripFormPage extends ConsumerStatefulWidget {
  const TripFormPage({super.key, this.trip});

  /// The trip being edited; null creates a new one.
  final Trip? trip;

  @override
  ConsumerState<TripFormPage> createState() => _TripFormPageState();
}

class _TripFormPageState extends ConsumerState<TripFormPage> {
  /// The Ionic radio group offers exactly these two.
  static const _offeredFrequencies = [
    TripFrequency.oneTime,
    TripFrequency.daily,
  ];

  late TripFrequency _frequency;
  Country? _fromCountry;
  City? _fromCity;
  Country? _toCountry;
  City? _toCity;
  DateTime? _date;

  bool get _isCreate => widget.trip == null;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    _frequency = trip?.frequency ?? .oneTime;
    // The Ionic form defaults the date to today.
    _date = trip?.date ?? _today;
    if (trip != null) {
      _fromCountry = _countryOf(trip.from);
      _fromCity = _cityOf(trip.from);
      _toCountry = _countryOf(trip.to);
      _toCity = _cityOf(trip.to);
    }
  }

  static Country? _countryOf(TripCity city) {
    final id = city.countryId;
    if (id == null) return null;
    return Country(
      id: id,
      name: city.countryName ?? '',
      nameAr: city.countryNameAr,
    );
  }

  static City? _cityOf(TripCity city) {
    final id = city.id;
    final countryId = city.countryId;
    if (id == null || countryId == null) return null;
    return City(
      id: id,
      name: city.name,
      nameAr: city.nameAr,
      countryId: countryId,
      image: city.image,
    );
  }

  List<TripFrequency> get _frequencyOptions {
    // A legacy weekdays/weekends trip keeps its value selectable.
    if (_offeredFrequencies.contains(_frequency)) return _offeredFrequencies;
    return [..._offeredFrequencies, _frequency];
  }

  bool get _needsDate => _frequency == .oneTime;

  bool get _canSubmit =>
      _fromCountry != null &&
      _fromCity != null &&
      _toCountry != null &&
      _toCity != null &&
      (!_needsDate || _date != null);

  /// The Ionic page hides "Update Trip" once a one-time trip's date passed.
  bool get _showSubmit => _isCreate || (widget.trip?.isUpcoming ?? true);

  Future<void> _pickCountry({required bool from}) async {
    final current = from ? _fromCountry : _toCountry;
    final l10n = context.l10n;
    final picked = await showSearchablePicker<Country>(
      context,
      title: from ? l10n.tripDepartCountry : l10n.tripArrivalCountry,
      searchHint: l10n.tripSearchCountryHint,
      items: countriesProvider,
      labelOf: (c) => c.nameFor(context.languageCode),
      matches: (c, query) => c.matches(query),
      leadingOf: (c) => c.flag,
      isSelected: (c) => c.id == current?.id,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (from) {
        if (_fromCountry?.id != picked.id) _fromCity = null;
        _fromCountry = picked;
      } else {
        if (_toCountry?.id != picked.id) _toCity = null;
        _toCountry = picked;
      }
    });
  }

  Future<void> _pickCity({required bool from}) async {
    final country = from ? _fromCountry : _toCountry;
    if (country == null) return;
    final current = from ? _fromCity : _toCity;
    final provider = citiesByCountryProvider(country.id);
    final l10n = context.l10n;
    final picked = await showSearchablePicker<City>(
      context,
      title: from ? l10n.tripDepartCity : l10n.tripArrivalCity,
      searchHint: l10n.tripSearchCityHint,
      items: provider,
      labelOf: (c) => c.nameFor(context.languageCode),
      matches: (c, query) => c.matches(query),
      isSelected: (c) => c.id == current?.id,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (from) {
        _fromCity = picked;
      } else {
        _toCity = picked;
      }
    });
  }

  Future<void> _pickDate() async {
    final today = _today;
    final initial = _date == null || _date!.isBefore(today) ? today : _date!;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(today.year + 3, today.month, today.day),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || !_canSubmit) return;
    final l10n = context.l10n;

    final input = TripInput(
      cityFromId: _fromCity!.id,
      cityToId: _toCity!.id,
      carrierId: userId,
      frequency: _frequency,
      date: _needsDate ? _date : null,
    );
    final ok = await ref
        .read(tripSubmitProvider.notifier)
        .save(input, tripId: widget.trip?.id);
    if (!ok || !mounted) return;

    AppFeedback.toast(
      context,
      _isCreate ? l10n.tripCreatedToast : l10n.tripUpdatedToast,
    );
    context.pop(true);
  }

  Future<void> _cancelTrip() async {
    final trip = widget.trip;
    if (trip == null) return;
    final l10n = context.l10n;

    final confirmed = await AppFeedback.confirm(
      context,
      title: l10n.tripCancelDialogTitle,
      message: l10n.tripCancelDialogMessage,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.tripGoBack,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final ok = await ref.read(tripSubmitProvider.notifier).delete(trip.id);
    if (!ok || !mounted) return;

    AppFeedback.toast(context, l10n.tripCancelledToast);
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tripSubmitProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        // The data layer flags a create/update answer without a trip id
        // with a marker, not user copy; show the localized message for it.
        final shown =
            error is InvalidInput && error.message == tripNotSavedMarker
            ? BusinessFailure.unexpected(message: context.l10n.tripNotSaved)
            : error;
        AppFeedback.error(context, shown);
      }
    });
    final submitting = ref.watch(tripSubmitProvider).isLoading;
    final l10n = context.l10n;

    // Keep the chosen countries' city lists alive so the picker opens
    // instantly; the Ionic page fetched them at modal open.
    final fromCountryId = _fromCountry?.id;
    final toCountryId = _toCountry?.id;
    if (fromCountryId != null) {
      ref.watch(citiesByCountryProvider(fromCountryId));
    }
    if (toCountryId != null) {
      ref.watch(citiesByCountryProvider(toCountryId));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_isCreate ? l10n.tripAddNew : l10n.tripUpdate),
        actions: [
          IconButton(
            onPressed: submitting ? null : () => context.pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: l10n.close,
          ),
        ],
      ),
      body: LoginRequired(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(context.dimensions.space.s16),
                children: [
                  _FieldLabel(l10n.tripTypeLabel),
                  FrequencySelector(
                    options: _frequencyOptions,
                    value: _frequency,
                    onChanged: submitting
                        ? (_) {}
                        : (f) => setState(() => _frequency = f),
                  ),
                  Gap(context.dimensions.space.s24),
                  _RouteSection(
                    label: l10n.tripDepartFrom,
                    countryPlaceholder: l10n.tripDepartCountry,
                    cityPlaceholder: l10n.tripDepartCity,
                    country: _fromCountry,
                    city: _fromCity,
                    icon: Icons.flight_takeoff_rounded,
                    onPickCountry: () => _pickCountry(from: true),
                    onPickCity: () => _pickCity(from: true),
                  ),
                  Gap(context.dimensions.space.s16),
                  _RouteSection(
                    label: l10n.tripArrivalTo,
                    countryPlaceholder: l10n.tripArrivalCountry,
                    cityPlaceholder: l10n.tripArrivalCity,
                    country: _toCountry,
                    city: _toCity,
                    icon: Icons.flight_land_rounded,
                    onPickCountry: () => _pickCountry(from: false),
                    onPickCity: () => _pickCity(from: false),
                  ),
                  if (_needsDate) ...[
                    Gap(context.dimensions.space.s16),
                    _FieldLabel(l10n.tripDateLabel),
                    SectionCard(
                      padding: EdgeInsets.zero,
                      child: PickerField(
                        placeholder: l10n.tripSelectDate,
                        value: _date == null
                            ? null
                            : Formatters.monthDayYear(_date),
                        icon: Icons.event_rounded,
                        onTap: _pickDate,
                      ),
                    ),
                    Gap(context.dimensions.space.s8),
                    BodySmallText.muted(l10n.tripDateHint),
                  ],
                  Gap(context.dimensions.space.s24),
                ],
              ),
            ),
            _FormFooter(
              submitLabel: _isCreate ? l10n.tripCreate : l10n.tripUpdate,
              isEdit: !_isCreate,
              showSubmit: _showSubmit,
              canSubmit: _canSubmit && !submitting,
              submitting: submitting,
              onSubmit: _submit,
              onCancelTrip: _isCreate || submitting ? null : _cancelTrip,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.dimensions.space.s4,
        bottom: context.dimensions.space.s8,
      ),
      child: LabelText(text),
    );
  }
}

/// A country picker and, once a country is chosen, its city picker.
class _RouteSection extends StatelessWidget {
  const _RouteSection({
    required this.label,
    required this.countryPlaceholder,
    required this.cityPlaceholder,
    required this.country,
    required this.city,
    required this.icon,
    required this.onPickCountry,
    required this.onPickCity,
  });

  final String label;
  final String countryPlaceholder;
  final String cityPlaceholder;
  final Country? country;
  final City? city;
  final IconData icon;
  final VoidCallback onPickCountry;
  final VoidCallback onPickCity;

  @override
  Widget build(BuildContext context) {
    final lang = context.languageCode;
    final flag = country?.flag;
    final countryName = country == null
        ? null
        : flag == null || flag.isEmpty
        ? country!.nameFor(lang)
        : '$flag  ${country!.nameFor(lang)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        SectionCard(
          padding: EdgeInsets.all(context.dimensions.space.s8),
          child: Column(
            children: [
              PickerField(
                placeholder: countryPlaceholder,
                value: countryName,
                icon: Icons.public_rounded,
                onTap: onPickCountry,
              ),
              if (country != null) ...[
                Gap(context.dimensions.space.s8),
                PickerField(
                  placeholder: cityPlaceholder,
                  value: city?.nameFor(lang),
                  icon: icon,
                  onTap: onPickCity,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The Ionic footer: the submit button and, in edit mode, "Cancel Trip".
class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.submitLabel,
    required this.isEdit,
    required this.showSubmit,
    required this.canSubmit,
    required this.submitting,
    required this.onSubmit,
    required this.onCancelTrip,
  });

  final String submitLabel;
  final bool isEdit;
  final bool showSubmit;
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback? onCancelTrip;

  @override
  Widget build(BuildContext context) {
    if (!showSubmit && !isEdit) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.color.background.surface,
        boxShadow: context.dimensions.elevation.navigation,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.dimensions.space.s16,
            context.dimensions.space.s12,
            context.dimensions.space.s16,
            context.dimensions.space.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showSubmit)
                FilledButton(
                  onPressed: canSubmit ? onSubmit : null,
                  child: submitting
                      ? SizedBox(
                          width: context.dimensions.size.iconMedium,
                          height: context.dimensions.size.iconMedium,
                          child: CircularProgressIndicator(
                            color: context.color.text.onPrimary,
                            strokeWidth: context.dimensions.border.lg,
                          ),
                        )
                      : Text(submitLabel),
                ),
              if (isEdit) ...[
                if (showSubmit) Gap(context.dimensions.space.s8),
                OutlinedButton.icon(
                  onPressed: onCancelTrip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.color.status.danger,
                    side: BorderSide(
                      color: context.color.status.danger,
                      width: context.dimensions.border.md,
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(context.l10n.tripCancel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
