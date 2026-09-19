/// Events — `tools/planning/events.tool.js` under `crud-engine.js`.
///
/// The reader's events lead — search and the records — and the tool's own
/// section follows: what is coming up, soonest first, with where and how
/// many are going. The reference draws that section from three fixture
/// events, one of which is not in the records; here it reads the records,
/// from today on (C86). A row opens its event. Nothing here schedules or
/// delivers a notification.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../records/presentation/record_family.dart';
import '../../records/presentation/record_tool.dart';
import '../../tools/application/tool_request.dart';
import '../domain/event_family.dart';

abstract final class LumeEventsTool {
  static const String id = 'events';
  static const LumeRecordKeys keys = LumeRecordKeys(id);

  static const Key upcomingKey = ValueKey<String>('events.upcoming');
  static const Key emptyKey = ValueKey<String>('events.empty');
  static const Key dayUnknownKey = ValueKey<String>('events.dayUnknown');

  static Widget open(LumeToolRequest request) => LumeRecordTool<LumeEvent>(
    request: request,
    family: const LumeEventFamily(),
    compose: _compose,
  );

  /// From today on, soonest first, kept by the shared query over the title
  /// and the place — the reference's own search.
  static List<LumeEvent> upcoming(
    List<LumeEvent> all,
    String query,
    DateTime now,
  ) {
    final String q = query.trim().toLowerCase();
    return <LumeEvent>[
      for (final LumeEvent x in all)
        if (x.date != null &&
            LumeFamilyText.daysFrom(x.date, now)! >= 0 &&
            (q.isEmpty || '${x.title} ${x.where}'.toLowerCase().contains(q)))
          x,
    ]..sort((LumeEvent a, LumeEvent b) => a.starts!.compareTo(b.starts!));
  }

  static List<Widget> _compose(
    BuildContext context,
    LumeRecordScope<LumeEvent> s,
  ) {
    final LumeRecordContext c = s.c;
    if (!c.dayKnown) {
      return <Widget>[
        LumeToolSection(
          title: c.l.eventsUpcoming,
          child: LumeRecordDayUnknown(key: dayUnknownKey, c: c),
        ),
      ];
    }
    final LumeColors lume = context.lume;
    const LumeEventFamily family = LumeEventFamily();
    final List<LumeEvent> rows = upcoming(s.items, s.query, c.today);

    return <Widget>[
      LumeToolSection(
        title: c.l.eventsUpcoming,
        child: rows.isEmpty
            ? LumeToolState(
                key: emptyKey,
                icon: LumeIcons.calendar,
                title: c.l.eventsNoMatch,
                text: c.l.eventsNoMatchText,
              )
            : LumeRows(
                key: upcomingKey,
                children: <Widget>[
                  for (final LumeEvent x in rows)
                    LumeRichRow(
                      icon: LumeIcons.calendar,
                      // `iconTone: 'accent'`.
                      iconTone: lume.tintAccent,
                      iconInk: lume.accent,
                      title: x.title,
                      subtitle: x.where.isEmpty ? null : x.where,
                      meta: <String>[
                        <String>[
                          family.time(x, c),
                          LumeFamilyText.when(c, x.date),
                        ].where((String p) => p.isNotEmpty).join(' · '),
                        if (x.people != null) c.l.eventsPeople(x.people!),
                      ],
                      chevron: true,
                      onTap: () => s.open(x.id),
                    ),
                ],
              ),
      ),
    ];
  }
}
