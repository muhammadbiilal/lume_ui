/// To-dos on the record layer — `record-schemas.js` `todos`.
///
/// A task is its words, a list, an optional due day, a priority, whether it
/// is done, and notes. Guide: "due state and completion" · "undo and
/// recurrence". A task is ticked from its row (`rec:toggle`) with no form;
/// nothing about a task schedules a notification — a due day is a date the
/// reader reads, not a reminder (Reminders, which would deliver one, is not
/// built).
library;

import '../../../core/icons/lume_icons.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/data/record_seeds.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_schema.dart';
import '../../records/presentation/record_family.dart';

/// `options.lists`, with the icon the reference's list rows carry.
enum LumeTodoList {
  work('@todos.listWork', LumeIcons.grid),
  home('@todos.listHome', LumeIcons.home),
  personal('@todos.listPersonal', LumeIcons.user);

  const LumeTodoList(this.legacy, this.icon);

  final String legacy;
  final String icon;

  static LumeTodoList? byId(Object? v) {
    for (final LumeTodoList x in values) {
      if (v == x.name || v == x.legacy) return x;
    }
    return null;
  }

  String label(AppLocalizations l) => switch (this) {
    work => l.todosListWork,
    home => l.todosListHome,
    personal => l.todosListPersonal,
  };
}

/// `options.priority`. Anything but `high` reads as normal, as `row()` does.
enum LumeTodoPriority {
  normal,
  high;

  static LumeTodoPriority of(Object? v) => v == 'high' ? high : normal;

  String label(AppLocalizations l) =>
      this == high ? l.recPriorityHigh : l.recPriorityNormal;
}

class LumeTodo extends LumeFamilyRecord {
  const LumeTodo(
    super.record, {
    required this.label,
    required this.list,
    required this.due,
    required this.priority,
    required this.done,
    required this.notes,
  });

  final String label;
  final LumeTodoList? list;

  /// A calendar day, or `null` — "No due date".
  final DateTime? due;

  final LumeTodoPriority priority;
  final bool done;
  final String notes;

  /// `!r.done && relDays(r.due) < 0`.
  bool overdueOn(DateTime now) =>
      !done && (LumeFamilyText.daysFrom(due, now) ?? 0) < 0;
}

class LumeTodoFamily extends LumeRecordFamily<LumeTodo> {
  const LumeTodoFamily();

  static const LumeRecordSchema kSchema = LumeRecordSchema(
    collection: 'todos',
    fields: <LumeRecordField>[
      LumeRecordField(
        name: 'label',
        kind: LumeRecordFieldKind.text,
        required: true,
      ),
      LumeRecordField(name: 'list', kind: LumeRecordFieldKind.select),
      LumeRecordField(
        name: 'due',
        kind: LumeRecordFieldKind.date,
        optional: true,
      ),
      LumeRecordField(name: 'priority', kind: LumeRecordFieldKind.select),
      LumeRecordField(name: 'done', kind: LumeRecordFieldKind.check),
      LumeRecordField(
        name: 'notes',
        kind: LumeRecordFieldKind.textarea,
        optional: true,
        wide: true,
      ),
    ],
  );

  @override
  LumeRecordSchema get schema => kSchema;

  @override
  String get icon => LumeIcons.checkSquare;

  @override
  String noun(AppLocalizations l) => l.recTodosNoun;
  @override
  String nounPlural(AppLocalizations l) => l.recTodosNounPlural;
  @override
  String emptyTitle(AppLocalizations l) => l.recTodosEmptyTitle;
  @override
  String emptyText(AppLocalizations l) => l.recTodosEmptyText;

  static String seeded(AppLocalizations l, String key) => switch (key) {
    'todosSeedItem1' => l.todosSeedItem1,
    'todosSeedItem2' => l.todosSeedItem2,
    'todosSeedItem3' => l.todosSeedItem3,
    'todosSeedItem4' => l.todosSeedItem4,
    _ => '@$key',
  };

  @override
  LumeTodo read(LumeRecord r, LumeRecordContext c) => LumeTodo(
    r,
    label: LumeFamilyText.resolve(r, 'label', (String k) => seeded(c.l, k)),
    list: LumeTodoList.byId(r['list']),
    due: LumeFamilyText.day(r['due']),
    priority: LumeTodoPriority.of(r['priority']),
    done: r['done'] == true,
    notes: LumeFamilyText.resolve(r, 'notes', (String k) => seeded(c.l, k)),
  );

  @override
  Map<String, Object?> defaults(LumeRecordContext c) => <String, Object?>{
    'list': LumeTodoList.values.first.name,
    'due': lumeIsoDay(c.now, 0),
    'priority': LumeTodoPriority.normal.name,
    'done': false,
  };

  @override
  Map<String, Object?> editValues(LumeTodo x) => <String, Object?>{
    'label': x.label,
    'list': x.list?.name ?? '',
    'due': x.due == null ? '' : lumeIsoDay(x.due!, 0),
    'priority': x.priority.name,
    'done': x.done,
    'notes': x.notes,
  };

