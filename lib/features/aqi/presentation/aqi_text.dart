/// The words Air Quality draws that its fixture data does not carry.
library;

import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../l10n/app_localizations.dart';
import '../data/aqi_fixtures.dart';

/// A band's label, its advice and the tone it is shown in — `AQI_BANDS`'
/// `key` resolved through the reader's own language, exactly the mapping
/// already ported for Weather's embedded AQI card.
typedef LumeAirQualityBandText = ({String label, String advice, LumeBadgeTone tone});

abstract final class LumeAqiText {
  static LumeAirQualityBandText bandText(
    AppLocalizations l,
    LumeAirQualityBand band,
  ) => switch (band) {
    LumeAirQualityBand.good => (
      label: l.aqiGoodLabel,
      advice: l.aqiGoodAdvice,
      tone: LumeBadgeTone.ok,
    ),
    LumeAirQualityBand.moderate => (
      label: l.aqiModerateLabel,
      advice: l.aqiModerateAdvice,
      tone: LumeBadgeTone.info,
    ),
    LumeAirQualityBand.sensitive => (
      label: l.aqiSensitiveLabel,
      advice: l.aqiSensitiveAdvice,
      tone: LumeBadgeTone.warn,
    ),
    LumeAirQualityBand.unhealthy => (
      label: l.aqiUnhealthyLabel,
      advice: l.aqiUnhealthyAdvice,
      tone: LumeBadgeTone.warn,
    ),
    LumeAirQualityBand.veryUnhealthy => (
      label: l.aqiVeryUnhealthyLabel,
      advice: l.aqiVeryUnhealthyAdvice,
      tone: LumeBadgeTone.late_,
    ),
    LumeAirQualityBand.hazardous => (
      label: l.aqiHazardousLabel,
      advice: l.aqiHazardousAdvice,
      tone: LumeBadgeTone.late_,
    ),
  };

  /// `aq.band.tone === 'ok' ? 'ok' : 'warn'` — the reference's own advice
  /// note only ever draws in one of two tones, whatever the badge's own
  /// (finer) tone is. [LumeNoticeKind] has no bare "ok", so good reads as
  /// its calmest kind and every other band reads as a warning.
  static LumeNoticeKind adviceKind(LumeBadgeTone tone) =>
      tone == LumeBadgeTone.ok ? LumeNoticeKind.info : LumeNoticeKind.warning;
}
