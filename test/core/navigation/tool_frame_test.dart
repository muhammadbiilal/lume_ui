/// The tool host: the four states, the gate, and the furniture.
///
/// The gate is the one that matters. §64 says a hidden feature must not be
/// reachable through a deep link, a related card, a search result or a
/// notification, and the way to guarantee that with a widget tree is to not
/// build the body at all. So the test looks for the body's *absence*, not for
/// its opacity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  const LumeToolFrameStrings strings = LumeToolFrameStrings(
    loading: 'Loading',
    errorTitle: 'Something went wrong',
    errorText: 'Try again in a moment.',
    retry: 'Try again',
    unavailableTitle: 'Not part of your setup',
    unavailableText: 'That tool is not part of your setup.',
    back: 'Back',
  );

  /// A body nothing else in the frame can produce, so finding it means the
  /// body itself was built.
  const Key bodyKey = Key('the-tool-body');

  Future<void> pumpFrame(
    WidgetTester tester, {
    LumeToolStatus status = LumeToolStatus.ready,
    bool eligible = true,
    Size surface = LumeViewport.phone,
    VoidCallback? onBack,
    VoidCallback? onRetry,
    String? source,
    Widget? privacy,
    List<LumeRelatedTool> related = const <LumeRelatedTool>[],
  }) => pumpLume(
    tester,
    LumeToolFrame(
      title: 'Calculator',
      subtitle: 'Everyday',
      strings: strings,
      status: status,
      eligible: eligible,
      onBack: onBack,
      onRetry: onRetry,
      source: source,
      privacy: privacy,
      related: related,
      freshness: LumeFreshnessQuality.live,
      freshnessLabel: 'Now',
      body: const SizedBox(key: bodyKey, height: 200),
    ),
    surface: surface,
  );

  group('the gate', () {
    testWidgets('an ineligible tool never builds its body', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, eligible: false);
      expect(find.byKey(bodyKey), findsNothing);
      expect(find.text('Not part of your setup'), findsOneWidget);
    });

    testWidgets('and it refuses whatever status it was handed', (
      WidgetTester tester,
    ) async {
      // A caller that says "ineligible, but ready" does not get a body. The
      // gate is not one branch of a switch; it comes first.
      for (final LumeToolStatus status in LumeToolStatus.values) {
        await pumpFrame(tester, eligible: false, status: status);
        expect(find.byKey(bodyKey), findsNothing, reason: status.name);
      }
    });

    testWidgets('an eligible tool builds its body', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester);
      expect(find.byKey(bodyKey), findsOneWidget);
    });
  });

  group('the states', () {
    testWidgets('loading shows skeletons, never a spinner', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, status: LumeToolStatus.loading);
      expect(find.byType(LumeSkeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(bodyKey), findsNothing);
    });

    testWidgets('error offers a retry when there is one', (
      WidgetTester tester,
    ) async {
      int retries = 0;
      await pumpFrame(
        tester,
        status: LumeToolStatus.error,
        onRetry: () => retries++,
      );
      expect(find.text('Something went wrong'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('unavailable says where, not that it broke', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, status: LumeToolStatus.unavailable);
      expect(find.text('Not part of your setup'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });
  });

  group('the furniture', () {
    testWidgets('the title and subtitle are the toolbar\'s', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester);
      expect(find.text('Calculator'), findsOneWidget);
      expect(find.text('Everyday'), findsOneWidget);
    });

    testWidgets('no back control when there is nowhere to go', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester);
      expect(find.bySemanticsLabel('Back'), findsNothing);

      int backs = 0;
      await pumpFrame(tester, onBack: () => backs++);
      await tester.tap(find.bySemanticsLabel('Back').first);
      expect(backs, 1);
    });

    testWidgets('provenance follows the body, not the title', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, source: 'State Bank');
      final double body = tester.getRect(find.byKey(bodyKey)).bottom;
      final double src = tester.getRect(find.byType(LumeSourceLine)).top;
      expect(src, greaterThanOrEqualTo(body));
    });

    testWidgets('privacy and related tools sit below the provenance', (
      WidgetTester tester,
    ) async {
      await pumpFrame(
        tester,
        surface: LumeViewport.tall,
        source: 'State Bank',
        privacy: const LumePrivateState(
          title: 'Stays on this device',
          text: 'Nothing here is uploaded.',
        ),
        related: const <LumeRelatedTool>[
          LumeRelatedTool(id: 'currency', name: 'Currency', icon: 'i-currency'),
        ],
      );
      final double src = tester.getRect(find.byType(LumeSourceLine)).bottom;
      final double privacy = tester.getRect(find.byType(LumePrivateState)).top;
      final double related = tester.getRect(find.byType(LumeRelatedTools)).top;
      expect(privacy, greaterThanOrEqualTo(src));
      expect(related, greaterThanOrEqualTo(privacy));
    });

    testWidgets('a state has no provenance, privacy or related rail', (
      WidgetTester tester,
    ) async {
      // A tool that could not load has nothing to attribute. Showing a source
      // line under an error would be attributing a number that is not there.
      await pumpFrame(
        tester,
        status: LumeToolStatus.error,
        source: 'State Bank',
        related: const <LumeRelatedTool>[
          LumeRelatedTool(id: 'currency', name: 'Currency', icon: 'i-currency'),
        ],
      );
      expect(find.byType(LumeSourceLine), findsNothing);
      expect(find.byType(LumeRelatedTools), findsNothing);
    });
  });

  group('leaving', () {
    testWidgets('onLeave runs once, when the frame goes', (
      WidgetTester tester,
    ) async {
      int left = 0;
      await pumpLume(
        tester,
        LumeToolFrame(
          title: 'Calculator',
          strings: strings,
          onLeave: () => left++,
          body: const SizedBox(key: bodyKey),
        ),
      );
      expect(left, 0);
      await pumpLume(tester, const SizedBox.shrink());
      expect(left, 1);
    });
  });

  group('it lays out at every width', () {
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
        for (final LumeToolStatus status in LumeToolStatus.values) {
          await pumpFrame(tester, status: status, surface: surface);
          expectNoOverflow(tester);
        }
      });
    }
  });
}
