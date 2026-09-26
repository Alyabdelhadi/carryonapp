import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/result.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../domain/failures/business_failure.dart';
import '../../../../domain/use_cases/auth_use_case.dart';

/// The three steps of "Forgot password".
enum ForgotPasswordStep { email, code, password }

class ForgotPasswordState {
  const ForgotPasswordState({
    this.step = ForgotPasswordStep.email,
    this.email = '',
    this.ticket,
    this.resendAt,
    this.busy = false,
    this.error,
  });

  final ForgotPasswordStep step;
  final String email;

  /// Set once the code was accepted.
  final PasswordResetTicket? ticket;

  /// When the backend allows another code to be sent.
  final DateTime? resendAt;
  final bool busy;

  /// The last failure, for the page to show once.
  final BusinessFailure? error;

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    String? email,
    PasswordResetTicket? ticket,
    DateTime? resendAt,
    bool? busy,
    BusinessFailure? error,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      email: email ?? this.email,
      ticket: ticket ?? this.ticket,
      resendAt: resendAt ?? this.resendAt,
      busy: busy ?? this.busy,
      error: error,
    );
  }
}

/// Email -> 6-digit code -> new password.
final forgotPasswordControllerProvider =
    NotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
      ForgotPasswordController.new,
    );

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  PasswordResetUseCase get _useCase => ref.read(passwordResetUseCaseProvider);

  /// Emails a code to [email] (also used for "Resend code").
  Future<bool> requestCode(String email, String languageCode) async {
    state = state.copyWith(busy: true);
    final result = await _useCase.requestCode(
      email: email,
      languageCode: languageCode,
    );
    if (!ref.mounted) return false;
    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          step: ForgotPasswordStep.code,
          email: email,
          resendAt: DateTime.now().add(Duration(seconds: data)),
          busy: false,
        );
        return true;
      case Error(:final error):
        state = state.copyWith(busy: false, error: error);
        return false;
    }
  }

  Future<void> verifyCode(String code) async {
    state = state.copyWith(busy: true);
    final result = await _useCase.verifyCode(email: state.email, code: code);
    if (!ref.mounted) return;
    state = switch (result) {
      Success(:final data) => state.copyWith(
        step: ForgotPasswordStep.password,
        ticket: data,
        busy: false,
      ),
      Error(:final error) => _failed(error),
    };
  }

  /// Resolves true once the password changed.
  Future<bool> resetPassword(String password) async {
    final ticket = state.ticket;
    if (ticket == null) return false;
    state = state.copyWith(busy: true);
    final result = await _useCase.resetPassword(
      ticket: ticket,
      password: password,
    );
    if (!ref.mounted) return false;
    switch (result) {
      case Success():
        state = state.copyWith(busy: false);
        return true;
      case Error(:final error):
        state = _failed(error);
        return false;
    }
  }

  /// Back to the email step (typo in the address, or a dead code).
  void restart() => state = ForgotPasswordState(email: state.email);

  /// A dead code or session sends the user back to request a new code.
  ForgotPasswordState _failed(BusinessFailure error) {
    final restart = switch (error.cause) {
      PasswordResetFailure(kind: PasswordResetFailureKind.invalidCode) => false,
      PasswordResetFailure() => true,
      _ => false,
    };
    return restart
        ? ForgotPasswordState(email: state.email, error: error)
        : state.copyWith(busy: false, error: error);
  }
}
