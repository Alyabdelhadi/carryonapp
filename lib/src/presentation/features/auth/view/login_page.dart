import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/localization.dart';
import '../../../../domain/failures/business_failure.dart';
import '../../../core/application_state/localization_provider/localization_provider.dart';
import '../../../core/extensions/app_texts_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/language_sheet.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/login_controller.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/password_field.dart';

/// Email + password sign-in. As the body of the Account tab
/// ([embeddedInTab]) it has no chrome and the tab re-renders as the account
/// screen once the session exists; pushed full-screen it closes itself.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.embeddedInTab = false});

  final bool embeddedInTab;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      AppFeedback.toast(
        context,
        ref.texts.get('login_validation', context.l10n.authLoginValidation),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(loginControllerProvider.notifier)
        .login(email: email, password: password);
    if (!ok || !mounted || widget.embeddedInTab) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.account.name);
    }
  }

  void _onFailure(Object error) {
    // The original page answered every rejected login with its own copy;
    // connection problems keep the generic mapped message.
    if (error is InvalidInput) {
      AppFeedback.toast(
        context,
        ref.texts.get('login_error', context.l10n.authLoginError),
      );
      return;
    }
    AppFeedback.error(context, error);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) _onFailure(error);
    });
    final isLoading = ref.watch(loginControllerProvider).isLoading;
    final l10n = context.l10n;
    final space = context.dimensions.space;

    final body = AuthPageLayout(
      title: ref.texts.get(
        'welcome_back',
        l10n.authWelcomeTitle(l10n.appTitle),
      ),
      subtitle: ref.texts.get('login_title', l10n.authLoginSubtitle),
      form: _LoginForm(
        email: _email,
        password: _password,
        isLoading: isLoading,
        onSubmit: _submit,
      ),
      footer: _SignupPrompt(enabled: !isLoading),
    );

    if (widget.embeddedInTab) {
      // No app bar here, so the language switch floats over the page.
      return Stack(
        children: [
          body,
          PositionedDirectional(
            top: space.s8,
            end: space.s8,
            child: const SafeArea(child: _LanguageButton()),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [const _LanguageButton(), Gap(space.s8)],
      ),
      body: body,
    );
  }
}

/// A light pill showing the current language; opens the [LanguageSheet]
/// so a signed-out user can switch before logging in.
class _LanguageButton extends ConsumerWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localizationProvider);
    final space = context.dimensions.space;
    return Material(
      color: context.color.background.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: context.color.border.defaultValue,
          width: context.dimensions.border.xs,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => LanguageSheet.show(context),
        child: Tooltip(
          message: context.l10n.language,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: space.s12,
              vertical: space.s8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language_rounded,
                  size: context.dimensions.size.iconSmall,
                  color: context.color.text.muted,
                ),
                Gap(space.s4),
                LabelText(LanguageSheet.nativeName(locale)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends ConsumerWidget {
  const _LoginForm({
    required this.email,
    required this.password,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = context.dimensions.space;
    final l10n = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: email,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              hintText: ref.texts.get('login_email', l10n.authEmail),
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
          ),
          Gap(space.s12),
          PasswordField(
            controller: password,
            enabled: !isLoading,
            hint: ref.texts.get('login_password', l10n.authPassword),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
          Gap(space.s4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : () => context.pushNamed(Routes.forgotPassword.name),
              child: Text(ref.texts.get('reset_here', l10n.authForgotPassword)),
            ),
          ),
          Gap(space.s12),
          FilledButton.icon(
            onPressed: isLoading ? null : onSubmit,
            iconAlignment: IconAlignment.end,
            icon: isLoading
                ? SizedBox(
                    width: context.dimensions.size.iconSmall,
                    height: context.dimensions.size.iconSmall,
                    child: CircularProgressIndicator(
                      strokeWidth: context.dimensions.border.lg,
                      color: context.color.text.onPrimary,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(ref.texts.get('login_button', l10n.login)),
          ),
        ],
      ),
    );
  }
}

class _SignupPrompt extends ConsumerWidget {
  const _SignupPrompt({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BodySmallText(
          ref.texts.get('dont_have', l10n.authJoinPrompt(l10n.appTitle)),
          textAlign: TextAlign.center,
        ),
        Gap(context.dimensions.space.s12),
        OutlinedButton.icon(
          onPressed: enabled
              ? () => context.pushNamed(Routes.signup.name)
              : null,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(ref.texts.get('signup_now', l10n.signUp)),
        ),
      ],
    );
  }
}
