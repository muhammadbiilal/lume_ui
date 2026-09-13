/// What a Profile test needs, once.
///
/// Profile draws from a *view*, not a repository, so the harness's job is to
/// put one together for each identity state rather than to drive a fixture.
/// That is the point of [LumeProfileView]: the four states are four values, and
/// a test names the one it wants.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/domain/profile_view.dart';
import 'package:lume/features/account/presentation/profile_screen.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';

import '../../helpers/lume_harness.dart';

/// The seeded account. The same figures the measurement driver writes into
/// `lume-accounts`, so a capture and a golden describe the same person.
final LumeAccountIdentity kProfileIdentity = LumeAccountIdentity(
  email: 'amina@example.com',
  createdAt: DateTime(2024, 3, 18, 9, 12),
  displayName: 'Amina Rahman',
  firstName: 'Amina',
  lastName: 'Rahman',
);

/// The same account with no name at all — the state that is invited to
/// complete itself.
final LumeAccountIdentity kNamelessIdentity = LumeAccountIdentity(
  email: 'amina@example.com',
  createdAt: DateTime(2024, 3, 18, 9, 12),
);

/// The row values a Pakistani reader sees, matching the measured capture.
const LumeProfileValues kProfileValues = LumeProfileValues(
  language: 'English',
  region: 'Pakistan · Islamabad · PKR',
  appearance: 'Follow the system',
  notifications: '11 of 11 on',
  interests: 7,
  favourites: 0,
  version: '0.1.0',
);

/// Everything Profile did, so a test can assert a tap rather than a mock.
class LumeRecordedProfile {
  final List<LumeAccountRoute> opened = <LumeAccountRoute>[];
  int interests = 0;
  int signIns = 0;
  int signUps = 0;
  int signOuts = 0;
  int tours = 0;

  LumeProfileActions get actions => LumeProfileActions(
    open: opened.add,
    openInterests: () => interests++,
    signIn: () => signIns++,
    signUp: () => signUps++,
    signOut: () => signOuts++,
    startTour: () => tours++,
  );
}

/// A view in one of the identity states.
LumeProfileView profileView({
  LumeAccountState state = LumeAccountState.guest,
  LumeAccountIdentity? identity,
  LumeProfileValues values = kProfileValues,
  String deviceName = '',
}) => LumeProfileView(
  state: state,
  identity:
      identity ??
      switch (state) {
        LumeAccountState.guest => null,
        LumeAccountState.authed => kProfileIdentity,
        LumeAccountState.expired => kProfileIdentity,
      },
  values: deviceName.isEmpty
      ? values
      : LumeProfileValues(
          language: values.language,
          region: values.region,
          appearance: values.appearance,
          notifications: values.notifications,
          interests: values.interests,
          favourites: values.favourites,
          version: values.version,
          deviceName: deviceName,
        ),
);

/// The screen, in a given state.
Widget profileScreenFor(LumeProfileView view, LumeRecordedProfile recorded) =>
    LumeProfileScreen(view: view, actions: recorded.actions);

/// Profile, pumped.
Future<LumeRecordedProfile> pumpProfile(
  WidgetTester tester, {
  LumeAccountState state = LumeAccountState.guest,
  LumeAccountIdentity? identity,
  LumeProfileValues values = kProfileValues,
  String deviceName = '',
  LumeRecordedProfile? actions,
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) async {
  final LumeRecordedProfile recorded = actions ?? LumeRecordedProfile();
  await pumpLume(
    tester,
    profileScreenFor(
      profileView(
        state: state,
        identity: identity,
        values: values,
        deviceName: deviceName,
      ),
      recorded,
    ),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
  );
  return recorded;
}

/// A reader whose profile carries a device name but no account.
const LumeProfileRecord kGuestRecord = LumeProfileRecord(displayName: 'Sara');
