import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/base/result.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/extensions/app_texts_extension.dart';
import '../../../core/router/route_args.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/login_required_view.dart';
import '../riverpod/order_form_provider.dart';
import '../widgets/order_form_amount_field.dart';
import '../widgets/order_form_contact_section.dart';
import '../widgets/order_form_country_picker_sheet.dart';
import '../widgets/order_form_delivery_section.dart';
import '../widgets/order_form_notes_section.dart';
import '../widgets/order_form_overview_card.dart';
import '../widgets/order_form_package_section.dart';
import '../widgets/order_form_payment_section.dart';
import '../widgets/order_form_reward_section.dart';
import '../widgets/order_form_route_card.dart';
import '../widgets/order_form_self_card.dart';
import '../widgets/order_form_step_indicator.dart';
import '../widgets/order_form_submit_bar.dart';
import '../../../core/extensions/place_names_extension.dart';

/// The parcel order form: the Ionic `pview` (receive, type 2) and `pview1`
/// (send, type 1) pages folded into one screen driven by [OrderFormArgs].
///
/// The two Ionic pages differed only in which side is the signed-in user:
/// receiving asks for the *sender's* name and phone and fills the receiver
/// from the session; sending does the reverse. Everything else (addresses,
/// package, delivery date, reward, payment, notes) is the same.
///
/// The form runs in two steps: "Where & who" (route and parties) and
/// "What & how" (package, delivery, reward, payment, notes, overview). All
/// state lives here, so moving between steps loses nothing.
class OrderFormPage extends ConsumerStatefulWidget {
  const OrderFormPage({super.key, required this.args});

  final OrderFormArgs args;

