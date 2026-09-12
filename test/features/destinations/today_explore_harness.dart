/// What a Today or Explore test needs, once.
///
/// The same shape as `destination_harness.dart`: deterministic fixtures, the
/// real composers, and a pump that gives a screen a settled day rather than a
/// loading one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/explore/data/explore_fixtures.dart';
import 'package:lume/features/explore/domain/explore_repository.dart';
import 'package:lume/features/explore/presentation/explore_screen.dart';
import 'package:lume/features/home/domain/home_model.dart';
import 'package:lume/features/today/data/today_fixtures.dart';
import 'package:lume/features/today/domain/today_model.dart';
import 'package:lume/features/today/domain/today_repository.dart';
import 'package:lume/features/today/presentation/today_screen.dart';

import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';

/// Everything a screen did, so a test can assert a tap rather than a mock.
class LumeRecordedDay {
  final List<LumeHomeTarget> opened = <LumeHomeTarget>[];
  final List<(String, bool)> toggled = <(String, bool)>[];
  int weeks = 0;
  int adds = 0;
  int privates = 0;
  int searches = 0;
  int refreshes = 0;
  int backs = 0;

  LumeTodayActions get today => LumeTodayActions(
    openTarget: opened.add,
    toggleTask: (String id, bool done) => toggled.add((id, done)),
    openWeek: () => weeks++,
    addTask: () => adds++,
    openPrivate: () => privates++,
  );

  LumeExploreActions get explore => LumeExploreActions(
    openTarget: opened.add,
    openSearch: () => searches++,
    refreshWeather: () => refreshes++,
  );
}

/// The pinned instant every fixture and capture shares — 7 September 2026,
/// 16:41:32, which is what `measure_destinations.mjs` freezes.
DateTime get kPinned => DateTime(2026, 9, 7, 16, 41, 32);

/// Today's day for a user, composed through the real repository.
Future<LumeTodayData> composeToday(
  LumeUserContext user, {
  DateTime? now,
  LumeFakeTodayRepository? repository,
}) async {
  final LumeFakeTodayRepository repo =
      repository ?? LumeFakeTodayRepository(eligibility: kEligibility);
  final LumeTodayDay day = await repo.load(user, now: now ?? kPinned);
  return day.data;
}

/// Explore's snapshot for a user.
Future<LumeExploreSnapshot> composeExplore(
  LumeUserContext user, {
  DateTime? now,
  LumeFakeExploreRepository? repository,
}) async {
  final LumeFakeExploreRepository repo =
      repository ?? LumeFakeExploreRepository(eligibility: kEligibility);
  return repo.load(user, now: now ?? kPinned);
}

/// Today, with a settled day.
Future<LumeRecordedDay> pumpToday(
  WidgetTester tester,
  LumeUserContext user, {
  DateTime? now,
  LumeFakeTodayRepository? repository,
  LumeRecordedDay? actions,
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) async {
  final LumeRecordedDay recorded = actions ?? LumeRecordedDay();
  final LumeTodayData data = await composeToday(
    user,
    now: now,
    repository: repository,
  );
  await pumpLume(
    tester,
    LumeTodayScreen(user: user, data: data, actions: recorded.today),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
    now: now ?? kPinned,
  );
  return recorded;
}

/// Explore, with a settled snapshot.
Future<LumeRecordedDay> pumpExplore(
  WidgetTester tester,
  LumeUserContext user, {
  DateTime? now,
  LumeFakeExploreRepository? repository,
  LumeRecordedDay? actions,
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) async {
  final LumeRecordedDay recorded = actions ?? LumeRecordedDay();
  final LumeExploreSnapshot snapshot = await composeExplore(
    user,
    now: now,
    repository: repository,
  );
  await pumpLume(
    tester,
    LumeExploreScreen(
      user: user,
      eligibility: kEligibility,
      snapshot: snapshot,
      actions: recorded.explore,
      // The same condition the host applies: a way back only where Explore is
      // not one of the market's tabs.
      onBack:
          LumeDestinations.orderFor(
            user.country,
          ).contains(LumeDestinationId.explore)
          ? null
          : () => recorded.backs++,
    ),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
    now: now ?? kPinned,
  );
  return recorded;
}
