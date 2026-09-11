/// Numbers, times and codes stay left-to-right inside right-to-left text.
///
/// `rtl.css` says it in one rule:
///
/// ```css
/// .is-rtl .num, .is-rtl .locrow__code, .is-rtl .trainno {
///   direction: ltr;
///   unicode-bidi: isolate;
/// }
/// ```
///
/// Without it a paragraph containing two numeric runs reorders them: an Urdu
/// line reading "1,240.50" then "16:41" renders as "16:41 1,240.50", because
/// bidi resolution lays the two runs out in paragraph order. The numbers
/// themselves are still correct; their *sequence* is not, and a price beside a
/// time silently swaps places.
///
/// Isolation matters as much as direction. An LTR run without it can still
/// bleed into the surrounding text's ordering; `TextDirection.ltr` on its own
/// changes the run's internal order but not its relationship to its neighbours.
/// A separate [Directionality] subtree gives both.
///
/// **This is not "make numbers English".** Locale-aware digits, separators and
/// currency formatting are `intl`'s job and happen before the string gets here.
/// This only fixes the order the runs are laid out in.
library;

import 'package:flutter/widgets.dart';

/// Lays its child out left-to-right, whatever the surrounding direction.
///
/// Wrap a numeral, a time, a country code, a train number, a percentage — any
/// run whose internal order is not a statement about the reading direction.
class LumeLtr extends StatelessWidget {
  const LumeLtr({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: TextDirection.ltr, child: child);
}

/// A number, a time or a code, laid out in its own direction.
///
/// The common case of [LumeLtr]: one string that must not reorder.
class LumeNumerals extends StatelessWidget {
  const LumeNumerals(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.semanticsLabel,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  /// What a screen reader says instead of the raw string. A time announced as
  /// "sixteen forty-one" is more use than "one six colon four one".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => LumeLtr(
    child: Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      semanticsLabel: semanticsLabel,
      // Start, not left: inside the isolated LTR subtree, start *is* left, and
      // saying so keeps the widget honest if it is ever nested differently.
      textAlign: TextAlign.start,
    ),
  );
}
