/// Small string/icon mappings for Health Records — no state, no logic
/// beyond a lookup.
library;

import '../../../core/icons/lume_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/health_model.dart';

abstract final class HealthText {
  static String kind(AppLocalizations l, HealthRecordKind k) => switch (k) {
    HealthRecordKind.appointment => l.healthKindAppointment,
    HealthRecordKind.report => l.healthKindReport,
    HealthRecordKind.prescription => l.healthKindPrescription,
    HealthRecordKind.vaccination => l.healthKindVaccination,
    HealthRecordKind.measurement => l.healthKindMeasurement,
  };

  static String icon(HealthRecordKind k) => switch (k) {
    HealthRecordKind.appointment => LumeIcons.calendar,
    HealthRecordKind.report => LumeIcons.note,
    HealthRecordKind.prescription => LumeIcons.pill,
    HealthRecordKind.vaccination => LumeIcons.syringe,
    HealthRecordKind.measurement => LumeIcons.gauge,
  };
}
