/// Where a Speed Test run's sample reading comes from.
library;

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The run's random source — a test overrides it with a seeded one.
final Provider<math.Random> speedtestRandomProvider = Provider<math.Random>(
  (Ref ref) => math.Random(),
);
