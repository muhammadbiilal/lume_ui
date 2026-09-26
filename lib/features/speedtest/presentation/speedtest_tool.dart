/// Speed Test — `tools/daily/speedtest.tool.js`, composed in the reference's
/// own order: the gauge with Start test, download / upload / ping, the
/// connection, and the history.
///
/// Every figure is the reference's own sample (`speedtest_fixtures.dart`),
/// and the source line says "Sample data" over them. Start test does what
/// the reference's `runSpeedTest()` does: the needle eases from zero to a new
/// reading over 1.8 seconds — at once where the reader has asked for reduced
/// motion — then says "{n} Mbps down". The reading is kept for the session,
/// as the reference's `st.down` is.
///
/// **Dayroz:** Start test measures the connection against a test server
/// (download, upload and ping), and Connection reads the real network type,
/// server and provider.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_spark.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/speedtest_providers.dart';
import '../data/speedtest_fixtures.dart';
import 'speedtest_gauge.dart';

class LumeSpeedtestTool extends ConsumerStatefulWidget {
  const LumeSpeedtestTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeSpeedtestTool(request: request);

  static const String id = 'speedtest';

  static const Key gaugeKey = ValueKey<String>('speedtest.gauge');
  static const Key startKey = ValueKey<String>('speedtest.start');
  static const Key metricsKey = ValueKey<String>('speedtest.metrics');
  static const Key connectionKey = ValueKey<String>('speedtest.connection');
  static const Key historyKey = ValueKey<String>('speedtest.history');

  @override
  ConsumerState<LumeSpeedtestTool> createState() => _LumeSpeedtestToolState();
}

class _LumeSpeedtestToolState extends ConsumerState<LumeSpeedtestTool>
    with SingleTickerProviderStateMixin {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: LumeSpeedtestFixtures.run,
  );

  /// The reading the needle is heading for, while a run is under way.
  double? _target;

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  /// `s.down || 48.2` — the last reading this session, or the default.
  double get _down =>
      double.tryParse(_session.read(LumeSpeedtestTool.id, 'down') ?? '') ??
      LumeSpeedtestFixtures.defaultDown;

  Future<void> _start(AppLocalizations l, LumeFormatting f) async {
    if (_run.isAnimating) return;
    final double target = LumeSpeedtestFixtures.nextReading(
      ref.read(speedtestRandomProvider),
    );
    setState(() => _target = target);
    if (MediaQuery.disableAnimationsOf(context)) {
      _run.value = 1;
    } else {
      await _run.forward(from: 0);
    }
    if (!mounted) return;
    setState(() {
      _session.write(LumeSpeedtestTool.id, 'down', '$target');
      _target = null;
    });
    _host.currentState?.say(
      l.speedDone(f.number(target, decimals: 1)),
      tone: LumeToastTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final double down = _down;
    final String countryName = LumeToolScreen.countryName(
      context,
      ref,
      r.user.country,
    );

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _run,
                    builder: (BuildContext context, Widget? _) {
                      // `v = target * eased` with `eased = 1 − (1 − p)³`.
                      final double? target = _target;
                      final double shown = target == null
                          ? down
                          : target * Curves.easeOutCubic.transform(_run.value);
                      return LumeSpeedGauge(
                        key: LumeSpeedtestTool.gaugeKey,
                        fraction: LumeSpeedtestFixtures.fraction(shown),
                        value: shown.toStringAsFixed(1),
                        unit: l.unitMbps,
                        semanticLabel:
                            '${l.speedDownload} '
                            '${f.number(shown, decimals: 1)} ${l.unitMbps}',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  LumeButtonRow(
                    children: <Widget>[
                      LumeButton.accent(
                        key: LumeSpeedtestTool.startKey,
                        label: l.speedStart,
                        icon: LumeIcons.play,
                        block: true,
                        onPressed: () => _start(l, f),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeMetrics(
              key: LumeSpeedtestTool.metricsKey,
              columns: 3,
              children: <Widget>[
                LumeMetric(
                  icon: LumeIcons.download,
                  value: f.number(down, decimals: 1),
                  label: l.speedDownload,
                ),
                LumeMetric(
                  icon: LumeIcons.arrowUr,
                  value: f.number(
                    LumeSpeedtestFixtures.upFor(down),
                    decimals: 1,
                  ),
                  label: l.speedUpload,
                ),
                LumeMetric(
                  icon: LumeIcons.timer,
                  value: '${f.integer(LumeSpeedtestFixtures.ping)} ${l.unitMs}',
                  label: l.speedPing,
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.speedConnection,
            child: LumeRows(
              key: LumeSpeedtestTool.connectionKey,
              children: <Widget>[
                LumeCompactRow(
                  icon: LumeIcons.wifi,
                  label: l.speedType,
                  valueMaxWidth: 170,
                  value: l.speedWifi,
                ),
                LumeCompactRow(
                  icon: LumeIcons.signal,
                  label: l.speedServer,
                  valueMaxWidth: 170,
                  value: countryName.isEmpty
                      ? r.user.city
                      : '${r.user.city} · $countryName',
                ),
                LumeCompactRow(
                  icon: LumeIcons.globe,
                  label: l.speedIsp,
                  valueMaxWidth: 170,
                  value: l.speedYourIsp,
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.commonHistory,
            child: LumeRows(
              key: LumeSpeedtestTool.historyKey,
              children: <Widget>[
                for (final LumeSpeedHistory h in LumeSpeedtestFixtures.history)
                  LumeRichRow(
                    icon: LumeIcons.wifi,
                    title: h.today ? l.commonToday : l.commonYesterday,
                    subtitle: h.wifi ? l.speedWifi : l.speedMobile,
                    meta: <String>[
                      '${l.speedPing} ${f.integer(h.ping)} ${l.unitMs}',
                    ],
                    trailing: LumeSparkline(
                      values: h.series,
                      trend: LumeTrend.up,
                    ),
                    value: f.number(h.down, decimals: 1),
                    valueSub: l.unitMbps,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
