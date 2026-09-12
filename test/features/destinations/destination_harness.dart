/// Pumping Home and the Tools hub with a known user and a known fixture.
///
/// Both screens are functions of their inputs — a [LumeUserContext], a
/// repository and a set of actions — so a test never has to drive a router to
/// reach a composition. The states here are the same seven the web measurement
/// tool drives the prototype into, by the same names, so a Flutter assertion
/// and a browser capture are talking about the same user.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/home/application/home_controller.dart';
import 'package:lume/features/home/data/home_fixtures.dart';
import 'package:lume/features/home/domain/home_model.dart';
import 'package:lume/features/home/domain/home_repository.dart';
import 'package:lume/features/home/presentation/home_screen.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/tools/presentation/tools_screen.dart';

import '../../helpers/lume_harness.dart';

/// The whole registry, as the product has it.
const LumeEligibility kEligibility = LumeEligibility(
  features: kLumeFeatures,
  categories: kLumeCategories,
);

/// `app-store.js` gives an onboarded user who chose nothing these seven.
const List<String> kDefaultInterests = <String>[
  'weather',
  'calendar',
  'tasks',
  'notes',
  'maths',
  'expenses',
  'news',
];

/// The states the measurement tool drives the prototype into.
abstract final class LumeUsers {
  /// Non-Muslim, Pakistan. The primary cell.
  static const LumeUserContext defaultPk = LumeUserContext(
    interests: <String>{
      'weather',
      'calendar',
      'tasks',
      'notes',
      'maths',
      'expenses',
      'news',
    },
  );

  /// Muslim, Pakistan.
  static final LumeUserContext muslimPk = defaultPk.copyWith(
    islamic: true,
    interests: <String>{...kDefaultInterests, 'prayer', 'quran', 'duas'},
  );

  /// Muslim, United Kingdom — faith on, no Pakistani service.
  static final LumeUserContext muslimGb = defaultPk.copyWith(
    islamic: true,
    country: 'GB',
    city: 'London',
    interests: <String>{...kDefaultInterests, 'prayer', 'quran'},
  );

  /// Non-Muslim, United States.
  static final LumeUserContext defaultUs = defaultPk.copyWith(
    country: 'US',
    city: 'New York',
  );

  /// Someone with a name, favourites and a history.
  static final LumeUserContext namedPk = defaultPk.copyWith(
    displayName: 'Amina Tariq',
    favourites: <String>['currency', 'qibla', 'notes'],
    recents: <String>['calculator', 'weather', 'todos'],
  );

  /// Content switches off — the third gate, which nothing else exercises.
  static final LumeUserContext prefsOffPk = defaultPk.copyWith(
    prefs: const LumeContentPrefs(news: false, cricket: false, finance: false),
  );

  /// Nobody has chosen anything.
  static final LumeUserContext noInterestsPk = defaultPk.copyWith(
    interests: const <String>{},
  );

  /// Every state, by the name the measurement tool uses.
  static Map<String, LumeUserContext> get all => <String, LumeUserContext>{
    'default_pk': defaultPk,
    'muslim_pk': muslimPk,
    'muslim_gb': muslimGb,
    'default_us': defaultUs,
    'named_pk': namedPk,
    'prefs_off_pk': prefsOffPk,
    'no_interests_pk': noInterestsPk,
  };
}

/// Actions that record where they were asked to go, so a test can assert the
/// destination without a router.
class LumeRecordedActions {
  final List<String> tools = <String>[];
  final List<String> destinations = <String>[];
  int searches = 0;
  int notifications = 0;
  int profiles = 0;
  int personalise = 0;

  LumeHomeActions get home => LumeHomeActions(
    openTarget: (LumeHomeTarget t) {
      switch (t) {
        case LumeToolTarget(:final String featureId):
          tools.add(featureId);
        case LumeDestinationTarget(:final String path):
          destinations.add(path);
      }
    },
    openSearch: () => searches++,
    openNotifications: () => notifications++,
    openProfile: () => profiles++,
    openTools: () => destinations.add(LumeRoutes.tools),
    openToday: () => destinations.add(LumeRoutes.today),
    openExplore: () => destinations.add(LumeRoutes.explore),
  );

  LumeToolsActions get toolsActions => LumeToolsActions(
    openTool: tools.add,
    openPersonalise: () => personalise++,
  );
}

/// The paths Home's composer needs, shared by every test that builds one.
final LumeHomeRoutes kRoutes = LumeHomeRoutes(
  today: LumeRoutes.today,
  tools: LumeRoutes.tools,
  trains: LumeRoutes.trains,
  explore: LumeRoutes.explore,
);

/// A controller on the fixture clock, for a test that supplies its own
/// repository — a slow one, a broken one, one told to fail a section.
LumeHomeController controllerOn(
  LumeHomeRepository repository, {
  DateTime? now,
}) => LumeHomeController(
  repository: repository,
  eligibility: kEligibility,
  clock: LumeClock.fixed(now ?? kFixtureInstant),
  routes: kRoutes,
);

/// A repository that cannot answer at all.
///
/// A whole-page failure is a different state from a section that failed, and
/// Home has to draw both.
class LumeBrokenHomeRepository implements LumeHomeRepository {
  const LumeBrokenHomeRepository();

  @override
  Future<LumeHomeSnapshot> load(
    LumeUserContext user, {
    required DateTime now,
  }) async => throw const LumeUnreachable();

  @override
  LumeToolStatuses statusesFor(LumeUserContext user, {required DateTime now}) =>
      LumeToolStatuses.none;
}

class LumeUnreachable implements Exception {
  const LumeUnreachable();
}

/// Compose Home without pumping it.
Future<LumeHomeController> composeHome(
  LumeUserContext user, {
  LumeHomeRepository? repository,
  DateTime? now,
}) async {
  final LumeHomeController controller = controllerOn(
    repository ?? LumeFakeHomeRepository(),
    now: now,
  );
  await controller.load(user);
  return controller;
}

/// Build the Home widget for a composed state.
Widget homeScreenFor(
  LumeHomeController controller,
  LumeUserContext user, {
  LumeRecordedActions? actions,
}) => LumeHomeScreen(
  data: controller.state.data,
  user: user,
  loading: controller.state.loading,
  failed: controller.state.failed,
  actions: (actions ?? LumeRecordedActions()).home,
);

/// Pump Home for [user], with the load already settled.
Future<LumeHomeController> pumpHome(
  WidgetTester tester,
  LumeUserContext user, {
  LumeHomeRepository? repository,
  DateTime? now,
  LumeRecordedActions? actions,
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) async {
  final LumeHomeController controller = await composeHome(
    user,
    repository: repository,
    now: now,
  );
  addTearDown(controller.dispose);
  await pumpLume(
    tester,
    homeScreenFor(controller, user, actions: actions),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
    now: now ?? kFixtureInstant,
  );
  return controller;
}

/// The Tools hub for [user].
Widget toolsScreenFor(
  LumeUserContext user, {
  LumeRecordedActions? actions,
  Map<String, int> attention = const <String, int>{'bills': 1, 'documents': 2},
}) => LumeToolsScreen(
  eligibility: kEligibility,
  user: user,
  attention: attention,
  actions: (actions ?? LumeRecordedActions()).toolsActions,
);

/// Pump the Tools hub.
Future<void> pumpTools(
  WidgetTester tester,
  LumeUserContext user, {
  LumeRecordedActions? actions,
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) => pumpLume(
  tester,
  toolsScreenFor(user, actions: actions),
  surface: surface,
  theme: theme,
  locale: locale,
  textScale: textScale,
);
