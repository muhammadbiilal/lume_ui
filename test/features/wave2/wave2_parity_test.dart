/// Rollout wave 2 against the running reference: every compared value is a
/// `getBoundingClientRect` read from the prototype and the same box read from
/// Flutter, written to `docs/conversion_archive/parity/tool_<id>.md`.
///
/// Bounds are compared in English, as every converted tool's are: the
/// reference shows these tools' own words in English under Urdu and Arabic
/// and sets them in its own font stack, so its Urdu and Arabic boxes measure
/// a different text. Urdu and Arabic are held to direction and translation in
/// each tool's own test instead.
///
/// What is compared is what the two builds draw alike. Where the composition
/// reads the records instead of a fixture (C86), the reference draws a
/// different number of rows; positions are compared up to that section, and
/// sizes after it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_agenda.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/events/presentation/events_tool.dart';
import 'package:lume/features/notes/presentation/notes_tool.dart';
import 'package:lume/features/records/presentation/record_tool.dart';
import 'package:lume/features/shopping/domain/shopping_family.dart';
import 'package:lume/features/shopping/presentation/shopping_tool.dart';
import 'package:lume/features/sunmoon/presentation/sunmoon_tool.dart';
import 'package:lume/features/todos/presentation/todos_tool.dart';

import '../../helpers/load_fonts.dart';
import '../tools/tool_parity.dart';
import 'wave2_harness.dart';

/// The chip a record filter draws, inside its 44-point target.
Finder drawnChip() => find.descendant(
  of: find.byType(LumeRecordChip),
  matching: find.byWidgetPredicate(
    (Widget w) =>
        w is Container && w.constraints?.minHeight == LumeRecordChip.height,
  ),
);

Map<String, Finder> recordList(LumeRecordKeys k) => <String, Finder>{
  'toolbar': find.byType(LumeToolbar),
  'toolbar.textbtn': find.byKey(k.add),
  'search': find.byKey(k.search),
  'recs': find.byKey(k.records),
  'rrec1': find.byType(LumeRecordRow).first,
  'rrec2': find.byType(LumeRecordRow).at(1),
};

/// The first field of each family's form.
String firstField(String tool) => switch (tool) {
  'todos' || 'shopping' => 'label',
  _ => 'title',
};

Map<String, Finder> composition(String tool) => switch (tool) {
  'notes' => <String, Finder>{
    'metrics': find.byKey(LumeNotesTool.metricsKey),
    'metric1': find.byType(LumeMetric).first,
    'metric2': find.byType(LumeMetric).at(1),
    'rows': find.byKey(LumeNotesTool.foldersKey),
    'crow1': inKey(LumeNotesTool.foldersKey, find.byType(LumeCompactRow)).first,
    'rrow1': inKey(LumeNotesTool.recentKey, find.byType(LumeRichRow)).first,
    'rrow2': inKey(LumeNotesTool.recentKey, find.byType(LumeRichRow)).at(1),
    'srcbar': find.byType(LumeSourceBar),
  },
  'todos' => <String, Finder>{
    'cchip1': drawnChip().first,
    'summary': find.byKey(LumeTodosTool.summaryKey),
    'taskrow1': inKey(
      LumeTodosTool.visibleKey,
      find.byType(LumeCheckRow),
    ).first,
    'taskrow2': inKey(
      LumeTodosTool.visibleKey,
      find.byType(LumeCheckRow),
    ).at(1),
  },
  'events' => <String, Finder>{
    'rrow1': inKey(LumeEventsTool.upcomingKey, find.byType(LumeRichRow)).first,
  },
  'shopping' => <String, Finder>{
    'cchip1': drawnChip().first,
    'cbulk': find.byKey(LumeShoppingTool.keys.bulk),
    'summary': find.byKey(LumeShoppingTool.summaryKey),
    'rows': find.byKey(LumeShoppingTool.groupKey(LumeShopAisle.produce)),
    'taskrow1': inKey(
      LumeShoppingTool.groupKey(LumeShopAisle.produce),
      find.byType(LumeCheckRow),
    ).first,
    'taskrow2': inKey(
      LumeShoppingTool.groupKey(LumeShopAisle.produce),
      find.byType(LumeCheckRow),
    ).at(1),
  },
  _ => <String, Finder>{},
};

/// The reference's record cards run past their column when a line does not
/// fit — Notes' 452 and To-dos' 353 in a 350 column (C86).
const Map<String, Set<String>> kOverflowing = <String, Set<String>>{
  'notes': <String>{'rrec1', 'rrec2'},
  'todos': <String>{'rrec1', 'rrec2'},
};

