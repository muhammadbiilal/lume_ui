/// Emergency's dataset, in the reader's language.
library;

import '../../../l10n/app_localizations.dart';
import '../data/emergency_directory.dart';

abstract final class LumeEmergencyStrings {
  static String name(AppLocalizations l, LumeEmergencyName n) => switch (n) {
    LumeEmergencyName.rescue1122 => l.emergNameRescue1122,
    LumeEmergencyName.police => l.emergNamePolice,
    LumeEmergencyName.fireBrigade => l.emergNameFireBrigade,
    LumeEmergencyName.edhiAmbulance => l.emergNameEdhiAmbulance,
    LumeEmergencyName.motorwayPolice => l.emergNameMotorwayPolice,
    LumeEmergencyName.emergency => l.emergNameEmergency,
    LumeEmergencyName.poisonControl => l.emergNamePoisonControl,
    LumeEmergencyName.crisisLifeline => l.emergNameCrisisLifeline,
    LumeEmergencyName.roadside => l.emergNameRoadside,
    LumeEmergencyName.nhs111 => l.emergNameNhs111,
    LumeEmergencyName.policeNonEmergency => l.emergNamePoliceNonEmergency,
    LumeEmergencyName.gasEmergency => l.emergNameGasEmergency,
    LumeEmergencyName.ambulance => l.emergNameAmbulance,
    LumeEmergencyName.fireCivilDefence => l.emergNameFireCivilDefence,
    LumeEmergencyName.coastGuard => l.emergNameCoastGuard,
    LumeEmergencyName.unifiedEmergency => l.emergNameUnifiedEmergency,
    LumeEmergencyName.redCrescent => l.emergNameRedCrescent,
    LumeEmergencyName.civilDefence => l.emergNameCivilDefence,
    LumeEmergencyName.traffic => l.emergNameTraffic,
    LumeEmergencyName.fire => l.emergNameFire,
    LumeEmergencyName.womenHelpline => l.emergNameWomenHelpline,
    LumeEmergencyName.international => l.emergNameInternational,
    LumeEmergencyName.local => l.emergNameLocal,
  };

  static String kind(AppLocalizations l, LumeEmergencyKind k) => switch (k) {
    LumeEmergencyKind.ambRescue => l.emergKindAmbRescue,
    LumeEmergencyKind.police => l.emergKindPolice,
    LumeEmergencyKind.fire => l.emergKindFire,
    LumeEmergencyKind.ambulance => l.emergKindAmbulance,
    LumeEmergencyKind.highway => l.emergKindHighway,
    LumeEmergencyKind.all3 => l.emergKindAll3,
    LumeEmergencyKind.poison => l.emergKindPoison,
    LumeEmergencyKind.mental => l.emergKindMental,
    LumeEmergencyKind.trafficInfo => l.emergKindTrafficInfo,
    LumeEmergencyKind.medAdvice => l.emergKindMedAdvice,
    LumeEmergencyKind.nonUrgent => l.emergKindNonUrgent,
    LumeEmergencyKind.gas => l.emergKindGas,
    LumeEmergencyKind.medical => l.emergKindMedical,
    LumeEmergencyKind.maritime => l.emergKindMaritime,
    LumeEmergencyKind.allServices => l.emergKindAllServices,
    LumeEmergencyKind.fireRescue => l.emergKindFireRescue,
    LumeEmergencyKind.traffic => l.emergKindTraffic,
    LumeEmergencyKind.helpline => l.emergKindHelpline,
    LumeEmergencyKind.gsm => l.emergKindGsm,
    LumeEmergencyKind.routed => l.emergKindRouted,
  };
}
