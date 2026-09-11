/// Every design token, asserted against the reference stylesheet it came from.
///
/// These tests parse `assets/css/tokens.css` rather than repeating its values,
/// so they fail when the Dart and the design disagree — not when someone typed
/// the same hex twice.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/theme/lume/lume_colors.dart';
import 'package:lume/core/theme/lume/lume_gradients.dart';
import 'package:lume/core/theme/lume/lume_motion.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/theme/lume/lume_type.dart';

import '../../helpers/reference_tokens.dart';

void main() {
  if (!ReferenceTokens.available) {
    // The reference is deleted at Phase F9. When that happens these tests are
    // rewritten to assert the values directly; until then, a missing
    // stylesheet is a broken checkout, not a passing suite.
    test('the reference stylesheet is present', () {
      fail(
        '${ReferenceTokens.path} is missing. Token parity cannot be '
        'checked against the source.',
      );
    });
    return;
  }

  final ReferenceTokens css = ReferenceTokens.load();

  group('colour — light', () {
    const Map<String, Color Function(LumeColors)> mapping =
        <String, Color Function(LumeColors)>{
          '--accent-50': _accent50,
          '--accent-100': _accent100,
          '--accent-200': _accent200,
          '--accent-400': _accent400,
          '--accent': _accent,
          '--accent-600': _accent600,
          '--accent-700': _accent700,
          '--accent-ink': _accentInk,
          '--violet': _violet,
          '--indigo': _indigo,
          '--amber': _amber,
          '--on-amber': _onAmber,
          '--amber-ink': _amberInk,
          '--rose': _rose,
          '--on-rose': _onRose,
          '--rose-ink': _roseInk,
          '--sky': _sky,
          '--bg': _bg,
          '--bg-sunk': _bgSunk,
          '--card': _card,
          '--card-2': _card2,
          '--card-hover': _cardHover,
          '--text': _text,
          '--text-2': _text2,
          '--text-3': _text3,
          '--border': _border,
          '--border-2': _border2,
          '--overlay': _overlay,
          '--tint-accent': _tintAccent,
          '--tint-neutral': _tintNeutral,
        };

    mapping.forEach((String token, Color Function(LumeColors) read) {
      test('$token matches the shipped value', () {
        expect(
          read(LumeColors.light),
          ReferenceTokens.colour(css.light[token]!),
          reason: '$token in :root',
        );
      });
    });
  });

  group('colour — dark', () {
    const Map<String, Color Function(LumeColors)> mapping =
        <String, Color Function(LumeColors)>{
          '--accent': _accent,
          '--accent-700': _accent700,
          '--accent-ink': _accentInk,
          '--bg': _bg,
          '--bg-sunk': _bgSunk,
          '--card': _card,
          '--card-2': _card2,
          '--card-hover': _cardHover,
          '--text': _text,
          '--text-2': _text2,
          '--text-3': _text3,
          '--border': _border,
          '--border-2': _border2,
          '--overlay': _overlay,
          '--tint-accent': _tintAccent,
          '--tint-neutral': _tintNeutral,
          '--rose': _rose,
          '--rose-ink': _roseInk,
          '--amber': _amber,
          '--amber-ink': _amberInk,
        };

    mapping.forEach((String token, Color Function(LumeColors) read) {
      test('$token matches the shipped value', () {
        expect(
          read(LumeColors.dark),
          ReferenceTokens.colour(css.dark[token]!),
          reason: '$token in [data-theme="dark"]',
        );
      });
    });

    test(
      'dark is authored, not inverted — its own canvas, card, text, accent',
      () {
        expect(LumeColors.dark.bg, isNot(LumeColors.light.bg));
        expect(LumeColors.dark.card, isNot(LumeColors.light.card));
        expect(LumeColors.dark.text, isNot(LumeColors.light.text));
        expect(LumeColors.dark.accent, isNot(LumeColors.light.accent));
      },
    );

    test('the accent ramp inverts direction in dark', () {
      // In light, 700 is the darkest jade. On a near-black ground the ink that
      // reads is the pale one, so 700 is the lightest. Anything computing dark
      // from light gets this backwards.
      double l(Color c) => HSLColor.fromColor(c).lightness;
      expect(
        l(LumeColors.light.accent700),
        lessThan(l(LumeColors.light.accent)),
      );
      expect(
        l(LumeColors.dark.accent700),
        greaterThan(l(LumeColors.dark.accent)),
      );
    });
  });

  group('ink and surface stay separate', () {
    test('rose as a surface and rose as ink are different values', () {
      expect(LumeColors.light.onRose, isNot(LumeColors.light.roseInk));
      expect(LumeColors.dark.onRose, isNot(LumeColors.dark.roseInk));
    });

    test('amber as a surface and amber as ink are different values', () {
      expect(LumeColors.light.onAmber, isNot(LumeColors.light.amberInk));
      expect(LumeColors.dark.onAmber, isNot(LumeColors.dark.amberInk));
    });

    test('what sits on the accent flips between themes', () {
      // White on the light jade; a deep ink on the lighter dark-mode jade.
      expect(LumeColors.light.onAccent, const Color(0xFFFFFFFF));
      expect(LumeColors.dark.onAccent, const Color(0xFF06231F));
    });

    test('roseInk carries AA on card', () {
      expect(
        _contrast(LumeColors.light.roseInk, LumeColors.light.card),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('amberInk carries AA on card', () {
      expect(
        _contrast(LumeColors.light.amberInk, LumeColors.light.card),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('primary text carries AA on the page ground, both themes', () {
      expect(
        _contrast(LumeColors.light.text, LumeColors.light.bg),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(LumeColors.dark.text, LumeColors.dark.bg),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('secondary text carries AA on card, both themes', () {
      expect(
        _contrast(LumeColors.light.text2, LumeColors.light.card),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(LumeColors.dark.text2, LumeColors.dark.card),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('what sits on the accent carries AA against it, both themes', () {
      expect(
        _contrast(LumeColors.light.onAccent, LumeColors.light.accent),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        _contrast(LumeColors.dark.onAccent, LumeColors.dark.accent),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('typography', () {
    const Map<String, LumeTypeRole> roles = <String, LumeTypeRole>{
      '--t-display': LumeTypeRole.display,
      '--t-title': LumeTypeRole.title,
      '--t-section': LumeTypeRole.section,
      '--t-cardtitle': LumeTypeRole.cardTitle,
      '--t-body': LumeTypeRole.body,
      '--t-bodystrong': LumeTypeRole.bodyStrong,
      '--t-label': LumeTypeRole.label,
      '--t-meta': LumeTypeRole.meta,
      '--t-metasm': LumeTypeRole.metaSmall,
      '--t-tab': LumeTypeRole.tab,
    };

    roles.forEach((String token, LumeTypeRole role) {
      test('$token has the shipped size, weight and line height', () {
        final ({double lineHeight, double size, FontWeight weight}) want =
            ReferenceTokens.font(css.light[token]!);
        final TextStyle got = LumeType.standard.role(role);

        expect(got.fontSize, want.size, reason: '$token size');
        expect(got.fontWeight, want.weight, reason: '$token weight');
        expect(
          got.height! * got.fontSize!,
          closeTo(want.lineHeight, 0.001),
          reason: '$token line height',
        );
      });
    });

    test('every role is set in Plus Jakarta Sans', () {
      for (final MapEntry<String, TextStyle> e
          in LumeType.standard.all.entries) {
        expect(e.value.fontFamily, LumeType.family, reason: e.key);
      }
    });

    test('only the five bundled weights are used', () {
      final Set<FontWeight> bundled = <FontWeight>{
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700,
        FontWeight.w800,
      };
      for (final MapEntry<String, TextStyle> e
          in LumeType.standard.all.entries) {
        expect(
          bundled,
          contains(e.value.fontWeight),
          reason:
              '${e.key} asks for a weight with no bundled file, which '
              'Flutter would synthesise',
        );
      }
    });

    test('numeric() asks for tabular figures', () {
      expect(
        LumeType.numeric(LumeType.standard.body).fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('the Arabic reading face is Noto Naskh at 1.8 line height', () {
      final TextStyle a = LumeType.arabic();
      expect(a.fontFamily, LumeType.arabicFamily);
      expect(a.height, LumeType.arabicReadingHeight);
      expect(a.height, greaterThanOrEqualTo(1.8));
    });

    test(
      'a heavier Arabic cut is an axis position, not a synthesised bold',
      () {
        final TextStyle bold = LumeType.arabic(weight: FontWeight.w700);
        expect(bold.fontVariations, contains(const FontVariation('wght', 700)));
      },
    );
  });

  group('spacing, shape and touch', () {
    test('--pad is 20 at phone width', () {
      expect(LumeSpace.pageCompact, ReferenceTokens.px(css.light['--pad']!));
    });

    test('--gap-card, --gap-section and --pad-card match', () {
      expect(LumeSpace.gapCard, ReferenceTokens.px(css.light['--gap-card']!));
      expect(
        LumeSpace.gapSection,
        ReferenceTokens.px(css.light['--gap-section']!),
      );
      expect(LumeSpace.padCard, ReferenceTokens.px(css.light['--pad-card']!));
    });

    test('--pad-row is one value for every row type', () {
      // `--pad-row: 12px 16px`
      final List<double> parts = RegExp(r'[\d.]+')
          .allMatches(css.light['--pad-row']!)
          .map((RegExpMatch m) => double.parse(m.group(0)!))
          .toList();
      expect(LumeSpace.padRow.top, parts[0]);
      expect(LumeSpace.padRow.left, parts[1]);
    });

    test('the radius scale matches', () {
      expect(LumeRadius.xs, ReferenceTokens.px(css.light['--r-xs']!));
      expect(LumeRadius.icon, ReferenceTokens.px(css.light['--r-icon']!));
      expect(LumeRadius.sm, ReferenceTokens.px(css.light['--r-sm']!));
      expect(LumeRadius.md, ReferenceTokens.px(css.light['--r-md']!));
      expect(LumeRadius.lg, ReferenceTokens.px(css.light['--r-lg']!));
      expect(LumeRadius.xl, ReferenceTokens.px(css.light['--r-xl']!));
    });

    test(
      'the Design System\'s named shapes: 12 controls, 16 cards, 26 sheets',
      () {
        expect(LumeRadius.sm, 12);
        expect(LumeRadius.md, 16);
        expect(LumeRadius.xl, 26);
      },
    );

    test('the minimum touch target is 44', () {
      expect(LumeSpace.tap, ReferenceTokens.px(css.light['--tap']!));
      expect(LumeSpace.tap, 44);
    });

    test('the layout constants match', () {
      expect(LumeSpace.navRail, ReferenceTokens.px(css.light['--nav-rail']!));
      expect(LumeSpace.navSide, ReferenceTokens.px(css.light['--nav-side']!));
      expect(
        LumeSpace.contentMax,
        ReferenceTokens.px(css.light['--content-max']!),
      );
      expect(
        LumeSpace.contentWide,
        ReferenceTokens.px(css.light['--content-wide']!),
      );
      expect(LumeSpace.listPane, ReferenceTokens.px(css.light['--list-pane']!));
    });

    test(
      'reading content is capped in the 680–760 band the document names',
      () {
        expect(LumeSpace.contentMax, inInclusiveRange(680, 760));
      },
    );

    test('the list pane sits in the 360–440 band', () {
      expect(LumeSpace.listPane, inInclusiveRange(360, 440));
    });

    test('the icon stroke is 1.75', () {
      expect(LumeSpace.iconStroke, 1.75);
    });
  });

  group('motion', () {
    test('the three durations match', () {
      expect(
        LumeMotion.fast,
        ReferenceTokens.seconds(css.light['--dur-fast']!),
      );
      expect(LumeMotion.standard, ReferenceTokens.seconds(css.light['--dur']!));
      expect(
        LumeMotion.slow,
        ReferenceTokens.seconds(css.light['--dur-slow']!),
      );
    });

    test('160 feedback, 260 standard, 420 screen — the numbers §5 names', () {
      expect(LumeMotion.fast.inMilliseconds, 160);
      expect(LumeMotion.standard.inMilliseconds, 260);
      expect(LumeMotion.slow.inMilliseconds, 420);
    });

    test('the curves match the cubic-beziers', () {
      Curve parse(String value) {
        final List<double> n = RegExp(r'-?[\d.]+')
            .allMatches(value)
            .map((RegExpMatch m) => double.parse(m.group(0)!))
            .toList();
        return Cubic(n[0], n[1], n[2], n[3]);
      }

      // Cubic has no value equality, so compare the control points.
      void same(Curve got, Curve want, String token) {
        final Cubic a = got as Cubic;
        final Cubic b = want as Cubic;
        expect(
          <double>[a.a, a.b, a.c, a.d],
          <double>[b.a, b.b, b.c, b.d],
          reason: token,
        );
      }

      same(LumeMotion.ease, parse(css.light['--ease']!), '--ease');
      same(LumeMotion.easeOut, parse(css.light['--ease-out']!), '--ease-out');
      same(
        LumeMotion.spring,
        parse(css.light['--ease-spring']!),
        '--ease-spring',
      );
    });
  });

  group('gradients', () {
    test('every colourway matches both stops in both themes', () {
      final Map<String, LumeGradient> light = LumeGradients.light.all;
      final Map<String, LumeGradient> dark = LumeGradients.dark.all;

      for (final String name in light.keys) {
        expect(
          light[name]!.a,
          ReferenceTokens.colour(css.light['--grad-$name-a']!),
          reason: '--grad-$name-a light',
        );
        expect(
          light[name]!.b,
          ReferenceTokens.colour(css.light['--grad-$name-b']!),
          reason: '--grad-$name-b light',
        );
        expect(
          dark[name]!.a,
          ReferenceTokens.colour(css.dark['--grad-$name-a']!),
          reason: '--grad-$name-a dark',
        );
        expect(
          dark[name]!.b,
          ReferenceTokens.colour(css.dark['--grad-$name-b']!),
          reason: '--grad-$name-b dark',
        );
      }
    });

    test('all eleven colourways are present', () {
      expect(LumeGradients.light.all, hasLength(11));
      expect(LumeGradients.dark.all, hasLength(11));
    });

    test('dark gradients are re-authored, not the light pair dimmed', () {
      final Map<String, LumeGradient> light = LumeGradients.light.all;
      final Map<String, LumeGradient> dark = LumeGradients.dark.all;
      double l(Color c) => HSLColor.fromColor(c).lightness;

      for (final String name in light.keys) {
        expect(
          l(dark[name]!.a),
          lessThan(l(light[name]!.a)),
          reason: '$name drops in luminance for the dark ground',
        );
      }
    });
  });
}

// ---- Readers, so the token maps above stay tables rather than closures.
Color _accent50(LumeColors c) => c.accent50;
Color _accent100(LumeColors c) => c.accent100;
Color _accent200(LumeColors c) => c.accent200;
Color _accent400(LumeColors c) => c.accent400;
Color _accent(LumeColors c) => c.accent;
Color _accent600(LumeColors c) => c.accent600;
Color _accent700(LumeColors c) => c.accent700;
Color _accentInk(LumeColors c) => c.accentInk;
Color _violet(LumeColors c) => c.violet;
Color _indigo(LumeColors c) => c.indigo;
Color _amber(LumeColors c) => c.amber;
Color _onAmber(LumeColors c) => c.onAmber;
Color _amberInk(LumeColors c) => c.amberInk;
Color _rose(LumeColors c) => c.rose;
Color _onRose(LumeColors c) => c.onRose;
Color _roseInk(LumeColors c) => c.roseInk;
Color _sky(LumeColors c) => c.sky;
Color _bg(LumeColors c) => c.bg;
Color _bgSunk(LumeColors c) => c.bgSunk;
Color _card(LumeColors c) => c.card;
Color _card2(LumeColors c) => c.card2;
Color _cardHover(LumeColors c) => c.cardHover;
Color _text(LumeColors c) => c.text;
Color _text2(LumeColors c) => c.text2;
Color _text3(LumeColors c) => c.text3;
Color _border(LumeColors c) => c.border;
Color _border2(LumeColors c) => c.border2;
Color _overlay(LumeColors c) => c.overlay;
Color _tintAccent(LumeColors c) => c.tintAccent;
Color _tintNeutral(LumeColors c) => c.tintNeutral;

/// WCAG relative-luminance contrast ratio.
double _contrast(Color a, Color b) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final double la = luminance(a);
  final double lb = luminance(b);
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}
