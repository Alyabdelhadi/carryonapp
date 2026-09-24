import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/extensions/localization.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../domain/failures/business_failure.dart';
import '../../../core/application_state/session_status_provider/session_status_provider.dart';
import '../../../core/extensions/app_texts_extension.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/login_required_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/account_providers.dart';

/// "Update Account Information": the original `setting` page. Name and
/// phone are shown read-only (they were disabled there, being the
/// identity-verified fields); email, country, city and a new password can
/// change.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _country;
  late final TextEditingController _city;
  late final TextEditingController _password;

  Map<String, String> _fieldErrors = const {};
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _country = TextEditingController(text: user?.country ?? '');
    _city = TextEditingController(text: user?.city ?? '');
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _country.dispose();
    _city.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _submit(AppUser user) async {
    setState(() => _fieldErrors = const {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final result = await ref
        .read(updateProfileUseCaseProvider)
        .call(
          user.id,
          ProfileUpdateInput(
            name: user.name,
            email: _email.text.trim(),
            phone: user.phone,
            country: _optional(_country.text),
            city: _optional(_city.text),
            password: _optional(_password.text),
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        ref
          ..invalidate(currentUserProvider)
          ..invalidate(accountProfileProvider(user.id));
        AppFeedback.toast(context, context.l10n.accAccountUpdated);
        context.pop();
      case Error(:final error):
        if (error is InvalidInput && error.fieldErrors != null) {
          setState(() => _fieldErrors = error.fieldErrors!);
        }
        AppFeedback.error(context, error);
    }
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return context.locale.emailRequired;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    if (!ok) return context.locale.validEmail;
    return _fieldErrors['email'];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final space = context.dimensions.space;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.color.background.canvas,
      appBar: AppBar(title: Text(l10n.accAccountDetails)),
      body: user == null
          ? const LoginRequired(child: SizedBox.shrink())
          : SafeArea(
              child: Form(
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
                    HeadingLevel1Text(l10n.accUpdateAccountInfo),
                    Gap(space.s4),
                    BodySmallText.muted(l10n.accVerifiedFieldsNote),
                    Gap(space.s20),
                    SectionCard(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _name,
                            readOnly: true,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: ref.texts.get(
                                'signup_name',
                                l10n.accName,
                              ),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                          Gap(space.s12),
                          TextFormField(
                            controller: _phone,
                            readOnly: true,
                            enabled: false,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                            decoration: InputDecoration(
                              labelText: ref.texts.get(
                                'signup_phone',
                                l10n.accPhone,
                              ),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                          ),
                          Gap(space.s12),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            validator: _validateEmail,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                            decoration: InputDecoration(
                              labelText: ref.texts.get(
                                'signup_email',
                                l10n.accEmail,
                              ),
                              prefixIcon: const Icon(Icons.mail_outline),
                            ),
                          ),
                          Gap(space.s12),
                          TextFormField(
                            controller: _country,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            validator: (_) => _fieldErrors['country'],
                            decoration: InputDecoration(
                              labelText: l10n.accCountry,
                              prefixIcon: const Icon(Icons.public_outlined),
                            ),
                          ),
                          Gap(space.s12),
                          TextFormField(
                            controller: _city,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            validator: (_) => _fieldErrors['city'],
                            decoration: InputDecoration(
                              labelText: l10n.accCity,
                              prefixIcon: const Icon(
                                Icons.location_city_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(space.s16),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LabelText(l10n.accChangePassword),
                          Gap(space.s4),
                          BodySmallText.muted(l10n.accLeaveEmptyPassword),
                          Gap(space.s12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            validator: (_) => _fieldErrors['password'],
                            onFieldSubmitted: (_) => _submit(user),
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                            decoration: InputDecoration(
                              labelText: l10n.accNewPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(space.s24),
                    FilledButton(
                      onPressed: _saving ? null : () => _submit(user),
                      child: _saving
                          ? const LoadingIndicator()
                          : Text(l10n.accUpdate),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
