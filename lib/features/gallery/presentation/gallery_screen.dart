/// The token gallery — the F1 verification surface.
///
/// Every token the foundation defines, rendered, so the palette, the type
/// scale, the spacing, the radii, the shadows, the gradients, the icon set and
/// the width classes can be looked at rather than trusted. It is a development
/// surface, not a product screen: it is not localised beyond what it borrows,
/// and no user ever reaches it.
///
/// It earns its place twice. It is how a person checks the foundation, and it
/// is the widget the golden harness pumps to prove the tokens render at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/locale_provider.dart';
import '../../../app/providers/theme_provider.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_locales.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_gradients.dart';
import '../../../core/theme/lume/lume_motion.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import 'component_gallery.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LumeColors lume = context.lume;

    return Scaffold(
      backgroundColor: lume.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const _GalleryBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: LumeSpace.x10),
                children: const <Widget>[
                  _MeasureSection(),
                  _ColourSection(),
                  _TypeSection(),
                  _SpaceSection(),
                  _RadiusSection(),
                  _ShadowSection(),
                  _GradientSection(),
                  _IconSection(),
                  _MotionSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Theme and language switches, so both axes are checkable without a rebuild.
class _GalleryBar extends ConsumerWidget {
  const _GalleryBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LumeColors lume = context.lume;
    final LumeType type = context.lumeType;
    final ThemeMode mode = ref.watch(themeModeProvider);
    final Locale? locale = ref.watch(localeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LumeSpace.pageCompact,
        vertical: LumeSpace.x3,
      ),
      decoration: BoxDecoration(
        color: lume.card,
        border: Border(
          bottom: BorderSide(color: lume.border, width: LumeSpace.border),
        ),
      ),
      // Wraps rather than overflows. At 200 % text the title and two pills do
      // not fit on one line at phone width, and §9 asks for that to degrade
      // rather than clip — so the row becomes two rows instead of running off
      // the edge.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: LumeSpace.x2,
        runSpacing: LumeSpace.x2,
        children: <Widget>[
          Text('Lume tokens', style: type.section.copyWith(color: lume.text)),
          _Pill(
            label: mode == ThemeMode.dark ? 'Dark' : 'Light',
            icon: mode == ThemeMode.dark ? LumeIcons.moon : LumeIcons.sun,
            onTap: () => ref.read(themeModeProvider.notifier).state =
                mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
          ),
          _Pill(
            label: LumeLocales.forCode(locale?.languageCode ?? 'en').native,
            icon: LumeIcons.globe,
            onTap: () {
              const List<String> codes = <String>['en', 'ur', 'ar'];
              final int i = codes.indexOf(locale?.languageCode ?? 'en');
              ref.read(localeProvider.notifier).state = Locale(
                codes[(i + 1) % codes.length],
              );
            },
          ),
          // The only way into the component gallery. No route resolves to it,
          // so it cannot become a production destination by accident.
          _Pill(
            label: 'Components',
            icon: LumeIcons.grid,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const ComponentGallery(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, required this.onTap});

  final String label;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: LumeSpace.tap),
          padding: const EdgeInsets.symmetric(horizontal: LumeSpace.x3),
          decoration: BoxDecoration(
            color: lume.tintNeutral,
            borderRadius: LumeRadius.full,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeIcon.small(icon, color: lume.text2),
              const SizedBox(width: LumeSpace.x2),
              Text(
                label,
                style: LumeType.fit(
                  context,
                  context.lumeType.meta,
                ).copyWith(color: lume.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled block, measured the way every real section will be.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.note});

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final LumeType type = context.lumeType;
    return Padding(
      padding: const EdgeInsets.only(top: LumeSpace.gapSection),
      child: LumeMeasure(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: type.section.copyWith(color: lume.text)),
            if (note != null) ...<Widget>[
              const SizedBox(height: LumeSpace.x1),
              Text(note!, style: type.metaSmall.copyWith(color: lume.text3)),
            ],
            const SizedBox(height: LumeSpace.x3),
            child,
          ],
        ),
      ),
    );
  }
}

class _MeasureSection extends StatelessWidget {
  const _MeasureSection();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final LumeType type = context.lumeType;
    final LumeWidthClass w = context.widthClass;

    String line(String k, String v) => '$k  $v';

