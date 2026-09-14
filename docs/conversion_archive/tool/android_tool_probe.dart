/// Launches the real application straight onto one route, for a device walk.
///
/// **Temporary conversion tooling. Deleted with the prototype at Phase F9.**
///
/// The F6A smoke walk: the packaged application on Android, opened on each
/// converted tool in turn. It is `android_home_probe.dart` with one more
/// override — the product's own router, built by `buildLumeRouter` from the
/// same startup gate, auth repository and onboarding store, starting at the
/// route given at build time. The profile is seeded because the profile
/// repository is deliberately not durable (F4C).
///
/// ```bash
/// flutter build apk --debug \
///   -t docs/conversion_archive/tool/android_tool_probe.dart \
///   --dart-define=LUME_ROUTE=/tools/tool/weather
/// flutter install -d emulator-5554 --debug
/// flutter screenshot -d emulator-5554 -o weather.png
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/app.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/routing/app_router.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';

/// The route to open — `/tools/tool/<id>`; empty is the product's own start.
const String _route = String.fromEnvironment('LUME_ROUTE');

/// `off` captures screens without the notification banner; anything else runs
/// the reference schedule, for a walk that is about the banner.
const String _banners = String.fromEnvironment('LUME_BANNERS');

/// The `muslim_pk` fixture, in the form the gate reads — Muslim, so the
/// faith-gated Hadith is reachable too.
const LumeProfileRecord _seed = LumeProfileRecord(
  country: 'PK',
  region: 'Islamabad Capital Territory',
  city: 'Islamabad',
  islamic: true,
  interests: <String>[
    'weather',
    'calendar',
    'tasks',
    'notes',
    'maths',
    'expenses',
    'news',
    'prayer',
    'quran',
    'duas',
  ],
  onboarded: true,
);

void main() {
  runApp(
    ProviderScope(
      overrides: <Override>[
        profileRepositoryProvider.overrideWithValue(
          LumeMemoryProfileRepository(
            initial: _seed,
            installation: const LumeInstallationInfo.existing(),
          ),
        ),
        if (_banners == 'off')
          notificationScheduleProvider.overrideWithValue(
            const LumeNotificationSchedule.off(),
          ),
        routerProvider.overrideWith((Ref ref) {
          final GoRouter router = buildLumeRouter(
            initialLocation: _route.isEmpty ? null : _route,
            startup: ref.watch(startupControllerProvider),
            auth: ref.watch(authRepositoryProvider),
            onboardingStore: ref.watch(onboardingStoreProvider),
          );
          ref.onDispose(router.dispose);
          return router;
        }),
      ],
      child: const LumeApp(),
    ),
  );
}
