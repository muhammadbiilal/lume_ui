/// Water — `tools/personal/water.tool.js` (36 lines) under `crud-engine.js`.
///
/// The reader's drinks lead, as they do in every record tool — search and
/// the list, with no filter chips, because the reference's schema declares
/// no `filters` and a family's chips are its schema's — and the tool's own
/// composition follows: what today adds up to, two buttons that log a glass,
/// today's intake on a timeline, and the daily goal with a way to change it.
///
/// Every one of those figures is read from the records. The reference's are
/// not: its total is `stateFor('water').ml`, seeded at 1250 in
/// `context.js:1622` and only ever added to in memory; its timeline is four
/// literals (`context.js:1636-1641`) although its own record schema holds the
/// same four drinks; its "Day streak" is `streak: 6`, a number with nothing
/// behind it; and its fifth section is a bar chart of seven constants,
/// `week: [1800, 2100, 1650, 2000, 1900, 2200, 1250]` under M T W T F S S
/// with the last bar highlighted. The streak and the week chart are not
/// converted — the store holds neither, and drawing either would mean
/// inventing a week of the reader's life. Nothing replaces them: the goal
/// takes the fifth section's place, and today's count of logged drinks takes
/// the streak's slot in the summary, because that one is a real count of real
/// records.
///
/// **The goal.** 2000 ml is a default goal and nothing more — never a
/// recommendation, a requirement or a healthy amount, never derived from
/// anything about the reader's body or circumstances, and always editable.
/// It is stored with the tool's records rather than compiled in, so every
/// figure here is measured against the target the reader is currently on, and
/// while they have never set one the row says "Default goal" beside it. See
/// `domain/water_goal.dart`. There is no advice anywhere in this tool, no
/// warning, no classification and no verdict: the ring is how full a number
/// the reader chose is, and the words beside it say the same thing without
/// it.
///
/// **Two states the reference cannot reach.** It always has 1250 ml, so it
/// has no empty day — a shipping build opens with one, and says so rather
/// than drawing a filled ring over zeros. And it reads one clock, so it never
/// meets a reader whose own day cannot be worked out; when that happens here,
/// everything that counts by day gives way to [LumeRecordDayUnknown], exactly
/// as Events does.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_gradients.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/data/record_seeds.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/presentation/record_family.dart';
import '../../records/presentation/record_tool.dart';
import '../../tools/application/tool_request.dart';
import '../domain/water_family.dart';
import '../domain/water_goal.dart';

abstract final class LumeWaterTool {
  static const String id = 'water';
  static const LumeRecordKeys keys = LumeRecordKeys(id);

  static const Key summaryKey = ValueKey<String>('water.summary');
  static const Key ringKey = ValueKey<String>('water.ring');
  static const Key buttonsKey = ValueKey<String>('water.buttons');
  static const Key addSmallKey = ValueKey<String>('water.addSmall');
  static const Key addLargeKey = ValueKey<String>('water.addLarge');
  static const Key timelineKey = ValueKey<String>('water.timeline');
  static const Key goalKey = ValueKey<String>('water.goal');
  static const Key goalEditKey = ValueKey<String>('water.goalEdit');
  static const Key goalFieldKey = ValueKey<String>('water.goalField');
  static const Key goalSaveKey = ValueKey<String>('water.goalSave');
  static const Key nothingKey = ValueKey<String>('water.nothing');
  static const Key dayUnknownKey = ValueKey<String>('water.dayUnknown');

  /// `var add = bits[0] === 'large' ? 500 : 250` (`tool.screen.js:250`). The
  /// two buttons log the same two amounts in every unit system; only their
  /// labels change, because what is stored is millilitres.
  static const int smallMl = 250;
  static const int largeMl = 500;

  static Widget open(LumeToolRequest request) => LumeRecordTool<LumeDrink>(
    request: request,
    family: const LumeWaterFamily(),
    compose: _compose,
  );

  static List<Widget> _compose(
    BuildContext context,
    LumeRecordScope<LumeDrink> scope,
  ) => <Widget>[_LumeWaterBody(scope: scope)];
}

/// The composition, as one widget, because it reads a second collection.
///
/// The goal lives beside the drinks in the same store, and somebody has to
/// ask for it to be read. The host opens only the family's own collection, so
/// this opens the other — once, here, rather than from four places that each
/// need the figure. The host listens to the whole repository, so a write to
/// either collection rebuilds it and this with it.
class _LumeWaterBody extends ConsumerStatefulWidget {
  const _LumeWaterBody({required this.scope});

  final LumeRecordScope<LumeDrink> scope;

  @override
  ConsumerState<_LumeWaterBody> createState() => _LumeWaterBodyState();
}

class _LumeWaterBodyState extends ConsumerState<_LumeWaterBody> {
  static const LumeWaterFamily _family = LumeWaterFamily();

  late final LumeRecordRepository _repo = ref.read(recordRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _repo.open(kLumeWaterGoalCollection);
  }

  LumeRecordScope<LumeDrink> get _scope => widget.scope;

