/// To-dos — `tools/planning/todos.tool.js` under `crud-engine.js`.
///
/// The reader's tasks lead — search, Open and Done chips, and the records,
/// each ticked from its row — and the tool's own composition follows: a
/// summary of today with its ring, the When and Priority filters, the
/// filtered tasks, what is coming up, and the lists with how many are open.
///
/// The reference draws that composition from its own fixture — six tasks
/// that are not the records, "1 overdue" and "12 done this week" whatever
/// the reader does, and ticks that write nowhere the records can see. Here
/// it reads the same records the list does, with the reference's formulas,
/// so a tick in either place is the same write (C86). Nothing here delivers
/// a notification.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/widgets/lume/lume_agenda.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/presentation/record_family.dart';
import '../../records/presentation/record_tool.dart';
import '../../tools/application/tool_request.dart';
import '../domain/todo_family.dart';

/// `c.filter('when')`.
enum LumeTodoWhen { today, week, all }

abstract final class LumeTodosTool {
  static const String id = 'todos';
  static const LumeRecordKeys keys = LumeRecordKeys(id);

  static const Key summaryKey = ValueKey<String>('todos.summary');
  static const Key whenKey = ValueKey<String>('todos.when');
  static const Key priorityKey = ValueKey<String>('todos.priority');
  static const Key visibleKey = ValueKey<String>('todos.visible');
  static const Key emptyKey = ValueKey<String>('todos.empty');
  static const Key upcomingKey = ValueKey<String>('todos.upcoming');
  static const Key listsKey = ValueKey<String>('todos.lists');
  static const Key fabKey = ValueKey<String>('todos.fab');

  static Key taskKey(String id) => ValueKey<String>('todos.task.$id');
  static Key whenChip(LumeTodoWhen w) =>
      ValueKey<String>('todos.when.${w.name}');
  static Key priorityChip(String p) => ValueKey<String>('todos.priority.$p');

  static Widget open(LumeToolRequest request) => LumeRecordTool<LumeTodo>(
    request: request,
    family: const LumeTodoFamily(),
    compose: _compose,
    floating: (BuildContext context, LumeRecordScope<LumeTodo> s) => LumeFab(
      key: fabKey,
      label: s.c.l.todosAdd,
      icon: LumeIcons.plus,
      onPressed: s.create,
    ),
  );

  /// The tasks the chosen filters and the shared query keep.
  static List<LumeTodo> visible(
    LumeTodoBoard board,
    LumeTodoWhen when,
    String priority,
    String query,
    LumeRecordContext c,
  ) {
    final Iterable<LumeTodo> pool = switch (when) {
      LumeTodoWhen.today => board.today,
      // The reference's Week and All pick the same tasks; a week here is
      // today's and the next seven days' (C86).
      LumeTodoWhen.week => <LumeTodo>[
        ...board.today,
        ...board.upcoming.where(
          (LumeTodo x) => LumeFamilyText.daysFrom(x.due, c.now)! <= 7,
        ),
      ],
      LumeTodoWhen.all => <LumeTodo>[...board.today, ...board.upcoming],
    };
    final String q = query.trim().toLowerCase();
    return <LumeTodo>[
      for (final LumeTodo x in pool)
        if ((priority == 'any' || x.priority.name == priority) &&
            (q.isEmpty ||
                '${x.label} ${x.list?.label(c.l) ?? ''}'.toLowerCase().contains(
                  q,
                )))
          x,
    ];
  }

  static String _whenLabel(AppLocalizations l, LumeTodoWhen w) => switch (w) {
    LumeTodoWhen.today => l.commonToday,
    LumeTodoWhen.week => l.commonWeek,
    LumeTodoWhen.all => l.commonAll,
  };

