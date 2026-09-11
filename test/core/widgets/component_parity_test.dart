/// Every component, measured against the rendered prototype.
///
/// These are the tests that make the conversion a conversion rather than an
/// interpretation. They read `docs/conversion_archive/measurements/*.json` —
/// `getComputedStyle` taken from the real components in a real browser, under
/// the real cascade — and compare the Flutter widget's own rendered geometry
/// and style against it.
///
/// A test that compared `LumeButton.height` to a literal `46` would prove only
/// that someone typed 46 twice. These fail when the widget and the *design*
/// disagree.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/theme/lume/lume_colors.dart';
import 'package:lume/core/widgets/lume/lume.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../../helpers/measured.dart';

void main() {
  if (!Measurements.available()) {
    test('component measurements are present', () {
      fail(
        'No measurements found. Run '
        'docs/conversion_archive/tool/measure_components.mjs first.',
      );
    });
    return;
  }

  final Measurements light = Measurements.load();
  final Measurements dark = Measurements.load('components_390_dark_ltr');

  setUpAll(loadLumeFonts);

  /// Renders [widget] centred and hands back the box that [of] resolves to.
  Future<RenderBox> render(
    WidgetTester tester,
    Widget widget, {
    Finder? of,
    ThemeMode theme = ThemeMode.light,
    double width = 390,
  }) async {
    await pumpLume(
      tester,
      Align(alignment: AlignmentDirectional.topStart, child: widget),
      theme: theme,
      surface: Size(width, 900),
    );
    return tester.renderObject<RenderBox>(of ?? find.byWidget(widget));
  }

  /// The decoration of the first [Container]/[DecoratedBox] under [finder].
  BoxDecoration decorationUnder(WidgetTester tester, Finder finder) {
    final Iterable<Widget> all = tester.widgetList(
      find.descendant(
        of: finder,
        matching: find.byWidgetPredicate(
          (Widget w) =>
              (w is Container && w.decoration is BoxDecoration) ||
              (w is DecoratedBox && w.decoration is BoxDecoration) ||
              (w is AnimatedContainer && w.decoration is BoxDecoration),
        ),
        matchRoot: true,
      ),
    );
    for (final Widget w in all) {
      final Decoration? d = w is Container
          ? w.decoration
          : w is DecoratedBox
          ? w.decoration
          : (w as AnimatedContainer).decoration;
      if (d is BoxDecoration && (d.color != null || d.gradient != null)) {
        return d;
      }
    }
    fail('no decorated box under $finder');
  }

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!;

  group('actions', () {
    testWidgets('the accent button matches .btn--accent', (
      WidgetTester tester,
    ) async {
      final Measured m = light['btn.accent'];
      // Enabled: a disabled button correctly drops its glow, so measuring one
      // would be measuring the wrong state.
      await render(
        tester,
        LumeButton.accent(label: 'Continue', onPressed: () {}),
        of: find.byType(LumeButton),
      );

      final RenderBox box = tester.renderObject<RenderBox>(
        find
            .descendant(
              of: find.byType(LumeButton),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(box.size.height, m.height, reason: 'height');

      final BoxDecoration d = decorationUnder(tester, find.byType(LumeButton));
      expect(d.color, m.backgroundColor, reason: 'fill');
      expect(
        (d.borderRadius! as BorderRadius).topLeft.x,
        m.radius,
        reason: 'radius',
      );
      expect(d.boxShadow, isNotEmpty, reason: 'the accent button casts a glow');

      final TextStyle s = styleOf(tester, 'Continue');
      expect(s.fontSize, m.fontSize);
      expect(s.fontWeight, m.fontWeight);
      expect(s.color, m.color, reason: 'ink');
      expect(s.letterSpacing, closeTo(m.letterSpacing, 0.01));
    });

    testWidgets('the ghost button matches .btn--ghost', (
      WidgetTester tester,
    ) async {
      final Measured m = light['btn.ghost'];
      await render(tester, const LumeButton(label: 'Cancel'));
      final BoxDecoration d = decorationUnder(tester, find.byType(LumeButton));
      expect(d.color, m.backgroundColor);
      expect(styleOf(tester, 'Cancel').color, m.color);
      expect(d.boxShadow, anyOf(isNull, isEmpty));
    });

    testWidgets('the small button keeps the full height', (
      WidgetTester tester,
    ) async {
      // The measurement's own surprise: `.btn--sm` shrinks its padding but
      // min-height still wins, so it is narrower, not shorter.
      final Measured m = light['btn.small'];
      expect(m.height, light['btn.accent'].height);

      await render(tester, const LumeButton(label: 'Edit', small: true));
      final RenderBox box = tester.renderObject<RenderBox>(
        find
            .descendant(
              of: find.byType(LumeButton),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(box.size.height, m.height);
      expect(styleOf(tester, 'Edit').fontSize, m.fontSize);
    });

    testWidgets('the icon button matches .iconbtn', (
      WidgetTester tester,
    ) async {
      final Measured m = light['iconbtn'];
      await render(tester, const LumeIconButton(icon: 'share', label: 'Share'));
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeIconButton),
      );
      expect(d.color, m.backgroundColor);
      expect((d.borderRadius! as BorderRadius).topLeft.x, m.radius);
      expect(d.border, isNotNull);
      expect(LumeIconButton.size, m.height);
    });

    testWidgets('the fab matches .fab', (WidgetTester tester) async {
      final Measured m = light['fab'];
      expect(LumeFab.height, m.height);
      await render(tester, const LumeFab(label: 'Add'));
      final BoxDecoration d = decorationUnder(tester, find.byType(LumeFab));
      expect(d.color, m.backgroundColor);
    });
  });

  group('inputs', () {
    testWidgets('the record form field matches .cfield__box', (
      WidgetTester tester,
    ) async {
      final Measured m = light['cfield.box'];
      expect(LumeFormField.boxHeight, m.minHeight);

      await render(tester, const LumeFormField(label: 'Title'));
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeFormField),
      );
      expect(d.color, m.backgroundColor, reason: 'fill');
      expect((d.borderRadius! as BorderRadius).topLeft.x, m.radius);
      expect(d.border!.top.color, m.borderColor, reason: 'resting border');
      expect(d.border!.top.width, m.borderWidth);
    });

    testWidgets('an invalid field takes the rose boundary', (
      WidgetTester tester,
    ) async {
      final Measured m = light['cfield.invalid'];
      await render(
        tester,
        const LumeFormField(label: 'Title', error: 'Required'),
      );
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeFormField),
      );
      expect(d.border!.top.color, m.borderColor);
    });

    testWidgets('an invalid field also shows its message and a glyph', (
      WidgetTester tester,
    ) async {
      // §9: colour never carries a status alone.
      final Measured m = light['cfield.err'];
      await render(
        tester,
        const LumeFormField(label: 'Title', error: 'Required'),
      );
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('!'), findsOneWidget);
      expect(styleOf(tester, 'Required').color, m.color);
      expect(styleOf(tester, 'Required').fontSize, m.fontSize);
    });

    testWidgets('the field label matches .cfield__label', (
      WidgetTester tester,
    ) async {
      final Measured m = light['cfield.label'];
      await render(tester, const LumeFormField(label: 'Title'));
      final TextStyle s = styleOf(tester, 'Title');
      expect(s.fontSize, m.fontSize);
      expect(s.fontWeight, m.fontWeight);
      expect(s.color, m.color);
    });

    testWidgets('the tool field is the *other* field system', (
      WidgetTester tester,
    ) async {
      final Measured m = light['field.box'];
      // Different height, radius and fill from the record form's field, and
      // deliberately so.
      expect(LumeToolField.boxHeight, m.height);
      expect(m.radius, isNot(light['cfield.box'].radius));

      await render(tester, const LumeToolField(label: 'Amount'));
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeToolField),
      );
      expect(d.color, m.backgroundColor);
      expect((d.borderRadius! as BorderRadius).topLeft.x, m.radius);
    });

    testWidgets('the search field matches .search', (
      WidgetTester tester,
    ) async {
      final Measured m = light['search'];
      expect(LumeSearchField.height, m.height);
      await render(tester, const LumeSearchField(placeholder: 'Search'));
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeSearchField),
      );
      expect(d.color, m.backgroundColor);
      expect((d.borderRadius! as BorderRadius).topLeft.x, m.radius);
      expect(d.boxShadow, isNotEmpty);
    });

    testWidgets('the stepper matches .stepper', (WidgetTester tester) async {
      final Measured m = light['stepper'];
      expect(LumeStepper.height, m.height);
      await render(tester, const LumeStepper(label: 'People', value: '2'));
      final BoxDecoration d = decorationUnder(tester, find.byType(LumeStepper));
      expect(d.color, m.backgroundColor);
    });

    testWidgets('the stepper value is tabular', (WidgetTester tester) async {
      expect(light['stepper.val'].isTabular, isTrue);
      await render(tester, const LumeStepper(label: 'P', value: '2'));
      expect(
        styleOf(tester, '2').fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('selection', () {
    testWidgets('a filter chip matches .fchip in both states', (
      WidgetTester tester,
    ) async {
      final Measured off = light['fchip'];
      final Measured on = light['fchip.on'];
      expect(LumeFilterChip.height, off.height);

      await render(tester, const LumeFilterChip(label: 'All'));
      BoxDecoration d = decorationUnder(tester, find.byType(LumeFilterChip));
      expect(d.color, off.backgroundColor, reason: 'unselected fill');
      expect(styleOf(tester, 'All').color, off.color);

      await render(tester, const LumeFilterChip(label: 'All', selected: true));
      d = decorationUnder(tester, find.byType(LumeFilterChip));
      expect(d.color, on.backgroundColor, reason: 'selected fill');
      expect(styleOf(tester, 'All').color, on.color);
    });

    testWidgets('a record chip matches .cchip in both states', (
      WidgetTester tester,
    ) async {
      final Measured off = light['cchip'];
      final Measured on = light['cchip.on'];
      expect(LumeRecordChip.height, off.minHeight);

      await render(tester, const LumeRecordChip(label: 'Food'));
      expect(
        decorationUnder(tester, find.byType(LumeRecordChip)).color,
        off.backgroundColor,
      );

      await render(tester, const LumeRecordChip(label: 'Food', selected: true));
      expect(
        decorationUnder(tester, find.byType(LumeRecordChip)).color,
        on.backgroundColor,
      );
    });

    testWidgets('a selected segment is raised, not just tinted', (
      WidgetTester tester,
    ) async {
      // The measurement's tell: `.seg.is-on` casts a shadow. It is a thumb on
      // a track, not a coloured cell.
      expect(light['seg.on'].hasShadow, isTrue);
      expect(light['seg'].hasShadow, isFalse);

      await render(
        tester,
        const LumeSegmented(
          items: <LumeChoice>[
            LumeChoice(value: 'a', label: 'Day'),
            LumeChoice(value: 'b', label: 'Week'),
          ],
          value: 'a',
        ),
      );
      final Iterable<AnimatedContainer> cells = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      final List<BoxDecoration> decos = cells
          .map((AnimatedContainer c) => c.decoration! as BoxDecoration)
          .toList();
      expect(
        decos.where((BoxDecoration d) => d.boxShadow?.isNotEmpty ?? false),
        hasLength(1),
        reason: 'exactly one segment is raised',
      );
    });

    testWidgets('a sort option matches .sortopt in both states', (
      WidgetTester tester,
    ) async {
      final Measured off = light['sortopt'];
      final Measured on = light['sortopt.on'];
      expect(off.backgroundColor, isNot(on.backgroundColor));
      expect(off.color, isNot(on.color));

      await render(
        tester,
        LumeSortBar(
          items: const <LumeChoice>[
            LumeChoice(value: 'a', label: 'Name'),
            LumeChoice(value: 'b', label: 'Date'),
          ],
          value: 'a',
          direction: LumeSortDirection.ascending,
          onChanged: (_, _) {},
        ),
      );
      expect(styleOf(tester, 'Name').color, on.color);
      expect(styleOf(tester, 'Date').color, off.color);
    });
  });

  group('surfaces and rows', () {
    testWidgets('the card matches .kard', (WidgetTester tester) async {
      final Measured m = light['kard'];
      await render(tester, const LumeCard(child: Text('x')));
      final BoxDecoration d = decorationUnder(tester, find.byType(LumeCard));
      expect(d.color, m.backgroundColor);
      expect(
        (d.borderRadius! as BorderRadius).topLeft.x,
        m.radius,
        reason: 'the card takes --r-lg, not --r-md',
      );
      expect(d.border!.top.color, m.borderColor);
      expect(d.boxShadow, isNotEmpty);
    });

    testWidgets('the record row matches .rrec', (WidgetTester tester) async {
      final Measured m = light['rrec'];
      await render(
        tester,
        const LumeRecordRow(title: 'Groceries', initial: 'G'),
      );
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeRecordRow),
      );
      expect(d.color, m.backgroundColor);
      expect((d.borderRadius! as BorderRadius).topLeft.x, m.radius);
      expect(d.boxShadow, isNotEmpty);
    });

    testWidgets('a selected record row is tinted and bordered, not pressed', (
      WidgetTester tester,
    ) async {
      final Measured m = light['rrec.selected'];
      await render(
        tester,
        const LumeRecordRow(title: 'G', initial: 'G', selected: true),
      );
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeRecordRow),
      );
      expect(d.color, m.backgroundColor);
      // The measured border is `accent` at 45 % — a persistent state.
      expect(d.border!.top.color.a, closeTo(0.45, 0.02));
    });

    testWidgets('a done record row is struck through and muted, not hidden', (
      WidgetTester tester,
    ) async {
      // `.rrec.is-done .rrec__title` takes line-through and `text-3`. It is
      // still a record the user can open, so it is quieter, never invisible.
      final Measured normal = light['rrec.title'];
      await render(
        tester,
        LumeRecordRow(title: 'G', done: true, onToggle: (_) {}),
      );
      final TextStyle s = styleOf(tester, 'G');
      expect(s.decoration, TextDecoration.lineThrough);
      expect(
        s.color,
        isNot(normal.color),
        reason: 'a completed record is muted from its resting ink',
      );
      expect(find.text('G'), findsOneWidget, reason: 'still legible');
    });

    testWidgets('the record title matches .rrec__title', (
      WidgetTester tester,
    ) async {
      final Measured m = light['rrec.title'];
      await render(
        tester,
        const LumeRecordRow(title: 'Groceries', initial: 'G'),
      );
      final TextStyle s = styleOf(tester, 'Groceries');
      expect(s.fontSize, m.fontSize);
      expect(s.fontWeight, m.fontWeight);
      expect(s.color, m.color);
      expect(s.letterSpacing, closeTo(m.letterSpacing, 0.02));
    });

    testWidgets('the record value is tabular and muted', (
      WidgetTester tester,
    ) async {
      final Measured m = light['rrec.value'];
      expect(m.isTabular, isTrue);
      await render(
        tester,
        const LumeRecordRow(title: 'G', initial: 'G', value: '1,240'),
      );
      final TextStyle s = styleOf(tester, '1,240');
      expect(s.color, m.color);
      expect(s.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    testWidgets('the initial disc matches .rrec__disc', (
      WidgetTester tester,
    ) async {
      final Measured m = light['rrec.disc'];
      await render(
        tester,
        const LumeRecordRow(title: 'Groceries', initial: 'G'),
      );
      expect(styleOf(tester, 'G').color, m.color);
      expect(styleOf(tester, 'G').fontSize, m.fontSize);
    });

    testWidgets('the rich row matches .rrow', (WidgetTester tester) async {
      final Measured m = light['rrow.title'];
      await render(tester, const LumeRichRow(title: 'USD'));
      final TextStyle s = styleOf(tester, 'USD');
      expect(s.fontSize, m.fontSize);
      expect(s.fontWeight, m.fontWeight);
      expect(s.color, m.color);
    });

    testWidgets('the compact row matches .crow', (WidgetTester tester) async {
      final Measured label = light['crow.label'];
      final Measured value = light['crow.value'];
      expect(value.isTabular, isTrue);

      await render(tester, const LumeCompactRow(label: 'Fajr', value: '05:12'));
      expect(styleOf(tester, 'Fajr').fontSize, label.fontSize);
      expect(styleOf(tester, 'Fajr').color, label.color);
      expect(styleOf(tester, '05:12').color, value.color);
    });
  });

  group('value surfaces', () {
    testWidgets('the summary value matches .summary__value', (
      WidgetTester tester,
    ) async {
      final Measured m = light['summary.value'];
      expect(LumeSummaryCard.valueSize, m.fontSize);
      await render(tester, const LumeSummaryCard(value: '12,400'));
      final TextStyle s = styleOf(tester, '12,400');
      expect(s.fontSize, m.fontSize);
      expect(s.fontWeight, m.fontWeight);
      expect(s.letterSpacing, closeTo(m.letterSpacing, 0.05));
    });

    testWidgets('the record hero matches .chero', (WidgetTester tester) async {
      final Measured card = light['chero'];
      final Measured value = light['chero.value'];
      expect(card.hasGradient, isTrue, reason: 'the hero is a gradient');
      expect(LumeRecordHero.valueSize, value.fontSize);

      await render(tester, const LumeRecordHero(value: '1,240'));
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeRecordHero),
      );
      expect(d.gradient, isNotNull);
      expect((d.borderRadius! as BorderRadius).topLeft.x, card.radius);
      expect(styleOf(tester, '1,240').fontSize, value.fontSize);
    });

    testWidgets('the metric matches .metric', (WidgetTester tester) async {
      final Measured card = light['metric'];
      final Measured value = light['metric.value'];
      expect(LumeMetric.height, card.height);

      await render(tester, const LumeMetric(value: '42', label: 'Tasks'));
      final BoxDecoration d = decorationUnder(tester, find.byType(LumeMetric));
      expect(d.color, card.backgroundColor);
      expect((d.borderRadius! as BorderRadius).topLeft.x, card.radius);
      expect(styleOf(tester, '42').fontSize, value.fontSize);
      expect(styleOf(tester, '42').fontWeight, value.fontWeight);
    });
  });

  group('status', () {
    testWidgets('every badge tone carries a glyph as well as a colour', (
      WidgetTester tester,
    ) async {
      // The reference's own rule, and the reason a badge is legible to someone
      // who cannot separate rose from jade.
      for (final LumeBadgeTone tone in <LumeBadgeTone>[
        LumeBadgeTone.live,
        LumeBadgeTone.ok,
        LumeBadgeTone.warn,
        LumeBadgeTone.late_,
        LumeBadgeTone.off,
      ]) {
        expect(LumeBadge.glyphFor(tone), isNotNull, reason: '$tone');
      }
    });

    testWidgets('the badge matches .badge', (WidgetTester tester) async {
      final Measured m = light['badge.neutral'];
      expect(LumeBadge.height, m.height);
      await render(tester, const LumeBadge(label: 'Draft'));
      final BoxDecoration d = decorationUnder(tester, find.byType(LumeBadge));
      expect(d.color, m.backgroundColor);
      expect(styleOf(tester, 'Draft').color, m.color);
      expect(styleOf(tester, 'Draft').fontSize, m.fontSize);
    });

    testWidgets('a delta names its direction as well as colouring it', (
      WidgetTester tester,
    ) async {
      await render(
        tester,
        const LumeDelta(text: '2.4%', direction: LumeDeltaDirection.down),
      );
      expect(find.text('▼'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(LumeDelta)).label,
        contains('down'),
      );
    });

    testWidgets('freshness differs in shape, not only colour', (
      WidgetTester tester,
    ) async {
      await render(
        tester,
        const LumeFreshness(
          label: 'Cached',
          quality: LumeFreshnessQuality.cached,
        ),
      );
      final Container dot = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (Container c) =>
                (c.decoration as BoxDecoration?)?.shape == BoxShape.circle,
          );
      final BoxDecoration d = dot.decoration! as BoxDecoration;
      expect(
        d.border,
        isNotNull,
        reason: 'a cached marker is hollow; a live one is filled',
      );
    });
  });

  group('states', () {
    testWidgets('the tool state matches .state', (WidgetTester tester) async {
      final Measured m = light['state.empty'];
      await render(
        tester,
        const LumeToolState(title: 'Nothing yet', text: 'Add one'),
        width: 390,
      );
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeToolState),
      );
      expect(d.color, m.backgroundColor);
      expect((d.borderRadius! as BorderRadius).topLeft.x, m.radius);
    });

    testWidgets('the collection state title matches .cstate__title', (
      WidgetTester tester,
    ) async {
      final Measured m = light['cstate.title'];
      await render(
        tester,
        const LumeCollectionState(
          kind: LumeCollectionStateKind.empty,
          title: 'Nothing on your list',
          text: 'Add a task',
        ),
      );
      final TextStyle s = styleOf(tester, 'Nothing on your list');
      expect(s.fontSize, m.fontSize);
      expect(s.fontWeight, m.fontWeight);
      expect(s.color, m.color);
    });

    testWidgets('the notice action matches .cnotice__act', (
      WidgetTester tester,
    ) async {
      final Measured m = light['cnotice.act'];
      expect(LumeNoticeAction.height, m.minHeight);
      await render(tester, const LumeNoticeAction(label: 'Retry'));
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeNoticeAction),
      );
      expect(d.color, m.backgroundColor);
      expect((d.borderRadius! as BorderRadius).topLeft.x, m.radius);
    });

    testWidgets('skeleton heights match their measured shapes', (
      WidgetTester tester,
    ) async {
      expect(
        LumeSkeleton.heightFor(LumeSkeletonKind.row),
        light['sk.row'].height,
      );
      expect(
        LumeSkeleton.heightFor(LumeSkeletonKind.card),
        light['sk.card'].height,
      );
      expect(
        LumeSkeleton.heightFor(LumeSkeletonKind.metric),
        light['sk.metric'].height,
      );
    });
  });

  group('crud', () {
    testWidgets('the edit action matches .cact--edit', (
      WidgetTester tester,
    ) async {
      final Measured m = light['cact.edit'];
      expect(LumeDetailAction.height, m.minHeight);
      await render(tester, const LumeDetailAction(label: 'Edit'));
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeDetailAction),
      );
      expect(d.color, m.backgroundColor);
      expect(styleOf(tester, 'Edit').color, m.color);
    });

    testWidgets('the delete action matches .cact--danger', (
      WidgetTester tester,
    ) async {
      final Measured m = light['cact.danger'];
      await render(
        tester,
        const LumeDetailAction(label: 'Delete', destructive: true),
      );
      expect(styleOf(tester, 'Delete').color, m.color);
    });

    testWidgets('a fact row matches .cfact', (WidgetTester tester) async {
      final Measured label = light['cfact.label'];
      final Measured value = light['cfact.value'];
      await render(
        tester,
        const LumeFactCard(
          facts: <LumeFact>[LumeFact(label: 'Category', value: 'Food')],
        ),
      );
      expect(styleOf(tester, 'Category').color, label.color);
      expect(styleOf(tester, 'Category').fontWeight, label.fontWeight);
      expect(styleOf(tester, 'Food').color, value.color);
      expect(styleOf(tester, 'Food').fontWeight, value.fontWeight);
    });

    testWidgets('the count line matches .crud__count', (
      WidgetTester tester,
    ) async {
      final Measured m = light['crud.count'];
      await render(tester, const LumeListCount(label: '12 expenses'));
      final TextStyle s = styleOf(tester, '12 expenses');
      expect(s.fontSize, m.fontSize);
      expect(s.color, m.color);
    });
  });

  group('chrome', () {
    testWidgets('the toolbar title matches .toolbar__title', (
      WidgetTester tester,
    ) async {
      final Measured m = light['toolbar.title'];
      await render(tester, const LumeToolbar(title: 'Currency'));
      final TextStyle s = styleOf(tester, 'Currency');
      expect(s.fontSize, m.fontSize);
      expect(s.fontWeight, m.fontWeight);
      expect(s.letterSpacing, closeTo(m.letterSpacing, 0.05));
    });

    testWidgets('the back control matches .onb__nav', (
      WidgetTester tester,
    ) async {
      expect(LumeBackButton.size, 34);
      await render(tester, LumeBackButton(onPressed: () {}));
      final BoxDecoration d = decorationUnder(
        tester,
        find.byType(LumeBackButton),
      );
      expect(d.shape, BoxShape.circle);
      expect(d.color, context(tester).lume.card);
    });

    testWidgets('the segmented progress is 3 px tall with 5 px gaps', (
      WidgetTester tester,
    ) async {
      expect(LumeSegmentedProgress.segmentHeight, 3);
      expect(LumeSegmentedProgress.gap, 5);
      await render(
        tester,
        const SizedBox(
          width: 300,
          child: LumeSegmentedProgress(total: 9, completed: 4),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the progress bar matches .pbar', (WidgetTester tester) async {
      final Measured m = light['pbar'];
      expect(LumeProgressBar.height, m.height);
      await render(
        tester,
        const SizedBox(width: 200, child: LumeProgressBar(value: 0.4)),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('dark theme', () {
    testWidgets('the accent button takes the dark ink', (
      WidgetTester tester,
    ) async {
      final Measured m = dark['btn.accent'];
      await render(
        tester,
        const LumeButton.accent(label: 'Continue'),
        theme: ThemeMode.dark,
      );
      expect(
        decorationUnder(tester, find.byType(LumeButton)).color,
        m.backgroundColor,
      );
      expect(styleOf(tester, 'Continue').color, m.color);
      expect(
        m.color,
        isNot(light['btn.accent'].color),
        reason: 'what sits on the accent flips between themes',
      );
    });

    testWidgets('the card takes the dark surface and border', (
      WidgetTester tester,
    ) async {
      final Measured m = dark['kard'];
      await render(
        tester,
        const LumeCard(child: Text('x')),
        theme: ThemeMode.dark,
      );
      final BoxDecoration d = decorationUnder(tester, find.byType(LumeCard));
      expect(d.color, m.backgroundColor);
      expect(d.border!.top.color, m.borderColor);
    });

    testWidgets('the record row takes the dark surface', (
      WidgetTester tester,
    ) async {
      final Measured m = dark['rrec'];
      await render(
        tester,
        const LumeRecordRow(title: 'G', initial: 'G'),
        theme: ThemeMode.dark,
      );
      expect(
        decorationUnder(tester, find.byType(LumeRecordRow)).color,
        m.backgroundColor,
      );
    });
  });
}

/// The live `BuildContext` of whatever was last pumped.
BuildContext context(WidgetTester tester) =>
    tester.element(find.byType(Align).first);

extension on BuildContext {
  LumeColors get lume =>
      Theme.of(this).extension<LumeColors>() ?? LumeColors.light;
}
