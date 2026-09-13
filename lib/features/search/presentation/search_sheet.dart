/// Global search — a sheet over whichever destination raised it.
///
/// It is not a screen. The reference opens `#sheet-search` from Home's app
/// bar and Explore's page head, and the destination behind it stays where it
/// was; `/<branch>/search` is an address for that sheet rather than a screen
/// of its own, so a deep link lands on the branch with the sheet up (Q10).
///
/// Three things it has to get right, all about what a search may not do.
///
/// **It cannot find what the reader cannot reach.** The index is built from
/// `visibleFeatures`, so a faith-gated or country-gated tool is *absent* from
/// it rather than filtered out of the results — there is no list to leak from
/// (§64).
///
/// **It leaves the branch it was opened from.** Choosing a tool opens it on
/// that branch, so Back returns to the destination the reader was on, not to
/// Home.
///
/// **It has no loading, error or offline state**, because the reference has
/// none: the index is local and synchronous. The repository contract can fail
/// so Dayroz can answer over a network, and nothing draws a state this build
/// cannot reach (Q11).
///
/// Geometry, measured against the running reference with
/// `measure_destinations.mjs --after search_*`: the field sits in a 68-point
/// head (14 above, 10 below); the chips are `.chip`, inset 20 inside the body;
/// recents and results are `.list.list--flat` — a shadowless card of 61-point
/// `.list-row`s; nothing found is `.empty` with its own drawing.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/personalisation.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/theme_provider.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/routing/lume_routes.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_settings.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../startup/application/startup_controller.dart';
import '../data/search_index.dart';
import '../domain/search_model.dart';

/// Raise global search over [branch].
///
/// Returns once the sheet is gone. The caller does not need the result: a hit
/// navigates for itself, because the destination it opens belongs to the
/// branch rather than to the sheet.
Future<void> showLumeSearch(BuildContext context, {required String branch}) =>
    showLumeSheet<void>(
      context: context,
      barrierLabel: AppLocalizations.of(context).searchEverything,
      child: LumeSearchSheet(branch: branch),
    );

/// The sheet's body: a field, then either the idle blocks or the results.
class LumeSearchSheet extends ConsumerStatefulWidget {
  const LumeSearchSheet({super.key, required this.branch});

  /// Which branch a chosen tool opens on, so Back returns here.
  final String branch;

  /// The field, for a test that wants to type into it.
  static const Key fieldKey = ValueKey<String>('search.field');

  /// The idle block — chips and recents — shown while the field is empty.
  static const Key idleKey = ValueKey<String>('search.idle');

  /// The result list.
  static const Key resultsKey = ValueKey<String>('search.results');

  /// Nothing found.
  static const Key emptyKey = ValueKey<String>('search.empty');

  /// `.sheet__head { padding: 14px 18px 10px }`. The body already pads the
  /// sides, so only the vertical halves are added here.
  static const double headTop = 14;
  static const double headBottom = 10;

  /// `.chips { padding: 0 var(--pad) 2px; gap: 7px }` — the suggestion chips
  /// are inset twenty points inside the body, not flush with the field.
  static const double chipInset = 20;
  static const double chipGap = 7;

  @override
  ConsumerState<LumeSearchSheet> createState() => _LumeSearchSheetState();
}

class _LumeSearchSheetState extends ConsumerState<LumeSearchSheet> {
  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();

  LumeSearchIdle? _idle;
  LumeSearchResults? _results;

  /// Which query the shown results answer. A late answer to a superseded
  /// question is dropped — the fixture is synchronous, but the contract is
  /// not, and a remote index would make this the difference between the
  /// right list and yesterday's.
  int _request = 0;