    return _Section(
      title: 'Width class',
      note: 'Measured from the shell, not the window.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(LumeSpace.padCard),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brMd,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.xs,
        ),
        child: DefaultTextStyle(
          style: LumeType.numeric(type.body).copyWith(color: lume.text2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(w.name, style: type.display.copyWith(color: lume.accentInk)),
              const SizedBox(height: LumeSpace.x2),
              Text(
                line(
                  'shell',
                  '${context.shellWidth.round()} × '
                      '${context.shellHeight.round()}',
                ),
              ),
              Text(line('measure class', context.measureClass.name)),
              Text(line('detail pane', '${context.hasDetailPane}')),
              Text(line('compact height', '${context.isCompactHeight}')),
              if (context.isHeightConstrained)
                Text(
                  'height override active — a landscape phone keeps the '
                  'phone presentation',
                  style: type.metaSmall.copyWith(color: lume.amberInk),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColourSection extends StatelessWidget {
  const _ColourSection();

  @override
  Widget build(BuildContext context) {
    final LumeColors c = context.lume;
    final List<(String, Color)> swatches = <(String, Color)>[
      ('accent50', c.accent50),
      ('accent100', c.accent100),
      ('accent200', c.accent200),
      ('accent400', c.accent400),
      ('accent', c.accent),
      ('accent600', c.accent600),
      ('accent700', c.accent700),
      ('accentInk', c.accentInk),
      ('onAccent', c.onAccent),
      ('violet', c.violet),
      ('indigo', c.indigo),
      ('amber', c.amber),
      ('amberInk', c.amberInk),
      ('rose', c.rose),
      ('roseInk', c.roseInk),
      ('sky', c.sky),
      ('bg', c.bg),
      ('bgSunk', c.bgSunk),
      ('card', c.card),
      ('card2', c.card2),
      ('cardHover', c.cardHover),
      ('text', c.text),
      ('text2', c.text2),
      ('text3', c.text3),
      ('tintAccent', c.tintAccent),
      ('tintNeutral', c.tintNeutral),
    ];

    return _Section(
      title: 'Colour',
      note:
          'Dark is authored, not derived. Ink and surface are separate '
          'tokens where one value would fail one of the two jobs.',
      child: Wrap(
        spacing: LumeSpace.x2,
        runSpacing: LumeSpace.x2,
        children: <Widget>[
          for (final (String name, Color colour) in swatches)
            _Swatch(name: name, colour: colour),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.colour});

  final String name;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: colour,
              borderRadius: LumeRadius.brIcon,
              border: Border.all(color: lume.border, width: LumeSpace.border),
            ),
          ),
          const SizedBox(height: LumeSpace.x1),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.lumeType.metaSmall.copyWith(color: lume.text3),
          ),
        ],
      ),
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final LumeType type = context.lumeType;
    const Map<String, String> sizes = <String, String>{
      'display': '28/32 · 800',
      'title': '20/26 · 700',
      'section': '17/22 · 700',
      'cardTitle': '15/20 · 700',
      'body': '14/22 · 400',
      'bodyStrong': '14/22 · 500',
      'label': '12/16 · 700',
      'meta': '12/16 · 600',
      'metaSmall': '11/16 · 500',
      'tab': '10/14 · 700',
    };

    return _Section(
      title: 'Typography',
      note:
          'Plus Jakarta Sans, five real weights. Line height loosens for '
          'scripts that would otherwise clip.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final MapEntry<String, TextStyle> role in type.all.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: LumeSpace.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${role.key}  ·  ${sizes[role.key]}',
                    style: type.metaSmall.copyWith(color: lume.text3),
                  ),
                  Text(
                    'Everything your day needs',
                    style: LumeType.fit(
                      context,
                      role.value,
                    ).copyWith(color: lume.text),
                  ),
                ],
              ),
            ),
          const SizedBox(height: LumeSpace.x2),
          Text(
            'Tabular figures',
            style: type.metaSmall.copyWith(color: lume.text3),
          ),
          Text(
            '1,240.50   16:41   −3.2%',
            style: LumeType.numeric(type.title).copyWith(color: lume.text),
          ),
          const SizedBox(height: LumeSpace.x3),
          Text(
            'Arabic reading face',
            style: type.metaSmall.copyWith(color: lume.text3),
          ),
          Text(
            'بِسْمِ ٱللَّٰهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            textDirection: TextDirection.rtl,
            style: LumeType.arabic().copyWith(color: lume.text),
          ),
        ],
      ),
    );
  }
}

