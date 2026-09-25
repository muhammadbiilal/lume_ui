/// Parcel Tracker — the reference tool for the tracking archetype, at its
/// smallest: two fixture parcels and no query that changes anything.
///
/// `tools/personal/parcel.tool.js` over `tool-data.js` `PARCELS`: a tracking
/// field and a "Track" button, the active parcels, the chosen one's carrier,
/// last-seen place and ETA with its progress, its journey, and notifying and
/// sharing it. Which parcel is chosen lives in the tool session, the same way
/// Flights keeps its own chosen flight.
///
/// **Kept exactly as the reference has it, on purpose:** the tracking field's
/// text is read by nothing in the reference, and "Track" answers any input —
/// or none — with the same fixed line ("Looking up the shipment"). There is
/// no reader-added parcel here, because the reference has none: selecting a
/// row is the only real interaction, and it only chooses which of the two
/// fixture parcels the sections below describe.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/parcel_fixtures.dart';
import 'parcel_strings.dart';

class LumeParcelTool extends ConsumerStatefulWidget {
  const LumeParcelTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeParcelTool(request: request);

  static const String id = 'parcel';

  static const Key fieldKey = ValueKey<String>('parcel.field');
  static const Key trackKey = ValueKey<String>('parcel.track');
  static const Key listKey = ValueKey<String>('parcel.active');
  static const Key metricsKey = ValueKey<String>('parcel.metrics');
  static const Key progressKey = ValueKey<String>('parcel.progress');
  static const Key timelineKey = ValueKey<String>('parcel.timeline');
  static const Key actionsKey = ValueKey<String>('parcel.actions');

  static Color toneOf(LumeColors lume, LumeParcelTone t) => switch (t) {
    LumeParcelTone.amber => lume.toneAmber,
    LumeParcelTone.rose => lume.tone(lume.rose),
  };

  /// `D.PARCELS.filter(x => x.ref === sel)[0] || D.PARCELS[0]` — the chosen
  /// parcel, falling back to the first when nothing (or a since-removed ref)
  /// is on record.
  static LumeParcel selected(List<LumeParcel> parcels, String? ref) => parcels
      .firstWhere((LumeParcel p) => p.ref == ref, orElse: () => parcels.first);

  @override
  ConsumerState<LumeParcelTool> createState() => _LumeParcelToolState();
}

class _LumeParcelToolState extends ConsumerState<LumeParcelTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _ref = TextEditingController(
    text: _session.read(LumeParcelTool.id, 'pc_ref') ?? '',
  );
  final FocusNode _refFocus = FocusNode();

  @override
  void dispose() {
    _ref.dispose();
    _refFocus.dispose();
    super.dispose();
  }

  void _setRef(String v) =>
      setState(() => _session.write(LumeParcelTool.id, 'pc_ref', v));

  void _select(String ref) =>
      setState(() => _session.write(LumeParcelTool.id, 'parcel', ref));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    const List<LumeParcel> parcels = LumeParcelBoard.parcels;
    final LumeParcel p = LumeParcelTool.selected(
      parcels,
      _session.read(LumeParcelTool.id, 'parcel'),
    );
    final String stage = LumeParcelStrings.stage(l, p.stage);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      actions: LumeToolActions(onSearch: _refFocus.requestFocus),
      // The reference shares an unrelated quote (C68); this shares the
      // chosen parcel and its current stage.
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.reminder,
        text: l.parcelShareText(p.item, stage),
        source: '${p.carrier} · ${p.ref}',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeCard(
              child: LumeToolField(
                key: LumeParcelTool.fieldKey,
                label: l.parcelTrackingLabel,
                controller: _ref,
                placeholder: l.parcelPlaceholder,
                onChanged: _setRef,
              ),
            ),
          ),
          LumeToolSection(
            child: LumeButtonRow(
              key: LumeParcelTool.trackKey,
              children: <Widget>[
                LumeButton.accent(
                  label: l.parcelTrack,
                  icon: LumeIcons.search,
                  block: true,
                  // The reference's own toast: fixed words that answer
                  // whatever was typed, or nothing, the same way — there is
                  // no lookup behind it.
                  onPressed: () => _host.currentState?.say(l.parcelLookingUp),
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.parcelActive,
            child: LumeRows(
              key: LumeParcelTool.listKey,
              children: <Widget>[
                for (final LumeParcel x in parcels)
                  LumeRichRow(
                    logo: x.logo,
                    iconTone: LumeParcelTool.toneOf(context.lume, x.tone),
                    title: x.item,
                    subtitle: '${x.carrier} · ${x.ref}',
                    meta: <String>[x.place, x.eta],
                    badge: LumeBadge(
                      label: LumeParcelStrings.stage(l, x.stage),
                      tone: x.badge,
                    ),
                    selected: x.ref == p.ref,
                    onTap: () => _select(x.ref),
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: p.item,
            child: LumeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LumeMetrics(
                    key: LumeParcelTool.metricsKey,
                    columns: 3,
                    children: <Widget>[
                      LumeMetric(
                        icon: LumeIcons.package,
                        value: p.carrier,
                        label: l.parcelCarrier,
                      ),
                      LumeMetric(
                        icon: LumeIcons.pin,
                        value: p.place,
                        label: l.parcelLastSeen,
                      ),
                      LumeMetric(
                        icon: LumeIcons.clock,
                        value: p.eta,
                        label: l.parcelExpected,
                      ),
                    ],
                  ),
                  const SizedBox(height: LumeSpace.x4),
                  LumeProgressBar(
                    key: LumeParcelTool.progressKey,
                    value: p.progress,
                    label: p.item,
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            title: l.parcelJourney,
            child: LumeTimeline(
              key: LumeParcelTool.timelineKey,
              entries: <LumeTimelineEntry>[
                for (final LumeParcelEvent e in p.events)
                  LumeTimelineEntry(
                    time: e.time,
                    title: LumeParcelStrings.stage(l, e.stage),
                    subtitle: e.place,
                    state: e.state,
                  ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeButtonRow(
              key: LumeParcelTool.actionsKey,
              children: <Widget>[
                LumeButton.accent(
                  label: l.parcelNotify,
                  icon: LumeIcons.bell,
                  // Another toast, not a subscription — the reference keeps
                  // no list of who asked to be notified.
                  onPressed: () => _host.currentState?.say(l.parcelNotifying),
                ),
                LumeButton(
                  label: l.commonShare,
                  icon: LumeIcons.share,
                  onPressed: () => _host.currentState?.share(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