void main() {
  setUpAll(loadLumeFonts);

  final Map<String, ToolParity> parity = <String, ToolParity>{
    for (final String t in <String>[
      'notes',
      'todos',
      'events',
      'shopping',
      'sunmoon',
    ])
      t: ToolParity(t),
  };
  tearDownAll(() {
    for (final ToolParity p in parity.values) {
      p.write();
    }
  });

  void check(
    WidgetTester tester,
    String tool,
    String cell,
    Map<String, Finder> e, {
    Set<String> noWidth = const <String>{},
    Set<String> noHeight = const <String>{},
    Set<String> drifting = const <String>{},
    Map<String, double> shifted = const <String, double>{},
  }) {
    final List<String> misses = parity[tool]!.bounds(
      tester,
      cell,
      e,
      noWidth: noWidth,
      noHeight: noHeight,
      drifting: drifting,
      shifted: shifted,
    );
    expect(misses, isEmpty, reason: misses.join('\n'));
  }

  for (final String tool in <String>['notes', 'todos', 'events', 'shopping']) {
    group(tool, () {
      final LumeRecordKeys k = LumeRecordKeys(tool);

      testWidgets('tool_${tool}_default_pk_390x844_light_en', (
        WidgetTester tester,
      ) async {
        await pumpWave2(tester, tool);
        check(
          tester,
          tool,
          'tool_${tool}_default_pk_390x844_light_en',
          <String, Finder>{...recordList(k), ...composition(tool)},
          noWidth: kOverflowing[tool] ?? const <String>{},
          drifting: const <String>{
            'rows',
            'crow1',
            'rrow1',
            'rrow2',
            'srcbar',
            'summary',
            'taskrow1',
            'taskrow2',
          },
          // Two rows of filter chips 8 apart: their 44-point targets cannot
          // both overhang the gap, so what follows sits 5 lower (C86).
          shifted: tool == 'todos'
              ? const <String, double>{'taskrow1': 5, 'taskrow2': 5}
              : const <String, double>{},
        );
      });

      testWidgets('tool_${tool}_default_pk_1100x900_light_en', (
        WidgetTester tester,
      ) async {
        await pumpWave2(tester, tool, surface: const Size(1050, 5000));
        check(
          tester,
          tool,
          'tool_${tool}_default_pk_1100x900_light_en',
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'recs': find.byKey(k.records),
            'rrec1': find.byType(LumeRecordRow).first,
            'cstate': find.byType(LumeCollectionState),
          },
          noWidth: kOverflowing[tool] ?? const <String>{},
        );
      });

      testWidgets('tool_${tool}_default_pk_detail_390x844_light_en', (
        WidgetTester tester,
      ) async {
        await pumpWave2(tester, tool);
        await tapVisible(tester, find.byType(LumeRecordRow));
        check(
          tester,
          tool,
          'tool_${tool}_default_pk_detail_390x844_light_en',
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'chero': find.byKey(k.hero),
            'cfacts': find.byKey(k.facts),
            'cacts': find.byKey(k.detailActions),
            'crud.id': find.byKey(k.recordId),
          },
          noWidth: const <String>{'crud.id'},
          // A block fact's wrapped lines (Notes' body) settle within two.
          drifting: const <String>{'cfacts', 'cacts', 'crud.id'},
        );
      });

      testWidgets('tool_${tool}_default_pk_new_390x844_light_en', (
        WidgetTester tester,
      ) async {
        await pumpWave2(tester, tool);
        await tapVisible(tester, find.byKey(k.add));
        check(
          tester,
          tool,
          'tool_${tool}_default_pk_new_390x844_light_en',
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'cform': find.byKey(k.form),
            'cfield1': find.byKey(k.field(firstField(tool))),
            'csubmit': find.byKey(k.submit),
          },
          noHeight: const <String>{'cform'},
          drifting: const <String>{'csubmit'},
          // A set optional date or time offers Clear under it — a native
          // input empties itself, a picker cannot (C86): 44 lower. Chrome's
          // date and time inputs are 73 tall where the pickers are 71, which
          // gives Events' two back; Notes' six textarea lines are 22.4 each
          // in Flutter's metrics against Chrome's 22.0.
          shifted: switch (tool) {
            'todos' => const <String, double>{'csubmit': 44},
            'events' => const <String, double>{'csubmit': 40},
            'notes' => const <String, double>{'csubmit': 2},
            _ => const <String, double>{},
          },
        );
      });

      testWidgets('tool_${tool}_default_pk_delete_390x844_light_en', (
        WidgetTester tester,
      ) async {
        // The sheet rises from the bottom of the reference's viewport: 844
        // less its 28-point status bar.
        await pumpWave2(tester, tool, surface: const Size(390, 816));
        await tapVisible(tester, find.byType(LumeRecordRow));
        await tapVisible(
          tester,
          find
              .descendant(
                of: find.byKey(k.detailActions),
                matching: find.byType(LumeDetailAction),
              )
              .last,
        );
        check(
          tester,
          tool,
          'tool_${tool}_default_pk_delete_390x844_light_en',
          <String, Finder>{'dconfirm': find.byType(LumeDeleteConfirmation)},
        );
      });
    });
  }

  group('sunmoon', () {
    for (final String state in <String>[
      'default_pk',
      'muslim_gb',
      'default_us',
      'default_ae',
    ]) {
      final String cell = 'tool_sunmoon_${state}_390x844_light_en';
      testWidgets(cell, (WidgetTester tester) async {
        await pumpWave2(tester, 'sunmoon', state: state);
        check(
          tester,
          'sunmoon',
          cell,
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'ctxbar': find.byKey(LumeSunmoonTool.contextKey),
            'summary': find.byKey(LumeSunmoonTool.summaryKey),
            'tline': find.byKey(LumeSunmoonTool.timelineKey),
            'srcbar': find.byType(LumeSourceBar),
          },
          drifting: const <String>{'tline', 'srcbar'},
        );
      });
    }
  });
}
