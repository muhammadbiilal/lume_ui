/// Who to call, by country — `tool-data.js` `EMERGENCY`.
///
/// A life-safety dataset, so a country without an entry falls back to the
/// international numbers rather than to an empty screen, exactly as
/// `emergencyFor(code)` does. The numbers are written as they are shown and
/// dialled as they are shown ([LumeDialNumber]); nothing here is inferred from
/// language or religion, only from the country the reader chose.
///
/// **Dayroz obligation:** this table is reference data from the prototype, not
/// a verified directory. Before release it must come from an owned, dated
/// source per country, with the region-level numbers (`reqCity`) the catalogue
/// promises.
library;

import 'package:flutter/foundation.dart';

import '../../../core/icons/lume_icons.dart';

/// What a number is for — `emerg.*`.
enum LumeEmergencyKind {
  ambRescue,
  police,
  fire,
  ambulance,
  highway,
  all3,
  poison,
  mental,
  trafficInfo,
  medAdvice,
  nonUrgent,
  gas,
  medical,
  maritime,
  allServices,
  fireRescue,
  traffic,
  helpline,
  gsm,
  routed,
}

/// Which service — one key per name the dataset writes.
enum LumeEmergencyName {
  rescue1122,
  police,
  fireBrigade,
  edhiAmbulance,
  motorwayPolice,
  emergency,
  poisonControl,
  crisisLifeline,
  roadside,
  nhs111,
  policeNonEmergency,
  gasEmergency,
  ambulance,
  fireCivilDefence,
  coastGuard,
  unifiedEmergency,
  redCrescent,
  civilDefence,
  traffic,
  fire,
  womenHelpline,
  international,
  local,
}

@immutable
class LumeEmergencyService {
  const LumeEmergencyService(this.name, this.number, this.icon, this.kind);

  final LumeEmergencyName name;

  /// As shown — `0800 111 999`, `1-800-222-1222`.
  final String number;
  final String icon;
  final LumeEmergencyKind kind;
}

abstract final class LumeEmergencyDirectory {
  static const Map<String, List<LumeEmergencyService>> _byCountry =
      <String, List<LumeEmergencyService>>{
        'PK': <LumeEmergencyService>[
          LumeEmergencyService(
            LumeEmergencyName.rescue1122,
            '1122',
            LumeIcons.pulse,
            LumeEmergencyKind.ambRescue,
          ),
          LumeEmergencyService(
            LumeEmergencyName.police,
            '15',
            LumeIcons.shield,
            LumeEmergencyKind.police,
          ),
          LumeEmergencyService(
            LumeEmergencyName.fireBrigade,
            '16',
            LumeIcons.flame,
            LumeEmergencyKind.fire,
          ),
          LumeEmergencyService(
            LumeEmergencyName.edhiAmbulance,
            '115',
            LumeIcons.pulse,
            LumeEmergencyKind.ambulance,
          ),
          LumeEmergencyService(
            LumeEmergencyName.motorwayPolice,
            '130',
            LumeIcons.car,
            LumeEmergencyKind.highway,
          ),
        ],
        'US': <LumeEmergencyService>[
          LumeEmergencyService(
            LumeEmergencyName.emergency,
            '911',
            LumeIcons.shield,
            LumeEmergencyKind.all3,
          ),
          LumeEmergencyService(
            LumeEmergencyName.poisonControl,
            '1-800-222-1222',
            LumeIcons.pill,
            LumeEmergencyKind.poison,
          ),
          LumeEmergencyService(
            LumeEmergencyName.crisisLifeline,
            '988',
            LumeIcons.heart,
            LumeEmergencyKind.mental,
          ),
          LumeEmergencyService(
            LumeEmergencyName.roadside,
            '511',
            LumeIcons.car,
            LumeEmergencyKind.trafficInfo,
          ),
        ],
        'GB': <LumeEmergencyService>[
          LumeEmergencyService(
            LumeEmergencyName.emergency,
            '999',
            LumeIcons.shield,
            LumeEmergencyKind.all3,
          ),
          LumeEmergencyService(
            LumeEmergencyName.nhs111,
            '111',
            LumeIcons.pulse,
            LumeEmergencyKind.medAdvice,
          ),
          LumeEmergencyService(
            LumeEmergencyName.policeNonEmergency,
            '101',
            LumeIcons.shield,
            LumeEmergencyKind.nonUrgent,
          ),
          LumeEmergencyService(
            LumeEmergencyName.gasEmergency,
            '0800 111 999',
            LumeIcons.bolt,
            LumeEmergencyKind.gas,
          ),
        ],
        'AE': <LumeEmergencyService>[
          LumeEmergencyService(
            LumeEmergencyName.police,
            '999',
            LumeIcons.shield,
            LumeEmergencyKind.police,
          ),
          LumeEmergencyService(
            LumeEmergencyName.ambulance,
            '998',
            LumeIcons.pulse,
            LumeEmergencyKind.medical,
          ),
          LumeEmergencyService(
            LumeEmergencyName.fireCivilDefence,
            '997',
            LumeIcons.flame,
            LumeEmergencyKind.fire,
          ),
          LumeEmergencyService(
            LumeEmergencyName.coastGuard,
            '996',
            LumeIcons.navigation,
            LumeEmergencyKind.maritime,
          ),
        ],
        'SA': <LumeEmergencyService>[
          LumeEmergencyService(
            LumeEmergencyName.unifiedEmergency,
            '911',
            LumeIcons.shield,
            LumeEmergencyKind.allServices,
          ),
          LumeEmergencyService(
            LumeEmergencyName.redCrescent,
            '997',
            LumeIcons.pulse,
            LumeEmergencyKind.ambulance,
          ),
          LumeEmergencyService(
            LumeEmergencyName.civilDefence,
            '998',
            LumeIcons.flame,
            LumeEmergencyKind.fireRescue,
          ),
          LumeEmergencyService(
            LumeEmergencyName.traffic,
            '993',
            LumeIcons.car,
            LumeEmergencyKind.traffic,
          ),
        ],
        'IN': <LumeEmergencyService>[
          LumeEmergencyService(
            LumeEmergencyName.emergency,
            '112',
            LumeIcons.shield,
            LumeEmergencyKind.allServices,
          ),
          LumeEmergencyService(
            LumeEmergencyName.ambulance,
            '108',
            LumeIcons.pulse,
            LumeEmergencyKind.medical,
          ),
          LumeEmergencyService(
            LumeEmergencyName.fire,
            '101',
            LumeIcons.flame,
            LumeEmergencyKind.fire,
          ),
          LumeEmergencyService(
            LumeEmergencyName.womenHelpline,
            '1091',
            LumeIcons.heart,
            LumeEmergencyKind.helpline,
          ),
        ],
      };

  /// `EMERGENCY_FALLBACK` — the international standard.
  static const List<LumeEmergencyService> fallback = <LumeEmergencyService>[
    LumeEmergencyService(
      LumeEmergencyName.international,
      '112',
      LumeIcons.shield,
      LumeEmergencyKind.gsm,
    ),
    LumeEmergencyService(
      LumeEmergencyName.local,
      '911',
      LumeIcons.shield,
      LumeEmergencyKind.routed,
    ),
  ];

  /// The countries with a list of their own.
  static Iterable<String> get countries => _byCountry.keys;

  /// `emergencyFor(code)` — the country's list, primary first, or [fallback].
  static List<LumeEmergencyService> forCountry(String code) =>
      _byCountry[code.toUpperCase()] ?? fallback;
}
