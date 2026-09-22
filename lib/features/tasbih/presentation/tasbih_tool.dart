/// Tasbih — a counter and a reset, and nothing else.
///
/// `tools/islamic/tasbih.tool.js` over `tool.screen.js:764-801`: the phrase,
/// the tap target with the count and the ring to the round's target, the
/// rounds read-out, and Reset. Faith-gated in the catalogue, so a reader who
/// has not turned the Islamic experience on never reaches it — the gate
/// decides, not this screen.
///
/// **What this tool does not do.** It counts and it resets. It prescribes no
/// number, declares no recitation obligatory, recommended or rewarded,
/// invents no virtue, quotes no scripture and cites no hadith: the repository
/// carries no verified licensed religious source, so nothing is asserted here
/// that a source would have to stand behind. The five phrases are the
/// reference's own (`tool-data.js:678-684`) and are reproduced exactly — the
/// Arabic, a transliteration, a gloss labelled `l.tasbihMeaning`, and the
/// conventional number in a round, stated as a fact about the round
/// ("Round of 33", `l.tasbihTargetLabel`) and never as a ruling.
///
/// ## Corrections to the reference
///
/// 1. **"Recent sessions" is dropped.** `tasbih.tool.js:44-46` closes with a
///    section of two rows — SubhanAllah / Today / 33 and Astaghfirullah /
///    Yesterday / 100 — read from `context.js:384-387`, where they are a
///    literal fixture. They are presented as the reader's own past dhikr and
///    nothing records it: no session is written down, so no session can be
///    listed back. The section is gone rather than emptied, and what is
///    actually true of the count is said instead (`l.tasbihNotKept`). Every
///    figure on this screen is now the reader's own taps.
/// 2. **The rounds read-out is a read-out.** `tasbih.tool.js:41` renders it
///    with `UI.button` and gives it no `act`, so the reference draws a
///    control that looks pressable, takes focus and does nothing. It is a
///    figure, and it is drawn as one.
/// 3. **Switching phrase asks first.** `tool.screen.js:775-780` sets
///    `count = 0` the instant another phrase is chosen, so a part-finished
///    round disappears on a mis-tap with no warning and no way back. It is
///    confirmed (`l.tasbihSwitchAsk`), and the finished rounds are kept.
/// 4. **One clamped ring.** `tasbih.tool.js:33` computes the arc from
///    `(1 - count / target)` with no floor while the live handler at
///    `tool.screen.js:792` clamps the same arithmetic with `Math.max(0, …)`:
///    two expressions for one geometry, one of which can go negative.
///    [LumeTasbihCount.progress] is the only expression and it is clamped.
/// 5. **The count is announced.** `tasbih.tool.js:28-38` puts the figure in a
///    plain `<span>` inside a button labelled "Counter", so a screen-reader
///    user taps and hears nothing at all. The tap target carries the count as
///    its value in a live region — throttled, so a burst of taps is announced
///    meaningfully rather than once per tap (see [announceAfter]).
/// 6. **The ring says it is a ring.** `tasbih.tool.js:36-37` draws two bare
///    `<circle>` elements with `aria-hidden`, so the progress towards the
///    round is invisible to assistive technology although the shared
///    component ([LumeProgressRing]) reports it as a progress bar. It is
///    drawn with the shared component.
///
/// ## Geometry
///
/// `tools/shared.css:1148-1176`. The block is a centred column 16 apart on
/// `6 var(--pad) 0`: the phrase picker (`.fchip` geometry, accent when on),
/// the Arabic at 28 on the reference's own 1.6 line, the gloss 8 under it
/// (`margin-top: -8px` against the 16 gap), the 224-point face, and the
/// actions. The capture measures the whole block at 434.8 at 390
/// (`tool_tasbih_muslim_pk_390x844_light_en`); the rules named above account
/// for [_named] of that, and the remainder is carried as one explicit spacer
/// ([_unattributed]) so that everything below the block lands where the
/// reference puts it. The measurement is the authority; the attribution is
/// not complete, and saying so is better than distributing the difference
/// invisibly. The picker is the one part drawn to a different rule: Lume's
/// 44-point touch floor makes it 13 taller than `.fchip`'s 31, and those 13
/// come out of the gap beneath it rather than off the end of the block
/// (D6/D35). The block then measures 435 against the capture's 434.8, which
/// is what `tasbih_parity_test.dart` holds it to.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_numerals.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/tasbih_store.dart';
import '../domain/tasbih_count.dart';
import '../domain/tasbih_phrase.dart';

class LumeTasbihTool extends ConsumerStatefulWidget {
  const LumeTasbihTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeTasbihTool(request: request);

