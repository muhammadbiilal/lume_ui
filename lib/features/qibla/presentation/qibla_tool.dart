/// Qibla Compass — a computed great-circle bearing to the Kaaba, drawn on a
/// static dial.
///
/// `tools/islamic/qibla.tool.js`, on the Sun & Moon reference's composition
/// (a context bar, a lead visual, a source card underneath it the shared
/// frame draws on its own): the reader's coordinates come from their city,
/// exactly as Sun & Moon reads them ([LumeSolar.coordsFor]), and the bearing
/// and the distance are worked out from those coordinates and the Kaaba's own
/// ([LumeQiblaMath]) — never a fixture, never a live sensor. This tool is
/// faith-gated at the catalogue (`faith: true`); nothing here re-decides that.
///
/// **What differs from the reference.** There is no live needle: this
/// conversion is not authorised to add a magnetometer/device-orientation
/// package, so `.compass`'s live rotation is out of scope and the dial here
/// is drawn once from the calculation and never re-drawn as the phone moves
/// (`LumeQiblaDial`). The note under it says so, replacing the reference's
/// own "hold the phone flat, move it in a figure of eight" instructions —
/// which are about calibrating a sensor this build does not read, and would
/// be a false instruction here. The reference's third metric,
/// "Compass · Calibrated", is left out for the same reason: nothing here is
/// calibrated, because nothing here is reading anything live.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/time/lume_solar.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/qibla_bearing.dart';
import 'qibla_dial.dart';

/// The bearing, the distance and the coordinates behind them.
@immutable
class LumeQiblaReading {
  const LumeQiblaReading({
    required this.lat,
    required this.lon,
    required this.bearing,
    required this.distanceKm,
  });

  final double lat;
  final double lon;

  /// Degrees clockwise from true north.
  final double bearing;
  final int distanceKm;

  String get compassPoint => LumeQiblaMath.compassPoint(bearing);

  /// `null` where [LumeSolar.coordsFor] has no coordinates for [city] — said,
  /// not guessed from the country (§ "no fabricated data").
  static LumeQiblaReading? at({
    required String country,
    required String city,
  }) {
    final (double, double)? coords = LumeSolar.coordsFor(country, city);
    if (coords == null) return null;
    final (double lat, double lon) = coords;
    return LumeQiblaReading(
      lat: lat,
      lon: lon,
      bearing: LumeQiblaMath.bearing(lat, lon),
      distanceKm: LumeQiblaMath.distanceKm(lat, lon),
    );
  }
}

class LumeQiblaTool extends ConsumerWidget {
  const LumeQiblaTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeQiblaTool(request: request);

  static const String id = 'qibla';

  static const Key contextKey = ValueKey<String>('qibla.context');
  static const Key dialKey = ValueKey<String>('qibla.dial');
  static const Key summaryKey = ValueKey<String>('qibla.summary');
  static const Key referenceKey = ValueKey<String>('qibla.reference');
  static const Key missingKey = ValueKey<String>('qibla.missing');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LumeToolRequest r = request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final LumeQiblaReading? reading = LumeQiblaReading.at(
      country: r.user.country,
      city: r.user.city,
    );
    final String countryName = LumeToolScreen.countryName(
      context,
      ref,
      r.user.country,
    );

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              key: LumeQiblaTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(
                  label: '${r.user.city}, $countryName',
                  icon: LumeIcons.pin,
                ),
              ],
            ),
          ),
          if (reading == null)
            LumeToolSection(
              child: LumeToolState(
                key: LumeQiblaTool.missingKey,
                icon: LumeIcons.navigation,
                title: l.qiblaNoCityTitle(r.user.city),
                text: l.qiblaNoCityText,
              ),
            )
          else
            ..._reading(l, f, reading),
        ],
      ),
    );
  }

  List<Widget> _reading(
    AppLocalizations l,
    LumeFormatting f,
    LumeQiblaReading q,
  ) {
    return <Widget>[
      LumeToolSection(
        child: Center(
          child: LumeQiblaDial(key: LumeQiblaTool.dialKey, bearing: q.bearing),
        ),
      ),
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeQiblaTool.summaryKey,
          kicker: l.qiblaDirection,
          value: '${f.integer(q.bearing)}°',
          unit: q.compassPoint,
          stats: <LumeStat>[
            LumeStat(
              value: _distance(l, f, q.distanceKm),
              label: l.qiblaToKaaba,
            ),
            LumeStat(value: l.qiblaTrueNorth, label: l.qiblaBasis),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeNotice(
          kind: LumeNoticeKind.info,
          title: l.qiblaNoteTitle,
          text: l.qiblaNoteText,
        ),
      ),
      LumeToolSection(
        title: l.qiblaReference,
        child: LumeRows(
          key: LumeQiblaTool.referenceKey,
          children: <Widget>[
            LumeCompactRow(
              icon: LumeIcons.mosque,
              label: l.qiblaKaaba,
              value: _coords(
                f,
                LumeQiblaMath.kaabaLat,
                LumeQiblaMath.kaabaLon,
                4,
              ),
            ),
            LumeCompactRow(
              icon: LumeIcons.pin,
              label: l.qiblaYourPosition,
              value: _coords(f, q.lat, q.lon, 2),
            ),
          ],
        ),
      ),
    ];
  }

  /// `L.distance(km)` — kept local to this tool rather than imported from
  /// another feature's presentation file, so this rollout wave stays inside
  /// its own directory; the rounding and the unit choice are the same as
  /// every other converted tool's (kilometres under ten to a tenth, miles the
  /// same, both units-aware through [LumeFormatting.units]).
  static String _distance(AppLocalizations l, LumeFormatting f, int km) {
    if (f.units == LumeUnits.imperial) {
      final double mi = km * 0.621;
      return '${mi < 10 ? mi.toStringAsFixed(1) : mi.round()} ${l.unitMi}';
    }
    return '${km < 10 ? km.toStringAsFixed(1) : km} ${l.unitKm}';
  }

  /// "21.4225°N, 39.8262°E" — the hemisphere letters stay in Latin script in
  /// every language, the way a coordinate pair is written everywhere.
  static String _coords(
    LumeFormatting f,
    double lat,
    double lon,
    int decimals,
  ) {
    String one(double v, String pos, String neg) =>
        '${f.fixed(v.abs(), decimals)}°${v < 0 ? neg : pos}';
    return '${one(lat, 'N', 'S')}, ${one(lon, 'E', 'W')}';
  }
}
