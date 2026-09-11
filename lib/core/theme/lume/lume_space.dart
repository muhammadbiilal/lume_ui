/// Lume's spacing, shape and size tokens.
///
/// The system's whole point is that nine row types share one padding value. A
/// screen that writes `EdgeInsets.all(17)` has left the system, and the next
/// screen will write 18.
///
/// Built on a 4 px base grid (Design System §5). Everything here is logical
/// pixels, which are the same unit the reference's CSS pixels are, so a number
/// that appears in `tokens.css` appears here unchanged.
library;

import 'package:flutter/widgets.dart';

/// Spacing, shape and the layout constants the width classes switch.
abstract final class LumeSpace {
  // ---- The 4 px scale (§5: 4, 8, 12, 16, 20, 24, 32, 40).
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;

  /// `--pad` at compact width. Page horizontal padding.
  static const double pageCompact = 20;

  /// `--pad` at medium width.
  static const double pageMedium = 24;

  /// `--pad` at expanded width.
  static const double pageExpanded = 32;

  /// `--gap-card` — between cards.
  static const double gapCard = 16;

  /// `--gap-section` — between sections.
  static const double gapSection = 24;

  /// `--pad-card` — inside a card.
  static const double padCard = 16;

  /// `--pad-row` — inside a list row. One value for nine row types.
  static const EdgeInsets padRow = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 16,
  );

  /// `--tap` — the minimum touch target (§9). 48 is preferred; 44 is the floor
  /// and nothing may be smaller.
  static const double tap = 44;

  /// The preferred touch target.
  static const double tapPreferred = 48;

  /// `--nav-rail` — the medium-width labelled rail.
  static const double navRail = 84;

  /// `--nav-side` — the expanded-width persistent sidebar.
  static const double navSide = 244;

  /// `--content-max` — the reading and form cap (§5, "680–760 px on tablets").
  static const double contentMax = 760;

  /// `--content-wide` — master-detail and multi-column compositions.
  static const double contentWide = 1180;

  /// `--list-pane` — the expanded master-detail list pane. The CSS is
  /// `minmax(320px, 380px)`, and §8 of the CRUD guide asks for 360–440.
  static const double listPane = 380;

  /// The floor of that range.
  static const double listPaneMin = 320;

  /// The shell's own ceiling (§1: the system supports 320–1366).
  static const double shellMax = 1366;

  // ---- Icon sizes (§5: 16, 20, 24).
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  /// The stroke every Lume icon is drawn with (§5).
  static const double iconStroke = 1.75;

  // ---- Control heights, from the components they belong to.

  /// `.btn` — the Design System asks for 46–48.
  static const double buttonHeight = 46;

  /// `.search` — and the floor for any field.
  static const double searchHeight = 44;

  /// `.cfield__box` — a form field. §7 asks for 44–52.
  static const double fieldHeight = 48;

  /// `.cfield__box textarea` minimum.
  static const double textAreaMinHeight = 76;

  /// `.onb__nav` — the circular back button.
  static const double circleBack = 34;

  // ---- Borders.

  /// Every hairline in the system.
  static const double border = 1;

  /// The focus ring (§9: "visible 2 px jade outline with 2 px offset").
  static const double focusRing = 2;
  static const double focusOffset = 2;
}

/// Corner radii. `--r-*`.
abstract final class LumeRadius {
  /// `--r-xs` — small controls.
  static const double xs = 8;

  /// `--r-icon` — every icon container. One value, not nine.
  static const double icon = 12;

  /// `--r-sm` — compact cards and controls (§5: "12 px controls").
  static const double sm = 12;

  /// `--r-md` — standard cards (§5: "16 px cards").
  static const double md = 16;

  /// `--r-lg` — prominent surfaces.
  static const double lg = 20;

  /// `--r-xl` — sheets and hero surfaces (§5: "26 px sheets").
  static const double xl = 26;

  static const Radius rXs = Radius.circular(xs);
  static const Radius rIcon = Radius.circular(icon);
  static const Radius rSm = Radius.circular(sm);
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);
  static const Radius rXl = Radius.circular(xl);

  static const BorderRadius brXs = BorderRadius.all(rXs);
  static const BorderRadius brIcon = BorderRadius.all(rIcon);
  static const BorderRadius brSm = BorderRadius.all(rSm);
  static const BorderRadius brMd = BorderRadius.all(rMd);
  static const BorderRadius brLg = BorderRadius.all(rLg);
  static const BorderRadius brXl = BorderRadius.all(rXl);

  /// `--r-full`. A pill, whatever its height.
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));

  /// A sheet: rounded at the top, square where it meets the bottom edge.
  static const BorderRadius sheetTop = BorderRadius.vertical(top: rXl);
}
