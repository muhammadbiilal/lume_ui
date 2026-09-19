/// Which build this is, and so which claims its screens may make.
///
/// Three flavors, chosen by `--dart-define=LUME_BUILD=…`:
///
/// | flavor | define | what a tool's source line says | may ship |
/// |---|---|---|---|
/// | [LumeBuildProfile.parity] | `parity` | the web reference's own words, for a controlled visual comparison | never |
/// | [LumeBuildProfile.development] | none, or anything else | what the adapters' capabilities support | no — not a production configuration |
/// | [LumeBuildProfile.release] | `release` | what the adapters' capabilities support | yes |
///
/// **Parity** reproduces the prototype, "Stored on this device", "Live" and
/// "Updated 30 sec ago" included, over fixtures, and says in About that its
/// data is sample data. It exists for the golden and side-by-side captures,
/// which is why the test harness selects it explicitly. A screen reader hears
/// each reproduced claim marked as reference copy ([LumeSourceClaim]). A
/// release-mode binary that was compiled as parity refuses to start
/// ([lumeRefuseUnshippable]).
///
/// **Development** is an ordinary `flutter run`: truthful copy derived from
/// capability metadata, exactly as a release says it — "Kept until you close
/// Lume" for the in-memory store — with the fixture harness still reachable.
/// Not being a release is no licence for the reference's claims.
///
/// **Release** draws only what a real adapter's capability supports
/// (`LumeDataCapability`), and `release_readiness_test.dart` fails on any
/// claim that nothing supports.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LumeBuildProfile {
  /// The reference reproduction, for visual comparison only.
  parity,

  /// An ordinary development build.
  development,

  /// A production build.
  release;

  /// Only a release may be published.
  bool get shippable => this == LumeBuildProfile.release;

  /// Its screens reproduce the reference's claims rather than deriving them.
  bool get reproducesReference => this == LumeBuildProfile.parity;

  /// The fixture harness (`/tools/tool/ready` …) is reachable.
  bool get hasFixtureHarness => this != LumeBuildProfile.release;
}

/// The define as it was compiled in.
const String kLumeBuildName = String.fromEnvironment('LUME_BUILD');

LumeBuildProfile lumeBuildProfileFrom(String name) => switch (name) {
  'parity' => LumeBuildProfile.parity,
  'release' => LumeBuildProfile.release,
  _ => LumeBuildProfile.development,
};

/// A parity build compiled in release mode.
class LumeUnshippableBuild implements Exception {
  const LumeUnshippableBuild(this.profile);

  final LumeBuildProfile profile;

  @override
  String toString() =>
      'LumeUnshippableBuild: a ${profile.name} build reproduces the web '
      'reference\'s claims and must never run as a production app. Build '
      'with --dart-define=LUME_BUILD=release.';
}

/// Refuses a [LumeBuildProfile.parity] build compiled in release mode, so a
/// capture flavor can never reach a reader as a product. `main` calls it
/// with `kReleaseMode` before anything draws.
void lumeRefuseUnshippable({
  required LumeBuildProfile profile,
  required bool releaseMode,
}) {
  if (releaseMode && profile == LumeBuildProfile.parity) {
    throw LumeUnshippableBuild(profile);
  }
}

final Provider<LumeBuildProfile> buildProfileProvider =
    Provider<LumeBuildProfile>(
      (Ref ref) => lumeBuildProfileFrom(kLumeBuildName),
    );
