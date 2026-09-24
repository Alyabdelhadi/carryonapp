import 'package:flutter/material.dart';
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

/// Password recovery: the registered email receives a reset link. This is
/// the only step of the original page that was reachable — its OTP and
/// new-password forms depended on `user_id`, which nothing ever set, and
/// the backend no longer has those endpoints.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

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
    final ok = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetLink(_email.text.trim());
    if (!ok || !mounted) return;
    AppFeedback.toast(context, l10n.authResetLinkSent);
    _backToLogin();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(forgotPasswordControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) AppFeedback.error(context, error);
    });
    final isLoading = ref.watch(forgotPasswordControllerProvider).isLoading;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _backToLogin,
        ),
      ),
      body: AuthPageLayout(
        title: ref.texts.get('forgot_title', l10n.authForgotPassword),
        subtitle: ref.texts.get('forgot_text', l10n.authForgotSubtitle),
        form: Form(
          key: _formKey,
          child: _ForgotForm(
            email: _email,
            isLoading: isLoading,
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

class _ForgotForm extends ConsumerWidget {
  const _ForgotForm({
    required this.email,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController email;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: email,
          enabled: !isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          onFieldSubmitted: (_) => onSubmit(),
          validator: (value) => (value ?? '').trim().isEmpty
              ? ref.texts.get('enter_email', l10n.authEnterRegisteredEmail)
              : null,
          decoration: InputDecoration(
            labelText: ref.texts.get(
              'enter_email',
              l10n.authEnterRegisteredEmail,
            ),
            prefixIcon: const Icon(Icons.mail_outline_rounded),
          ),
        ),
        Gap(context.dimensions.space.s20),
        FilledButton(
          onPressed: isLoading ? null : onSubmit,
          child: isLoading
              ? SizedBox(
                  width: context.dimensions.size.iconSmall,
                  height: context.dimensions.size.iconSmall,
                  child: CircularProgressIndicator(
                    strokeWidth: context.dimensions.border.lg,
                    color: context.color.text.onPrimary,
                  ),
                )
              : Text(ref.texts.get('reset', l10n.authReset)),
        ),
      ],
    );
  }
}
