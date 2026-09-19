/// The host every converted tool is drawn through.
///
/// `engine.js` `build()` in Flutter: given a feature and a body, it supplies
/// everything the reference supplies around a module — the title, the sub-line,
/// the header actions the spec declares, the source card, the privacy note for
/// a sensitive tool, and the related tools the reader may actually open. A tool
/// hands over its sections and nothing else, so no tool can draw its own frame
/// differently from the other 84.
///
/// It also owns the one voice the frame speaks with — the toast — because the
/// header's own actions ("Added Learning & Growth to favourites") speak before
/// any tool does.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/personalisation.dart';
import '../../../app/providers/platform_services.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../core/config/lume_build_profile.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../share/presentation/share_sheet.dart';
import '../../startup/application/startup_controller.dart';
import '../domain/tool_capability.dart';
import 'source_claims.dart';
import 'tool_strings.dart';

/// What the header's actions do for one tool, where the tool does more than
/// the frame's default.
///
/// The frame's defaults: **favourite** toggles the feature in the reader's
/// saved favourites and says so, as `toggleFavourite` does; **search** focuses
/// the tool's own search field, and a tool without one has nothing to focus —
/// the reference does nothing there either. Share and export are the tool's to
/// supply (D7).
@immutable
class LumeToolActions {
  const LumeToolActions({
    this.onShare,
    this.onExport,
    this.onFavourite,
    this.onSearch,
  });

  final VoidCallback? onShare;
  final VoidCallback? onExport;
  final VoidCallback? onFavourite;
  final VoidCallback? onSearch;
}

/// A converted tool, in the shared frame.
class LumeToolScreen extends ConsumerStatefulWidget {
  const LumeToolScreen({
    super.key,
    required this.feature,
    required this.user,
    required this.body,
    this.onBack,
    this.onOpenRelated,
    this.actions = const LumeToolActions(),
    this.status = LumeToolStatus.ready,
    this.onRetry,
    this.subtitle,
    this.shareCard,
    this.exportFile,
    this.floating,
    this.title,
    this.leadingAction,
    this.headerActions,
    this.bare = false,
  });

  final LumeFeature feature;
  final LumeUserContext user;

  /// The tool's sections, top to bottom.
  final Widget body;

  final VoidCallback? onBack;
  final ValueChanged<String>? onOpenRelated;
  final LumeToolActions actions;
  final LumeToolStatus status;
  final VoidCallback? onRetry;

  /// `c.headerSub` — a tool's own sub-line, where it has one.
  final String? subtitle;

  /// D7 — the card this tool shares, as the screen stands at the moment of
  /// the press. `null` (the function, or its answer) when there is nothing
  /// honest to share: the tool bar's Share is then disabled, not inert.
  final LumeShareCard? Function()? shareCard;

  /// D7 — the file this tool exports, as the screen stands at the moment of
  /// the press. Throws [ArgumentError] only on a tool's own bug, which the
  /// reader is told as a failure.
  final LumeExportFile? Function()? exportFile;

  /// `.fab` -- a floating action, 22 from the end and 96 from the bottom,
  /// under the toast as the reference stacks them.
  final Widget? floating;

  /// A record operation's own title — "Expense details", "Add expense". `null`
  /// is the tool's name.
  final String? title;

  /// `recordActions(c)` — a record tool's Add, in words, ahead of the header's
  /// own actions, within the same cap of three.
  final Widget? leadingAction;

  /// A record operation's header actions — Edit on a detail, Save on a form —
  /// in place of the tool's.
  final List<Widget>? headerActions;

  /// `LUME_CRUD.screen(c)` — a detail or a form owns the screen, so it has no
  /// source card, privacy note or related rail of its own.
  final bool bare;

  /// `toast()` — 2.1 seconds, or 6 with an action.
  static const Duration toastFor = Duration(milliseconds: 2100);
  static const Duration toastWithActionFor = Duration(seconds: 6);