  /// The catalogue id.
  static const String id = LumeTasbihStore.tool;

  static const Key phrasesKey = ValueKey<String>('tasbih.phrases');
  static const Key phraseKey = ValueKey<String>('tasbih.phrase');
  static const Key counterKey = ValueKey<String>('tasbih.counter');
  static const Key ringKey = ValueKey<String>('tasbih.ring');
  static const Key countKey = ValueKey<String>('tasbih.count');
  static const Key roundsKey = ValueKey<String>('tasbih.rounds');
  static const Key resetKey = ValueKey<String>('tasbih.reset');
  static const Key notKeptKey = ValueKey<String>('tasbih.notkept');
  static const Key confirmKey = ValueKey<String>('tasbih.confirm');

  /// `.tasbih__counter { width: 224px; height: 224px }`.
  static const double face = 224;

  /// The ring is drawn on a 200-unit view box inside that face, at `r="88"`
  /// and `stroke-width="8"` (`tasbih.tool.js:29-34`).
  static const double _ringScale = face / 200;
  static const double ringRadius = 88 * _ringScale;
  static const double ringStroke = 8 * _ringScale;

  /// [LumeProgressRing] derives its radius from its box as `30 / 72`, so this
  /// is the box that puts the arc on [ringRadius].
  static const double ringBox = ringRadius * 72 / 30;

  /// `.tasbih__target { bottom: 62px }`.
  static const double targetInset = 62;

  /// How long the counter waits, after the last tap, before it announces
  /// where it has got to.
  ///
  /// A live region that follows every tap turns a round of 33 into 33
  /// interruptions, and a screen-reader user counting at speed hears a queue
  /// of stale numbers rather than the number they are on. The value settles
  /// once the taps stop; finishing a round, resetting, changing phrase and
  /// reaching the ceiling are said at once, because each is an event rather
  /// than a running total.
  static const Duration announceAfter = Duration(milliseconds: 700);

  @override
  ConsumerState<LumeTasbihTool> createState() => _LumeTasbihToolState();
}

