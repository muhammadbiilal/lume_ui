/// The test harness every Lume widget test pumps through.
///
/// It exists because four things go wrong otherwise, and all four cost real
/// time before they are understood.
///
/// **`pumpAndSettle` hangs on any screen carrying an indefinite animation.**
/// A skeleton shimmer and a live-data pulse never end, so the pump never
/// settles. Both stop when the platform asks for less motion, so the harness
/// asks by default and a test that is actually testing an animation opts out
/// with `animate: true`.
///
/// **Counting rendered widgets proves nothing on a phone-sized surface.**
/// Lists and grids build only what is visible, so "before" and "after" a filter
/// are both a screenful. A test that counts needs [tall].
///
/// **Time moves.** Every fixture runs on a pinned clock, so a golden taken
/// today matches one taken next week.
///
/// **A width class is measured, not assumed.** The harness sizes the surface
/// and lets [LumeBreakpointScope] measure it, exactly as the shell does, rather
/// than stubbing the class.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/layout/lume_breakpoint.dart';
import 'package:lume/core/localization/lume_locales.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/platform/lume_link_opener.dart';
import 'package:lume/core/platform/lume_scanner.dart';
import 'package:lume/core/platform/lume_dialer.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/routing/app_router.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/auth/domain/auth_repository.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/core/theme/lume/lume_theme.dart';
import 'package:lume/l10n/app_localizations.dart';

/// The viewports the conversion is verified at.
///
/// The same nine geometries the capture matrix uses, so a widget test and a
/// screenshot are talking about the same surface.
abstract final class LumeViewport {
  /// Triggers the sub-360 refinements.
  static const Size narrow = Size(359, 800);

  /// The first width that does *not* trigger them.
  static const Size small = Size(360, 800);

  /// The Design System's phone reference.
  static const Size phone = Size(390, 844);

  static const Size phoneMid = Size(400, 860);
  static const Size phoneLarge = Size(430, 932);

  /// Rail, centred content.
  static const Size medium = Size(700, 1000);

  /// Sidebar and master-detail, below the 1180 wide refinement.
  static const Size expanded = Size(1100, 900);

  /// Above 1180 — four-column metrics, five-column tiles.
  static const Size wide = Size(1280, 800);

  /// A landscape phone. Wide enough for `expanded` on width alone, and short
  /// enough that the height override must claim it back.
  static const Size landscapePhone = Size(852, 393);

  /// Tall enough that a lazy list builds everything, for tests that count.
  static const Size tall = Size(390, 5000);
}

