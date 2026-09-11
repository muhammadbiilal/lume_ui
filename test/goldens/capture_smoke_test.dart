/// Proves the capture pipeline works end to end, on the gallery.
///
/// It is a smoke test, not a parity test: it writes a Flutter capture and its
/// sidecar, and asserts the surface was measured the way it was asked for.
/// Comparing that image against the web is what the phases from F2 on do.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/capture.dart';
import '../helpers/lume_harness.dart';

void main() {
  testWidgets('captures a surface and records what it measured', (
    WidgetTester tester,
  ) async {
    final Map<String, Object?> sidecar = await captureLume(
      tester,
      const _Swatches(),
      name: 'foundation',
      surface: LumeViewport.phone,
    );

    final Map<String, Object?> measured =
        sidecar['measured']! as Map<String, Object?>;
    expect(measured['imageWidth'], LumeViewport.phone.width);
    expect(measured['imageHeight'], LumeViewport.phone.height);
    expect(measured['widthClass'], 'compact');
    expect(measured['dir'], 'ltr');
  });

  testWidgets('a landscape phone captures as compact', (WidgetTester t) async {
    final Map<String, Object?> sidecar = await captureLume(
      t,
      const _Swatches(),
      name: 'foundation',
      surface: LumeViewport.landscapePhone,
    );
    final Map<String, Object?> measured =
        sidecar['measured']! as Map<String, Object?>;
    // The whole point of the height override, recorded in a capture the
    // comparison can point at.
    expect(measured['widthClass'], 'compact');
    expect(measured['measureClass'], 'expanded');
  });

  testWidgets('an RTL capture records its direction', (WidgetTester t) async {
    final Map<String, Object?> sidecar = await captureLume(
      t,
      const _Swatches(),
      name: 'foundation',
      locale: const Locale('ar'),
      theme: ThemeMode.dark,
    );
    final Map<String, Object?> measured =
        sidecar['measured']! as Map<String, Object?>;
    expect(measured['dir'], 'rtl');
    expect((sidecar['requested']! as Map<String, Object?>)['theme'], 'dark');
  });
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: Color(0xFFF6F6F4), child: SizedBox.expand());
}
