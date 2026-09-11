/// A tool, drawn in the real frame, with fixture content inside it.
///
/// The frame is production code; what it hosts here is not. Enough tools are
/// declared to exercise every path the frame has — ready, loading, error,
/// unavailable and ineligible — so the host is verified before a single real
/// tool exists.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../l10n/app_localizations.dart';

/// The fixture tools, and which of the frame's paths each one takes.
///
/// Keyed by the id that appears in the route, so `/home/tool/loading` renders
/// the loading state and `/home/tool/gated` is refused by the eligibility gate
/// rather than by the absence of a screen.
enum LumeFixtureTool {
  ready,
  loading,
  failed,
  elsewhere,
  gated,
  records;

  static LumeFixtureTool? parse(String id) {
    for (final LumeFixtureTool t in LumeFixtureTool.values) {
      if (t.name == id) return t;
    }
    return null;
  }
}

/// Hosts one fixture tool.
class FixtureToolScreen extends StatelessWidget {
  const FixtureToolScreen({
    super.key,
    required this.toolId,
    this.onBack,
    this.onOpenRelated,
    this.onOpenRecords,
  });

  final String toolId;
  final VoidCallback? onBack;
  final ValueChanged<String>? onOpenRelated;
  final VoidCallback? onOpenRecords;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFixtureTool? tool = LumeFixtureTool.parse(toolId);

    final LumeToolFrameStrings strings = LumeToolFrameStrings(
      loading: l.toolLoading,
      errorTitle: l.toolErrorTitle,
      errorText: l.toolErrorText,
      retry: l.actionTryAgain,
      unavailableTitle: l.toolUnavailableTitle,
      unavailableText: l.toolUnavailableText,
      back: l.actionBack,
    );

    // An unknown id is not a missing screen — it is a tool this user may not
    // have, and §64 says the answer is the same either way: the gate refuses,
    // and the body is never built.
    return LumeToolFrame(
      title: tool == null ? l.toolUnavailableTitle : _title(l, tool),
      subtitle: tool == null ? null : toolId,
      onBack: onBack,
      strings: strings,
      eligible: tool != null && tool != LumeFixtureTool.gated,
      status: switch (tool) {
        LumeFixtureTool.loading => LumeToolStatus.loading,
        LumeFixtureTool.failed => LumeToolStatus.error,
        LumeFixtureTool.elsewhere => LumeToolStatus.unavailable,
        _ => LumeToolStatus.ready,
      },
      onRetry: () {},
      freshness: LumeFreshnessQuality.live,
      freshnessLabel: l.commonNow,
      source: l.commonStatus,
      updated: l.commonToday,
      privacy: LumePrivateState(
        title: l.toolPrivateTitle,
        text: l.toolPrivateText,
      ),
      related: <LumeRelatedTool>[
        LumeRelatedTool(
          id: LumeFixtureTool.ready.name,
          name: l.navTools,
          icon: LumeIcons.grid,
        ),
        LumeRelatedTool(
          id: LumeFixtureTool.records.name,
          name: l.commonHistory,
          icon: LumeIcons.list,
        ),
      ],
      onOpenRelated: onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LumeCard(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < 6; i++)
                  LumeCompactRow(
                    label: l.navTools,
                    value: '${i + 1}',
                    chevron: false,
                  ),
              ],
            ),
          ),
          if (onOpenRecords != null) ...<Widget>[
            const SizedBox(height: LumeSpace.gapCard),
            LumeCard(
              child: LumeRichRow(
                title: l.commonHistory,
                icon: LumeIcons.list,
                onTap: onOpenRecords,
                chevron: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _title(AppLocalizations l, LumeFixtureTool tool) => switch (tool) {
    LumeFixtureTool.records => l.commonHistory,
    _ => l.navTools,
  };
}