class _SpaceSection extends StatelessWidget {
  const _SpaceSection();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    const List<(String, double)> steps = <(String, double)>[
      ('4', LumeSpace.x1),
      ('8', LumeSpace.x2),
      ('12', LumeSpace.x3),
      ('16', LumeSpace.x4),
      ('20', LumeSpace.x5),
      ('24', LumeSpace.x6),
      ('32', LumeSpace.x8),
      ('40', LumeSpace.x10),
    ];
    return _Section(
      title: 'Spacing',
      note: 'A 4 px base grid. 20 px phone padding, 24–32 px tablet gutters.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (String label, double value) in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: LumeSpace.x1),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 32,
                    child: Text(
                      label,
                      style: LumeType.numeric(
                        context.lumeType.metaSmall,
                      ).copyWith(color: lume.text3),
                    ),
                  ),
                  Container(
                    width: value,
                    height: 12,
                    decoration: BoxDecoration(
                      color: lume.accent,
                      borderRadius: LumeRadius.brXs,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RadiusSection extends StatelessWidget {
  const _RadiusSection();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    const List<(String, double)> radii = <(String, double)>[
      ('xs 8', LumeRadius.xs),
      ('icon 12', LumeRadius.icon),
      ('sm 12', LumeRadius.sm),
      ('md 16', LumeRadius.md),
      ('lg 20', LumeRadius.lg),
      ('xl 26', LumeRadius.xl),
    ];
    return _Section(
      title: 'Radius',
      note: '12 px controls, 16 px cards, 26 px sheets.',
      child: Wrap(
        spacing: LumeSpace.x3,
        runSpacing: LumeSpace.x3,
        children: <Widget>[
          for (final (String label, double r) in radii)
            Column(
              children: <Widget>[
                Container(
                  width: 64,
                  height: 48,
                  decoration: BoxDecoration(
                    color: lume.tintAccent,
                    borderRadius: BorderRadius.circular(r),
                    border: Border.all(
                      color: lume.border,
                      width: LumeSpace.border,
                    ),
                  ),
                ),
                const SizedBox(height: LumeSpace.x1),
                Text(
                  label,
                  style: context.lumeType.metaSmall.copyWith(color: lume.text3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ShadowSection extends StatelessWidget {
  const _ShadowSection();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return _Section(
      title: 'Elevation',
      note: 'LG is for sheets and overlays only.',
      child: Wrap(
        spacing: LumeSpace.x4,
        runSpacing: LumeSpace.x4,
        children: <Widget>[
          for (final MapEntry<String, List<BoxShadow>> s
              in context.lumeShadows.all.entries)
            Column(
              children: <Widget>[
                Container(
                  width: 76,
                  height: 56,
                  decoration: BoxDecoration(
                    color: lume.card,
                    borderRadius: LumeRadius.brMd,
                    boxShadow: s.value,
                  ),
                ),
                const SizedBox(height: LumeSpace.x2),
                Text(
                  s.key,
                  style: context.lumeType.metaSmall.copyWith(color: lume.text3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GradientSection extends StatelessWidget {
  const _GradientSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Gradients',
      note:
          'Hero surfaces, featured content and decoration only. '
          'Re-authored for dark, never dimmed.',
      child: Wrap(
        spacing: LumeSpace.x2,
        runSpacing: LumeSpace.x2,
        children: <Widget>[
          for (final MapEntry<String, LumeGradient> g
              in context.lumeGradients.all.entries)
            Container(
              width: 108,
              height: 68,
              padding: const EdgeInsets.all(LumeSpace.x2),
              alignment: AlignmentDirectional.bottomStart,
              decoration: BoxDecoration(
                gradient: g.value.linear,
                borderRadius: LumeRadius.brMd,
              ),
              child: Text(
                g.key,
                style: context.lumeType.meta.copyWith(color: g.value.on),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconSection extends StatelessWidget {
  const _IconSection();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return _Section(
      title: 'Icons — ${LumeIcons.all.length}',
      note:
          'One 24 px stroke family at 1.75. Directional glyphs mirror in '
          'RTL; clocks and media controls never do.',
      child: Wrap(
        spacing: LumeSpace.x3,
        runSpacing: LumeSpace.x3,
        children: <Widget>[
          for (final String name in LumeIcons.all)
            SizedBox(
              width: 56,
              child: Column(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: lume.tintNeutral,
                      borderRadius: LumeRadius.brIcon,
                    ),
                    child: LumeIcon(name, color: lume.text2),
                  ),
                  const SizedBox(height: LumeSpace.x1),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.lumeType.metaSmall.copyWith(
                      color: lume.text3,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MotionSection extends StatelessWidget {
  const _MotionSection();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final LumeType type = context.lumeType;
    return _Section(
      title: 'Motion',
      note: LumeMotion.stillness(context)
          ? 'Reduced motion is on — indefinite animation is stopped.'
          : '160 ms feedback · 260 ms standard · 420 ms screen.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'fast    ${LumeMotion.fast.inMilliseconds} ms',
            style: LumeType.numeric(type.body).copyWith(color: lume.text2),
          ),
          Text(
            'standard ${LumeMotion.standard.inMilliseconds} ms',
            style: LumeType.numeric(type.body).copyWith(color: lume.text2),
          ),
          Text(
            'slow    ${LumeMotion.slow.inMilliseconds} ms',
            style: LumeType.numeric(type.body).copyWith(color: lume.text2),
          ),
        ],
      ),
    );
  }
}
