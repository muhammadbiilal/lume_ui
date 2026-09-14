/// Which build this is: the reference reproduction, or a release.
///
/// F6B decision 5. The reference build reproduces the web prototype — its
/// "Stored on this device", "Live" and "Updated 30 sec ago" included — over
/// fixtures, and says in About that its data is sample data. A release build
/// may make a claim only when a real adapter's capability supports it
/// (`LumeDataCapability`), and `release_readiness_test.dart` fails on any
/// claim that nothing supports.
///
/// `flutter build … --dart-define=LUME_BUILD=release`. Anything else, and no
/// define at all, is the reference build.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LumeBuildProfile { reference, release }

/// The define as it was compiled in.
const String kLumeBuildName = String.fromEnvironment('LUME_BUILD');

LumeBuildProfile lumeBuildProfileFrom(String name) =>
    name == 'release' ? LumeBuildProfile.release : LumeBuildProfile.reference;

final Provider<LumeBuildProfile> buildProfileProvider =
    Provider<LumeBuildProfile>(
      (Ref ref) => lumeBuildProfileFrom(kLumeBuildName),
    );