  /// Log one glass: the amount, water, the time now and today's date.
  void _log(int ml) {
    final LumeRecordContext c = _scope.c;
    if (!c.dayKnown) return;
    final LumeWriteResult result = _repo
        .create(LumeWaterFamily.kSchema.collection, <String, Object?>{
          'ml': ml,
          'kind': LumeDrinkKind.water.name,
          'at': LumeFamilyText.isoClock(c.local.hour, c.local.minute),
          'date': lumeIsoDay(c.today, 0),
        });
    if (!result.ok) {
      _scope.say(c.l.recSaveFailed, tone: LumeToastTone.error);
      return;
    }
    _scope.say(c.l.waterAdded(LumeWaterVolume.amount(c, ml)));
  }

  Future<void> _editGoal(LumeWaterGoal goal) async {
    final LumeRecordContext c = _scope.c;
    final int? ml = await showLumeSheet<int>(
      context: context,
      barrierLabel: c.l.waterGoal,
      child: _LumeWaterGoalSheet(goal: goal),
    );
    if (ml == null || !mounted) return;

    const String coll = kLumeWaterGoalCollection;
    final Map<String, Object?> fields = <String, Object?>{'ml': ml};
    LumeWriteResult result = goal.recordId == null
        ? _repo.create(coll, fields)
        : _repo.update(
            coll,
            goal.recordId!,
            fields,
            expectVersion: goal.version,
          );
    // The one goal record was removed under us. Writing a new one is what the
    // reader asked for; refusing would leave them with a goal they did not
    // choose and no way to say so.
    if (!result.ok && result.failure == LumeWriteFailure.missing) {
      result = _repo.create(coll, fields);
    }
    _scope.say(
      result.ok ? c.l.recUpdated : c.l.recSaveFailed,
      tone: result.ok ? LumeToastTone.success : LumeToastTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LumeRecordScope<LumeDrink> s = _scope;
    final LumeRecordContext c = s.c;
    final AppLocalizations l = c.l;
    final LumeCollectionView goalView = _repo.view(kLumeWaterGoalCollection);

    // Nothing at all until both collections have answered. A total of zero
    // over a store that has not been read yet is not a reading, and "nothing
    // logged today" would be a claim about a day nobody has looked at. The
    // host is drawing its own skeleton above this.
    if (s.status == LumeCollectionStatus.loading ||
        goalView.status == LumeCollectionStatus.loading) {
      return const SizedBox.shrink();
    }

    // Every section below counts by the reader's calendar day. Without one,
    // none of them can be drawn — not even the goal, which is a goal *per
    // day*.
    if (!c.dayKnown) {
      return LumeToolSection(
        title: l.waterToday,
        child: LumeRecordDayUnknown(key: LumeWaterTool.dayUnknownKey, c: c),
      );
    }

    final LumeWaterGoal goal = LumeWaterGoal.from(goalView);
    final List<LumeDrink> drinks = LumeWaterFamily.today(s.items, c.today);
    final int total = LumeWaterFamily.totalMl(s.items, c.today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (drinks.isEmpty)
          LumeToolSection(
            child: LumeToolState(
              key: LumeWaterTool.nothingKey,
              icon: LumeIcons.droplet,
              title: l.waterNothingTitle,
              text: l.waterNothingText,
            ),
          )
        else
          LumeToolSection(child: _summary(context, c, goal, drinks, total)),
        LumeToolSection(child: _buttons(c)),
        if (drinks.isNotEmpty)
          LumeToolSection(
            title: l.waterTimeline,
            child: LumeTimeline(
              key: LumeWaterTool.timelineKey,
              entries: <LumeTimelineEntry>[
                for (final LumeDrink x in drinks)
                  LumeTimelineEntry(
                    time: _family.time(x, c),
                    title: LumeWaterVolume.amount(c, x.ml!),
                    subtitle: x.kind.label(l),
                    icon: LumeIcons.droplet,
                    // Everything on this list has already happened.
                    state: LumeTimelineState.done,
                  ),
              ],
            ),
          ),
        LumeToolSection(child: _goalRow(c, goal)),
      ],
    );
  }

  Widget _summary(
    BuildContext context,
    LumeRecordContext c,
    LumeWaterGoal goal,
    List<LumeDrink> drinks,
    int total,
  ) {
    final AppLocalizations l = c.l;
    final LumeGradient sky = context.lumeGradients.sky;
    final String target = LumeWaterVolume.total(c, goal.ml);
    // The ring's per cent, in words as well as in the arc — §60 asks that no
    // status be carried by one indicator alone, and the three figures under
    // the card say the same thing without looking at it.
    final String percent = c.f.percent(
      LumeWaterFamily.percent(total, goal.ml),
      decimals: 0,
    );

    return LumeSummaryCard(
      key: LumeWaterTool.summaryKey,
      gradient: sky,
      kicker: l.waterToday,
      value: LumeWaterVolume.total(c, total),
      // Which target this is measured against, and whether anybody chose it.
      caption: goal.chosen ? l.waterOfTarget(target) : l.waterOfDefault(target),
      aside: LumeProgressRing(
        key: LumeWaterTool.ringKey,
        value: LumeWaterFamily.fraction(total, goal.ml),
        centreValue: percent,
        valueText: percent,
        label: l.waterProgress,
        tone: sky.on,
        centreInk: sky.on,
      ),
      stats: <LumeStat>[
        LumeStat(
          value: LumeWaterVolume.total(
            c,
            LumeWaterFamily.remaining(total, goal.ml),
          ),
          label: l.waterRemaining,
        ),
        LumeStat(
          value: c.f.integer(LumeWaterFamily.glasses(total)),
          label: l.waterGlasses,
        ),
        // Where the reference prints `streak: 6`. This one is a count of the
        // records above it.
        LumeStat(value: c.f.integer(drinks.length), label: l.waterLogged),
      ],
    );
  }

