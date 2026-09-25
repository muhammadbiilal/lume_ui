/// [LumeLocator] over `geolocator`: the one file that knows which plugin
/// reads the position.
library;

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'lume_locator.dart';

class LumePlatformLocator implements LumeLocator {
  const LumePlatformLocator({this.timeLimit = const Duration(seconds: 8)});

  /// How long the reader is kept waiting before the screen says it could not
  /// find them. The reference waited the same eight seconds.
  final Duration timeLimit;

  @override
  Future<LumeLocateResult> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LumeLocateResult.refused(LumeLocateOutcome.serviceOff);
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Asked here and only here — when the reader has just tapped the
        // action that needs it.
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return const LumeLocateResult.refused(LumeLocateOutcome.denied);
        case LocationPermission.deniedForever:
          return const LumeLocateResult.refused(LumeLocateOutcome.blocked);
        case LocationPermission.unableToDetermine:
          return const LumeLocateResult.refused(LumeLocateOutcome.failed);
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }
      final Position p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          // City-level: low accuracy is quicker, kinder to the battery, and
          // all that approximate-only permission allows anyway.
          accuracy: LocationAccuracy.low,
          timeLimit: timeLimit,
        ),
      );
      return LumeLocateResult.located(p.latitude, p.longitude);
    } on TimeoutException {
      return const LumeLocateResult.refused(LumeLocateOutcome.failed);
    } on Exception {
      // The plugin reports missing hardware, a revoked permission mid-request
      // and platform errors as exceptions; each is "could not locate".
      return const LumeLocateResult.refused(LumeLocateOutcome.failed);
    }
  }
}
