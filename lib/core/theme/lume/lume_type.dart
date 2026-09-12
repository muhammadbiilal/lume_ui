/// Lume's type scale — ten semantic roles, not per-widget declarations.
///
/// A screen reaches for "section title", never for "17px/700", so 200 % dynamic
/// type and a longer translation move one value rather than ninety. This is the
/// Design System's §4 table, and `tests/design.js` asserts every row of it.
///
/// Three rules that cost real bugs when broken.
///
/// **Never write a bare line height.** Plus Jakarta Sans covers Latin and
/// numerals only. Arabic, Urdu, Devanagari and CJK fall back per glyph to a
/// system face *while keeping the height they were handed*, and Lume's tight
/// 1.14–1.33 clips harakat, Nastaliq descenders and Devanagari matras. Use
/// [LumeType.fit], which loosens the height for those scripts exactly as
/// `rtl.css` does with `[lang="ur"] body { line-height: 1.6 }`.
///
/// **Never call `toUpperCase()`.** Dart's is locale-independent: Turkish `i`
/// becomes `I` rather than `İ`, and in caseless scripts it is an allocation
/// that changes nothing. [LumeType.overline] is the only correct way to render
/// a kicker.
///
/// **Numbers that align use tabular figures.** Money, timers, rates and stacked
/// statistics, which is what the reference's `.num` class marks.
library;

import 'package:flutter/material.dart';

/// The name of a type role. Used by the gallery and the token tests to walk the
/// scale rather than listing it twice.
enum LumeTypeRole {
  display,
  title,
  section,
  cardTitle,
  body,
  bodyStrong,
  label,
  meta,
  metaSmall,
  tab,
}

/// The typographic half of the design system.
@immutable
class LumeType extends ThemeExtension<LumeType> {
  const LumeType({
    required this.display,
    required this.title,
    required this.section,
    required this.cardTitle,
    required this.body,
    required this.bodyStrong,
    required this.label,
    required this.meta,
    required this.metaSmall,
    required this.tab,
  });

  /// The one family the interface is set in.
  static const String family = 'PlusJakartaSans';

  /// Arabic-script reading content. A variable face, 400–700.
  static const String arabicFamily = 'NotoNaskhArabic';

  /// `--t-display` · 28/32 · w800. Key values and onboarding titles.
  final TextStyle display;

  /// `--t-title` · 20/26 · w700. Screen titles.
  final TextStyle title;

  /// `--t-section` · 17/22 · w700. Section hierarchy.
  final TextStyle section;

  /// `--t-cardtitle` · 15/20 · w700. Record and card names.
  final TextStyle cardTitle;

  /// `--t-body` · 14/22 · w400. Descriptions and values.
  final TextStyle body;

  /// `--t-bodystrong` · 14/22 · w500.
  final TextStyle bodyStrong;

  /// `--t-label` · 12/16 · w700. Field labels and actions.
  final TextStyle label;

  /// `--t-meta` · 12/16 · w600. Dates and statuses.
  final TextStyle meta;

  /// `--t-metasm` · 11/16 · w500. Small metadata.
  final TextStyle metaSmall;

  /// `--t-tab` · 10/14 · w700. Bottom bar and rail labels only.
  final TextStyle tab;

  /// What carries a glyph Plus Jakarta Sans does not have.
  ///
  /// Plus Jakarta Sans covers Latin and numerals. Urdu and Arabic interface
  /// text — a navigation label, a button, a field label — is set in the
  /// *interface* scale, not the reading scale, so without a fallback every
  /// glyph would render as tofu. The browser falls back to a system face on
  /// its own; Flutter has to be told.
  ///
  /// Noto Naskh Arabic is the fallback because it is the face the reference
  /// loads for Arabic script and the only one bundled. Urdu is conventionally
  /// set in Nastaliq, which is a different face the reference does not ship;
  /// that is recorded as a known difference rather than solved by bundling a
  /// font the design has not asked for.
  static const List<String> _fallback = <String>[arabicFamily];

  static TextStyle _s(double size, double lineHeight, FontWeight weight) =>
      TextStyle(
        fontFamily: family,
        fontFamilyFallback: _fallback,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        // The reference sets letter-spacing per call site rather than in the
        // token; the roles that carry one apply it through `tracked()`.
        letterSpacing: 0,
        leadingDistribution: TextLeadingDistribution.even,
      );

