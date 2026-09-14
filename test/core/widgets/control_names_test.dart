/// Every control has a name a screen reader can say (C84).
///
/// Found on an Android device in F6B: `LumeButton` excluded its own text from
/// the semantics tree so it would not be read twice, and named itself only
/// when given a separate `semanticLabel` — so TalkBack read every text button
/// as "Button". Widget tests had not noticed, because they find a button by
/// the text drawn on it. These assert the tree the platform receives.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';

import '../../helpers/lume_harness.dart';

void main() {
  testWidgets('a text button is named by its text', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpLume(
      tester,
      Center(
        child: LumeButton.accent(
          key: const ValueKey<String>('b'),
          label: 'Scan',
          onPressed: () {},
        ),
      ),
    );
    final SemanticsNode node = tester.getSemantics(
      find.byKey(const ValueKey<String>('b')),
    );
    expect(node.label, 'Scan');
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('a separate semantic label still wins', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpLume(
      tester,
      Center(
        child: LumeButton(
          key: const ValueKey<String>('b'),
          label: 'Save',
          semanticLabel: 'Save the card',
          onPressed: () {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey<String>('b'))).label,
      'Save the card',
    );
    semantics.dispose();
  });

  testWidgets('a picked field is named by its label and value, once', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpLume(
      tester,
      Padding(
        padding: const EdgeInsets.all(20),
        child: LumeToolField(
          label: 'Date of birth',
          value: '18/4/1993',
          kind: LumeFieldKind.date,
          onTap: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Date of birth, 18/4/1993'), findsOneWidget);
    expect(find.bySemanticsLabel('18/4/1993'), findsNothing);
    semantics.dispose();
  });
}
