/// The rules, without a widget in sight.
///
/// This is the suite a Dayroz adapter has to satisfy when it replaces the
/// double: what counts as an address, what counts as a password, what a
/// refusal is allowed to reveal, and what a session is when it has run out.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/auth/domain/auth_model.dart';
import 'package:lume/features/auth/domain/password_policy.dart';

import 'auth_harness.dart';

void main() {
  group('what counts as an address', () {
    test('accepts the shapes people actually have', () {
      for (final String value in <String>[
        'a@b.co',
        'amina.tariq@example.com',
        "o'neill+lume@sub.domain.example",
        'user_name-99@example.co.uk',
      ]) {
        expect(LumeEmailPolicy.isValid(value), isTrue, reason: value);
      }
    });

    test('refuses the shapes that cannot be sent to', () {
      for (final String value in <String>[
        '',
        '   ',
        'nobody',
        'nobody@',
        '@example.com',
        'two@@example.com',
        'spaces in@example.com',
        'trailing@example.',
      ]) {
        expect(LumeEmailPolicy.isValid(value), isFalse, reason: '"$value"');
      }
    });

    test('the two lengths the specification names', () {
      expect(LumeEmailPolicy.isValid('${'a' * 64}@example.com'), isTrue);
      expect(LumeEmailPolicy.isValid('${'a' * 65}@example.com'), isFalse);
      expect(LumeEmailPolicy.isValid('${'a' * 250}@example.com'), isFalse);
    });

    test('normalising is trim and lower case, and nothing else', () {
      expect(
        LumeEmailPolicy.normalise('  Amina@Example.COM '),
        'amina@example.com',
      );
    });
  });

  group('masking an address', () {
    test('keeps the first character and the whole domain', () {
      expect(LumeEmailPolicy.mask('amina@example.com'), 'a••••@example.com');
    });

    test('never gives away more than five characters of length', () {
      // Two addresses of very different length mask identically past five, so
      // the bullet count cannot be counted back into a name.
      expect(
        LumeEmailPolicy.mask('a${'b' * 40}@example.com'),
        LumeEmailPolicy.mask('a${'b' * 12}@example.com'),
      );
    });

    test('a single-character local part still masks', () {
      expect(LumeEmailPolicy.mask('a@example.com'), 'a•@example.com');
    });

    test('something that is not an address is left alone', () {
      expect(LumeEmailPolicy.mask('nobody'), 'nobody');
      expect(LumeEmailPolicy.mask('@example.com'), '@example.com');
    });
  });

  group('the password rules', () {
    test('the checklist is four rules, in the drawn order', () {
      expect(
        LumePasswordPolicy.checks('').map((LumePasswordCheck c) => c.rule),
        <LumePasswordRule>[
          LumePasswordRule.length,
          LumePasswordRule.upper,
          LumePasswordRule.lower,
          LumePasswordRule.digit,
        ],
      );
    });

    test('what the screen shows is what a submission enforces', () {
      for (final String password in <String>[
        '',
        'short1A',
        'alllowercase1',
        'ALLUPPERCASE1',
        'NoDigitsHere',
      ]) {
        final bool everyRule = LumePasswordPolicy.checks(
          password,
        ).every((LumePasswordCheck c) => c.met);
        expect(
          LumePasswordPolicy.isAcceptable(password),
          everyRule,
          reason: password,
        );
        expect(everyRule, isFalse, reason: password);
      }
      expect(LumePasswordPolicy.isAcceptable('Passw0rdy'), isTrue);
    });

    test('the meter never reads better than Fair while a rule is unmet', () {
      // Long, punctuated and entirely lower case: plenty of bonus, one rule
      // short. It used to read "Good" beside two unticked rows and was then
      // refused on submission.
      const String flattering = 'aaaaaaaaaaaa!';
      expect(LumePasswordPolicy.isAcceptable(flattering), isFalse);
      expect(
        LumePasswordPolicy.segments(LumePasswordPolicy.strength(flattering)),
        lessThanOrEqualTo(2),
      );
    });

    test('an empty field is its own state, not weak', () {
      expect(LumePasswordPolicy.strength(''), LumePasswordStrength.none);
      expect(LumePasswordPolicy.segments(LumePasswordStrength.none), 0);
    });

    test('meeting every rule reads at least Good', () {
      expect(
        LumePasswordPolicy.segments(LumePasswordPolicy.strength('Passw0rdy')),
        greaterThanOrEqualTo(3),
      );
      expect(
        LumePasswordPolicy.strength('Passw0rdy!Longer'),
        LumePasswordStrength.strong,
      );
    });
  });

  group('a session', () {
    final DateTime now = DateTime(2026, 9, 12, 16, 41);
    LumeSession at(DateTime expires, {bool revoked = false}) => LumeSession(
      email: kTestEmail,
      deviceId: 'dev',
      issued: now,
      expires: expires,
      revoked: revoked,
    );

    test('is live until its expiry and not a moment after', () {
      expect(at(now.add(const Duration(seconds: 1))).isExpiredAt(now), isFalse);
      expect(at(now).isExpiredAt(now), isTrue, reason: 'the closing moment');
      expect(
        at(now.subtract(const Duration(seconds: 1))).isExpiredAt(now),
        isTrue,
      );
    });

    test('a revoked session is expired however far off its expiry is', () {
      expect(
        at(now.add(const Duration(days: 30)), revoked: true).isExpiredAt(now),
        isTrue,
        reason: 'signed out from another device, or the password changed',
      );
    });
  });

  group('the repository', () {
    test('one answer for an unknown account and a wrong password', () async {
      final LumeFakeAuthRepository repo = fakeAuth();
      final LumeAuthResult unknown = await repo.signIn(
        email: 'nobody@example.com',
        password: 'Passw0rdy',
      );
      final LumeAuthResult wrong = await repo.signIn(
        email: kTestEmail,
        password: 'NotTheOne1',
      );
      expect((unknown as LumeAuthRefused).failure, LumeAuthFailure.credentials);
      expect((wrong as LumeAuthRefused).failure, LumeAuthFailure.credentials);
    });

    test(
      'a locked account is told, because resetting is the way out',
      () async {
        final LumeFakeAuthRepository repo = fakeAuth(locked: true);
        final LumeAuthResult r = await repo.signIn(
          email: kTestEmail,
          password: kTestPassword,
        );
        expect((r as LumeAuthRefused).failure, LumeAuthFailure.locked);
      },
    );

    test('a recovery request is neutral either way', () async {
      final LumeFakeAuthRepository repo = fakeAuth();
      final LumeAuthResult known = await repo.requestPasswordReset(kTestEmail);
      final LumeAuthResult unknown = await repo.requestPasswordReset(
        'nobody@example.com',
      );
      expect(known, isA<LumeAuthAccepted>());
      expect(unknown, isA<LumeAuthAccepted>());
      // Same shape, so nothing downstream can render the difference.
      expect((known as LumeAuthAccepted).recoveryToken, isNotNull);
      expect((unknown as LumeAuthAccepted).recoveryToken, isNotNull);
      expect(known.recoveryToken!.length, unknown.recoveryToken!.length);
    });

    test(
      'a token for an address with no account resolves to nothing',
      () async {
        final LumeFakeAuthRepository repo = fakeAuth();
        final LumeAuthAccepted asked =
            await repo.requestPasswordReset('nobody@example.com')
                as LumeAuthAccepted;
        final LumeAuthResult spent = await repo.resetPassword(
          token: asked.recoveryToken!,
          password: 'Passw0rdy',
          confirm: 'Passw0rdy',
        );
        expect((spent as LumeAuthRefused).failure, LumeAuthFailure.linkInvalid);
      },
    );

    test('a spent token cannot be spent again', () async {
      final LumeFakeAuthRepository repo = fakeAuth();
      final LumeAuthAccepted asked =
          await repo.requestPasswordReset(kTestEmail) as LumeAuthAccepted;
      expect(
        await repo.resetPassword(
          token: asked.recoveryToken!,
          password: 'Passw0rdy2',
          confirm: 'Passw0rdy2',
        ),
        isA<LumeAuthAccepted>(),
      );
      final LumeAuthResult again = await repo.resetPassword(
        token: asked.recoveryToken!,
        password: 'Passw0rdy3',
        confirm: 'Passw0rdy3',
      );
      expect((again as LumeAuthRefused).failure, LumeAuthFailure.linkInvalid);
    });

    test('an hour later the link is expired rather than invalid', () async {
      DateTime now = DateTime(2026, 9, 12, 9);
      final LumeFakeAuthRepository repo = LumeFakeAuthRepository.withAccount(
        clock: () => now,
      );
      final LumeAuthAccepted asked =
          await repo.requestPasswordReset(kTestEmail) as LumeAuthAccepted;
      now = now.add(const Duration(hours: 1, seconds: 1));
      final LumeAuthResult late = await repo.resetPassword(
        token: asked.recoveryToken!,
        password: 'Passw0rdy2',
        confirm: 'Passw0rdy2',
      );
      expect((late as LumeAuthRefused).failure, LumeAuthFailure.linkExpired);
    });

    test('changing the password ends the session it belonged to', () async {
      final LumeFakeAuthRepository repo = fakeAuth();
      await repo.signIn(email: kTestEmail, password: kTestPassword);
      expect(repo.status.isAuthenticated, isTrue);

      final LumeAuthAccepted asked =
          await repo.requestPasswordReset(kTestEmail) as LumeAuthAccepted;
      await repo.resetPassword(
        token: asked.recoveryToken!,
        password: 'Passw0rdy2',
        confirm: 'Passw0rdy2',
      );
      expect(
        repo.status.isGuest,
        isTrue,
        reason: 'a password change that left old sessions alive is not one',
      );
    });

    test('signing up refuses an address that already has an account', () async {
      final LumeFakeAuthRepository repo = fakeAuth();
      final LumeAuthResult r = await repo.signUp(
        name: 'Someone',
        email: kTestEmail,
        password: 'Passw0rdy',
        confirm: 'Passw0rdy',
      );
      expect(
        (r as LumeAuthRefused).issues[LumeAuthField.email],
        LumeAuthIssue.emailTaken,
      );
    });

    test('the identity step runs the rules the whole form will run', () async {
      final LumeFakeAuthRepository repo = fakeAuth();
      // Whatever the first step accepts, the second must not reject for the
      // same reason.
      final LumeAuthResult step = await repo.checkIdentity(
        name: '',
        email: kTestEmail,
      );
      final LumeAuthResult whole = await repo.signUp(
        name: '',
        email: kTestEmail,
        password: 'Passw0rdy',
        confirm: 'Passw0rdy',
      );
      expect(
        (step as LumeAuthRefused).issues[LumeAuthField.email],
        LumeAuthIssue.emailTaken,
      );
      expect(
        (whole as LumeAuthRefused).issues[LumeAuthField.email],
        LumeAuthIssue.emailTaken,
      );
    });

    test('restoring fails closed on an expired session', () async {
      final LumeFakeAuthRepository repo = fakeAuth()
        ..seedSession(kTestEmail)
        ..expireSession();
      final LumeAuthStatus status = await repo.restore();
      expect(status.state, LumeSessionState.expired);
      expect(
        status.account?.email,
        kTestEmail,
        reason: 'the address is still known, so the screen can show it back',
      );
      expect(
        status.signedInAccount,
        isNull,
        reason: 'but nothing may read it as a live identity',
      );
    });

    test('a restore that fails is a guest, never a signed-in guess', () async {
      final LumeFakeAuthRepository repo = fakeAuth()..seedSession(kTestEmail);
      repo.script.fail(LumeAuthFailure.storage);
      expect((await repo.restore()).state, LumeSessionState.guest);
    });

    test('signing out is not a wipe of the account that existed', () async {
      final LumeFakeAuthRepository repo = fakeAuth();
      await repo.signIn(email: kTestEmail, password: kTestPassword);
      await repo.signOut();
      expect(repo.status.isGuest, isTrue);
      // The account is still there to sign back in to.
      expect(
        await repo.signIn(email: kTestEmail, password: kTestPassword),
        isA<LumeAuthAccepted>(),
      );
    });

    test('a resend inside the window is rate limited, with a wait', () async {
      DateTime now = DateTime(2026, 9, 12, 9);
      final LumeFakeAuthRepository repo = LumeFakeAuthRepository.withAccount(
        clock: () => now,
      );
      await repo.signIn(email: kTestEmail, password: kTestPassword);
      repo.requestEmailChange('moved@example.com');

      final LumeAuthResult tooSoon = await repo.resendVerification();
      expect((tooSoon as LumeAuthRefused).failure, LumeAuthFailure.rateLimited);
      expect(tooSoon.retryAfter, isNotNull);
      expect(tooSoon.retryAfter!.inSeconds, lessThanOrEqualTo(45));

      now = now.add(const Duration(seconds: 46));
      expect(await repo.resendVerification(), isA<LumeAuthAccepted>());
    });

    test('a code past its window is expired, not wrong', () async {
      DateTime now = DateTime(2026, 9, 12, 9);
      final LumeFakeAuthRepository repo = LumeFakeAuthRepository.withAccount(
        clock: () => now,
      );
      await repo.signIn(email: kTestEmail, password: kTestPassword);
      final LumeAuthAccepted asked =
          repo.requestEmailChange('moved@example.com') as LumeAuthAccepted;

      now = now.add(const Duration(minutes: 11));
      final LumeAuthResult late = await repo.verifyEmail(asked.deliveredCode!);
      expect((late as LumeAuthRefused).failure, LumeAuthFailure.codeExpired);
    });

    test(
      'a wrong code is a field complaint, because retyping fixes it',
      () async {
        final LumeFakeAuthRepository repo = fakeAuth();
        await repo.signIn(email: kTestEmail, password: kTestPassword);
        repo.requestEmailChange('moved@example.com');
        final LumeAuthResult wrong = await repo.verifyEmail('000000');
        expect(
          (wrong as LumeAuthRefused).issues[LumeAuthField.code],
          LumeAuthIssue.codeIncorrect,
        );
      },
    );

    test('verifying moves the address and keeps the session', () async {
      final LumeFakeAuthRepository repo = fakeAuth();
      await repo.signIn(email: kTestEmail, password: kTestPassword);
      final LumeAuthAccepted asked =
          repo.requestEmailChange('moved@example.com') as LumeAuthAccepted;
      expect(
        await repo.verifyEmail(asked.deliveredCode!),
        isA<LumeAuthAccepted>(),
      );
      expect(repo.status.signedInAccount?.email, 'moved@example.com');
      expect(repo.status.signedInAccount?.emailVerified, isTrue);
    });

    test('the script makes any failure reachable on demand', () async {
      final LumeFakeAuthRepository repo = fakeAuth();
      for (final LumeAuthFailure failure in LumeAuthFailure.values) {
        repo.script.fail(failure);
        final LumeAuthResult r = await repo.signIn(
          email: kTestEmail,
          password: kTestPassword,
        );
        expect((r as LumeAuthRefused).failure, failure, reason: failure.name);
      }
      // And is spent after one call, so it cannot leak into the next.
      expect(
        await repo.signIn(email: kTestEmail, password: kTestPassword),
        isA<LumeAuthAccepted>(),
      );
    });
  });

  group('nothing carries a secret', () {
    test('an account has no password, digest or token on it', () {
      const LumeAccount account = LumeAccount(
        id: 'usr-1',
        email: kTestEmail,
        displayName: kTestName,
      );
      // `toString` is what lands in a log or a crash report. A field that is
      // not on the class cannot be in it.
      expect(account.toString(), isNot(contains(kTestPassword)));
    });

    test('a refusal names a reason, never a value', () async {
      final LumeFakeAuthRepository repo = fakeAuth();
      final LumeAuthResult r = await repo.signIn(
        email: kTestEmail,
        password: 'SomethingSecret1',
      );
      expect(r.toString(), isNot(contains('SomethingSecret1')));
      expect((r as LumeAuthRefused).issues, isEmpty);
    });
  });
}