class _LumeTasbihToolState extends ConsumerState<LumeTasbihTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();

  late final LumeTasbihStore _store = LumeTasbihStore(
    ref.read(toolSessionProvider),
  );

  late LumeTasbihCount _count = _store.read();

  /// What the tap target last announced, which trails [_count] by at most
  /// [LumeTasbihTool.announceAfter].
  late LumeTasbihCount _spoken = _count;

  Timer? _voice;

  @override
  void dispose() {
    _voice?.cancel();
    super.dispose();
  }

  /// Say where the counter has got to, once the taps stop.
  void _speakSoon() {
    _voice?.cancel();
    _voice = Timer(LumeTasbihTool.announceAfter, () {
      if (mounted) setState(() => _spoken = _count);
    });
  }

  /// Say it now — for something that happened, rather than a running total.
  void _speakNow() {
    _voice?.cancel();
    _spoken = _count;
  }

  void _put(LumeTasbihCount next) {
    _count = next;
    _store.write(next);
  }

  /// `navigator.vibrate(…)` — optional, and never a condition of counting.
  ///
  /// A device with no vibrator, a platform that has not registered the
  /// channel, and a test with no plugins all end up here; the count has
  /// already been made by the time this is called, and none of them can
  /// unmake it.
  Future<void> _feel({required bool finished}) async {
    try {
      if (finished) {
        await HapticFeedback.vibrate();
      } else {
        await HapticFeedback.selectionClick();
      }
    } on MissingPluginException {
      // No haptics in this build. Counting is unaffected.
    } on PlatformException {
      // No vibrator, or the platform refused. Counting is unaffected.
    }
  }

  void _tap() {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeTasbihTap tapped = _count.tap();
    if (tapped.refused) {
      _host.currentState?.say(l.tasbihMax, tone: LumeToastTone.info);
      return;
    }
    setState(() {
      _put(tapped.count);
      if (tapped.finishedRound) _speakNow();
    });
    if (tapped.finishedRound) {
      _host.currentState?.say(l.tasbihComplete);
    } else {
      _speakSoon();
    }
    unawaited(_feel(finished: tapped.finishedRound));
  }

  Future<void> _reset() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool yes = await _ask(
      title: l.tasbihResetAsk,
      text: l.tasbihResetText,
      confirm: l.tasbihResetGo,
    );
    if (!yes || !mounted) return;
    setState(() {
      _put(_count.reset());
      _speakNow();
    });
  }

  Future<void> _choose(int phrase) async {
    if (phrase == _count.phrase) return;
    final AppLocalizations l = AppLocalizations.of(context);
    // Only a part-finished round is at stake. Asking when there is nothing to
    // lose is a dialog for its own sake.
    if (_count.count > 0) {
      final bool yes = await _ask(
        title: l.tasbihSwitchAsk,
        text: l.tasbihSwitchText,
        confirm: l.tasbihSwitchGo,
      );
      if (!yes || !mounted) return;
    }
    setState(() {
      _put(_count.switchTo(phrase));
      _speakNow();
    });
  }

  Future<bool> _ask({
    required String title,
    required String text,
    required String confirm,
  }) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool? answer = await showLumeSheet<bool>(
      context: context,
      barrierLabel: title,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          confirm: true,
          child: LumeDeleteConfirmation(
            key: LumeTasbihTool.confirmKey,
            title: title,
            consequence: text,
            confirmLabel: confirm,
            cancelLabel: l.tasbihKeepCount,
            onConfirm: () => Navigator.of(sheet).pop(true),
            onCancel: () => Navigator.of(sheet).pop(false),
          ),
        ),
      ),
    );
    return answer ?? false;
  }

  /// The parts `tools/shared.css:1148-1176` names, at text scale 1: the
  /// block's 6 of top padding, the picker on `.fchip`'s 31 and its 2 of
  /// bottom padding, three 16-point gaps, the Arabic's 28 × 1.6, the gloss's
  /// 12-point line 8 under it, the 224-point face and the 46-point actions.
  ///
  /// Lume draws the picker at its 44-point target rather than at the 31 the
  /// stylesheet gives, so the strip is 13 taller than this on screen and the
  /// 13 comes back out of the gap under it.
  static const double _named =
      6 +
      (LumeFilterChip.height + 2) +
      16 +
      44.8 +
      8 +
      15 +
      16 +
      LumeTasbihTool.face +
      16 +
      LumeButton.height;

  /// What the capture measures the whole block at, at 390.
  static const double _measured = 434.8;

  /// The difference between the two, carried where it can be seen. No rule in
  /// `shared.css` accounts for it; the measurement does, and the sections
  /// below the block depend on it.
  static const double _unattributed = _measured - _named;

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final double gutter = LumeLayout.pageGutter(context.measureClass);
    final LumeTasbihPhrase phrase = _count.spoken;

    String reading(LumeTasbihCount c) =>
        l.tasbihOf(f.integer(c.count), f.integer(c.target));

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _picker(l, lume),
                // The 16 the stylesheet gives, less the points the chips'
                // 44-point targets already reach into it above and below
                // (D6/D35, as `LumeFilterBar` takes them back): the targets
                // overhang the gap rather than growing the page.
                const SizedBox(height: 16 - 2 * LumeFilterBar.overhang),
                _phrase(l, lume, phrase),
                const SizedBox(height: 16),
                _face(l, lume, f, reading(_count), reading(_spoken)),
                const SizedBox(height: 16 + _unattributed),
                _actions(l, f),
              ],
            ),
          ),
          LumeToolSection(
            key: LumeTasbihTool.notKeptKey,
            child: LumeNoteCard(icon: LumeIcons.beads, title: l.tasbihNotKept),
          ),
        ],
      ),
    );
  }

  /// `.tasbih__pick` — the five phrases, one row, scrolling sideways.
  Widget _picker(AppLocalizations l, LumeColors lume) => Semantics(
    container: true,
    label: l.tasbihPickTitle,
    child: SingleChildScrollView(
      key: LumeTasbihTool.phrasesKey,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < LumeTasbihPhrases.all.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 6),
            LumeFilterChip(
              label: LumeTasbihPhrases.all[i].transliteration,
              selected: i == _count.phrase,
              onTap: () => _choose(i),
            ),
          ],
        ],
      ),
    ),
  );

  /// `.tasbih__ar` and `.tasbih__tr` — the words, and what they mean.
  Widget _phrase(
    AppLocalizations l,
    LumeColors lume,
    LumeTasbihPhrase phrase,
  ) => Semantics(
    container: true,
    label: l.tasbihPhrase,
    child: Column(
      key: LumeTasbihTool.phraseKey,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Arabic script, in its own direction whatever the interface's is,
        // on the reference's own line for this one line of it — the 1.8
        // reading line belongs to passages (`LumeType.arabic`), and
        // `lume_explore.dart` sets the reference's line the same way.
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            phrase.arabic,
            textAlign: TextAlign.center,
            locale: const Locale('ar'),
            style: LumeType.arabic(
              size: 28,
            ).copyWith(color: lume.text, height: 1.6),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          label: l.tasbihMeaning,
          value: phrase.meaning,
          child: ExcludeSemantics(
            child: Text(
              phrase.meaning,
              textAlign: TextAlign.center,
              style: LumeType.natural(
                context,
                context.lumeType.meta,
              ).copyWith(color: lume.text3, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    ),
  );

  /// `.tasbih__counter` — the face, the ring, the figure and the tap target.
  Widget _face(
    AppLocalizations l,
    LumeColors lume,
    LumeFormatting f,
    String now,
    String announced,
  ) => SizedBox.square(
    dimension: LumeTasbihTool.face,
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // `radial-gradient(circle at 50% 40%, var(--card), var(--card-2))`.
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              colors: <Color>[lume.card, lume.card2],
            ),
            border: Border.all(color: lume.border, width: LumeSpace.border),
            boxShadow: context.lumeShadows.md,
          ),
          child: const SizedBox.expand(),
        ),
        // The ring reports itself as a progress bar, which is the whole
        // reason it is the shared component and not two `<circle>`s.
        OverflowBox(
          maxWidth: LumeTasbihTool.ringBox,
          maxHeight: LumeTasbihTool.ringBox,
          child: LumeProgressRing(
            key: LumeTasbihTool.ringKey,
            value: _count.progress,
            size: LumeTasbihTool.ringBox,
            stroke: LumeTasbihTool.ringStroke,
            label: l.tasbihCounter,
            valueText: now,
          ),
        ),
        // `.tasbih__num` — 58 / 800 / −.06em, tabular, and left to right even
        // in an RTL interface (`shared.css:647`). The ring's value says the
        // same thing to a screen reader, so the figure itself is not read.
        ExcludeSemantics(
          child: LumeNumerals(
            f.integer(_count.count),
            key: LumeTasbihTool.countKey,
            style: LumeType.numeric(
              LumeType.tracked(
                LumeType.natural(
                  context,
                  context.lumeType.display,
                  size: 58,
                ).copyWith(fontWeight: FontWeight.w800),
                -0.06,
              ),
            ).copyWith(color: lume.text),
          ),
        ),
        // `.tasbih__target` — the conventional number in this round, stated
        // as a fact about the round.
        Positioned(
          bottom: LumeTasbihTool.targetInset,
          child: Text(
            l.tasbihTargetLabel(f.integer(_count.target)),
            style: LumeType.natural(
              context,
              context.lumeType.metaSmall,
              size: 11,
            ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
          ),
        ),
        // The whole face is the target: pointer, Enter, Space and an
        // assistive activation all reach the same handler.
        Positioned.fill(
          child: Semantics(
            key: LumeTasbihTool.counterKey,
            button: true,
            label: l.tasbihTap,
            value: announced,
            liveRegion: true,
            child: LumePressable(
              onTap: _tap,
              borderRadius: LumeRadius.full,
              minSize: 0,
              excludeSemantics: true,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    ),
  );

  /// `.tasbih__acts` — Reset, and the rounds.
  ///
  /// A [Wrap] rather than a row: side by side at the reference's own text
  /// size, and stacked once a translation or a large-text setting makes them
  /// wider than the page. Four digits of rounds at 200 % is enough to do it.
  Widget _actions(AppLocalizations l, LumeFormatting f) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      LumeButton(
        key: LumeTasbihTool.resetKey,
        label: l.tasbihReset,
        icon: LumeIcons.refresh,
        onPressed: _count.isEmpty ? null : _reset,
      ),
      _RoundsReadout(
        key: LumeTasbihTool.roundsKey,
        label: l.tasbihSets(_count.rounds),
      ),
    ],
  );
}

/// The rounds, as a figure rather than as a button that does nothing.
///
/// `tasbih.tool.js:41` gives this `UI.button` with no `act`. It keeps the
/// button's measured shape — 46 tall, `0 20` inside `--r-sm` on the neutral
/// tint, its glyph 17 and 7 from the words — and none of its behaviour: it
/// does not take focus, it does not press, and a screen reader reads it as
/// the text it is.
class _RoundsReadout extends StatelessWidget {
  const _RoundsReadout({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Container(
      constraints: const BoxConstraints(minHeight: LumeButton.height),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: lume.tintNeutral,
        borderRadius: LumeRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LumeIcon(LumeIcons.beads, size: 17, color: lume.text),
          const SizedBox(width: 7),
          LumeNumerals(
            label,
            style: LumeType.tracked(
              LumeType.fit(
                context,
                context.lumeType.label,
              ).copyWith(fontWeight: FontWeight.w700),
              -0.022,
            ).copyWith(color: lume.text),
          ),
        ],
      ),
    );
  }
}
