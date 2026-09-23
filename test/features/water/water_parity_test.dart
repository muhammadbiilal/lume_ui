/// Water against the running reference — the parity day's four drinks.
///
/// The cells were measured in a browser with `measure_destinations.mjs
/// --tool water`, and [ToolParity] compares each recorded
/// `getBoundingClientRect` against the finder for the same element, relative
/// to the tool bar on both sides. Only the parity build is compared: Water's
/// four seeded drinks exist only there (`kLumeParityOnlySeeds`), and a
/// development or release build opens the collection empty
/// (`water_screen_test.dart`).
///
/// **The reference's fifth section is not Flutter's.** It draws seven:
/// records, the summary, the two buttons, "Today's intake", **"This week"**,
/// the source bar and "Related tools". The fifth is a bar chart of seven
/// constants — `week: [1800, 2100, 1650, 2000, 1900, 2200, 1250]`, which the
/// store holds nothing behind — and it is recorded as dropped in
/// `ROLLOUT_WAVE_4.md` §2 and §7. Flutter's fifth section is the daily goal,
/// the approved functional correction for a reference that fixes 2000 ml with
/// no way to change it. So `bars`, `bars.*`, `kard` and `kard2` are not
/// mapped across — there is nothing on this side that is the same thing — and
/// what the reference draws there is asserted as a subtraction in the second
/// group, with the seven figures named. Everything above the swapped section
/// compares with no allowance at all; everything below it carries one
/// recorded number, [_kWeekForGoal].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icon.dart';
import 'package:lume/core/localization/lume_numerals.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/records/presentation/record_tool.dart';
import 'package:lume/features/water/domain/water_family.dart';
import 'package:lume/features/water/presentation/water_tool.dart';

import '../../helpers/load_fonts.dart';
import '../tools/tool_parity.dart';
import 'water_harness.dart';

/// The reference's fifth section, gap included — `sect5.height` 181 under the
/// 24 every `.sect` carries — against Flutter's daily goal section, 144 with
/// its own gap inside it: everything after the swapped section sits 61 points
/// higher on this side.
const double _kWeekForGoal = -61;

/// A `LumeToolSection` carries the gap above it *inside* its own box; the
/// reference's `<section>` has it as a margin, outside. 24 for a plain
/// section, 16 for the record list's `.sect--tight`.
const double _kSectionGap = -24;
const double _kTightGap = -16;

/// Flutter's record detail adds two facts the reference's has not — the
/// amount and the day — at 53 points each, hairline included.
const double _kTwoAddedFacts = 106;

Finder _inKey(Key k, Finder m) =>
    find.descendant(of: find.byKey(k), matching: m);

Finder _inType(Type t, Finder m) =>
    find.descendant(of: find.byType(t), matching: m);

/// The first record card's own descendants.
Finder _inRow1(Finder m) =>
    find.descendant(of: find.byType(LumeRecordRow).first, matching: m);

/// A `Container` constrained to [w] × [h] — the disc, the timeline node.
Finder _box(double w, double h) => find.byWidgetPredicate(
  (Widget x) =>
      x is Container &&
      x.constraints == BoxConstraints.tightFor(width: w, height: h),
);

