/// Lume — a global daily-life super-app.
///
/// The entry point does one thing: install the provider scope and run the app.
/// There is no backend to initialise, no push registration and no remote
/// configuration — this project is the interface, driven by deterministic
/// fixtures, and the production wiring belongs to the application it is
/// integrated into.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  runApp(const ProviderScope(child: LumeApp()));
}