/// Pump a widget inside the full Lume environment.
///
/// [surface] sizes the test view, and the width class is then *measured* from
/// it rather than injected — so a test that asserts a presentation is asserting
/// the same code path the shell runs.
Future<void> pumpLume(
  WidgetTester tester,
  Widget child, {
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  DateTime? now,
  bool animate = false,
  double textScale = 1.0,
  List<Override> overrides = const <Override>[],
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Pump an empty tree first. Re-pumping into the same slot otherwise reuses
  // the old elements — a second `ProviderScope`'s overrides silently do not
  // take, and `MaterialApp`'s `AnimatedTheme` lerps from the previous theme
  // rather than arriving at the new one. Both make a test that pumps twice
  // assert against the *first* pump's state.
  await tester.pumpWidget(const SizedBox.shrink());

  await tester.pumpWidget(
    ProviderScope(
      // No test reaches a device service: the recording fakes stand in, and a
      // test that asserts on one passes its own instance in [overrides].
      overrides: <Override>[
        dialerProvider.overrideWithValue(LumeRecordingDialer()),
        sharerProvider.overrideWithValue(LumeRecordingSharer()),
        imageSaverProvider.overrideWithValue(LumeRecordingImageSaver()),
        exporterProvider.overrideWithValue(LumeRecordingExporter()),
        scannerProvider.overrideWithValue(LumeRecordingScanner()),
        linkOpenerProvider.overrideWithValue(LumeRecordingLinkOpener()),
        // Tests are the parity captures: the reference's own source-line
        // copy, stated explicitly rather than inherited from a missing
        // define. A test about another flavor overrides this.
        buildProfileProvider.overrideWithValue(LumeBuildProfile.parity),
        // Records on the fixture day, read at once: a test that is about
        // loading builds its own store with a delay.
        //
        // The seeds are asked the build's own question, exactly as
        // `records_provider.dart` asks it, so that the two families seeded
        // only in the reproduction (`kLumeParityOnlySeeds`) are seeded here
        // under parity and empty under a shipping flavor. A harness that
        // passed `lumeRecordSeeds` bare would leave every parity capture of
        // Birthdays and Water blank and call it the reference.
        recordRepositoryProvider.overrideWith((Ref ref) {
          final bool parity = ref
              .watch(buildProfileProvider)
              .reproducesReference;
          final LumeMemoryRecordRepository store = LumeMemoryRecordRepository(
            seeds: (String collection, DateTime now) =>
                lumeRecordSeeds(collection, now, reproducesReference: parity),
            now: () => kFixtureInstant,
            hydrateDelay: null,
          );
          ref.onDispose(store.dispose);
          return store;
        }),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LumeTheme.light(),
        darkTheme: LumeTheme.dark(),
        themeMode: theme,
        locale: locale,
        supportedLocales: LumeLocales.supported,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // The MediaQuery has to sit *inside* MaterialApp. Wrapping the app
        // instead is the obvious mistake and a silent one: MaterialApp inserts
        // its own `MediaQuery.fromView`, so an outer one is replaced and both
        // `textScaler` and `disableAnimations` are quietly discarded.
        builder: (BuildContext context, Widget? navigator) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            // Indefinite animation stops, so the pump can settle.
            disableAnimations: !animate,
          ),
          child: navigator ?? const SizedBox.shrink(),
        ),
        home: LumeClockScope(
          clock: LumeClock.fixed(now ?? kFixtureInstant),
          child: LumeBreakpointScope(child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Pump the real router inside the same environment.
///
/// [pumpLume] hosts one widget; this hosts the whole navigator, so a test can
/// assert what happens *between* screens — a branch keeping its stack, Back
/// landing where the user came from, a tab set changing under a live
/// navigation. The router is built per call, so no test inherits another's
/// history.
Future<GoRouter> pumpLumeRouter(
  WidgetTester tester, {
  String? initialLocation,
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  bool animate = false,
  double textScale = 1.0,
  List<Override> overrides = const <Override>[],
  LumeAuthRepository? auth,
  LumeProfileRepository? profile,
  bool signedIn = false,

  /// Off for a test that wants to see the frames a slow launch draws. Settling
  /// would run the boot to completion and there would be no splash to find.
  bool settle = true,

  /// The clock the whole tree reads, for a test that has to move time —
  /// a tool that ticks, or one whose figures depend on the instant.
  /// Defaults to the pinned fixture instant, so every other test is
  /// unaffected and nothing reads the wall clock either way.
  LumeClock? clock,
}) async {
  // One set of objects, shared by the router's gate and by the widgets that
  // read them through Riverpod. Two sets would be a split brain: the gate
  // would redirect on one session while the screens drew another.
  final LumeAuthRepository repository =
      auth ??
      (signedIn
          ? (LumeFakeAuthRepository.withAccount()..seedSession(kFixtureEmail))
          : LumeFakeAuthRepository.withAccount());
  final LumeProfileRepository profiles =
      profile ?? LumeMemoryProfileRepository();
  final LumeStartupController gate = LumeStartupController(
    authRepository: repository,
    profileRepository: profiles,
  );
  addTearDown(gate.dispose);

  final GoRouter router = buildLumeRouter(
    initialLocation: initialLocation,
    startup: gate,
    auth: repository,
  );
  addTearDown(router.dispose);

  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        routerProvider.overrideWithValue(router),
        authRepositoryProvider.overrideWithValue(repository),
        profileRepositoryProvider.overrideWithValue(profiles),
        startupControllerProvider.overrideWithValue(gate),
        dialerProvider.overrideWithValue(LumeRecordingDialer()),
        sharerProvider.overrideWithValue(LumeRecordingSharer()),
        imageSaverProvider.overrideWithValue(LumeRecordingImageSaver()),
        exporterProvider.overrideWithValue(LumeRecordingExporter()),
        scannerProvider.overrideWithValue(LumeRecordingScanner()),
        linkOpenerProvider.overrideWithValue(LumeRecordingLinkOpener()),
        // Tests are the parity captures: the reference's own source-line
        // copy, stated explicitly rather than inherited from a missing
        // define. A test about another flavor overrides this.
        buildProfileProvider.overrideWithValue(LumeBuildProfile.parity),
        // Records on the fixture day, read at once: a test that is about
        // loading builds its own store with a delay.
        //
        // The seeds are asked the build's own question, exactly as
        // `records_provider.dart` asks it, so that the two families seeded
        // only in the reproduction (`kLumeParityOnlySeeds`) are seeded here
        // under parity and empty under a shipping flavor. A harness that
        // passed `lumeRecordSeeds` bare would leave every parity capture of
        // Birthdays and Water blank and call it the reference.
        recordRepositoryProvider.overrideWith((Ref ref) {
          final bool parity = ref
              .watch(buildProfileProvider)
              .reproducesReference;
          final LumeMemoryRecordRepository store = LumeMemoryRecordRepository(
            seeds: (String collection, DateTime now) =>
                lumeRecordSeeds(collection, now, reproducesReference: parity),
            now: () => kFixtureInstant,
            hydrateDelay: null,
          );
          ref.onDispose(store.dispose);
          return store;
        }),
        ...overrides,
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: LumeTheme.light(),
        darkTheme: LumeTheme.dark(),
        themeMode: theme,
        locale: locale,
        supportedLocales: LumeLocales.supported,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
        builder: (BuildContext context, Widget? navigator) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: !animate,
          ),
          child: LumeClockScope(
            clock: clock ?? LumeClock.fixed(kFixtureInstant),
            child: LumeBreakpointScope(
              child: navigator ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return router;
}

/// The account [pumpLumeRouter] seeds when a test asks to be signed in.
const String kFixtureEmail = 'amina@example.com';

/// Where the router currently is.
String locationOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

/// The `BuildContext` of a pumped subject, for asserting what the environment
/// resolved to.
BuildContext lumeContext(WidgetTester tester, Finder of) => tester.element(of);

/// A probe that reports what the layout decided, so a responsive test can
/// assert the resolved class rather than re-deriving it.
class LumeProbe extends StatelessWidget {
  const LumeProbe({super.key, this.onBuild});

  final void Function(BuildContext context)? onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild?.call(context);
    return const SizedBox.expand();
  }
}
