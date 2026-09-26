import '../../../core/gen/l10n/app_localizations.dart';
import '../../../domain/entities/auth_inputs.dart';
import '../../../domain/failures/business_failure.dart';
import 'failure_ui_model.dart';

/// The presentation boundary of the failure pipeline: translates a
/// [BusinessFailure] into finished, localized copy plus a recovery
/// action. The exhaustive switch means a new [BusinessFailure] variant
/// does not compile until it receives a UI treatment here.
///
/// Takes the generated [AppLocalizations] object rather than a
/// `BuildContext`, so the mapper stays a pure function and unit tests
/// construct a lookup class (for example `AppLocalizationsEn`) directly.
///
/// A server-provided [BusinessFailure.message] takes precedence over the
/// generic localized copy — it is more specific, even if it arrives in
/// the server's language.
abstract final class BusinessFailureUIMapper {
  static FailureUIModel map(BusinessFailure failure, AppLocalizations l10n) {
    if (failure.cause case IdentityVerificationFailure(
      :final kind,
      :final detail,
    )) {
      return FailureUIModel(
        message: switch (kind) {
          IdentityVerificationFailureKind.declined => l10n.identityDeclined,
          IdentityVerificationFailureKind.invalid =>
            detail == null
                ? l10n.identityUnreadable
                : l10n.identityUnreadableDetail(detail),
          IdentityVerificationFailureKind.unreachable =>
            l10n.identityUnreachable,
          IdentityVerificationFailureKind.liveRequired =>
            l10n.identityLiveRequired,
        },
        action:
            kind == IdentityVerificationFailureKind.unreachable ||
                kind == IdentityVerificationFailureKind.liveRequired
            ? .retry
            : .inlineFields,
      );
    }
    if (failure.cause case PasswordResetFailure(:final kind)) {
      return FailureUIModel(
        message: switch (kind) {
          PasswordResetFailureKind.invalidCode => l10n.pwdCodeInvalid,
          PasswordResetFailureKind.expiredCode => l10n.pwdCodeExpired,
          PasswordResetFailureKind.tooManyAttempts => l10n.pwdCodeLocked,
          PasswordResetFailureKind.sessionExpired => l10n.pwdSessionExpired,
        },
        action: .inlineFields,
      );
    }
    return switch (failure) {
      Unauthenticated() => FailureUIModel(
        message: failure.message ?? l10n.failureUnauthenticated,
        action: .reauthenticate,
      ),
      PermissionDenied() => FailureUIModel(
        message: failure.message ?? l10n.failurePermissionDenied,
        action: .none,
      ),
      Unreachable() => FailureUIModel(
        message: failure.message ?? l10n.failureUnreachable,
        action: .retry,
      ),
      InvalidInput(:final fieldErrors) => FailureUIModel(
        message: failure.message ?? l10n.failureInvalidInput,
        action: .inlineFields,
        fieldErrors: fieldErrors,
      ),
      NotFound() => FailureUIModel(
        message: failure.message ?? l10n.failureNotFound,
        action: .none,
      ),
      Conflict() => FailureUIModel(
        message: failure.message ?? l10n.failureConflict,
        action: .retry,
      ),
      Cancelled() => FailureUIModel(
        message: failure.message ?? l10n.failureCancelled,
        action: .none,
      ),
      Unexpected() => FailureUIModel(
        message: failure.message ?? l10n.failureUnexpected,
        action: .retry,
      ),
      Defect() => FailureUIModel(
        message: l10n.failureUnexpected,
        action: .none,
      ),
    };
  }

  /// The degradation target for errors that are not a [BusinessFailure]
  /// at all — generic copy, retry offered.
  static FailureUIModel unexpected(AppLocalizations l10n) {
    return FailureUIModel(message: l10n.failureUnexpected, action: .retry);
  }
}