  @override
  LumeFamilyRow row(LumeTodo x, LumeRecordContext c) => LumeFamilyRow(
    title: x.label,
    subtitle: <String>[
      if (x.list != null) x.list!.label(c.l),
      if (x.due != null) LumeFamilyText.when(c, x.due),
    ].join(' · '),
    badge: x.priority == LumeTodoPriority.high
        ? LumeBadge(label: c.l.recPriorityHigh, tone: LumeBadgeTone.warn)
        : null,
  );

  @override
  LumeFamilyHero hero(LumeTodo x, LumeRecordContext c) => LumeFamilyHero(
    kicker: x.list?.label(c.l) ?? c.l.recTodosNoun,
    value: x.label,
    caption: x.due == null ? c.l.recNoDue : LumeFamilyText.when(c, x.due),
    gradient: (g) => x.done ? g.sport : g.accent,
  );

  @override
  List<LumeFact> facts(LumeTodo x, LumeRecordContext c) => <LumeFact>[
    LumeFact(label: c.l.recFieldList, value: x.list?.label(c.l) ?? '—'),
    LumeFact(
      label: c.l.recFieldDue,
      value: x.due == null ? c.l.recNoDue : c.f.dateShort(x.due!),
    ),
    LumeFact(label: c.l.recFieldPriority, value: x.priority.label(c.l)),
    LumeFact(
      label: c.l.commonStatus,
      value: x.done ? c.l.recDone : c.l.recOpen,
    ),
    LumeFact(
      label: c.l.recFieldNotes,
      value: x.notes.isEmpty ? c.l.recNone : x.notes,
    ),
  ];

  @override
  List<LumeFamilyField> fields(LumeRecordContext c) => <LumeFamilyField>[
    LumeFamilyField(
      name: 'label',
      label: c.l.recFieldTask,
      placeholder: c.l.recTodosPh,
    ),
    LumeFamilyField(
      name: 'list',
      label: c.l.recFieldList,
      options: <LumeFamilyOption>[
        for (final LumeTodoList x in LumeTodoList.values)
          LumeFamilyOption(x.name, x.label(c.l)),
      ],
    ),
    LumeFamilyField(name: 'due', label: c.l.recFieldDue),
    LumeFamilyField(
      name: 'priority',
      label: c.l.recFieldPriority,
      options: <LumeFamilyOption>[
        for (final LumeTodoPriority p in LumeTodoPriority.values)
          LumeFamilyOption(p.name, p.label(c.l)),
      ],
    ),
    LumeFamilyField(name: 'done', label: c.l.recFieldCompleted),
    LumeFamilyField(name: 'notes', label: c.l.recFieldNotes),
  ];

  @override
  List<LumeFamilyFilter<LumeTodo>> filters(
    LumeRecordContext c,
  ) => <LumeFamilyFilter<LumeTodo>>[
    LumeFamilyFilter<LumeTodo>('open', c.l.recOpen, (LumeTodo x) => !x.done),
    LumeFamilyFilter<LumeTodo>('done', c.l.recDone, (LumeTodo x) => x.done),
  ];

  @override
  String? checkLabel(AppLocalizations l) => l.recFieldCompleted;

  @override
  bool checked(LumeTodo x) => x.done;

  @override
  Map<String, Object?> toggled(LumeTodo x, LumeRecordContext c) =>
      <String, Object?>{'done': !x.done};
}

/// The composition's figures, from the records (`c.todos()`'s shape).
class LumeTodoBoard {
  LumeTodoBoard(this.all, DateTime now)
    : today = <LumeTodo>[
        for (final LumeTodo x in all)
          if (x.due == null || LumeFamilyText.daysFrom(x.due, now)! <= 0) x,
      ],
      upcoming = <LumeTodo>[
        for (final LumeTodo x in all)
          if (!x.done &&
              x.due != null &&
              LumeFamilyText.daysFrom(x.due, now)! > 0)
            x,
      ]..sort((LumeTodo a, LumeTodo b) => a.due!.compareTo(b.due!)),
      overdue = all.where((LumeTodo x) => x.overdueOn(now)).length,
      done7 = all
          .where(
            (LumeTodo x) =>
                x.done &&
                now.difference(x.record.updatedAt) < const Duration(days: 7),
          )
          .length;

  final List<LumeTodo> all;

  /// What is on today: due today or before, or undated.
  final List<LumeTodo> today;

  /// Open and due after today, soonest first.
  final List<LumeTodo> upcoming;

  final int overdue;

  /// Done, and last changed within seven days — the store keeps no separate
  /// completion time, so a done task edited this week counts too.
  final int done7;

  int get doneToday => today.where((LumeTodo x) => x.done).length;

  double get share => today.isEmpty ? 0 : doneToday / today.length;

  int openIn(LumeTodoList list) =>
      all.where((LumeTodo x) => !x.done && x.list == list).length;
}