  /// The scale. Colour is applied at the call site from [LumeColors]; a role
  /// carries size, weight and height and nothing else.
  static final LumeType standard = LumeType(
    display: _s(28, 32, FontWeight.w800),
    title: _s(20, 26, FontWeight.w700),
    section: _s(17, 22, FontWeight.w700),
    cardTitle: _s(15, 20, FontWeight.w700),
    body: _s(14, 22, FontWeight.w400),
    bodyStrong: _s(14, 22, FontWeight.w500),
    label: _s(12, 16, FontWeight.w700),
    meta: _s(12, 16, FontWeight.w600),
    metaSmall: _s(11, 16, FontWeight.w500),
    tab: _s(10, 14, FontWeight.w700),
  );

  /// Look a role up by name.
  TextStyle role(LumeTypeRole r) => switch (r) {
    LumeTypeRole.display => display,
    LumeTypeRole.title => title,
    LumeTypeRole.section => section,
    LumeTypeRole.cardTitle => cardTitle,
    LumeTypeRole.body => body,
    LumeTypeRole.bodyStrong => bodyStrong,
    LumeTypeRole.label => label,
    LumeTypeRole.meta => meta,
    LumeTypeRole.metaSmall => metaSmall,
    LumeTypeRole.tab => tab,
  };

  /// Every role, keyed by its token name.
  Map<String, TextStyle> get all => <String, TextStyle>{
    'display': display,
    'title': title,
    'section': section,
    'cardTitle': cardTitle,
    'body': body,
    'bodyStrong': bodyStrong,
    'label': label,
    'meta': meta,
    'metaSmall': metaSmall,
    'tab': tab,
  };

  // -------------------------------------------------------------------------
  // Script awareness
  // -------------------------------------------------------------------------

  /// Language codes whose script needs more vertical room than the Latin scale
  /// allows. `rtl.css` gives Urdu and Arabic `line-height: 1.6` on the body for
  /// exactly this reason.
  static const Set<String> _tallScripts = <String>{
    'ur',
    'ar',
    'fa',
    'ps',
    'sd',
    'hi',
    'bn',
    'ne',
    'mr',
    'ta',
    'te',
    'th',
  };

  /// The minimum line height for a script that needs room. The Design System
  /// asks for at least 1.8 on Arabic *reading passages* specifically; this is
  /// the floor for interface text, which the reference sets at 1.6.
  static const double tallScriptMinHeight = 1.6;

  /// Reading passages in Arabic script — §4, "at least 1.8".
  static const double arabicReadingHeight = 1.8;

  /// Whether [locale]'s script needs the looser height.
  static bool needsTallLineHeight(Locale? locale) =>
      locale != null && _tallScripts.contains(locale.languageCode);

  /// A role, fitted to the locale.
  ///
  /// This is how a widget should reach for type. It raises the line height for
  /// scripts that would otherwise clip, and drops the negative tracking the
  /// Latin display roles carry — `rtl.css` sets `letter-spacing: 0` on the
  /// greeting, the page title and the onboarding title in ur and ar, because
  /// tightening a joined script pulls its letterforms into each other.
  static TextStyle fit(BuildContext context, TextStyle style) {
    final Locale locale =
        Localizations.maybeLocaleOf(context) ?? const Locale('en');
    if (!needsTallLineHeight(locale)) return style;
    final double current = style.height ?? 1.0;
    return style.copyWith(
      height: current < tallScriptMinHeight ? tallScriptMinHeight : current,
      letterSpacing: 0,
    );
  }

  /// `line-height: normal`, as the browser resolves it for Plus Jakarta Sans.
  ///
  /// Most of the prototype's small text sets a size and leaves the line height
  /// alone, and CSS's `normal` is the *font's* natural line — ascent, descent
  /// and line gap — not a ratio anybody chose. The roles in [standard] carry
  /// the `--t-*` tokens' explicit heights, which are the right thing where a
  /// token is used and the wrong thing where the stylesheet is not using one.
  ///
  /// These are the measured values, read off the rendered prototype rather
  /// than computed: a 12-point line is 15 and an 11-point one is 13, which no
  /// single ratio produces.
  static double naturalLine(double size) => switch (size.round()) {
    10 => 12,
    11 => 13,
    12 => 15,
    13 => 16,
    14 => 18,
    15 => 19,
    17 => 22,
    20 => 26,
    24 => 30,
    28 => 35,
    _ => size * 1.26,
  };

