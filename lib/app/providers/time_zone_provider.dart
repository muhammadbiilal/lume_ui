/// The time-zone service and the device's zone, as providers — the one place
/// a screen gets either.
///
/// The service loads the IANA database once ([LumeTimeZoneService.shared]);
/// a test overrides it with its own, or with a detached one to see the
/// unavailable path. The device zone is a platform concern this build has no
/// adapter for, so it is unknown until Dayroz supplies one.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/lume_iana_zones.dart';
import '../../features/startup/domain/startup_state.dart';

final Provider<LumeTimeZoneService> timeZoneServiceProvider =
    Provider<LumeTimeZoneService>((Ref ref) => LumeTimeZoneService.shared);

final Provider<LumeDeviceZone> deviceZoneProvider = Provider<LumeDeviceZone>(
  (Ref ref) => const LumeDeviceZone.unknown(),
);

extension LumeReaderZone on LumeTimeZoneService {
  /// The reader's zone from what they set: their explicit zone; else, under
  /// Account › Time's "Follow region", their country's zone from the country
  /// table; else the verified device zone.
  LumeZoneResolution readerZone(
    LumeStartupState startup,
    String country,
    LumeDeviceZone device,
  ) => reader(
    configured: startup.profile.timeZone,
    regionZone: startup.countries?.zoneOf(country),
    device: device,
  );
}
