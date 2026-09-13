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
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/personalisation.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/theme_provider.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/routing/lume_routes.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
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
    return LumeFixtureSearchRepository(
      eligibility: ref.read(eligibilityProvider),
      l: l,
      user: LumeUserContext.from(profile),
      recents: profile.recents,
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
    final AppLocalizations l = AppLocalizations.of(context);

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
    // Nothing reaches here that the reference does not do; `l` is read so a
    // future verb can report itself without re-plumbing the localisations.
    assert(l.searchEverything.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;
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
            padding: const EdgeInsets.only(bottom: 10),
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
                : _resultList(results, lume),
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
          _groupLabel(l.searchTry, top: 4),
          // `.chips--wrap { flex-wrap: wrap }` — the idle chips wrap rather
          // than scrolling sideways, because there are at most six and a
          // hidden one is a suggestion nobody takes.
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              for (final String word in idle.suggestions)
                LumeFilterChip(label: word, onTap: () => _suggest(word)),
            ],
          ),
          _groupLabel(l.searchJumpBack, top: 20),
          LumeRows(
            flat: true,
            children: <Widget>[
              for (final LumeSearchHit hit in idle.recent)
                LumeRichRow(
                  icon: hit.icon,
                  title: hit.title,
                  subtitle: hit.subtitle.isEmpty ? null : hit.subtitle,
                  chevron: true,
                  onTap: () => _activate(hit),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultList(LumeSearchResults results, LumeColors lume) =>
      SingleChildScrollView(
        key: LumeSearchSheet.resultsKey,
        child: Semantics(
          // A screen reader is told how many there are before it starts
          // reading them out.
          label: AppLocalizations.of(
            context,
          ).toolsResultCount(results.hits.length),
          container: true,
          child: LumeRows(
            flat: true,
            children: <Widget>[
              for (final LumeSearchHit hit in results.hits)
                LumeRichRow(
                  icon: hit.icon,
                  title: hit.title,
                  subtitle: hit.subtitle.isEmpty ? null : hit.subtitle,
                  // `#i-arrow-ur` — a result leaves for somewhere, which is a
                  // different promise from a row that drills in.
                  trailing: LumeIcon(
                    LumeIcons.arrowUr,
                    size: LumeSpace.iconSm,
                    color: lume.text3,
                  ),
                  onTap: () => _activate(hit),
                ),
            ],
          ),
        ),
      );

  Widget _nothingFound(AppLocalizations l) => SingleChildScrollView(
    child: LumeToolState(
      icon: LumeIcons.search,
      title: l.searchNothing,
      text: l.searchNothingSub,
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