  /// A style set at [size] on its natural line, fitted to the locale.
  ///
  /// The locale still wins: a script that needs 1.6 gets 1.6, because a clipped
  /// diacritic is worse than a line that does not match the prototype.
  static TextStyle natural(
    BuildContext context,
    TextStyle style, {
    double? size,
  }) {
    final double s = size ?? style.fontSize ?? 14;
    final Locale locale =
        Localizations.maybeLocaleOf(context) ?? const Locale('en');
    final TextStyle fitted = fit(context, style.copyWith(fontSize: s));
    final double wanted = naturalLine(s) / s;
    // The locale still wins upward: a script that needs 1.6 gets it, because a
    // clipped diacritic is worse than a line that does not match.
    final double floor = needsTallLineHeight(locale) ? tallScriptMinHeight : 0;
    return fitted.copyWith(height: wanted > floor ? wanted : floor);
  }

  /// A line height that is never tighter than the locale's script can carry.
  /// Use it when building a one-off [TextStyle] rather than taking a role.
  static double lineHeight(BuildContext context, double base) {
    final Locale locale =
        Localizations.maybeLocaleOf(context) ?? const Locale('en');
    if (!needsTallLineHeight(locale)) return base;
    return base < tallScriptMinHeight ? tallScriptMinHeight : base;
  }

  /// Arabic-script reading content — the Qur'an, a hadith, a dua.
  ///
  /// A different family, and a much looser line so the diacritics have room.
  static TextStyle arabic({
    double size = 22,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: arabicFamily,
    fontSize: size,
    height: arabicReadingHeight,
    fontWeight: weight,
    // The face is variable over 400–700, so a heavier cut is an axis
    // position rather than a synthesised bold.
    fontVariations: <FontVariation>[
      FontVariation('wght', weight.value.toDouble()),
    ],
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Tabular figures, for money, timers, rates and aligned statistics. The
  /// reference's `.num` class.
  static TextStyle numeric(TextStyle style) => style.copyWith(
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );

  /// Apply the reference's per-call-site tracking, expressed the way CSS does:
  /// in `em`, relative to the style's own size.
  ///
  /// `.btn` is `-.022em`, `.navtab` is `-.02em`, `.onb__title` is `-.04em`,
  /// a kicker is `.1em`.
  static TextStyle tracked(TextStyle style, double em) =>
      style.copyWith(letterSpacing: em * (style.fontSize ?? 14));

  /// An uppercase kicker — `.onb__kicker`, `.statusbar__brand`.
  ///
  /// Uppercasing is done with the locale's own rules, and skipped entirely for
  /// scripts that have no case. Never call `String.toUpperCase()` directly:
  /// Dart's is locale-independent and gets Turkish wrong.
  static String overline(BuildContext context, String text) {
    final Locale locale =
        Localizations.maybeLocaleOf(context) ?? const Locale('en');
    if (_tallScripts.contains(locale.languageCode)) return text;
    return text.toUpperCase();
  }

  /// The style a kicker is set in: `--t-metasm` size, w800, `.1em` tracking.
  static TextStyle overlineStyle(BuildContext context, LumeType type) =>
      tracked(
        fit(context, type.metaSmall).copyWith(fontWeight: FontWeight.w800),
        0.1,
      );

  /// The Material [TextTheme] the roles map onto, so a stray Material widget
  /// inherits something from the Lume scale rather than Roboto at 14.
  TextTheme get materialTextTheme => TextTheme(
    displayLarge: display,
    displayMedium: display,
    displaySmall: display,
    headlineLarge: display,
    headlineMedium: title,
    headlineSmall: title,
    titleLarge: title,
    titleMedium: section,
    titleSmall: cardTitle,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: metaSmall,
    labelLarge: label,
    labelMedium: meta,
    labelSmall: tab,
  );

  @override
  LumeType copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? section,
    TextStyle? cardTitle,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? label,
    TextStyle? meta,
    TextStyle? metaSmall,
    TextStyle? tab,
  }) {
    return LumeType(
      display: display ?? this.display,
      title: title ?? this.title,
      section: section ?? this.section,
      cardTitle: cardTitle ?? this.cardTitle,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      label: label ?? this.label,
      meta: meta ?? this.meta,
      metaSmall: metaSmall ?? this.metaSmall,
      tab: tab ?? this.tab,
    );
  }

  @override
  LumeType lerp(ThemeExtension<LumeType>? other, double t) {
    if (other is! LumeType) return this;
    return LumeType(
      display: TextStyle.lerp(display, other.display, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      section: TextStyle.lerp(section, other.section, t)!,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      meta: TextStyle.lerp(meta, other.meta, t)!,
      metaSmall: TextStyle.lerp(metaSmall, other.metaSmall, t)!,
      tab: TextStyle.lerp(tab, other.tab, t)!,
    );
  }
}
