import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../core/application_state/app_settings_provider/app_settings_provider.dart';
import '../../../core/extensions/app_texts_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/countries_provider.dart';
import '../riverpod/signup_controller.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/country_code_button.dart';
import '../model/document_normalizer.dart';
import '../widgets/document_upload_tile.dart';
import '../widgets/password_field.dart';
import '../widgets/signup_progress_overlay.dart';
import '../widgets/terms_checkbox.dart';

const _defaultCountryName = 'Lebanon';

/// Account creation: name, phone with country code, email, password, a
/// selfie and an identity document, and the terms consent. Submitting runs
/// the identity check and then creates the account. In live verification
/// mode only the selfie (profile photo) is asked for: the identity check
/// happens afterwards on Shufti's page (see `VerifyIdentityPage`).
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  Country? _pickedCountry;
  PickedDocument? _selfie;
  PickedDocument? _identity;
  bool _agreed = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// The picked country, or the default one once the list has loaded.
  Country? _country(List<Country> countries) {
    if (_pickedCountry != null) return _pickedCountry;
    for (final c in countries) {
      if (c.name == _defaultCountryName) return c;
    }
    return countries.isEmpty ? null : countries.first;
  }

  /// "+961" + "70123456" -> "0096170123456", the backend's convention. With
  /// no country loaded the raw number goes through, as the original did.
  String _fullPhone(Country? country) {
    final number = _phone.text.trim();
    final code = country?.phoneCode;
    if (code == null || code.isEmpty) return number;
    return '${code.replaceFirst('+', '00')}$number';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final live = ref.read(appSettingsProvider).value?.shuftiLive ?? false;
    final selfie = _selfie;
    final identity = live ? null : _identity;
    if (selfie == null) {
      AppFeedback.toast(
        context,
        live
            ? context.l10n.authUploadSelfie
            : context.l10n.authUploadBothDocuments,
      );
      return;
    }
    if (!live && identity == null) {
      AppFeedback.toast(context, context.l10n.authUploadBothDocuments);
      return;
    }
    FocusScope.of(context).unfocus();
    final country = _country(ref.read(countriesProvider).value ?? const []);
    final ok = await ref
        .read(signupControllerProvider.notifier)
        .signup(
          SignupInput(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _fullPhone(country),
            password: _password.text,
            selfiePath: selfie.path,
            identityPath: identity?.path,
          ),
          checksIdentity: !live,
        );
    if (!ok || !mounted) return;
    context.goNamed(Routes.account.name);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(signupControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) AppFeedback.error(context, error);
    });
    final country = _country(ref.watch(countriesProvider).value ?? const []);
    final state = ref.watch(signupControllerProvider);
    final step = state.value;
    final isBusy = step != null;
    final live = ref.watch(appSettingsProvider).value?.shuftiLive ?? false;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: isBusy
              ? null
              : () => context.canPop()
                    ? context.pop()
                    : context.goNamed(Routes.home.name),
        ),
      ),
      body: Stack(
        children: [
          AuthPageLayout(
            title: ref.texts.get('signup_title', l10n.authSignupTitle),
            subtitle: ref.texts.get('signup_desc', l10n.authSignupSubtitle),
            form: Form(
              key: _formKey,
              child: _SignupForm(
                name: _name,
                phone: _phone,
                email: _email,
                password: _password,
                country: country,
                selfie: _selfie,
                identity: _identity,
                askIdentity: !live,
                agreed: _agreed,
                enabled: !isBusy,
                onCountry: (c) => setState(() => _pickedCountry = c),
                onSelfie: (f) => setState(() => _selfie = f),
                onIdentity: (f) => setState(() => _identity = f),
                onAgreed: (v) => setState(() => _agreed = v),
                onSubmit: _submit,
              ),
            ),
          ),
          if (isBusy)
            Positioned.fill(
              child: SignupProgressOverlay(step: step, checksIdentity: !live),
            ),
        ],
      ),
    );
  }
}

class _SignupForm extends ConsumerWidget {
  const _SignupForm({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.country,
    required this.selfie,
    required this.identity,
    required this.askIdentity,
    required this.agreed,
    required this.enabled,
    required this.onCountry,
    required this.onSelfie,
    required this.onIdentity,
    required this.onAgreed,
    required this.onSubmit,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController password;
  final Country? country;
  final PickedDocument? selfie;
  final PickedDocument? identity;

  /// False in live verification mode: the ID is scanned after signup.
  final bool askIdentity;
  final bool agreed;
  final bool enabled;
  final ValueChanged<Country> onCountry;
  final ValueChanged<PickedDocument?> onSelfie;
  final ValueChanged<PickedDocument?> onIdentity;
  final ValueChanged<bool> onAgreed;
  final VoidCallback onSubmit;

  String? _required(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = context.dimensions.space;
    final l10n = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: name,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (v) => _required(v, l10n.authFullNameRequired),
            decoration: InputDecoration(
              hintText: l10n.authFullName,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          Gap(space.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CountryCodeButton(
                selected: country,
                onSelected: onCountry,
                enabled: enabled,
              ),
              Gap(space.s8),
              Expanded(
                child: TextFormField(
                  controller: phone,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  validator: (v) => _required(v, l10n.authPhoneRequired),
                  decoration: InputDecoration(hintText: l10n.authPhoneNumber),
                ),
              ),
            ],
          ),
          Gap(space.s12),
          TextFormField(
            controller: email,
            enabled: enabled,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            validator: (v) => _required(v, l10n.emailRequired),
            decoration: InputDecoration(
              hintText: ref.texts.get('signup_email', l10n.authEmail),
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
          ),
          Gap(space.s12),
          PasswordField(
            controller: password,
            enabled: enabled,
            hint: l10n.authPassword,
            textInputAction: TextInputAction.done,
            validator: (v) => _required(v, l10n.passwordRequired),
          ),
          Gap(space.s20),
          DocumentUploadTile(
            icon: Icons.face_rounded,
            title: l10n.authSelfieTitle,
            subtitle: l10n.authSelfieSubtitle,
            file: selfie,
            onChanged: onSelfie,
            preferFrontCamera: true,
            enabled: enabled,
          ),
          if (askIdentity) ...[
            Gap(space.s12),
            DocumentUploadTile(
              icon: Icons.badge_outlined,
              title: l10n.authIdentityTitle,
              subtitle: l10n.authIdentitySubtitle,
              file: identity,
              onChanged: onIdentity,
              allowPdf: true,
              enabled: enabled,
            ),
          ],
          Gap(space.s16),
          TermsCheckbox(
            value: agreed,
            onChanged: enabled ? onAgreed : null,
            agreeLabel: ref.texts.get('i_agree', l10n.authAgreeToThe),
            termsLabel: ref.texts.get('terms', l10n.authTermsAndConditions),
          ),
          Gap(space.s8),
          const _SecurityNote(),
          Gap(space.s20),
          FilledButton.icon(
            onPressed: enabled && agreed ? onSubmit : null,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(ref.texts.get('signup_btn', l10n.signUp)),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.shield_outlined,
          size: context.dimensions.size.iconLarge,
          color: context.color.status.success,
        ),
        Gap(context.dimensions.space.s8),
        Expanded(child: BodySmallText.muted(context.l10n.authSecurityNote)),
      ],
    );
  }
}