  /// The reader's country, named in their language from the table the launch
  /// read — the ISO code where there is no table, which is true, rather than a
  /// guess.
  static String countryName(
    BuildContext context,
    WidgetRef ref,
    String country,
  ) {
    final String language = Localizations.localeOf(context).languageCode;
    return ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.nameOf(country, language) ??
        country;
  }

  /// The nearest host, so a tool can speak through the same toast.
  static LumeToolScreenState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<LumeToolScreenState>();

  @override
  ConsumerState<LumeToolScreen> createState() => LumeToolScreenState();
}

class LumeToolScreenState extends ConsumerState<LumeToolScreen> {
  LumeToastData? _toast;
  Timer? _toastTimer;

  /// Show [message], and tell a screen reader once it is on screen.
  void say(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    LumeToastTone tone = LumeToastTone.success,
  }) {
    if (!mounted) return;
    _toastTimer?.cancel();
    setState(
      () => _toast = LumeToastData(
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
    _toastTimer = Timer(
      actionLabel == null
          ? LumeToolScreen.toastFor
          : LumeToolScreen.toastWithActionFor,
      () {
        if (mounted) setState(() => _toast = null);
      },
    );
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  /// `share:<tool>` — the share card sheet, with the card as it stands now.
  Future<void> share() async {
    final LumeShareCard? card = widget.shareCard?.call();
    if (card == null || !mounted) return;
    await showLumeShareSheet(context: context, card: card);
  }

  /// `export:<tool>` — the file as it stands now, handed to the exporter, and
  /// a sentence only for what the platform reported.
  Future<void> export() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeExportFile? file;
    try {
      file = widget.exportFile?.call();
    } on ArgumentError {
      say(l.toolExportFailed, tone: LumeToastTone.error);
      return;
    }
    if (file == null) return;
    final LumeExportOutcome outcome = await ref
        .read(exporterProvider)
        .export(file);
    if (!mounted) return;
    switch (outcome) {
      case LumeExportOutcome.saved:
        say(l.toolExportedAs(file.fileName));
      case LumeExportOutcome.cancelled:
        break;
      case LumeExportOutcome.unavailable:
        say(l.toolExportUnavailable, tone: LumeToastTone.info);
      case LumeExportOutcome.failed:
        say(l.toolExportFailed, tone: LumeToastTone.error);
    }
  }

  static void _inert() {}

  /// `toggleFavourite(id)` — the reader's own saved list, then the sentence.
  void _toggleFavourite(AppLocalizations l) {
    final LumeStartupController gate = ref.read(startupControllerProvider);
    final LumeProfileRecord profile = gate.state.profile;
    final String id = widget.feature.id;
    final bool had = profile.favourites.contains(id);
    gate.profileChanged(
      profile.copyWith(
        favourites: had
            ? <String>[
                for (final String f in profile.favourites)
                  if (f != id) f,
              ]
            : <String>[...profile.favourites, id],
      ),
    );
    final String name = LumeFeatureStrings.name(l, id);
    say(had ? l.toolUnfavourited(name) : l.toolFavourited(name));
  }

  /// `headerActions()` — share, export, then favourite and search while there
  /// is room, at most three.
  List<Widget> _actions(AppLocalizations l) {
    if (widget.headerActions case final List<Widget> own) return own;
    final Set<LumeToolSupport> s = widget.feature.supports;
    final LumeToolActions a = widget.actions;
    final List<Widget> out = <Widget>[
      if (s.contains(LumeToolSupport.sharing))
        LumeIconButton(
          icon: LumeIcons.share,
          label: l.a11yShare,
          onPressed: a.onShare ?? (widget.shareCard == null ? null : share),
        ),
      if (s.contains(LumeToolSupport.export))
        LumeIconButton(
          icon: LumeIcons.download,
          label: l.a11yExport,
          onPressed: a.onExport ?? (widget.exportFile == null ? null : export),
        ),
    ];
    if (s.contains(LumeToolSupport.favourites) && out.length < 3) {
      out.add(
        LumeIconButton(
          icon: LumeIcons.bookmark,
          label: l.a11yFavourite,
          onPressed: a.onFavourite ?? () => _toggleFavourite(l),
        ),
      );
    }
    if (s.contains(LumeToolSupport.search) && out.length < 3) {
      out.add(
        LumeIconButton(
          icon: LumeIcons.search,
          label: l.a11ySearchTool,
          onPressed: a.onSearch ?? _inert,
        ),
      );
    }
    // `recordActions(c).concat(headerActions(c)).slice(0, 3)`.
    return <Widget>[?widget.leadingAction, ...out].take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFeature feature = widget.feature;
    final LumeUserContext user = widget.user;
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: user.country,
    );
    final LumeEligibility eligibility = ref.watch(eligibilityProvider);
    final DateTime now = LumeClockScope.of(context).now();
    // F6B decision 5: what the source bar may claim is resolved from the
    // tool's capability and the build, never worked out here.
    final LumeSourceClaim claim = LumeSourceClaims.resolve(
      l: l,
      f: f,
      feature: feature,
      capability: ref.watch(dataCapabilityProvider(feature.id)),
      profile: ref.watch(buildProfileProvider),
      now: now,
      city: user.city,
    );

    final Widget frame = LumeToolFrame(
      title: widget.title ?? LumeFeatureStrings.name(l, feature.id),
      subtitle:
          widget.subtitle ??
          LumeToolStrings.subtitle(
            l,
            feature,
            user,
            LumeToolScreen.countryName(context, ref, user.country),
          ),
      strings: LumeToolFrameStrings(
        loading: l.toolLoading,
        errorTitle: l.toolErrorTitle,
        errorText: l.toolErrorText,
        retry: l.actionTryAgain,
        unavailableTitle: l.toolUnavailableTitle,
        unavailableText: l.toolUnavailableText,
        back: l.actionBack,
        relatedTitle: l.toolRelated,
      ),
      onBack: widget.onBack,
      actions: _actions(l),
      status: widget.status,
      // The route has already asked; asking again here is the frame's own
      // gate, so a tool built some other way still cannot draw for a reader
      // who may not have it (§64).
      eligible: eligibility.isVisible(feature, user),
      onRetry: widget.onRetry,
      freshness: widget.bare ? null : claim.quality,
      freshnessLabel: widget.bare ? null : claim.label,
      freshnessSemantics: widget.bare ? null : claim.labelSemantics,
      source: widget.bare ? null : claim.source,
      updated: widget.bare ? null : claim.updated,
      sourceSample: widget.bare ? null : claim.sample,
      sourceSampleSemantics: l.fixtureSampleA11y,
      privacy: feature.sensitive && !widget.bare
          ? LumePrivateState(title: l.toolPrivateTitle, text: l.toolPrivateText)
          : null,
      related: <LumeRelatedTool>[
        if (!widget.bare)
          for (final String id in feature.related)
            if (eligibility.visibleById(id, user) case final LumeFeature r)
              LumeRelatedTool(
                id: r.id,
                name: LumeFeatureStrings.name(l, r.id),
                icon: r.icon,
              ),
      ],
      onOpenRelated: widget.onOpenRelated,
      body: widget.body,
    );

    if (_toast == null && widget.floating == null) return frame;
    return Stack(
      children: <Widget>[
        frame,
        if (widget.floating != null)
          PositionedDirectional(
            end: 22,
            bottom: 96 + MediaQuery.paddingOf(context).bottom,
            child: widget.floating!,
          ),
        if (_toast != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 92 + MediaQuery.paddingOf(context).bottom,
            child: Align(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LumeToast(data: _toast!),
              ),
            ),
          ),
      ],
    );
  }
}
