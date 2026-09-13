/// Profile, against the screen the prototype renders.
///
/// One composition for every identity state. These tests are written the other
/// way round from the usual: rather than asserting that a guest's screen looks
/// a certain way, they assert that the *sections* are the same in all three
/// states and only their contents change — which is the property the
/// reference's own source claims and the one a later change is most likely to
/// break.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/core/widgets/lume/lume_destination.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/presentation/profile_screen.dart';

import '../../helpers/load_fonts.dart';
import 'profile_harness.dart';

const Size kTall = Size(390, 5000);

void main() {
  setUpAll(loadLumeFonts);

  double topOf(WidgetTester tester, String key) =>
      tester.getTopLeft(find.byKey(ValueKey<String>(key))).dy;

  group('the sections, in the order the source emits them', () {
    for (final LumeAccountState state in LumeAccountState.values) {
      testWidgets('identity, your Lume, account, support — $state', (
        WidgetTester tester,
      ) async {
        await pumpProfile(tester, state: state, surface: kTall);

        final List<double> tops = <double>[
          topOf(tester, LumeProfileScreen.headKey),
          topOf(tester, LumeProfileScreen.identityKey),
          topOf(tester, LumeProfileScreen.lumeKey),
          topOf(tester, LumeProfileScreen.accountKey),
          topOf(tester, LumeProfileScreen.supportKey),
        ];
        expect(tops, orderedEquals(<double>[...tops]..sort()));
        expect(tops.toSet(), hasLength(tops.length));

        // The version line closes the page in every state.
        expect(
          topOf(tester, LumeProfileScreen.versionKey),
          greaterThan(tops.last),
        );
      });
    }

    testWidgets('and the sign-out row exists only where there is a session', (
      WidgetTester tester,
    ) async {
      for (final (LumeAccountState, bool) cell in <(LumeAccountState, bool)>[
        (LumeAccountState.guest, false),
        (LumeAccountState.expired, false),
        (LumeAccountState.authed, true),
      ]) {
        await pumpProfile(tester, state: cell.$1, surface: kTall);
        expect(
          find.byKey(const ValueKey<String>(LumeProfileScreen.sessionKey)),
          cell.$2 ? findsOneWidget : findsNothing,
          reason: '${cell.$1} should ${cell.$2 ? "" : "not "}offer a sign-out',
        );
      }
    });
  });

  group('the identity card says who this is', () {
    testWidgets('a guest is a guest, and is told what an account would do', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester, surface: kTall);
      expect(find.text('Welcome to Lume'), findsOneWidget);
      expect(find.byType(LumeGuestWhy), findsOneWidget);
      // Never an account's name, and never initials invented from one.
      expect(find.text('Amina Rahman'), findsNothing);
      expect(find.text('AR'), findsNothing);
    });

    testWidgets('a guest who named this device is greeted by that name', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester, deviceName: 'Sara', surface: kTall);
      // Twice on purpose: the card greets them by it, and the Display name
      // row shows it as the value it is.
      expect(find.text('Sara'), findsNWidgets(2));
      expect(find.byKey(LumeIdentityCard.nameKey), findsOneWidget);
      expect(
        (tester.widget<Text>(find.byKey(LumeIdentityCard.nameKey))).data,
        'Sara',
      );
      // Still a guest: the badge and the reasons stay.
      expect(find.byType(LumeGuestWhy), findsOneWidget);
    });

    testWidgets('a holder is named, with their address under it', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester, state: LumeAccountState.authed, surface: kTall);
      expect(find.text('Amina Rahman'), findsOneWidget);
      expect(find.text('amina@example.com'), findsWidgets);
      expect(find.text('AR'), findsOneWidget);
      expect(find.byType(LumeGuestWhy), findsNothing);
    });

    testWidgets('an account with no name shows the address, and invites one', (
      WidgetTester tester,
    ) async {
      await pumpProfile(
        tester,
        state: LumeAccountState.authed,
        identity: kNamelessIdentity,
        surface: kTall,
      );
      // The address *is* the identity. Nothing is invented to fill the line,
      // and the avatar falls back to a glyph rather than to two letters taken
      // from an email.
      expect(find.text('amina@example.com'), findsWidgets);
      expect(find.text('AM'), findsNothing);
      expect(find.text('AE'), findsNothing);
      // Invited, not forced.
      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('Add your name'), findsOneWidget);
    });

    testWidgets('an expired session is neither signed in nor a guest', (
      WidgetTester tester,
    ) async {
      await pumpProfile(
        tester,
        state: LumeAccountState.expired,
        surface: kTall,
      );
      // The returning holder's own name must not sit over "you're using Lume
      // as a guest" — the defect the reference's own source calls out.
      expect(find.text('Your session has expired'), findsWidgets);
      expect(find.text('Signed in as amina@example.com'), findsOneWidget);
      expect(find.byType(LumeGuestWhy), findsNothing);
      expect(find.text('Amina Rahman'), findsNothing);
      // And nothing reads them as signed in: no initials, no membership tag.
      expect(find.text('AR'), findsNothing);
      expect(find.byType(LumeTag), findsNothing);
      expect(find.byType(LumeBadge), findsOneWidget);
    });

    testWidgets('a locked account says so beside its membership', (
      WidgetTester tester,
    ) async {
      await pumpProfile(
        tester,
        state: LumeAccountState.authed,
        identity: LumeAccountIdentity(
          email: 'amina@example.com',
          createdAt: DateTime(2024, 3, 18),
          displayName: 'Amina Rahman',
          status: LumeAccountStatus.locked,
        ),
        surface: kTall,
      );
      expect(find.text('Locked'), findsOneWidget);
      expect(find.textContaining('Member since'), findsOneWidget);
    });
  });

  group('the rows a state has', () {
    testWidgets('a guest is offered an account and can name this device', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester, surface: kTall);
      expect(find.text('Create account'), findsWidgets);
      expect(find.text('Sign in'), findsWidgets);
      // §124.4 — a guest has a name too, and it can be changed.
      expect(find.text('Display name'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget);
      // No account, so no account-only rows.
      expect(find.text('Personal information'), findsNothing);
      expect(find.text('Security'), findsNothing);
    });

    testWidgets('a holder edits their name on the account form instead', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester, state: LumeAccountState.authed, surface: kTall);
      expect(find.text('Display name'), findsNothing);
      expect(find.text('Personal information'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
    });

    testWidgets('privacy and data & sync are on every state', (
      WidgetTester tester,
    ) async {
      for (final LumeAccountState state in LumeAccountState.values) {
        await pumpProfile(tester, state: state, surface: kTall);
        // A row a guest can see must lead somewhere: both describe what is on
        // *this device*, which is exactly as true without an account.
        expect(find.text('Privacy'), findsOneWidget, reason: '$state');
        expect(find.text('Data & sync'), findsOneWidget, reason: '$state');
      }
    });

    testWidgets('an expired session is offered its way back first', (
      WidgetTester tester,
    ) async {
      await pumpProfile(
        tester,
        state: LumeAccountState.expired,
        surface: kTall,
      );
      final double back = tester
          .getTopLeft(find.widgetWithText(LumeSettingsRow, 'Sign in again'))
          .dy;
      final double make = tester
          .getTopLeft(find.widgetWithText(LumeSettingsRow, 'Create account'))
          .dy;
      expect(back, lessThan(make));
    });
  });

  group('every row leads somewhere', () {
    testWidgets('each settings row opens the route it names', (
      WidgetTester tester,
    ) async {
      final LumeRecordedProfile recorded = await pumpProfile(
        tester,
        state: LumeAccountState.authed,
        surface: kTall,
      );

      const Map<String, LumeAccountRoute> rows = <String, LumeAccountRoute>{
        'Preferences': LumeAccountRoute.prefs,
        'Notifications': LumeAccountRoute.notifications,
        'Appearance': LumeAccountRoute.appearance,
        'Language': LumeAccountRoute.language,
        'Region & currency': LumeAccountRoute.region,
        'Your library': LumeAccountRoute.library,
        'Personal information': LumeAccountRoute.account,
        'Security': LumeAccountRoute.security,
        'Privacy': LumeAccountRoute.privacy,
        'Data & sync': LumeAccountRoute.sync,
        'Help': LumeAccountRoute.help,
        'About Lume': LumeAccountRoute.about,
      };

      for (final MapEntry<String, LumeAccountRoute> row in rows.entries) {
        recorded.opened.clear();
        await tester.tap(
          find.widgetWithText(LumeSettingsRow, row.key),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(recorded.opened, <LumeAccountRoute>[
          row.value,
        ], reason: '"${row.key}" should open ${row.value.name}');
      }
    });

    testWidgets('the head control opens preferences', (
      WidgetTester tester,
    ) async {
      final LumeRecordedProfile recorded = await pumpProfile(
        tester,
        surface: kTall,
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>(LumeProfileScreen.headKey)),
          matching: find.byType(LumeHeaderButton),
        ),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(recorded.opened, <LumeAccountRoute>[LumeAccountRoute.prefs]);
    });

    testWidgets('interests opens the picker, not a route', (
      WidgetTester tester,
    ) async {
      final LumeRecordedProfile recorded = await pumpProfile(
        tester,
        surface: kTall,
      );
      await tester.tap(
        find.widgetWithText(LumeSettingsRow, 'Your interests'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(recorded.interests, 1);
      expect(recorded.opened, isEmpty);
    });

    testWidgets('the tour and the sign-out are their own actions', (
      WidgetTester tester,
    ) async {
      final LumeRecordedProfile recorded = await pumpProfile(
        tester,
        state: LumeAccountState.authed,
        surface: kTall,
      );
      await tester.tap(
        find.widgetWithText(LumeSettingsRow, 'Replay the welcome tour').first,
        warnIfMissed: false,
      );
      await tester.pump();
      expect(recorded.tours, 1);

      await tester.tap(
        find.widgetWithText(LumeSettingsRow, 'Log out'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(recorded.signOuts, 1);
      expect(recorded.opened, isEmpty);
    });
  });

  group('the version line', () {
    testWidgets('names this build, not the prototype', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester, surface: kTall);
      // D40. A version number is a claim about which code is running.
      expect(find.textContaining('0.1.0'), findsOneWidget);
      expect(find.textContaining('4.1.0'), findsNothing);
    });
  });
}
