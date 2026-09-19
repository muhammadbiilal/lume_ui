/// The banner never lies over anything the reader needs (C92).
///
/// The reference's `.nbanner` is absolutely placed: over the header — Back,
/// the title, Save — on a phone, and over the pane's bottom corner on a
/// tablet. Lume gives it a measured slot of its own above the shell, so the
/// shell is laid out in what the banner leaves. These hold that at every
/// cell the brief names, on a real tool with a real form, through the real
/// router and the real tick.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/locale_provider.dart';
import 'package:lume/core/navigation/lume_shell.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/features/ledger/domain/ledger_model.dart';
import 'package:lume/features/ledger/presentation/ledger_tool.dart';
import 'package:lume/features/notifications/presentation/notification_banner.dart';
import 'package:lume/features/notifications/presentation/notification_presenter.dart';

import '../../helpers/load_fonts.dart';
import '../ledger/ledger_screen_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  Finder banner() => find.byType(LumeNotificationBanner);

  Future<void> past(WidgetTester t, Duration d) async {
    await t.pump(d);
    await t.pump();
    await t.pump();
  }

  Future<void> firstBanner(WidgetTester t) async {
    await past(t, LumeNotificationPresenter.firstTick);
    await t.pump(const Duration(milliseconds: 50));
    expect(banner(), findsOneWidget);
  }

  /// Nothing of the shell is under the banner: the shell starts where the
  /// banner's slot ends.
  void clearOf(WidgetTester t, Finder f, {String? reason}) {
    final Rect b = t.getRect(banner());
    for (final Element e in f.evaluate()) {
      final Rect r = t.getRect(find.byElementPredicate((Element x) => x == e));
      expect(r.overlaps(b), isFalse, reason: reason ?? '$r under $b');
    }
    expect(
      t.getRect(find.byType(LumeShell)).top,
      greaterThanOrEqualTo(b.bottom),
    );
  }

  /// A tap at the centre of [f] reaches [f], not the banner.
  void hits(WidgetTester t, Finder f) {
    final Offset c = t.getCenter(f);
    final HitTestResult r = HitTestResult();
    WidgetsBinding.instance.hitTestInView(r, c, t.view.viewId);
    final RenderObject target = t.renderObject(f);
    expect(
      r.path.any((HitTestEntry e) => e.target == target),
      isTrue,
      reason: 'the tap at $c does not reach it',
    );
    final RenderObject b = t.renderObject(banner());
    expect(r.path.any((HitTestEntry e) => e.target == b), isFalse);
  }

  Future<GoRouter> ledgerForm(
    WidgetTester t,
    LedgerWorld w, {
    Size surface = const Size(390, 844),
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    final GoRouter router = await pumpLedger(
      t,
      w,
      surface: surface,
      locale: locale,
      textScale: textScale,
    );
    await t.ensureVisible(find.byKey(LumeLedgerTool.addPersonKey));
    await t.pumpAndSettle();
    await t.tap(find.byKey(LumeLedgerTool.addPersonKey));
    await t.pumpAndSettle();
    expect(find.byKey(LumeLedgerTool.nameField), findsOneWidget);
    return router;
  }

  const Map<String, (Size, Locale, double)> cells =
      <String, (Size, Locale, double)>{
        '390x844 en': (Size(390, 844), Locale('en'), 1),
        '852x393 en': (Size(852, 393), Locale('en'), 1),
        '390x844 en 200%': (Size(390, 844), Locale('en'), 2),
        '390x844 ur': (Size(390, 844), Locale('ur'), 1),
        '390x844 ar': (Size(390, 844), Locale('ar'), 1),
        '1100x900 en': (Size(1100, 900), Locale('en'), 1),
      };

  for (final MapEntry<String, (Size, Locale, double)> c in cells.entries) {
    testWidgets('${c.key}: Back, the title and Save stay clear, tappable and '
        'announced', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final (Size size, Locale locale, double scale) = c.value;
      final LedgerWorld w = LedgerWorld();
      await ledgerForm(t, w, surface: size, locale: locale, textScale: scale);
      await firstBanner(t);

      final Finder back = find.byType(LumeBackButton);
      final Finder title = find.byType(LumeToolbar);
      final Finder save = find.byKey(LumeLedgerTool.saveKey);
      clearOf(t, back);
      clearOf(t, title);
      clearOf(t, save);
      hits(t, back);
      hits(t, save);
      // Still a button a screen reader can reach and press.
      final SemanticsNode s = t.getSemantics(save);
      expect(s.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      // And Save saves, with the banner still up.
      await t.enterText(find.byKey(LumeLedgerTool.nameField), 'Ivan');
      await t.pump();
      expect(banner(), findsOneWidget);
      await t.tap(save);
      await t.pumpAndSettle();
      expect(w.repo.view().parties.map((LedgerParty p) => p.name), <String>[
        'Ivan',
      ]);
      h.dispose();
      w.dispose();
    });
  }

  testWidgets('keyboard open: Save stays above it and the field keeps its '
      'focus', (WidgetTester t) async {
    final LedgerWorld w = LedgerWorld();
    await ledgerForm(t, w);
    await t.showKeyboard(find.byKey(LumeLedgerTool.nameField));
    t.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    addTearDown(t.view.resetViewInsets);
    await t.pump();
    final FocusNode? typing = FocusManager.instance.primaryFocus;

    await firstBanner(t);
    expect(FocusManager.instance.primaryFocus, same(typing));
    final Finder save = find.byKey(LumeLedgerTool.saveKey);
    clearOf(t, save);
    expect(t.getRect(save).bottom, lessThan(844 - 300));
    hits(t, save);
    await t.enterText(find.byKey(LumeLedgerTool.nameField), 'Mira');
    await t.tap(save);
    await t.pumpAndSettle();
    expect(w.repo.view().parties.single.name, 'Mira');
    w.dispose();
  });

  testWidgets('the shell keeps its state when the banner comes and goes', (
    WidgetTester t,
  ) async {
    final LedgerWorld w = LedgerWorld();
    await ledgerForm(t, w);
    await t.enterText(find.byKey(LumeLedgerTool.nameField), 'Half typed');
    await firstBanner(t);
    await past(t, LumeNotificationBanner.life);
    expect(banner(), findsNothing);
    expect(find.text('Half typed'), findsOneWidget);
    w.dispose();
  });

  testWidgets('no invisible bounds: beside it, and after it, taps go '
      'through', (WidgetTester t) async {
    final LedgerWorld w = LedgerWorld();
    await pumpLedger(t, w, surface: const Size(1100, 900));
    await firstBanner(t);
    // At pane width the banner is 400 wide at the end of its slot; the rest
    // of the slot is plain background and holds nothing that can be tapped.
    final Rect b = t.getRect(banner());
    expect(b.width, LumeShellMetrics.bannerWidthPane);
    expect(1100 - b.right, LumeShellMetrics.bannerInsetPane);
    final HitTestResult beside = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      beside,
      Offset(b.left - 40, b.center.dy),
      t.view.viewId,
    );
    expect(
      beside.path.any(
        (HitTestEntry e) => e.target is RenderSemanticsGestureHandler,
      ),
      isFalse,
    );

    await past(t, LumeNotificationBanner.life);
    expect(banner(), findsNothing);
    expect(t.getRect(find.byType(LumeShell)).top, 0);
    w.dispose();
  });

  testWidgets('over a dialog it waits; heard once when it comes back', (
    WidgetTester t,
  ) async {
    final SemanticsHandle h = t.ensureSemantics();
    final LedgerWorld w = LedgerWorld();
    await pumpLedger(t, w, surface: const Size(390, 844));
    await firstBanner(t);
    expect(t.takeAnnouncements(), hasLength(1));

    showDialog<void>(
      context: t.element(find.byType(LumeShell)),
      builder: (BuildContext c) => const AlertDialog(content: Text('Sure?')),
    );
    await t.pump();
    await t.pump();
    expect(banner(), findsNothing);
    // The dialog's own controls are not under anything.
    expect(find.text('Sure?'), findsOneWidget);

    Navigator.of(t.element(find.text('Sure?'))).pop();
    await t.pump();
    await t.pump();
    expect(banner(), findsOneWidget);
    expect(t.takeAnnouncements(), isEmpty);
    h.dispose();
    w.dispose();
  });

  testWidgets('background and resume do not bring a second one', (
    WidgetTester t,
  ) async {
    final SemanticsHandle h = t.ensureSemantics();
    final LedgerWorld w = LedgerWorld();
    await pumpLedger(t, w, surface: const Size(390, 844));
    await firstBanner(t);
    expect(t.takeAnnouncements(), hasLength(1));
    for (final AppLifecycleState s in <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      t.binding.handleAppLifecycleStateChanged(s);
    }
    await t.pump(const Duration(seconds: 1));
    for (final AppLifecycleState s in <AppLifecycleState>[
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      t.binding.handleAppLifecycleStateChanged(s);
    }
    await t.pump();
    expect(banner(), findsOneWidget);
    expect(t.takeAnnouncements(), isEmpty);
    h.dispose();
    w.dispose();
  });

  testWidgets('a language change keeps the same banner, unannounced', (
    WidgetTester t,
  ) async {
    final SemanticsHandle h = t.ensureSemantics();
    final LedgerWorld w = LedgerWorld();
    await pumpLedger(t, w, surface: const Size(390, 844));
    await firstBanner(t);
    expect(t.takeAnnouncements(), hasLength(1));
    final String title = t
        .widget<LumeNotificationBanner>(banner())
        .notification
        .title;
    ProviderScope.containerOf(
      t.element(find.byType(LumeNotificationPresenter)),
    ).read(localeProvider.notifier).state = const Locale(
      'ur',
    );
    await t.pump();
    await t.pump();
    expect(banner(), findsOneWidget);
    expect(
      t.widget<LumeNotificationBanner>(banner()).notification.title,
      title,
    );
    expect(t.takeAnnouncements(), isEmpty);
    h.dispose();
    w.dispose();
  });

  testWidgets('repeated ticks never stack two banners', (WidgetTester t) async {
    final LedgerWorld w = LedgerWorld();
    await pumpLedger(t, w, surface: const Size(390, 844));
    await firstBanner(t);
    for (int i = 0; i < 4; i++) {
      await past(t, LumeNotificationPresenter.interval);
      expect(banner().evaluate().length, lessThanOrEqualTo(1));
    }
    w.dispose();
  });

  group('dismissed by', () {
    Finder close() => find.descendant(
      of: banner(),
      matching: find.byWidgetPredicate(
        (Widget x) => x is LumePressable && x.semanticLabel == 'Dismiss',
      ),
    );

    FocusNode nodeIn(WidgetTester t, Finder f) => Focus.of(
      t.element(
        find.descendant(of: f, matching: find.byType(GestureDetector)).first,
      ),
    );

    testWidgets('the keyboard: Enter on its close control', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld();
      await pumpLedger(t, w, surface: const Size(390, 844));
      await firstBanner(t);
      nodeIn(t, close()).requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      await t.pump();
      expect(banner(), findsNothing);
      w.dispose();
    });

    testWidgets('the keyboard: Escape from inside it', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld();
      await pumpLedger(t, w, surface: const Size(390, 844));
      await firstBanner(t);
      nodeIn(t, close()).requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      await t.pump();
      expect(banner(), findsNothing);
      w.dispose();
    });

    testWidgets('a switch or screen reader: the tap action', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      final LedgerWorld w = LedgerWorld();
      await pumpLedger(t, w, surface: const Size(390, 844));
      await firstBanner(t);
      // What a switch or a screen reader sends: the node's tap action.
      t.semantics.tap(find.semantics.byLabel('Dismiss'));
      await t.pump();
      await t.pump();
      expect(banner(), findsNothing);
      h.dispose();
      w.dispose();
    });
  });
}
