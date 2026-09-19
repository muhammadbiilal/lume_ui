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
import '../../features/onboarding/domain/onboarding_state.dart';

final Provider<LumeTimeZoneService> timeZoneServiceProvider =
    Provider<LumeTimeZoneService>((Ref ref) => LumeTimeZoneService.shared);

final Provider<LumeDeviceZone> deviceZoneProvider = Provider<LumeDeviceZone>(
  (Ref ref) => const LumeDeviceZone.unknown(),
);

extension LumeReaderZone on LumeTimeZoneService {
  /// The reader's zone from what they set in Account › Time: the zone they
  /// named; else "Follow my region" (their city, else their country's one
  /// civil time) or "Follow this device".
  LumeZoneResolution readerZone(
    LumeProfileRecord profile,
    LumeDeviceZone device, {
    String? country,
    String? city,
  }) => reader(
    explicit: profile.timeZone,
    follow: profile.zoneFollow,
    country: country ?? profile.country,
    city: city ?? profile.city,
    device: device,
  );
}
