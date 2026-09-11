/// Master-detail: one selection, two layouts, and everything the list was
/// holding when you left it.
///
/// The CRUD guide's promise is that selecting a record at expanded width does
/// not rebuild the list. That is not observable by looking at the screen — the
/// list looks the same either way — so every test here reaches for something
/// only a *kept* element could still have: a scroll offset, a filter, a
/// counter.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_master_detail.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

/// A list that remembers two things nothing outside it can restore: how many
/// times its filter was changed, and where it was scrolled to.
class _StatefulList extends StatefulWidget {
  const _StatefulList({required this.selectedId, required this.onSelect});

  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  State<_StatefulList> createState() => _StatefulListState();
}

class _StatefulListState extends State<_StatefulList> {
  final ScrollController _controller = ScrollController();
  int filterChanges = 0;

  /// Read by the tests through the element, so the assertion is about the
  /// surviving `State` rather than about anything rendered.
  double get offset => _controller.hasClients ? _controller.offset : 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextButton(
          onPressed: () => setState(() => filterChanges++),
          child: Text('filter $filterChanges'),
        ),
        Expanded(
          child: ListView.builder(
            controller: _controller,
            itemCount: 40,
            itemExtent: 60,
            itemBuilder: (BuildContext context, int i) => TextButton(
              onPressed: () => widget.onSelect('$i'),
              child: Text('row $i${widget.selectedId == '$i' ? ' •' : ''}'),
            ),
          ),
        ),
      ],
    );
  }
}