/// `.related__item` — 78 wide, as tall as the tallest name in the rail.
final Finder _tile = find.byWidgetPredicate(
  (Widget x) => x is Container && x.constraints?.maxWidth == 78,
);

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('water');
  tearDownAll(parity.write);

  const LumeRecordKeys k = LumeWaterTool.keys;
  const Size tall = Size(390, 5000);

  // `<p>`, `<div>` and `<span>`s the width of the box they sit in, where
  // Flutter's text is the width of the text; only position and height
  // compare. The record row's sub also *says* something different — Flutter's
  // carries the day — which the second group asserts in words.
  const Set<String> textBlocks = <String>{
    'toolbar.title',
    'toolbar.sub',
    'rrec.sub',
    'summary.kicker',
    'summary.value',
    'summary.caption',
    'tline.title',
    'tline.sub',
    'chero.kicker',
    'chero.value',
    'chero.caption',
  };

  Map<String, Finder> listElements() => <String, Finder>{
    // Not mapped, and why:
    //
    // `kard`, `kard2`, `bars`, `bars.*` — the week chart, which is not drawn.
    // `srcline` — C85 puts "Sample data" at the head of a parity build's
    //   source line; the reference has no such mark, so the line is 80 points
    //   wider and starts 80 points earlier inside the same end-aligned run.
    //   `srcbar` and `fresh` are compared, and the words are asserted below.
    'toolbar': find.byType(LumeToolbar),
    'toolbar.back': find.byKey(LumeBackButton.circleKey),
    'toolbar.title': _inType(LumeToolbar, find.text('Water')),
    'toolbar.sub': _inType(LumeToolbar, find.text('4 records')),
    'toolbar.actions': find
        .ancestor(of: find.byKey(k.add), matching: find.byType(Row))
        .first,
    'toolbar.textbtn': find.byKey(k.add),
    'search': find.byKey(k.search),
    'search.input': _inKey(k.search, find.byType(TextField)),
    'recs': find.byKey(k.records),
    'rrec1': find.byType(LumeRecordRow).first,
    'rrec2': find.byType(LumeRecordRow).at(1),
    'rrec.disc': _inRow1(_box(38, 38)).first,
    'rrec.title': _inRow1(find.text('Water')).first,
    'rrec.sub': _inRow1(find.text('Today · 8:10 am')),
    'rrec.value': _inRow1(find.byType(LumeNumerals)).first,
    'rrec.chev': _inRow1(find.byType(LumeIcon)).last,
    'sect1': find.byType(LumeToolSection).at(0),
    'sect2': find.byType(LumeToolSection).at(1),
    'sect3': find.byType(LumeToolSection).at(2),
    'sect4': find.byType(LumeToolSection).at(3),
    'summary': find.byKey(LumeWaterTool.summaryKey),
    'summary.kicker': _inKey(LumeWaterTool.summaryKey, find.text('TODAY')),
    'summary.value': _inKey(LumeWaterTool.summaryKey, find.text('1.3 L')),
    'summary.caption': _inKey(
      LumeWaterTool.summaryKey,
      find.text('of the default 2.0 L goal'),
    ),
    // One box in the reference too: `.summary__aside`, `.pring` and the
    // element the ring's ARIA sits on are the same 66-point square.
    'summary.aside': find.byKey(LumeWaterTool.ringKey),
    'summary.ring': find.byKey(LumeWaterTool.ringKey),
    'pring': find.byKey(LumeWaterTool.ringKey),
    'pring.mid': _inKey(LumeWaterTool.ringKey, find.byType(Column)).first,
    'summary.stats': _inKey(
      LumeWaterTool.summaryKey,
      find.byWidgetPredicate(
        (Widget w) =>
            w is Container && w.padding == const EdgeInsets.only(top: 14),
      ),
    ),
    'summary.stat1': find
        .ancestor(
          of: _inKey(LumeWaterTool.summaryKey, find.text('Remaining')),
          matching: find.byType(Column),
        )
        .first,
    'summary.stat2': find
        .ancestor(
          of: _inKey(LumeWaterTool.summaryKey, find.text('Glasses')),
          matching: find.byType(Column),
        )
        .first,
    'summary.stat3': find
        .ancestor(
          of: _inKey(LumeWaterTool.summaryKey, find.text('Logged')),
          matching: find.byType(Column),
        )
        .first,
    'btnrow': find.byKey(LumeWaterTool.buttonsKey),
    'btn1': find.byKey(LumeWaterTool.addSmallKey),
    'btn2': find.byKey(LumeWaterTool.addLargeKey),
    'tline': find.byKey(LumeWaterTool.timelineKey),
    'tline.item1': find
        .ancestor(
          of: _inKey(
            LumeWaterTool.timelineKey,
            find.byType(IntrinsicHeight),
          ).first,
          matching: find.byType(Padding),
        )
        .first,
    'tline.item2': find
        .ancestor(
          of: _inKey(
            LumeWaterTool.timelineKey,
            find.byType(IntrinsicHeight),
          ).at(1),
          matching: find.byType(Padding),
        )
        .first,
    'tline.time': _inKey(
      LumeWaterTool.timelineKey,
      find.byWidgetPredicate((Widget w) => w is SizedBox && w.width == 52),
    ).first,
    'tline.rail': _inKey(
      LumeWaterTool.timelineKey,
      find.byWidgetPredicate((Widget w) => w is SizedBox && w.width == 16),
    ).first,
    'tline.node': _inKey(LumeWaterTool.timelineKey, _box(14, 14)).first,
    'tline.title': _inKey(LumeWaterTool.timelineKey, find.text('250 ml')).first,
    'tline.sub': _inKey(LumeWaterTool.timelineKey, find.text('Water')).first,
    'srcbar': find.byType(LumeSourceBar),
    'fresh': find.byType(LumeFreshness),
    'related': find.byType(LumeRelatedTools),
    'related.sect': find
        .ancestor(
          of: find.byType(LumeRelatedTools),
          matching: find.byType(LumeToolSection),
        )
        .first,
    'related.title': find.text('Related tools'),
    'related.item1': _inType(LumeRelatedTools, _tile).at(0),
    'related.item2': _inType(LumeRelatedTools, _tile).at(1),
  };

  // Only the English cells are compared point for point. The Urdu and Arabic
  // cells were measured in Chrome with its own Noto faces; Flutter loads
  // different ones, so their line boxes differ by a few points everywhere and
  // a bounds comparison would be measuring the font, not the layout. What
  // those cells are for — the words, the direction and the numerals — is
  // asserted in `water_l10n_test.dart`.
  //
  // The wide cells are pumped at the shell's own width, not the reference's
  // viewport: the tool's column is what is left after the rail (84 at medium)
  // or the sidebar (244 at expanded) and the stage's 25-point margins, so 650
  // draws the 566 measured inside 700 and 1050 the 806 measured inside 1100.
  // 852×393 is the height-constrained landscape cell; its column comes from
  // the rail against a 393-point height, which a tall test surface cannot
  // reproduce, so comparing it would measure the stage rather than the tool.
  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_water_default_pk_390x844_light_en', tall),
      ('tool_water_default_pk_390x844_dark_en', tall),
      ('tool_water_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_water_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpWater(
          tester,
          surface: size,
          theme: cell.contains('_dark_') ? ThemeMode.dark : ThemeMode.light,
        );
        final List<String> misses = parity.bounds(
          tester,
          cell,
          listElements(),
          noWidth: textBlocks,
          // Chrome reports the `<input>`'s own 20-point content box; the
          // dense `TextField` that replaces it is its 22-point text line. The
          // reference's `.tline__time` shrink-wraps its one line inside a
          // 52-point gutter; Flutter's is the same 52-point column, stretched
          // to the row it leads. Both compare in position and in width.
          noHeight: const <String>{'search.input', 'tline.time'},
          shifted: const <String, double>{
            'sect1': _kTightGap,
            'sect2': _kSectionGap,
            'sect3': _kSectionGap,
            'sect4': _kSectionGap,
            // Everything after the swapped fifth section.
            'srcbar': _kWeekForGoal,
            'fresh': _kWeekForGoal,
            'related': _kWeekForGoal,
            'related.title': _kWeekForGoal,
            'related.item1': _kWeekForGoal,
            'related.item2': _kWeekForGoal,
            // The related rail's own section carries both: the 24 it holds
            // inside its box, and the 61 the goal saves above it.
            'related.sect': _kWeekForGoal + _kSectionGap,
          },
          grown: const <String, double>{
            'sect1': -_kTightGap,
            'sect2': -_kSectionGap,
            'sect3': -_kSectionGap,
            'sect4': -_kSectionGap,
            'related.sect': -_kSectionGap,
          },
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }

    testWidgets('tool_water_default_pk_detail_390x844_light_en', (
      WidgetTester tester,
    ) async {
      await pumpWater(tester, surface: tall);
      await tapWater(tester, find.byType(LumeRecordRow).first);

      final List<String> misses = parity.bounds(
        tester,
        'tool_water_default_pk_detail_390x844_light_en',
        <String, Finder>{
          // `cfact.value` is not mapped: the reference's is a `<span>` the
          // width of its own words at the end of the row, and Flutter's is
          // the stretched, end-aligned box that holds them — the same value,
          // in a box that is not the same box. The words are asserted below.
          'toolbar': find.byType(LumeToolbar),
          'chero': find.byKey(k.hero),
          'chero.kicker': _inKey(k.hero, find.byType(Text)).first,
          'chero.value': _inKey(k.hero, find.byType(LumeNumerals)),
          'chero.caption': _inKey(k.hero, find.byType(Text)).last,
          'cfacts': find.byKey(k.facts),
          'cfact1': _inKey(
            k.facts,
            find.byWidgetPredicate(
              (Widget w) =>
                  w is Padding &&
                  w.padding == const EdgeInsets.symmetric(vertical: 15),
            ),
          ).first,
          'cfact.label': _inKey(k.facts, find.text('Drink')),
          'cacts': find.byKey(k.detailActions),
          'cact.edit': find.byType(LumeDetailAction).first,
          'cact.danger': find.byType(LumeDetailAction).at(1),
          'crud.id': find.byKey(k.recordId),
        },
        noWidth: textBlocks,
        // A record's detail should state what the record holds. The
        // reference's lists two facts and never states the amount — the one
        // number a drink exists to hold — nor the day; this one adds both.
        grown: const <String, double>{'cfacts': _kTwoAddedFacts},
        shifted: const <String, double>{
          'cacts': _kTwoAddedFacts,
          'cact.edit': _kTwoAddedFacts,
          'cact.danger': _kTwoAddedFacts,
          'crud.id': _kTwoAddedFacts,
        },
      );
      expect(misses, isEmpty, reason: misses.join('\n'));
    });

    testWidgets('tool_water_default_pk_new_390x844_light_en', (
      WidgetTester tester,
    ) async {
      await pumpWater(tester, surface: tall);
      await tapWater(tester, find.byKey(k.add));

      final List<String> misses = parity.bounds(
        tester,
        'tool_water_default_pk_new_390x844_light_en',
        <String, Finder>{
          'toolbar': find.byType(LumeToolbar),
          'cform': find.byKey(k.form),
          'cfield1': find.byKey(k.field('ml')),
          'cfield2': find.byKey(k.field('kind')),
          'cfield.label': _inKey(k.field('ml'), find.byType(Row)).first,
          'cfield.box': _inKey(
            k.field('ml'),
            find.byType(AnimatedContainer),
          ).first,
          'csubmit': find.byKey(k.submit),
          'csubmit.btn': _inKey(k.submit, find.byType(LumeButton)),
          'csubmit.note': _inKey(
            k.submit,
            find.text('Changes are saved only after confirmation'),
          ),
        },
        // `.cform` is the fields alone and `.csubmit` its sibling; Flutter's
        // form column holds both, so its height is the two together.
        noHeight: const <String>{'cform'},
        shifted: const <String, double>{
          // The fourth field, Date, which the reference's schema does not
          // have at all (18 of gap and 71 of field), less the two points
          // Chrome's native time input is taller than the picker that stands
          // in for it, plus the 0.4 the Drink picker's own line adds.
          'csubmit': 87.4,
          'csubmit.btn': 87.4,
          // …and two more under the button: `.csubmit` sets 10 between the
          // action and its note where `LumeSubmitBar` sets 12.
          'csubmit.note': 89.4,
        },
        grown: const <String, double>{'csubmit': 2},
      );
      expect(misses, isEmpty, reason: misses.join('\n'));
    });
  });

  group('what it says, in the state the reference was captured in', () {
    const String cell = 'tool_water_default_pk_390x844_light_en';

    Map<String, dynamic> composition(String c) =>
        webToolCell(c)!['composition'] as Map<String, dynamic>;

    testWidgets('the bar, the search and the four records', (
      WidgetTester tester,
    ) async {
      await pumpWater(tester, surface: tall);
      final Map<String, dynamic> w = composition(cell);

      final Map<String, dynamic> header = w['header'] as Map<String, dynamic>;
      expect(find.text(header['title'] as String), findsWidgets);
      expect(find.text(header['sub'] as String), findsOneWidget);
      final Map<String, dynamic> add =
          (header['actions'] as List<dynamic>).single as Map<String, dynamic>;
      final LumeTextButton button = tester.widget<LumeTextButton>(
        find.byKey(k.add),
      );
      expect(button.label, add['text']);
      // What the reference carries as that control's `aria-label`.
      expect(button.semanticLabel, add['label']);

      // The search field's placeholder is the one line that does not match.
      // The reference's says "today's drinks", and its list is not today's:
      // every stored drink is in it, as every stored drink is in this one —
      // a glass logged yesterday is still a record, and is still listed and
      // still searchable. So the placeholder names what can be searched.
      final Map<String, dynamic> recs = w['records'] as Map<String, dynamic>;
      expect(recs['placeholder'], 'Search today’s drinks');
      expect(
        tester.widget<LumeSearchField>(find.byKey(k.search)).placeholder,
        'Search drinks',
      );

      final List<dynamic> rows = recs['rows'] as List<dynamic>;
      final List<LumeRecordRow> drawn = tester
          .widgetList<LumeRecordRow>(find.byType(LumeRecordRow))
          .toList();
      expect(drawn.length, rows.length);
      const List<String> clock = <String>[
        '8:10 am',
        '10:30 am',
        '1:05 pm',
        '3:40 pm',
      ];
      for (int i = 0; i < rows.length; i++) {
        final Map<String, dynamic> r = rows[i] as Map<String, dynamic>;
        expect(drawn[i].initial, r['initial'], reason: 'row $i initial');
        expect(drawn[i].title, r['title'], reason: 'row $i title');
        expect(drawn[i].value, r['value'], reason: 'row $i value');
        // The one field that differs, and deliberately: the reference stores
        // no day, so its row can say only the bare stored `08:10`. These
        // records carry a day, so the row says which day as well, and the
        // clock is the reader's rather than the stored 24-hour string.
        expect(drawn[i].subtitle, isNot(r['sub']), reason: 'row $i sub');
        expect(drawn[i].subtitle, 'Today · ${clock[i]}', reason: 'row $i sub');
      }
    });

    testWidgets('the summary, the ring and the two buttons', (
      WidgetTester tester,
    ) async {
      await pumpWater(tester, surface: tall);
      final Map<String, dynamic> w = composition(cell);

      final Map<String, dynamic> s = w['summary'] as Map<String, dynamic>;
      final LumeSummaryCard card = tester.widget<LumeSummaryCard>(
        find.byKey(LumeWaterTool.summaryKey),
      );
      expect(card.kicker, s['kicker']);
      expect(card.value, s['value']);
      // The reference calls 2000 ml "a target". It is a default goal the
      // reader can change and nothing recommends it, so the caption says
      // which until they have chosen one.
      expect(s['caption'], 'of a 2.0 L target');
      expect(card.caption, 'of the default 2.0 L goal');

      final List<dynamic> stats = s['stats'] as List<dynamic>;
      for (int i = 0; i < 2; i++) {
        final Map<String, dynamic> x = stats[i] as Map<String, dynamic>;
        expect(card.stats[i].value, x['value'], reason: 'stat $i');
        expect(card.stats[i].label, x['label'], reason: 'stat $i');
      }
      // `streak: 6` (`context.js:1633`) is a literal with nothing behind it;
      // the third figure here is a count of the records drawn above it.
      expect(stats[2], <String, dynamic>{'value': '6', 'label': 'Day streak'});
      expect(card.stats[2].value, '4');
      expect(card.stats[2].label, 'Logged');

      final Map<String, dynamic> ring = w['ring'] as Map<String, dynamic>;
      final LumeProgressRing drawn = tester.widget<LumeProgressRing>(
        find.byKey(LumeWaterTool.ringKey),
      );
      expect(drawn.centreValue, ring['text']);
      expect(drawn.valueText, ring['text']);
      expect(drawn.label, ring['label']);
      // 1250 of 2000 is 62.5 %, and `aria-valuenow` is 63: `Math.round` is
      // half **up**, where half to even would print 62. The arc itself is the
      // unrounded share.
      expect(int.parse(ring['now'] as String), 63);
      expect(LumeWaterFamily.percent(1250, 2000), 63);
      expect(drawn.value, closeTo(0.625, 1e-12));

      expect(<String>[
        tester.widget<LumeButton>(find.byKey(LumeWaterTool.addSmallKey)).label,
        tester.widget<LumeButton>(find.byKey(LumeWaterTool.addLargeKey)).label,
      ], w['buttons']);
    });

    testWidgets('the timeline, the source bar and the related rail', (
      WidgetTester tester,
    ) async {
      await pumpWater(tester, surface: tall);
      final Map<String, dynamic> w = composition(cell);

      final List<dynamic> web = w['timeline'] as List<dynamic>;
      final List<LumeTimelineEntry> drawn = tester
          .widget<LumeTimeline>(find.byKey(LumeWaterTool.timelineKey))
          .entries;
      expect(drawn.length, web.length);
      for (int i = 0; i < web.length; i++) {
        final Map<String, dynamic> e = web[i] as Map<String, dynamic>;
        expect(drawn[i].time, e['time'], reason: 'entry $i time');
        expect(drawn[i].title, e['title'], reason: 'entry $i title');
        expect(drawn[i].subtitle, e['sub'], reason: 'entry $i sub');
        expect(drawn[i].state.name, e['state'], reason: 'entry $i state');
      }

      final Map<String, dynamic> src = w['source'] as Map<String, dynamic>;
      expect(find.text(src['fresh'] as String), findsOneWidget);
      expect(referenceSourceLine(tester), src['line']);
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), w['related']);
    });

    testWidgets('and the week the store cannot answer for is not drawn', (
      WidgetTester tester,
    ) async {
      await pumpWater(tester, surface: tall);
      final List<dynamic> bars = composition(cell)['bars'] as List<dynamic>;

      // What the reference's fifth section is, exactly: seven constants under
      // M T W T F S S, with the last one highlighted.
      expect(
        <String>[
          for (final dynamic b in bars)
            ((b as Map<String, dynamic>)['title'] as String).split(': ').last,
        ],
        <String>['1800', '2100', '1650', '2000', '1900', '2200', '1250'],
      );
      expect(
        <String>[
          for (final dynamic b in bars) (b as Map<String, dynamic>)['label'],
        ],
        <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      );
      expect(
        <bool>[for (final dynamic b in bars) (b as Map<String, dynamic>)['on']],
        <bool>[false, false, false, false, false, false, true],
      );

      // Not one of the seven is on this screen, in either spelling, and
      // nothing draws a bar.
      final List<String> page = allTexts(tester);
      for (final String figure in <String>[
        '1800',
        '1,800',
        '2100',
        '2,100',
        '1650',
        '1,650',
        '1900',
        '1,900',
        '2200',
        '2,200',
      ]) {
        expect(page, isNot(contains(figure)), reason: figure);
      }
      expect(find.text('This week'), findsNothing);
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where(
              (CustomPaint p) =>
                  '${p.painter.runtimeType}'.toLowerCase().contains('bar'),
            ),
        isEmpty,
      );

      // What stands there instead: the goal, and a way to change it.
      expect(
        find.descendant(
          of: find.byType(LumeToolSection).at(4),
          matching: find.byKey(LumeWaterTool.goalKey),
        ),
        findsOneWidget,
      );
      expect(find.byKey(LumeWaterTool.goalEditKey), findsOneWidget);
    });

    testWidgets('the detail states the two facts the reference states, and '
        'two it does not', (WidgetTester tester) async {
      const String detail = 'tool_water_default_pk_detail_390x844_light_en';
      await pumpWater(tester, surface: tall);
      await tapWater(tester, find.byType(LumeRecordRow).first);

      final Map<String, dynamic> recs =
          composition(detail)['records'] as Map<String, dynamic>;
      final Map<String, dynamic> hero = recs['hero'] as Map<String, dynamic>;
      final LumeRecordHero drawn = tester.widget<LumeRecordHero>(
        find.byKey(k.hero),
      );
      expect(drawn.kicker, hero['kicker']);
      expect(drawn.value, hero['value']);
      // The reference prints the bare stored `08:10` here and `8:10 am` on
      // the timeline three sections above. Both read the reader's clock here,
      // and the caption says which day as well.
      expect(hero['caption'], '08:10');
      expect(drawn.caption, 'Today · 8:10 am');

      final List<LumeFact> facts = tester
          .widget<LumeFactCard>(
            find.descendant(
              of: find.byKey(k.facts),
              matching: find.byType(LumeFactCard),
            ),
          )
          .facts;
      // The two the reference states, in its own order and its own words.
      final List<dynamic> web = recs['facts'] as List<dynamic>;
      expect(
        <String>[
          for (final dynamic f in web) (f as List<dynamic>).first as String,
        ],
        <String>['Drink', 'Time'],
      );
      expect(facts.first.label, 'Drink');
      expect(facts.first.value, (web.first as List<dynamic>)[1]);
      expect(facts[2].label, 'Time');
      // …and the two it does not, because a drink's detail that never states
      // the amount does not state what the record holds.
      expect(facts.map((LumeFact f) => f.label).toList(), <String>[
        'Drink',
        'Amount in ml',
        'Time',
        'Date',
      ]);
      expect(facts[1].value, '250');
      expect(facts[3].value, 'Mon, 7 Sept');
    });

    testWidgets('the form asks what the reference asks, and the day it '
        'cannot ask for', (WidgetTester tester) async {
      const String form = 'tool_water_default_pk_new_390x844_light_en';
      await pumpWater(tester, surface: tall);
      await tapWater(tester, find.byKey(k.add));

      final Map<String, dynamic> recs =
          composition(form)['records'] as Map<String, dynamic>;
      final List<dynamic> web = recs['fields'] as List<dynamic>;
      expect(
        <String>[
          for (final dynamic f in web) (f as Map<String, dynamic>)['label'],
        ],
        <String>['Amount in ml', 'Drink', 'Time'],
      );

      // Amount: the same label over the same kind of control.
      expect(
        tester.widget<LumeFormField>(find.byKey(k.field('ml'))).label,
        (web.first as Map<String, dynamic>)['label'],
      );

      // Drink: the same two options — and the reference's select sits on the
      // raw translation key it stores (`record-schemas.js:610`), which is
      // then what the reader's own record holds. This one stores the plain
      // `water` and draws the translated label.
      final Map<String, dynamic> kind = web[1] as Map<String, dynamic>;
      expect(kind['value'], '@water.kindWater');
      expect(kind['options'], <String>['Water', 'Tea']);
      final LumeFormPicker picker = tester.widget<LumeFormPicker>(
        find.byKey(k.field('kind')),
      );
      expect(picker.label, kind['label']);
      expect(picker.value, 'Water');

      expect(
        tester.widget<LumeFormPicker>(find.byKey(k.field('at'))).label,
        (web[2] as Map<String, dynamic>)['label'],
      );

      // The fourth field. The reference's schema has no `date`, so its screen
      // calls the sum of every stored drink "today" — true only until
      // midnight. Every figure on this screen counts by the day, so the form
      // asks for one.
      expect(find.byKey(k.field('date')), findsOneWidget);
      expect(
        tester.widget<LumeFormPicker>(find.byKey(k.field('date'))).label,
        'Date',
      );

      expect(
        tester.widget<LumeSubmitBar>(find.byKey(k.submit)).saveLabel,
        (recs['submit'] as List<dynamic>).single,
      );
      expect(find.text(recs['submitNote'] as String), findsOneWidget);
    });
  });
}
