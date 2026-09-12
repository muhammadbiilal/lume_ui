/// Launches the real application straight onto Home, for a device render.
///
/// **Temporary conversion tooling. Deleted with the prototype at Phase F9.**
///
/// P2 is the question of whether the greeting's `👋` reaches the screen. It
/// does not in `flutter_test`, which loads only the fonts the package
/// declares and so has no emoji face at all — a *capture* limitation, and one
/// that says nothing about a device. Settling it needs the packaged
/// application running on Android, where the platform's own font fallback is
/// what answers.
///
/// This is that application. The same `LumeApp`, the same fonts, the same
/// assets, the same build — with one override, because the profile repository
/// in this repository is deliberately not durable (F4C), so every launch
/// starts at onboarding and nothing reaches Home. The override seeds a profile
/// that has already been through it.
///
/// ```bash
/// flutter build apk --debug \
///   -t docs/conversion_archive/tool/android_home_probe.dart
/// adb install -r build/app/outputs/flutter-apk/app-debug.apk
/// adb shell am start -n com.lume.lume/.MainActivity
/// adb exec-out screencap -p > home.png
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lume/app/app.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';

/// The `muslim_pk` fixture, in the form the gate reads.
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
      ],
      child: const LumeApp(),
    ),
  );
}