  Widget _buttons(LumeRecordContext c) {
    final String small = LumeWaterVolume.amount(c, LumeWaterTool.smallMl);
    final String large = LumeWaterVolume.amount(c, LumeWaterTool.largeMl);
    return LumeButtonRow(
      key: LumeWaterTool.buttonsKey,
      children: <Widget>[
        // The reference labels these with a bare amount — "+ 250 ml" — which
        // a screen reader reads out as a loose number. The label stays; what
        // is announced is a sentence.
        LumeButton.accent(
          key: LumeWaterTool.addSmallKey,
          label: '+ $small',
          icon: LumeIcons.plus,
          semanticLabel: c.l.waterAddSmall(small),
          onPressed: () => _log(LumeWaterTool.smallMl),
        ),
        LumeButton(
          key: LumeWaterTool.addLargeKey,
          label: '+ $large',
          icon: LumeIcons.droplet,
          semanticLabel: c.l.waterAddSmall(large),
          onPressed: () => _log(LumeWaterTool.largeMl),
        ),
      ],
    );
  }

  Widget _goalRow(LumeRecordContext c, LumeWaterGoal goal) {
    final AppLocalizations l = c.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LumeRows(
          key: LumeWaterTool.goalKey,
          children: <Widget>[
            LumeRichRow(
              icon: LumeIcons.target,
              title: l.waterGoal,
              // The mark is there until the reader chooses, and gone after.
              subtitle: goal.chosen ? null : l.waterGoalDefault,
              value: LumeWaterVolume.total(c, goal.ml),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LumeButton(
          key: LumeWaterTool.goalEditKey,
          label: l.waterSetGoal,
          icon: LumeIcons.sliders,
          onPressed: () => unawaited(_editGoal(goal)),
        ),
      ],
    );
  }
}

/// The one field that changes the goal.
///
/// It refuses rather than corrects: a zero, a negative and anything past ten
/// litres come back as an error in the form's own style, and the reader types
/// another figure. Silently clamping would hand them a goal they did not
/// choose while the row went on saying they had.
class _LumeWaterGoalSheet extends StatefulWidget {
  const _LumeWaterGoalSheet({required this.goal});

  final LumeWaterGoal goal;

  @override
  State<_LumeWaterGoalSheet> createState() => _LumeWaterGoalSheetState();
}

class _LumeWaterGoalSheetState extends State<_LumeWaterGoalSheet> {
  // The goal as it stands, in plain digits: what `num.tryParse` reads back.
  // Grouped digits ("2,000") would not parse, and the field takes the
  // reader's own numerals as well as Latin ones either way.
  late final TextEditingController _field = TextEditingController(
    text: '${widget.goal.ml}',
  );

  LumeWaterGoalProblem? _problem;
  bool _touched = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  /// §8: judged on blur and on save, never while the reader is still typing
  /// the first digit.
  void _check() =>
      setState(() => _problem = LumeWaterGoalEntry.parse(_field.text).problem);

  void _save() {
    final LumeWaterGoalEntry entry = LumeWaterGoalEntry.parse(_field.text);
    if (!entry.ok) {
      setState(() {
        _touched = true;
        _problem = entry.problem;
      });
      return;
    }
    Navigator.of(context).pop(entry.ml);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String? error = !_touched
        ? null
        : switch (_problem) {
            LumeWaterGoalProblem.missing => l.recErrRequired(l.waterGoalMl),
            LumeWaterGoalProblem.notPositive => l.recErrPositive,
            // There is no Water string for a figure that is too large, and
            // adding one is not this tool's to add; this sentence already
            // says exactly that, in all three languages.
            LumeWaterGoalProblem.tooLarge => l.commErrTooLarge,
            null => null,
          };

    return LumeSheet(
      title: l.waterGoal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LumeFormField(
            key: LumeWaterTool.goalFieldKey,
            label: l.waterGoalMl,
            controller: _field,
            kind: LumeFieldKind.number,
            localDigits: true,
            required: true,
            autofocus: true,
            // What the goal is, said plainly, under the field that sets it.
            hint: l.waterGoalHint,
            error: error,
            onChanged: (String _) {
              if (_touched) _check();
            },
            onEditingComplete: () {
              _touched = true;
              _check();
            },
          ),
          const SizedBox(height: 20),
          LumeButton.accent(
            key: LumeWaterTool.goalSaveKey,
            label: l.actionSave,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