  @override
  ConsumerState<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends ConsumerState<OrderFormPage> {
  /// The Ionic `tips` list.
  static const List<String> _rewardOptions = [
    OrderFormRewardSection.free,
    '10',
    '20',
    '50',
    '100',
    '150',
    '200',
    OrderFormRewardSection.other,
  ];

  static const String _termsUrl = 'https://carryonapp.com/terms-conditions';

  late final ParcelFlow _flow;

  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _otherNameController = TextEditingController();
  final _otherPhoneController = TextEditingController();
  final _valueController = TextEditingController();
  final _weightController = TextEditingController();
  final _customRewardController = TextEditingController();

  /// 0 = "Where & who", 1 = "What & how".
  int _step = 0;

  int? _categoryId;
  String? _categoryName;

  String? _rewardChip;
  String _reward = '';

  bool _neededSoon = true;
  DateTime? _neededBefore;

  OrderAddress? _sender;
  OrderAddress? _receiver;

  Country? _country;
  bool _countryResolved = false;

  /// The other party's phone as stored on the order being edited; split
  /// into country code + number once the countries arrive.
  String? _pendingPhone;

  int _paymentMethodId = 1;
  bool _paymentResolved = false;

  /// True after the first frame; listeners fired before that must not
  /// call `setState`.
  bool _built = false;

  bool get _isReceive => _flow == ParcelFlow.receive;

  @override
  void initState() {
    super.initState();
    final order = widget.args.order;
    _flow = switch (order?.type) {
      1 => ParcelFlow.send,
      2 => ParcelFlow.receive,
      _ => widget.args.flow,
    };
    if (order != null) _prefill(order);
    _valueController.addListener(_onAmountChanged);
    _weightController.addListener(_onAmountChanged);

    ref.listenManual(
      orderFormCountriesProvider,
      _onCountries,
      fireImmediately: true,
    );
    ref.listenManual(
      orderFormPaymentMethodsProvider,
      _onPaymentMethods,
      fireImmediately: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _built = true);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _otherNameController.dispose();
    _otherPhoneController.dispose();
    _valueController.dispose();
    _weightController.dispose();
    _customRewardController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ prefill

  void _prefill(ParcelOrder order) {
    _categoryId = order.categoryId;
    _categoryName = order.categoryNameFor(context.languageCode);
    _descriptionController.text = order.description ?? '';
    _notesController.text = order.notes ?? '';

    // Older orders stored free text ("less than $100", "under 1kg"); the
    // number in it, if any, is what the fields can show.
    _valueController.text = _numberIn(order.value);
    _weightController.text = _numberIn(order.weight);

    final reward = _formatTip(order.amount);
    if (reward.isNotEmpty) {
      _reward = reward;
      if (_rewardOptions.contains(reward) &&
          reward != OrderFormRewardSection.other) {
        _rewardChip = reward;
      } else {
        _rewardChip = OrderFormRewardSection.other;
        _customRewardController.text = reward;
      }
    }

    _neededBefore = order.orderDate;
    _neededSoon = order.orderDate == null;
    _sender = order.sender;
    _receiver = order.receiver;

    _otherNameController.text = _isReceive
        ? order.senderName
        : order.receiverName;
    _pendingPhone = _isReceive ? order.senderPhone : order.receiverPhone;
  }

  /// `formatTip` of the Ionic page: "20.00" reads back as "20".
  static String _formatTip(String? raw) {
    final text = (raw ?? '').trim();
    final number = double.tryParse(text);
    if (number == null) return text;
    return number.toStringAsFixed(0);
  }

  /// The first number in a stored value / weight string, else empty.
  static String _numberIn(String? raw) {
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(raw ?? '');
    return match?.group(0) ?? '';
  }

  /// The overview card mirrors the value and weight fields as they are
  /// typed.
  void _onAmountChanged() {
    if (_built && mounted) setState(() {});
  }

  void _onCountries(
    AsyncValue<List<Country>>? previous,
    AsyncValue<List<Country>> next,
  ) {
    if (_countryResolved) return;
    if (next case AsyncData(:final value)) {
      _countryResolved = true;
      final split = _splitPhone(_pendingPhone, value);
      _pendingPhone = null;
      void apply() {
        _country = split.country ?? _defaultCountry(value);
        if (split.number != null) _otherPhoneController.text = split.number!;
      }

      if (_built) {
        setState(apply);
      } else {
        apply();
      }
    }
  }

  static Country? _defaultCountry(List<Country> countries) {
    for (final c in countries) {
      if (c.name == AppConfig.defaultCountryName) return c;
    }
    return countries.isEmpty ? null : countries.first;
  }

  /// Splits a stored `00<code><number>` phone back into its country and
  /// local number (longest matching code wins). Unknown prefixes are kept
  /// verbatim with no country so they are not prefixed twice on save.
  static ({Country? country, String? number}) _splitPhone(
    String? raw,
    List<Country> countries,
  ) {
    if (raw == null) return (country: null, number: null);
    var n = raw.replaceAll(RegExp(r'\s+'), '');
    if (n.startsWith('+')) n = '00${n.substring(1)}';
    if (!n.startsWith('00')) return (country: null, number: n);

    Country? match;
    var matchLength = 0;
    for (final c in countries) {
      final digits = (c.phoneCode ?? '').replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty || digits.length <= matchLength) continue;
      if (n.startsWith('00$digits')) {
        match = c;
        matchLength = digits.length;
      }
    }
    if (match == null) return (country: null, number: n);
    return (country: match, number: n.substring(2 + matchLength));
  }

  void _onPaymentMethods(
    AsyncValue<List<PaymentMethod>>? previous,
    AsyncValue<List<PaymentMethod>> next,
  ) {
    if (_paymentResolved) return;
    if (next case AsyncData(:final value) when value.isNotEmpty) {
      _paymentResolved = true;
      final stored = widget.args.order?.paymentMethod?.trim().toLowerCase();
      PaymentMethod? chosen;
      for (final m in value) {
        if (stored != null &&
            (m.id.toString() == stored ||
                m.code.toLowerCase() == stored ||
                m.name.toLowerCase() == stored)) {
          chosen = m;
          break;
        }
      }
      for (final m in value) {
        if (chosen != null) break;
        if (m.isCash) chosen = m;
      }
      chosen ??= value.first;
      final id = chosen.id;
      if (_built) {
        setState(() => _paymentMethodId = id);
      } else {
        _paymentMethodId = id;
      }
    }
  }

  // ----------------------------------------------------------- derived

  double? get _distanceKm {
    final s = _sender;
    final r = _receiver;
    if (s == null || r == null) return null;
    final km = _haversineKm(s.lat, s.lng, r.lat, r.lng);
    return (km * 100).round() / 100;
  }

  double? get _weightKg => OrderFormAmountField.parse(_weightController.text);

  double? get _valueAmount => OrderFormAmountField.parse(_valueController.text);

  /// The wire strings: value "120", weight "0.5 kg".
  String? get _valueText {
    final amount = _valueAmount;
    return amount == null ? null : OrderFormAmountField.format(amount);
  }

  String? get _weightText {
    final kg = _weightKg;
    if (kg == null) return null;
    return '${OrderFormAmountField.format(kg)} '
        '${OrderFormPackageSection.weightUnit}';
  }

  String get _otherPartyLabel =>
      _isReceive ? context.l10n.pkgSender : context.l10n.pkgReceiver;

  /// `00<code><number>` with no whitespace, as `pview.book()` built it.
  String _otherPhoneFull() {
    var number = _otherPhoneController.text.replaceAll(RegExp(r'\s+'), '');
    if (number.startsWith('+')) number = '00${number.substring(1)}';
    if (number.startsWith('00')) return number;
    final code = _country?.phoneCode?.trim() ?? '';
    if (code.isEmpty) return number;
    return '${code.replaceFirst('+', '00')}$number';
  }

  // ----------------------------------------------------------- actions

  Future<void> _pickAddress({required bool senderSide}) async {
    final result = await context.pushNamed<OrderAddress>(
      Routes.addressPicker.name,
      extra: AddressPickerArgs(
        title: senderSide
            ? context.l10n.pkgSenderAddress
            : context.l10n.pkgReceiverAddress,
        initial: senderSide ? _sender : _receiver,
        isSenderSide: senderSide,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (senderSide) {
        _sender = result;
      } else {
        _receiver = result;
      }
    });
  }

  void _openCarbonCalculator() {
    context.pushNamed(
      Routes.carbonCalculator.name,
      extra: CarbonCalculatorArgs(
        fromCity: _cityOf(_sender),
        toCity: _cityOf(_receiver),
        weightKg: _weightKg,
      ),
    );
  }

  static String? _cityOf(OrderAddress? address) {
    if (address == null) return null;
    final city = address.city?.trim();
    if (city != null && city.isNotEmpty) return city;
    return address.name.trim().isEmpty ? null : address.name;
  }

  Future<void> _pickCountry() async {
    final countries = ref.read(orderFormCountriesProvider).value;
    if (countries == null || countries.isEmpty) {
      AppFeedback.toast(context, context.l10n.pkgCountriesLoading);
      return;
    }
    final picked = await OrderFormCountryPickerSheet.show(
      context,
      countries: countries,
      selected: _country,
    );
    if (!mounted || picked == null) return;
    setState(() => _country = picked);
  }

  void _onCategory(ParcelCategory category) {
    setState(() {
      _categoryId = category.id;
      _categoryName = category.nameFor(context.languageCode);
    });
  }

  void _onRewardChip(String chip) {
    setState(() {
      if (_rewardChip == chip) {
        _rewardChip = null;
        _reward = '';
      } else {
        _rewardChip = chip;
        _reward = chip == OrderFormRewardSection.other
            ? _customRewardController.text.trim()
            : chip;
      }
    });
  }

  void _onAddReward() {
    final custom = _customRewardController.text.trim();
    if (custom.isEmpty) {
      AppFeedback.toast(context, context.l10n.pkgRewardRequired);
      return;
    }
    setState(() => _reward = custom);
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = _neededBefore ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: DateTime(today.year + 2, today.month, today.day),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _neededSoon = false;
      _neededBefore = picked;
    });
  }

  Future<void> _openTerms() async {
    final opened = await launchUrl(
      Uri.parse(_termsUrl),
      mode: LaunchMode.inAppBrowserView,
    );
    if (!opened && mounted) {
      AppFeedback.toast(context, context.l10n.pkgTermsOpenFailed);
    }
  }

  /// The first problem of step 1 (route and parties); null when complete.
  String? _validateWhereAndWho() {
    final l10n = context.l10n;
    if (_sender == null) return l10n.pkgPickupAddressRequired;
    if (_receiver == null) return l10n.pkgDeliveryAddressRequired;
    if (_otherNameController.text.trim().isEmpty) {
      return _isReceive
          ? l10n.pkgSenderNameRequired
          : l10n.pkgReceiverNameRequired;
    }
    if (_otherPhoneController.text.trim().isEmpty) {
      return _isReceive
          ? l10n.pkgSenderPhoneRequired
          : l10n.pkgReceiverPhoneRequired;
    }
    return null;
  }

  /// The first problem, in the order the Ionic `areAllInputsFilled` /
  /// `book()` checks would have caught it; null when the form is complete.
  String? _validate() {
    final whereAndWho = _validateWhereAndWho();
    if (whereAndWho != null) return whereAndWho;
    final l10n = context.l10n;
    if (_categoryId == null) return l10n.pkgPackageTypeRequired;
    if (_valueText == null) return l10n.pkgPackageValueRequired;
    if (_weightText == null) return l10n.pkgWeightRequired;
    if (_reward.isEmpty || _reward == OrderFormRewardSection.other) {
      return l10n.pkgRewardRequired;
    }
    if (!_neededSoon && _neededBefore == null) {
      return l10n.pkgNeededBeforeRequired;
    }
    return null;
  }

  void _goToWhatAndHow() {
    FocusScope.of(context).unfocus();
    final problem = _validateWhereAndWho();
    if (problem != null) {
      AppFeedback.toast(context, problem);
      return;
    }
    setState(() => _step = 1);
  }

  void _goToWhereAndWho() {
    FocusScope.of(context).unfocus();
    setState(() => _step = 0);
  }

  /// The close button: step 2 returns to step 1, step 1 leaves the form.
  void _close() {
    if (_step > 0) {
      _goToWhereAndWho();
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final user = ref.read(currentUserProvider);
    final userId = ref.read(currentUserIdProvider);
    if (user == null || userId == null) {
      AppFeedback.toast(context, context.l10n.pkgLoginRequired);
      return;
    }
    final problem = _validate();
    if (problem != null) {
      AppFeedback.toast(context, problem);
      return;
    }

    final otherName = _otherNameController.text.trim();
    final otherPhone = _otherPhoneFull();
    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

    final draft = ParcelOrderDraft(
      orderId: widget.args.order?.id,
      userId: userId,
      flow: _flow,
      categoryId: _categoryId!,
      senderName: _isReceive ? otherName : user.name,
      senderPhone: _isReceive ? otherPhone : user.phone,
      receiverName: _isReceive ? user.name : otherName,
      receiverPhone: _isReceive ? user.phone : otherPhone,
      sender: _sender!,
      receiver: _receiver!,
      weight: _weightText!,
      reward: _reward,
      paymentMethodId: _paymentMethodId,
      value: _valueText,
      description: description.isEmpty ? null : description,
      notes: notes.isEmpty ? null : notes,
      neededBefore: _neededSoon ? null : _neededBefore,
      distanceKm: _distanceKm,
    );

    final result = await ref
        .read(orderFormSubmitProvider.notifier)
        .submit(draft);
    if (!mounted || result == null) return;
    switch (result) {
      case Success():
        context.goNamed(
          Routes.success.name,
          pathParameters: {'type': '${SuccessType.orderPlaced.code}'},
        );
      case Error(:final error):
        AppFeedback.error(context, error);
    }
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final countries = ref.watch(orderFormCountriesProvider);
    final submitting = ref.watch(orderFormSubmitProvider).isLoading;
    final texts = ref.texts;
    final l10n = context.l10n;
    final isEdit = widget.args.isEdit;

    final contactSection = OrderFormContactSection(
      title: _otherPartyLabel,
      subtitle: _isReceive
          ? l10n.pkgSenderContactSubtitle
          : l10n.pkgReceiverContactSubtitle,
      nameHint: _isReceive ? l10n.pkgSenderName : l10n.pkgReceiverName,
      phoneHint: _isReceive ? l10n.pkgSenderPhone : l10n.pkgReceiverPhone,
      nameController: _otherNameController,
      phoneController: _otherPhoneController,
      country: _country,
      countriesLoading: countries.isLoading,
      onPickCountry: _pickCountry,
    );

    // Built only for a signed-in user; `LoginRequired` shows its own
    // body otherwise.
    Widget? whereAndWho;
    Widget? whatAndHow;
    if (user != null) {
      whereAndWho = ListView(
        key: const ValueKey('order-form-step-1'),
        padding: EdgeInsets.all(context.dimensions.space.s16),
        children: [
          OrderFormRouteCard(
            sender: _sender,
            receiver: _receiver,
            distanceKm: _distanceKm,
            onPickSender: () => _pickAddress(senderSide: true),
            onPickReceiver: () => _pickAddress(senderSide: false),
            onCarbonEstimate: _openCarbonCalculator,
          ),
          if (_isReceive)
            contactSection
          else
            OrderFormSelfCard(
              title: l10n.pkgSender,
              subtitle: l10n.pkgSenderSelfSubtitle,
              user: user,
            ),
          if (_isReceive)
            OrderFormSelfCard(
              title: l10n.pkgReceiver,
              subtitle: l10n.pkgReceiverSelfSubtitle,
              user: user,
            )
          else
            contactSection,
        ],
      );

      whatAndHow = ListView(
        key: const ValueKey('order-form-step-2'),
        padding: EdgeInsets.all(context.dimensions.space.s16),
        children: [
          OrderFormPackageSection(
            selectedCategoryId: _categoryId,
            onCategory: _onCategory,
            descriptionController: _descriptionController,
            valueController: _valueController,
            weightController: _weightController,
          ),
          OrderFormDeliverySection(
            neededSoon: _neededSoon,
            neededBefore: _neededBefore,
            onNeededSoon: () => setState(() => _neededSoon = true),
            onNeededBefore: () {
              setState(() => _neededSoon = false);
              if (_neededBefore == null) _pickDate();
            },
            onPickDate: _pickDate,
          ),
          OrderFormRewardSection(
            options: _rewardOptions,
            rewardChip: _rewardChip,
            onRewardChip: _onRewardChip,
            customRewardController: _customRewardController,
            onAddReward: _onAddReward,
          ),
          OrderFormPaymentSection(
            selectedId: _paymentMethodId,
            onSelect: (method) {
              _paymentResolved = true;
              setState(() => _paymentMethodId = method.id);
            },
          ),
          OrderFormNotesSection(
            notesController: _notesController,
            termsText: texts.get('acc_term', l10n.pkgTermsAcceptance),
            termsLinkText: texts.get('term', l10n.pkgTermsAndConditions),
            onOpenTerms: _openTerms,
          ),
          OrderFormOverviewCard(
            categoryName: _categoryName,
            weight: _weightText,
            value: _valueText,
            reward: _reward == OrderFormRewardSection.other ? null : _reward,
            neededBefore: _neededSoon ? null : _neededBefore,
            distanceKm: _distanceKm,
          ),
        ],
      );
    }

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToWhereAndWho();
      },
      child: Scaffold(
        backgroundColor: context.color.background.canvas,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            _isReceive ? l10n.pkgReceivePackageTitle : l10n.pkgSendPackageTitle,
          ),
          actions: [
            IconButton(
              tooltip: l10n.close,
              icon: const Icon(Icons.close_rounded),
              onPressed: _close,
            ),
          ],
        ),
        body: LoginRequired(
          child: whereAndWho == null || whatAndHow == null
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    OrderFormStepIndicator(
                      steps: [l10n.pkgStepWhereWho, l10n.pkgStepWhatHow],
                      currentStep: _step,
                      onStepTap: (_) => _goToWhereAndWho(),
                    ),
                    Expanded(child: _step == 0 ? whereAndWho : whatAndHow),
                  ],
                ),
        ),
        bottomNavigationBar: user == null
            ? null
            : _step == 0
            ? OrderFormSubmitBar(
                label: l10n.next,
                loading: false,
                onPressed: _goToWhatAndHow,
              )
            : OrderFormSubmitBar(
                label: isEdit ? l10n.pkgUpdatePackage : l10n.pkgCreatePackage,
                loading: submitting,
                onPressed: _submit,
                secondaryLabel: l10n.back,
                onSecondaryPressed: _goToWhereAndWho,
              ),
      ),
    );
  }
}

/// Great-circle distance in kilometres (the Ionic page's `distance()`
/// helper, which used the same spherical formula).
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  if (lat1 == lat2 && lon1 == lon2) return 0;
  const earthRadiusKm = 6371.0088;
  final dLat = _radians(lat2 - lat1);
  final dLon = _radians(lon2 - lon1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadiusKm * math.asin(math.sqrt(a));
}

double _radians(double degrees) => degrees * math.pi / 180;