  static List<Widget> _compose(
    BuildContext context,
    LumeRecordScope<LumeTodo> s,
  ) {
    final LumeRecordContext c = s.c;
    final AppLocalizations l = c.l;
    final LumeTodoBoard board = LumeTodoBoard(s.items, c.now);
    final LumeTodoWhen when = LumeTodoWhen.values.firstWhere(
      (LumeTodoWhen w) => w.name == s.read('when'),
      orElse: () => LumeTodoWhen.today,
    );
    final String priority = s.read('priority') ?? 'any';
    final List<LumeTodo> shown = visible(board, when, priority, s.query, c);
    final int pct = (board.share * 100).round();

    String meta(LumeTodo x) => <String>[
      if (x.list != null) x.list!.label(l),
      if (x.due != null) LumeFamilyText.when(c, x.due),
    ].join(' · ');

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: summaryKey,
          kicker: l.todosToday,
          value: c.f.integer(board.doneToday),
          valueSmall: '/ ${c.f.integer(board.today.length)}',
          caption: board.overdue > 0
              ? l.todosOverdueN(board.overdue)
              : l.todosOnTrack,
          aside: LumeProgressRing(
            value: board.share,
            centreValue: '${c.f.integer(pct)}%',
            label: l.todosToday,
          ),
          stats: <LumeStat>[
            LumeStat(value: c.f.integer(board.overdue), label: l.commonOverdue),
            LumeStat(
              value: c.f.integer(board.upcoming.length),
              label: l.todosUpcoming,
            ),
            LumeStat(value: c.f.integer(board.done7), label: l.todosDone7),
          ],
        ),
      ),
      LumeToolSection(
        spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              container: true,
              label: l.todosWhen,
              child: LumeFilterBar(
                key: whenKey,
                gutters: false,
                children: <Widget>[
                  for (final LumeTodoWhen w in LumeTodoWhen.values)
                    LumeFilterChip(
                      key: whenChip(w),
                      label: _whenLabel(l, w),
                      selected: w == when,
                      onTap: () => s.write('when', w.name),
                    ),
                ],
              ),
            ),
            Semantics(
              container: true,
              label: l.todosPriority,
              child: LumeFilterBar(
                key: priorityKey,
                gutters: false,
                children: <Widget>[
                  for (final (String v, String label) in <(String, String)>[
                    ('any', l.commonAll),
                    ('high', l.todosHigh),
                    ('normal', l.todosNormal),
                  ])
                    LumeFilterChip(
                      key: priorityChip(v),
                      label: label,
                      selected: v == priority,
                      onTap: () => s.write('priority', v),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      LumeToolSection(
        spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
        title: _whenLabel(l, when),
        child: shown.isEmpty
            ? LumeToolState(
                key: emptyKey,
                icon: LumeIcons.checkCircle,
                title: l.todosClear,
                text: l.todosClearText,
              )
            : LumeRows(
                key: visibleKey,
                children: <Widget>[
                  for (final LumeTodo x in shown)
                    LumeCheckRow(
                      key: taskKey(x.id),
                      label: x.label,
                      meta: meta(x),
                      done: x.done,
                      trailing: x.priority == LumeTodoPriority.high
                          ? LumeBadge(
                              label: l.todosHigh,
                              tone: LumeBadgeTone.warn,
                            )
                          : null,
                      onToggle: () => s.toggle(x),
                    ),
                ],
              ),
      ),
      if (board.upcoming.isNotEmpty)
        LumeToolSection(
          title: l.todosUpcoming,
          child: LumeRows(
            key: upcomingKey,
            children: <Widget>[
              for (final LumeTodo x in board.upcoming)
                LumeCompactRow(
                  icon: LumeIcons.checkSquare,
                  label: x.label,
                  subtitle: x.list?.label(l),
                  value: LumeFamilyText.when(c, x.due),
                  onTap: () => s.open(x.id),
                ),
            ],
          ),
        ),
      LumeToolSection(
        title: l.todosLists,
        child: LumeRows(
          key: listsKey,
          children: <Widget>[
            for (final LumeTodoList list in LumeTodoList.values)
              LumeCompactRow(
                icon: list.icon,
                label: list.label(l),
                value: l.todosOpenN(board.openIn(list)),
                chevron: false,
              ),
          ],
        ),
      ),
    ];
  }
}
