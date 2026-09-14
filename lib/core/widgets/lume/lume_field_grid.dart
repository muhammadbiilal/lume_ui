/// `.fgrid` — a calculator's fields in two columns.
///
/// `grid-template-columns: 1fr 1fr; gap: 12px`. A field marked wide
/// (`.field--wide`) spans both, and a lone field takes the whole row
/// (`.fgrid > .field:only-child`); every other field fills the next free cell
/// in order. Measured on Loan / EMI, Compound Interest and Date Calculator at
/// 390, 700 and 1100: two columns at every width.
library;

import 'package:flutter/widgets.dart';

class LumeFieldGrid extends StatelessWidget {
  const LumeFieldGrid({
    super.key,
    required this.children,
    this.wide = const <int>{},
  });

  final List<Widget> children;

  /// The indexes of [children] that span both columns.
  final Set<int> wide;

  static const double gap = 12;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    int i = 0;
    while (i < children.length) {
      if (children.length == 1 || wide.contains(i)) {
        rows.add(children[i]);
        i++;
        continue;
      }
      final bool pair = i + 1 < children.length && !wide.contains(i + 1);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: children[i]),
            const SizedBox(width: gap),
            Expanded(child: pair ? children[i + 1] : const SizedBox.shrink()),
          ],
        ),
      );
      i += pair ? 2 : 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int r = 0; r < rows.length; r++) ...<Widget>[
          if (r > 0) const SizedBox(height: gap),
          rows[r],
        ],
      ],
    );
  }
}
