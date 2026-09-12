/// What a Trains test needs, once.
///
/// The same shape as `today_explore_harness.dart`: deterministic fixtures, the
/// real composer, and a pump that gives the screen a settled snapshot rather
/// than a loading one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/trains/data/trains_fixtures.dart';
import 'package:lume/features/trains/domain/trains_model.dart';
import 'package:lume/features/trains/domain/trains_repository.dart';
import 'package:lume/features/trains/presentation/trains_screen.dart';

import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';
import 'today_explore_harness.dart';

/// Everything Trains did, so a test can assert a tap rather than a mock.
class LumeRecordedRail {
  int saved = 0;
  int origins = 0;
  int destinations = 0;
  int swaps = 0;
  int searches = 0;
  int refreshes = 0;
  int alls = 0;
  final List<LumeJourneyDay> days = <LumeJourneyDay>[];
  final List<String> services = <String>[];
  final List<String> routes = <String>[];

  LumeTrainsActions get actions => LumeTrainsActions(
    openSaved: () => saved++,
    chooseOrigin: () => origins++,
    chooseDestination: () => destinations++,
    swap: () => swaps++,
    chooseDay: days.add,
    search: () => searches++,
    refresh: () async => refreshes++,
    openAllDepartures: () => alls++,
    openService: (LumeTrainService s) => services.add(s.number),
    openRoute: (LumePopularRoute r) => routes.add('${r.fromCode}${r.toCode}'),
  );
}

/// Trains' snapshot for a reader, composed through the real repository.
Future<LumeTrainsSnapshot> composeTrains(
  LumeUserContext user, {
  DateTime? now,
  LumeFakeTrainsRepository? repository,
}) {
  final LumeFakeTrainsRepository repo =
      repository ?? LumeFakeTrainsRepository(eligibility: kEligibility);
  return repo.load(user, now: now ?? kPinned);
}

/// Trains, with a settled snapshot.
Future<LumeRecordedRail> pumpTrains(
  WidgetTester tester,
  LumeUserContext user, {
  DateTime? now,
  LumeFakeTrainsRepository? repository,
  LumeRecordedRail? actions,
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) async {
  final LumeRecordedRail recorded = actions ?? LumeRecordedRail();
  final LumeTrainsSnapshot snapshot = await composeTrains(
    user,
    now: now,
    repository: repository,
  );
  await pumpLume(
    tester,
    LumeTrainsScreen(user: user, snapshot: snapshot, actions: recorded.actions),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
    now: now ?? kPinned,
  );
  return recorded;
}