  /// The reference focuses the field 320 ms after the sheet opens, once it
  /// has finished rising: focusing during the transition fights the animation
  /// and, on a phone, raises the keyboard into a moving sheet.
  ///
  /// Held so it can be cancelled. A sheet dismissed inside those 320 ms would
  /// otherwise leave a timer running against a disposed tree.
  static const Duration focusDelay = Duration(milliseconds: 320);
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    _field.addListener(_onTyped);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadIdle());
      _focusTimer = Timer(focusDelay, () {
        if (mounted) _focus.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _field
      ..removeListener(_onTyped)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  LumeFixtureSearchRepository _repository() {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeStartupController gate = ref.read(startupControllerProvider);
    final LumeProfileRecord profile = gate.state.profile;
    final LumeUserContext user = LumeUserContext.from(profile);
    return LumeFixtureSearchRepository(
      eligibility: ref.read(eligibilityProvider),
      l: l,
      user: user,
      recents: profile.recents,
      // The same live status lines Home's tiles and the hub read, so a recent
      // says "34° Hazy sun" where its tile does.
      live: ref
          .read(homeDataRepositoryProvider)
          .statusesFor(user, now: LumeClockScope.of(context).now()),
      formatting: LumeFormatting.of(context, countryCode: user.country),
    );
  }

  Future<void> _loadIdle() async {
    final LumeSearchIdle idle = await _repository().idle();
    if (mounted) setState(() => _idle = idle);
  }

  void _onTyped() {
    // No debounce: the reference runs on every `input` event, because the
    // index is in memory and a delay would only make it feel slower.
    unawaited(_run(_field.text));
  }

  Future<void> _run(String query) async {
    final int request = ++_request;
    if (query.trim().isEmpty) {
      if (mounted) setState(() => _results = null);
      return;
    }
    final LumeSearchResults r = await _repository().search(query);
    if (!mounted || request != _request) return;
    setState(() => _results = r);
  }

  void _suggest(String word) {
    _field
      ..text = word
      ..selection = TextSelection.collapsed(offset: word.length);
  }

  /// What a hit does. The sheet closes first, so the reader is not left
  /// looking at a search field over the screen they just asked for.
  void _activate(LumeSearchHit hit) {
    final NavigatorState nav = Navigator.of(context);
    final GoRouter router = GoRouter.of(context);

    switch (hit.action) {
      case LumeSearchAction.tool:
        ref.read(recentToolsProvider).note(hit.target);
        nav.pop();
        router.go(LumeRoutes.tool(widget.branch, hit.target));
      case LumeSearchAction.destination:
        nav.pop();
        router.go('/${hit.target}');
      case LumeSearchAction.sheet:
        nav.pop();
        unawaited(showLumePersonalise(context));
      case LumeSearchAction.theme:
        final StateController<ThemeMode> mode = ref.read(
          themeModeProvider.notifier,
        );
        mode.state = mode.state == ThemeMode.dark
            ? ThemeMode.light
            : ThemeMode.dark;
        nav.pop();
      case LumeSearchAction.say:
        nav.pop();
        showLumeToast(context, LumeToastData(message: hit.target));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeSearchResults? results = _results;

    return LumeSheet(
      tall: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // `.sheet__head` holds the field alone: search has no title,
          // because the field says what the sheet is.
          Padding(
            padding: const EdgeInsets.only(
              top: LumeSearchSheet.headTop,
              bottom: LumeSearchSheet.headBottom,
            ),
            child: LumeSearchField(
              key: LumeSearchSheet.fieldKey,
              controller: _field,
              focusNode: _focus,
              placeholder: l.searchPlaceholder,
              semanticLabel: l.searchEverything,
              onSubmitted: (String q) => unawaited(_run(q)),
            ),
          ),
          Flexible(
            child: results == null
                ? _idleView(l)
                : results.isEmpty
                ? _nothingFound(l)
                : _resultList(l, results),
          ),
        ],
      ),
    );
  }

  Widget _idleView(AppLocalizations l) {
    final LumeSearchIdle? idle = _idle;
    if (idle == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      key: LumeSearchSheet.idleKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // `style="margin:4px 0 9px"`.
          _groupLabel(l.searchTry, top: 4),
          // `.chips.chips--wrap` — they wrap rather than scroll sideways,
          // because there are at most six and a hidden one is a suggestion
          // nobody takes.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LumeSearchSheet.chipInset,
              0,
              LumeSearchSheet.chipInset,
              2,
            ),
            child: Wrap(
              spacing: LumeSearchSheet.chipGap,
              runSpacing: LumeSearchSheet.chipGap,
              children: <Widget>[
                for (final String word in idle.suggestions)
                  LumeChoiceChip(
                    label: word,
                    selected: false,
                    onTap: () => _suggest(word),
                  ),
              ],
            ),
          ),
          // `style="margin:20px 0 9px"`.
          _groupLabel(l.searchJumpBack, top: 20),
          _list(<Widget>[
            for (int i = 0; i < idle.recent.length; i++)
              LumeSettingsRow(
                icon: idle.recent[i].icon,
                title: idle.recent[i].title,
                subtitle: idle.recent[i].subtitle.isEmpty
                    ? null
                    : idle.recent[i].subtitle,
                onTap: () => _activate(idle.recent[i]),
                isLast: i == idle.recent.length - 1,
              ),
          ]),
        ],
      ),
    );
  }

  Widget _resultList(AppLocalizations l, LumeSearchResults results) =>
      SingleChildScrollView(
        key: LumeSearchSheet.resultsKey,
        child: Semantics(
          // A screen reader is told how many there are before it starts
          // reading them out.
          label: l.toolsResultCount(results.hits.length),
          container: true,
          child: _list(<Widget>[
            for (int i = 0; i < results.hits.length; i++)
              LumeSettingsRow(
                icon: results.hits[i].icon,
                title: results.hits[i].title,
                subtitle: results.hits[i].subtitle.isEmpty
                    ? null
                    : results.hits[i].subtitle,
                // `#i-arrow-ur` — a result leaves for somewhere, which is a
                // different promise from a row that drills in.
                trailingIcon: LumeIcons.arrowUr,
                onTap: () => _activate(results.hits[i]),
                isLast: i == results.hits.length - 1,
              ),
          ]),
        ),
      );

  /// `.list.list--flat` — the card without its shadow, because the sheet it
  /// sits in already casts one.
  Widget _list(List<Widget> rows) => LumeCard(
    padded: false,
    shadow: false,
    child: Column(mainAxisSize: MainAxisSize.min, children: rows),
  );

  Widget _nothingFound(AppLocalizations l) => SingleChildScrollView(
    child: LumeEmptyState(
      key: LumeSearchSheet.emptyKey,
      title: l.searchNothing,
      text: l.searchNothingSub,
      art: const _SearchEmptyArt(),
    ),
  );

  Widget _groupLabel(String text, {required double top}) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 9),
    child: Text(
      LumeType.overline(context, text),
      style: LumeType.tracked(
        LumeType.natural(context, context.lumeType.metaSmall, size: 11),
        0.07,
      ).copyWith(color: context.lume.text3, fontWeight: FontWeight.w700),
    ),
  );
}

