/// 99 Names — the reference gallery for a starting set of the Names of Allah.
///
/// `tools/islamic/names99.tool.js`: the count against the traditional 99, a
/// search, and the grid of names — each a tap that names the transliteration
/// and the meaning, and nothing else. Faith-gated in the catalogue, so a
/// reader who has not turned the Islamic experience on never reaches it (the
/// gate, not this screen, decides), and the shared tool frame refuses the
/// body a second time regardless of how the screen was reached (§64).
///
/// **Twelve of ninety-nine.** `LumeNames99Fixtures` holds twelve names, not
/// the full ninety-nine the tool is named for — see its own doc comment for
/// why. The count is drawn exactly where the reference already draws it
/// (`UI.summaryCard`'s "12 / 99"), so nothing here hides behind a full-looking
/// list that simply stops; the caption goes one step further than the
/// reference and says what the remaining names need.
///
/// ## Corrections to the reference
///
/// 1. **Practise is dropped.** `names99.tool.js:40` draws a button labelled
///    Practise whose only effect is a toast reading "Starting a practice
///    round" (`i18n/tools.js:401`) — nothing starts, because no practice mode
///    exists in this build. It is left out rather than kept as a control that
///    announces an action it does not take, the same reasoning Tasbih's
///    dropped "Recent sessions" and re-drawn rounds read-out follow.
/// 2. **Share hands over the name being read.** The reference's own Share
///    button (`act: 'share:names99'`) shares the tool as a whole, with
///    nothing typed for a card to carry. Tapping a name is treated as reading
///    it — the same relationship Hadith has between its day's passage and its
///    Share button (C77) — so the toolbar's Share, and the toast's own Share
///    action, both hand over whichever name was tapped last, defaulting to
///    the first while none has been.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_numerals.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../hadith/domain/religious_content.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/names99_fixtures.dart';
import '../domain/names99_model.dart';
import 'names99_text.dart';

class LumeNames99Tool extends ConsumerStatefulWidget {
  const LumeNames99Tool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeNames99Tool(request: request);

  static const String id = 'names99';

  static const Key summaryKey = ValueKey<String>('names99.summary');
  static const Key searchKey = ValueKey<String>('names99.search');
  static const Key gridKey = ValueKey<String>('names99.grid');
  static const Key emptyKey = ValueKey<String>('names99.empty');

  @override
  ConsumerState<LumeNames99Tool> createState() => _LumeNames99ToolState();
}

