/// Lume — a global daily-life super-app.
///
/// The entry point installs the provider scope and runs the app, after
/// loading the IANA time-zone database once at this boundary — so no screen
/// is the first to pay for it, and none ever loads it. There is no backend to initialise, no push registration and no remote
/// configuration — this project is the interface, driven by deterministic
/// fixtures, and the production wiring belongs to the application it is
/// integrated into.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/lume_build_profile.dart';
import 'core/time/lume_iana_zones.dart';

void main() {
  // A parity build reproduces the reference's claims for visual comparison
  // and must never run as a product.
  lumeRefuseUnshippable(
    profile: lumeBuildProfileFrom(kLumeBuildName),
    releaseMode: kReleaseMode,
  );
  LumeTimeZoneService.shared;
  runApp(const ProviderScope(child: LumeApp()));
}
