/// The one place a domain answer becomes a sentence.
///
/// Every mapping is exhaustive by construction — a `switch` over an enum with
/// no default — so adding a failure to the domain is a compile error here
/// rather than a blank line on a screen.
///
/// Nothing in this file interpolates a value the user typed. An address, a
/// code or a password never reaches a message: the messages are fixed strings,
/// and the only interpolations in the whole flow are a display name, a step
/// number and a countdown.
library;

import '../../../l10n/app_localizations.dart';
import '../application/auth_flow_controller.dart';
import '../domain/auth_model.dart';
import '../domain/password_policy.dart';

extension LumeAuthIssueText on LumeAuthIssue {
  String message(AppLocalizations l) => switch (this) {
    LumeAuthIssue.emailRequired => l.authErrEmailRequired,
    LumeAuthIssue.emailInvalid => l.authErrEmailInvalid,
    LumeAuthIssue.emailTaken => l.authErrEmailTaken,
    LumeAuthIssue.emailSame => l.authErrEmailSame,
    LumeAuthIssue.passwordRequired => l.authErrPasswordRequired,
    LumeAuthIssue.passwordWeak => l.authErrPasswordWeak,
    LumeAuthIssue.confirmRequired => l.authErrConfirmRequired,
    LumeAuthIssue.confirmMismatch => l.authErrConfirmMismatch,
    LumeAuthIssue.codeRequired => l.authErrCodeRequired,
    LumeAuthIssue.codeIncorrect => l.authErrCodeIncorrect,
  };
}

extension LumeAuthFailureText on LumeAuthFailure {
  String message(AppLocalizations l) => switch (this) {
    LumeAuthFailure.credentials => l.authErrCredentials,
    LumeAuthFailure.locked => l.authErrLocked,
    LumeAuthFailure.linkInvalid => l.authErrLinkInvalid,
    LumeAuthFailure.linkExpired => l.authErrLinkExpired,
    LumeAuthFailure.codeExpired => l.authErrCodeExpired,
    LumeAuthFailure.nothingPending => l.authErrNothingPending,
    LumeAuthFailure.rateLimited => l.authErrRateLimited,
    LumeAuthFailure.network => l.authErrNetwork,
    LumeAuthFailure.storage => l.authErrStorage,
    LumeAuthFailure.signedOut => l.authErrSignedOut,
  };
}

extension LumePasswordRuleText on LumePasswordRule {
  String label(AppLocalizations l) => switch (this) {
    LumePasswordRule.length => l.authPasswordRuleLength,
    LumePasswordRule.upper => l.authPasswordRuleUpper,
    LumePasswordRule.lower => l.authPasswordRuleLower,
    LumePasswordRule.digit => l.authPasswordRuleDigit,
  };
}

extension LumePasswordStrengthText on LumePasswordStrength {
  String label(AppLocalizations l) => switch (this) {
    LumePasswordStrength.none => l.authStrength0,
    LumePasswordStrength.weak => l.authStrength1,
    LumePasswordStrength.fair => l.authStrength2,
    LumePasswordStrength.good => l.authStrength3,
    LumePasswordStrength.strong => l.authStrength4,
  };
}

extension LumeTroubleReasonText on LumeTroubleReason {
  String message(AppLocalizations l) => switch (this) {
    LumeTroubleReason.linkInvalid => l.authTroubleText,
    LumeTroubleReason.linkExpired => l.authTroubleExpired,
  };
}

extension LumeAuthRouteText on LumeAuthRoute {
  /// What the screen announces itself as. One host, eleven screens — a fixed
  /// label would announce the same thing for all of them.
  String title(AppLocalizations l, {int step = 1}) => switch (this) {
    LumeAuthRoute.signIn => l.authSignInTitle,
    LumeAuthRoute.signUp =>
      step == 2 ? l.authSignUpPasswordTitle : l.authSignUpTitle,
    LumeAuthRoute.forgot => l.authForgotTitle,
    LumeAuthRoute.sent => l.authSentTitle,
    LumeAuthRoute.reset => l.authResetTitle,
    LumeAuthRoute.updated => l.authUpdatedTitle,
    LumeAuthRoute.created => l.authCreatedTitle,
    LumeAuthRoute.expired => l.authExpiredTitle,
    LumeAuthRoute.trouble => l.authTroubleTitle,
    LumeAuthRoute.verify => l.authVerifyTitle,
  };
}