void main() {
  setUpAll(loadLumeFonts);

  /// `skipOffstage: false` is the whole point: at compact the list is offstage
  /// while a record shows, and its surviving `State` is exactly what these
  /// tests are about.
  _StatefulListState listState(WidgetTester tester) =>
      tester.state<_StatefulListState>(
        find.byType(_StatefulList, skipOffstage: false),
      );

  Future<void> pumpShell(
    WidgetTester tester, {
    Size surface = LumeViewport.phone,
    String? initialSelectedId,
    LumeSelectionController? controller,
  }) => pumpLume(
    tester,
    LumeMasterDetailShell(
      initialSelectedId: initialSelectedId,
      controller: controller,
      emptyDetail: const Center(child: Text('nothing selected')),
      listBuilder:
          (
            BuildContext context,
            String? selectedId,
            ValueChanged<String?> select,
          ) => _StatefulList(selectedId: selectedId, onSelect: select),
      detailBuilder: (BuildContext context, String id) =>
          Center(child: Text('detail $id')),
    ),
    surface: surface,
  );

  group('compact', () {
    testWidgets('shows the list, then the record over it', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester);
      expect(find.text('row 0'), findsOneWidget);
      expect(find.text('nothing selected'), findsNothing);

      await tester.tap(find.text('row 2'));
      await tester.pumpAndSettle();
      expect(find.text('detail 2'), findsOneWidget);
      expect(find.text('row 2'), findsNothing, reason: 'the list is offstage');
    });

    testWidgets('keeps the list\'s scroll and filter while a record shows', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester);

      await tester.tap(find.text('filter 0'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final double before = listState(tester).offset;
      expect(before, greaterThan(0));
      expect(listState(tester).filterChanges, 1);

      await tester.tap(find.text('row 8'));
      await tester.pumpAndSettle();
      expect(find.text('detail 8'), findsOneWidget);

      // The list is offstage, not gone, so its State is still the same one.
      expect(listState(tester).offset, before);
      expect(listState(tester).filterChanges, 1);
    });

    // Back is tested through the router, in `router_test.dart`: the listener
    // needs a `Router` to register with, and a collection screen mounted on a
    // real route is where that exists.
  });

  group('expanded', () {
    testWidgets('shows both panes, and the empty state before a choice', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, surface: LumeViewport.expanded);
      expect(find.text('row 0'), findsOneWidget);
      expect(find.text('nothing selected'), findsOneWidget);
      expect(find.byType(LumeMasterDetail), findsOneWidget);
    });

    testWidgets('selecting updates the pane and keeps the list', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, surface: LumeViewport.expanded);

      await tester.tap(find.text('filter 0'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final double before = listState(tester).offset;

      await tester.tap(find.text('row 6'));
      await tester.pumpAndSettle();

      expect(find.text('detail 6'), findsOneWidget);
      expect(find.text('row 6 •'), findsOneWidget, reason: 'still listed');
      expect(listState(tester).offset, before);
      expect(listState(tester).filterChanges, 1);
    });
  });

  group('rotation', () {
    testWidgets('compact to expanded keeps the record and the list', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester);
      await tester.tap(find.text('filter 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('row 4'));
      await tester.pumpAndSettle();
      expect(find.text('detail 4'), findsOneWidget);

      // Turn the device. The tree is re-laid-out, not rebuilt from nothing.
      tester.view.physicalSize = LumeViewport.expanded;
      await tester.pumpAndSettle();

      expect(find.text('detail 4'), findsOneWidget);
      expect(find.text('row 4 •'), findsOneWidget);
      expect(
        listState(tester).filterChanges,
        1,
        reason: 'the list survived the rotation with its State',
      );
    });

    testWidgets('expanded to compact keeps the record', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, surface: LumeViewport.expanded);
      await tester.tap(find.text('filter 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('row 5'));
      await tester.pumpAndSettle();

      tester.view.physicalSize = LumeViewport.phone;
      await tester.pumpAndSettle();

      expect(find.text('detail 5'), findsOneWidget);
      expect(find.text('row 5'), findsNothing, reason: 'one pane now');
      expect(listState(tester).filterChanges, 1);
    });
  });

  group('deep links', () {
    testWidgets('an opening selection shows that record', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, initialSelectedId: '9');
      expect(find.text('detail 9'), findsOneWidget);
    });

    testWidgets('at expanded it arrives selected in the list', (
      WidgetTester tester,
    ) async {
      await pumpShell(
        tester,
        surface: LumeViewport.expanded,
        initialSelectedId: '9',
      );
      expect(find.text('detail 9'), findsOneWidget);
      expect(find.text('row 9 •'), findsOneWidget);
    });

    testWidgets('and it can be navigated away from afterwards', (
      WidgetTester tester,
    ) async {
      // The opening selection is an opening, not a lock: a rebuild with the
      // same link must not drag the user back to the record they just left.
      await pumpShell(
        tester,
        surface: LumeViewport.expanded,
        initialSelectedId: '9',
      );
      await tester.tap(find.text('row 1'));
      await tester.pumpAndSettle();
      expect(find.text('detail 1'), findsOneWidget);

      await tester.pump();
      expect(find.text('detail 1'), findsOneWidget);
    });
  });

  group('an external controller', () {
    testWidgets('drives the selection, and reports it back', (
      WidgetTester tester,
    ) async {
      final LumeSelectionController controller = LumeSelectionController();
      addTearDown(controller.dispose);

      await pumpShell(
        tester,
        surface: LumeViewport.expanded,
        controller: controller,
      );
      expect(find.text('nothing selected'), findsOneWidget);

      controller.id = '12';
      await tester.pumpAndSettle();
      expect(find.text('detail 12'), findsOneWidget);

      await tester.tap(find.text('row 3'));
      await tester.pumpAndSettle();
      expect(controller.id, '3');

      controller.clear();
      await tester.pumpAndSettle();
      expect(find.text('nothing selected'), findsOneWidget);
    });
  });

  group('nothing overflows', () {
    for (final Size surface in <Size>[
      LumeViewport.narrow,
      LumeViewport.phone,
      LumeViewport.medium,
      LumeViewport.expanded,
      LumeViewport.landscapePhone,
    ]) {
      testWidgets('${surface.width}x${surface.height}', (
        WidgetTester tester,
      ) async {
        await pumpShell(tester, surface: surface, initialSelectedId: '2');
        expectNoOverflow(tester);
      });
    }
  });
}
