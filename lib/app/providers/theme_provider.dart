/// Appearance: light, dark, or whatever the device is set to.
///
/// The reference stores this in `localStorage` under `lume-theme` and applies
/// it before first paint so the page never flashes the wrong ground. Flutter
/// has no equivalent flash — the first frame is already themed — so this is
/// simply the chosen mode, with no persistence yet: F1 is fixtures, and
/// persistence is a Dayroz provider's job at integration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The appearance mode the application is rendering in.
final StateProvider<ThemeMode> themeModeProvider = StateProvider<ThemeMode>(
  (Ref ref) => ThemeMode.system,
);