class _LumeNames99ToolState extends ConsumerState<LumeNames99Tool> {
  static const String _id = LumeNames99Tool.id;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(_id, 'q') ?? '',
  );

  /// The name Share hands over — the one last tapped, or the first while
  /// none has been (see the library note, correction 2).
  int _selected = 0;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(AppLocalizations l, LumeName n) {
    setState(() => _selected = n.number - 1);
    _host.currentState?.say(
      Names99Text.opened(l, n),
      actionLabel: l.commonShare,
      onAction: () => _host.currentState?.share(),
      tone: LumeToastTone.info,
    );
  }

  LumeShareCard? _shareCard(AppLocalizations l) {
    final LumeName n = LumeNames99Fixtures.all[_selected];
    return LumeShareCard.forFeature(
      sensitive: widget.request.feature.sensitive,
      kind: LumeShareKind.quote,
      text: n.meaning.text,
      source: Names99Text.shareSource(l, n),
      arabic: n.arabic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final double gutter = LumeLayout.pageGutter(context.measureClass);

    final int held = LumeNames99Fixtures.held;
    const int total = LumeNames99Fixtures.total;
    final int pct = total == 0 ? 0 : (100 * held / total).round();

    // The reference's own meaning is the only one this build holds, in every
    // interface language (C82) — said once here rather than on every card.
    final LumeContentLanguage lang = LumeContentLanguage(
      Localizations.localeOf(context).languageCode,
    );
    final bool fallbackEnglish =
        LumeNames99Fixtures.all.isNotEmpty &&
        LumeNames99Fixtures.all.first.resolve(lang).isFallback;

    final List<LumeName> shown = LumeNames99Fixtures.shown(query: _query.text);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      shareCard: () => _shareCard(l),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeNames99Tool.summaryKey,
              kicker: l.names99Kicker,
              value: f.integer(held),
              valueSmall: Names99Text.ofTotal(l, f, total),
              caption: Names99Text.caption(l, f, held, total),
              aside: LumeProgressRing(
                value: total == 0 ? 0 : held / total,
                centreValue: '$pct%',
                label: l.names99Progress,
                valueText: Names99Text.reading(l, f, held, total),
              ),
            ),
          ),
          if (fallbackEnglish)
            LumeToolSection(
              tight: true,
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: gutter),
                child: Text(
                  l.readerFallbackEnglish,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: context.lume.text3),
                ),
              ),
            ),
          LumeToolSection(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: LumeSearchField(
                key: LumeNames99Tool.searchKey,
                controller: _query,
                placeholder: l.names99Search,
                onChanged: (String q) =>
                    setState(() => _session.write(_id, 'q', q)),
              ),
            ),
          ),
          LumeToolSection(
            title: l.names99AllTitle,
            child: shown.isEmpty
                ? LumeToolState(
                    key: LumeNames99Tool.emptyKey,
                    icon: LumeIcons.search,
                    title: l.names99NoMatch,
                    text: l.names99NoMatchText,
                    action: LumeButton(
                      label: l.actionClear,
                      icon: LumeIcons.refresh,
                      onPressed: () {
                        _query.clear();
                        setState(() => _session.write(_id, 'q', ''));
                      },
                    ),
                  )
                : _grid(context, l, f, shown),
          ),
        ],
      ),
    );
  }

  /// `.ngrid` — two columns, four on a wide surface (`.app--wide .ngrid`).
  Widget _grid(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    List<LumeName> names,
  ) {
    final int cols = context.isWideSurface ? 4 : 2;
    return LayoutBuilder(
      key: LumeNames99Tool.gridKey,
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 10;
        final double width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final LumeName n in names)
              SizedBox(
                width: width > 0 ? width : null,
                child: _NameCard(
                  key: ValueKey<int>(n.number),
                  name: n,
                  number: f.integer(n.number),
                  onTap: () => _open(l, n),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// `.ncard` — the number in the traditional list of 99, the Arabic, the
/// transliteration and the meaning.
class _NameCard extends StatelessWidget {
  const _NameCard({
    super.key,
    required this.name,
    required this.number,
    required this.onTap,
  });

  final LumeName name;
  final String number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      button: true,
      label: name.transliteration,
      value: name.meaning.text,
      child: LumePressable(
        onTap: onTap,
        borderRadius: LumeRadius.brSm,
        minSize: 0,
        excludeSemantics: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 13),
          decoration: BoxDecoration(
            color: lume.card,
            border: Border.all(color: lume.border, width: LumeSpace.border),
            borderRadius: LumeRadius.brSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // `.ncard__n` — the accent number, excluded from semantics: the
              // card's label and value already say everything it stands for.
              ExcludeSemantics(
                child: LumeNumerals(
                  number,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                    size: 10,
                  ).copyWith(color: lume.accent, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 5),
              // `.ncard__ar` — Arabic script, in its own direction whatever
              // the interface's is.
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  name.arabic,
                  locale: const Locale('ar'),
                  style: LumeType.arabic(
                    size: 20,
                  ).copyWith(color: lume.text, height: 1.5),
                ),
              ),
              const SizedBox(height: 7),
              // `.ncard__tl`.
              Text(
                name.transliteration,
                style: LumeType.tracked(
                  LumeType.natural(
                    context,
                    context.lumeType.body,
                    size: 12,
                  ).copyWith(fontWeight: FontWeight.w700),
                  -0.024,
                ).copyWith(color: lume.text),
              ),
              const SizedBox(height: 3),
              // `.ncard__meaning`.
              Text(
                name.meaning.text,
                style:
                    LumeType.natural(
                      context,
                      context.lumeType.metaSmall,
                      size: 10,
                    ).copyWith(
                      color: lume.text3,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