/// The drawing over "Nothing found", from `#sheet-search`'s own `.empty`.
///
/// `<circle cx="44" cy="30" r="22" stroke="var(--border-2)" stroke-width="2"
/// stroke-dasharray="5 7"/>`, `<path d="m58 44 12 12" stroke-width="2.4"
/// stroke-linecap="round"/>` and `<circle cx="20" cy="14" r="3"
/// fill="var(--accent)" opacity=".4"/>` — a dashed lens with nothing in it.
class _SearchEmptyArt extends StatelessWidget {
  const _SearchEmptyArt();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return CustomPaint(
      size: const Size(88, 66),
      painter: _SearchEmptyPainter(ring: lume.border2, dot: lume.accent),
    );
  }
}

class _SearchEmptyPainter extends CustomPainter {
  const _SearchEmptyPainter({required this.ring, required this.dot});

  final Color ring;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint lens = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const Offset centre = Offset(44, 30);
    const double r = 22;
    // `stroke-dasharray="5 7"`, walked round the circle as arcs.
    const double dash = 5 / r;
    const double gap = 7 / r;
    final Rect box = Rect.fromCircle(center: centre, radius: r);
    for (double a = 0; a < 2 * math.pi; a += dash + gap) {
      canvas.drawArc(box, a, math.min(dash, 2 * math.pi - a), false, lens);
    }

    canvas.drawLine(
      const Offset(58, 44),
      const Offset(70, 56),
      Paint()
        ..color = ring
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      const Offset(20, 14),
      3,
      Paint()..color = dot.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(_SearchEmptyPainter old) =>
      old.ring != ring || old.dot != dot;
}
