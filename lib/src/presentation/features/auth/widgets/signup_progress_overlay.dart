import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/text/typography.dart';
import '../riverpod/signup_controller.dart';

/// The blocking progress card shown while the signup runs, listing the two
/// steps of the original flow ("Verifying identity...", then "Creating
/// account...") with the current one highlighted. Live verification mode
/// has no identity step at signup, so only the second row shows.
class SignupProgressOverlay extends StatelessWidget {
  const SignupProgressOverlay({
    super.key,
    required this.step,
    this.checksIdentity = true,
  });

  final SignupStep step;
  final bool checksIdentity;

  @override
  Widget build(BuildContext context) {
    final space = context.dimensions.space;
    return ColoredBox(
      color: context.color.background.scrim,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(space.s24),
          child: SectionCard(
            padding: EdgeInsets.all(space.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                Gap(space.s20),
                if (checksIdentity) ...[
                  _StepRow(
                    label: context.l10n.authVerifyingIdentity,
                    state: _stateFor(SignupStep.verifyingIdentity),
                  ),
                  Gap(space.s8),
                ],
                _StepRow(
                  label: context.l10n.authCreatingAccount,
                  state: _stateFor(SignupStep.creatingAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StepState _stateFor(SignupStep own) {
    if (own.index < step.index) return _StepState.done;
    if (own == step) return _StepState.active;
    return _StepState.pending;
  }
}

enum _StepState { done, active, pending }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      .done => Icon(
        Icons.check_circle_rounded,
        size: context.dimensions.size.iconMedium,
        color: context.color.status.success,
      ),
      .active => Icon(
        Icons.radio_button_checked_rounded,
        size: context.dimensions.size.iconMedium,
        color: context.color.primary.strong,
      ),
      .pending => Icon(
        Icons.radio_button_unchecked_rounded,
        size: context.dimensions.size.iconMedium,
        color: context.color.text.muted,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        Gap(context.dimensions.space.s8),
        state == .pending ? LabelText.muted(label) : LabelText(label),
      ],
    );
  }
}
