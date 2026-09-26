import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/extensions/app_texts_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/feedback.dart';
import '../riverpod/forgot_password_controller.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/password_field.dart';

const _minPasswordLength = 6;

/// Password recovery by emailed code: the registered email receives a
/// 6-digit code, the code unlocks a new-password form, and the user goes
/// back to login with the new password.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // repaint the resend countdown
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  ForgotPasswordController get _controller =>
      ref.read(forgotPasswordControllerProvider.notifier);

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.account.name);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    switch (ref.read(forgotPasswordControllerProvider).step) {
      case ForgotPasswordStep.email:
        final sent = await _controller.requestCode(
          _email.text.trim(),
          Localizations.localeOf(context).languageCode,
        );
        if (sent && mounted) AppFeedback.toast(context, l10n.pwdCodeSentToast);
      case ForgotPasswordStep.code:
        await _controller.verifyCode(_code.text.trim());
      case ForgotPasswordStep.password:
        final changed = await _controller.resetPassword(_password.text);
        if (!changed || !mounted) return;
        AppFeedback.toast(context, l10n.pwdChangedToast);
        _backToLogin();
    }
  }

  Future<void> _resend() async {
    _code.clear();
    final l10n = context.l10n;
    final sent = await _controller.requestCode(
      ref.read(forgotPasswordControllerProvider).email,
      Localizations.localeOf(context).languageCode,
    );
    if (sent && mounted) AppFeedback.toast(context, l10n.pwdCodeSentToast);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(forgotPasswordControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(error, previous?.error)) {
        AppFeedback.error(context, error);
      }
      if (previous?.step != next.step &&
          next.step == ForgotPasswordStep.email) {
        _code.clear();
      }
    });
    final state = ref.watch(forgotPasswordControllerProvider);
    final l10n = context.l10n;

    final (title, subtitle) = switch (state.step) {
      ForgotPasswordStep.email => (
        ref.texts.get('forgot_title', l10n.authForgotPassword),
        ref.texts.get('forgot_text', l10n.authForgotSubtitle),
      ),
      ForgotPasswordStep.code => (
        l10n.pwdCodeTitle,
        l10n.pwdCodeSubtitle(state.email),
      ),
      ForgotPasswordStep.password => (l10n.pwdNewTitle, l10n.pwdNewSubtitle),
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _backToLogin,
        ),
      ),
      body: AuthPageLayout(
        title: title,
        subtitle: subtitle,
        form: Form(
          key: _formKey,
          child: AnimatedSwitcher(
            duration: kThemeAnimationDuration,
            child: switch (state.step) {
              ForgotPasswordStep.email => _EmailStep(
                key: const ValueKey('email'),
                email: _email,
                busy: state.busy,
                onSubmit: _submit,
              ),
              ForgotPasswordStep.code => _CodeStep(
                key: const ValueKey('code'),
                code: _code,
                busy: state.busy,
                resendIn: _secondsUntil(state.resendAt),
                onSubmit: _submit,
                onResend: _resend,
                onChangeEmail: _controller.restart,
              ),
              ForgotPasswordStep.password => _PasswordStep(
                key: const ValueKey('password'),
                password: _password,
                confirm: _confirm,
                busy: state.busy,
                onSubmit: _submit,
              ),
            },
          ),
        ),
      ),
    );
  }

  static int _secondsUntil(DateTime? at) {
    if (at == null) return 0;
    final left = at.difference(DateTime.now()).inSeconds;
    return left > 0 ? left : 0;
  }
}

class _EmailStep extends ConsumerWidget {
  const _EmailStep({
    super.key,
    required this.email,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController email;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final label = ref.texts.get('enter_email', l10n.authEnterRegisteredEmail);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: email,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          onFieldSubmitted: (_) => onSubmit(),
          validator: (value) => (value ?? '').trim().isEmpty ? label : null,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.mail_outline_rounded),
          ),
        ),
        Gap(context.dimensions.space.s20),
        _SubmitButton(label: l10n.pwdSendCode, busy: busy, onPressed: onSubmit),
      ],
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({
    super.key,
    required this.code,
    required this.busy,
    required this.resendIn,
    required this.onSubmit,
    required this.onResend,
    required this.onChangeEmail,
  });

  final TextEditingController code;
  final bool busy;
  final int resendIn;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: code,
          enabled: !busy,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: context.textStyle.heading.level1.copyWith(letterSpacing: 12),
          onChanged: (value) {
            if (value.length == 6) onSubmit();
          },
          onFieldSubmitted: (_) => onSubmit(),
          validator: (value) =>
              (value ?? '').length == 6 ? null : l10n.pwdCodeRequired,
          decoration: InputDecoration(
            labelText: l10n.pwdCodeLabel,
            counterText: '',
            prefixIcon: const Icon(Icons.pin_outlined),
          ),
        ),
        Gap(context.dimensions.space.s20),
        _SubmitButton(label: l10n.pwdVerify, busy: busy, onPressed: onSubmit),
        Gap(context.dimensions.space.s8),
        TextButton(
          onPressed: busy || resendIn > 0 ? null : onResend,
          child: Text(
            resendIn > 0 ? l10n.pwdResendIn(resendIn) : l10n.pwdResend,
          ),
        ),
        TextButton(
          onPressed: busy ? null : onChangeEmail,
          child: Text(l10n.pwdChangeEmail),
        ),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    super.key,
    required this.password,
    required this.confirm,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController password;
  final TextEditingController confirm;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PasswordField(
            controller: password,
            enabled: !busy,
            hint: l10n.pwdNewPassword,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v ?? '').length < _minPasswordLength ? l10n.pwdTooShort : null,
          ),
          Gap(context.dimensions.space.s12),
          PasswordField(
            controller: confirm,
            enabled: !busy,
            hint: l10n.pwdConfirmPassword,
            textInputAction: TextInputAction.done,
            validator: (v) => v != password.text ? l10n.pwdMismatch : null,
          ),
          Gap(context.dimensions.space.s20),
          _SubmitButton(label: l10n.pwdSave, busy: busy, onPressed: onSubmit),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? SizedBox(
              width: context.dimensions.size.iconSmall,
              height: context.dimensions.size.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: context.dimensions.border.lg,
                color: context.color.text.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}
