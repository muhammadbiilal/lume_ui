/// Speed Test — the reference's own instrument is fabricated end to end, and
/// this build has no network access to replace it with a real one.
///
/// `tools/daily/speedtest.tool.js` draws a gauge, three metrics and a
/// two-row "history", all from `context.js`'s `speedTest()`: a hardcoded
/// `48.2` Mbps default (`s.down || 48.2`), `up: down * 0.42`, a fixed `18`
/// ms ping, and two history rows that are literal constants — nothing
/// measured, ever. Pressing "Start" (`tool.screen.js` `runSpeedTest()`)
/// does not touch the network either: `target = 30 + Math.random() * 70`,
/// animated toward with an ease-out cubic over 1.8 seconds. There is no
/// server, no request and no real throughput anywhere in the reference —
/// its own "speed test" was always a random-number generator wearing a
/// progress bar, on a static site that could not have run a real one
/// either.
///
/// Lume makes zero network calls anywhere in this codebase (confirmed
/// project-wide; there is no HTTP client wired up and nothing to test
/// against). So there is nothing real to port, and no honest way to
/// reproduce even the reference's own fabrication: a "real" 48.2 Mbps or a
/// fresh random 61.3 Mbps would both be a measurement no one took, shown as
/// if Lume had taken it. That is worse than most invented figures, because
/// a reader could act on a false "your wifi is fine" — this tool does not
/// build that. It says plainly that it cannot measure a connection, and
/// offers the one honest way out: handing the reader's own browser a
/// well-known, free, ad-free test address, the same kind of hop the QR
/// tool's own link opener already makes for any other web address (C80).
/// Lume still sends nothing itself — the browser does, on the reader's own
/// press.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/platform_services.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/platform/lume_link_opener.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';

class LumeSpeedtestTool extends ConsumerStatefulWidget {
  const LumeSpeedtestTool({super.key, required this.request});

  final LumeToolRequest request;

  /// The registry's builder.
  static Widget open(LumeToolRequest request) =>
      LumeSpeedtestTool(request: request);

  static const String id = 'speedtest';

  static const Key stateKey = ValueKey<String>('speedtest.unavailable');
  static const Key openKey = ValueKey<String>('speedtest.open');

  /// A free, single-number, ad-free browser test with no account and
  /// nothing installed — a reasonable, neutral destination for "somewhere
  /// that can actually measure this". Lume only hands this address to the
  /// reader's own browser ([LumeLinkOpener], C80); it never requests it
  /// itself, and never learns the result.
  static final Uri realTest = Uri.parse('https://fast.com');

  @override
  ConsumerState<LumeSpeedtestTool> createState() => _LumeSpeedtestToolState();
}

class _LumeSpeedtestToolState extends ConsumerState<LumeSpeedtestTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  bool _busy = false;

  Future<void> _openRealTest() async {
    if (_busy) return;
    final AppLocalizations l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final LumeOpenOutcome outcome = await ref
          .read(linkOpenerProvider)
          .open(LumeSpeedtestTool.realTest);
      if (!mounted) return;
      switch (outcome) {
        case LumeOpenOutcome.opened:
          break;
        case LumeOpenOutcome.unavailable:
        case LumeOpenOutcome.refused:
          _host.currentState?.say(
            l.speedtestOpenUnavailable,
            tone: LumeToastTone.info,
          );
        case LumeOpenOutcome.failed:
          _host.currentState?.say(
            l.speedtestOpenFailed,
            tone: LumeToastTone.error,
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: LumeToolSection(
        child: LumeToolState(
          key: LumeSpeedtestTool.stateKey,
          icon: LumeIcons.gauge,
          title: l.speedtestUnavailableTitle,
          text: l.speedtestUnavailableText,
          action: LumeButton.accent(
            key: LumeSpeedtestTool.openKey,
            label: l.speedtestOpenBrowser,
            icon: LumeIcons.arrowUr,
            busy: _busy,
            onPressed: _openRealTest,
          ),
          footnote: l.speedtestOpenFootnote,
        ),
      ),
    );
  }
}
