/// The host every converted tool is drawn through.
///
/// `engine.js` `build()` in Flutter: given a feature and a body, it supplies
/// everything the reference supplies around a module — the title, the sub-line,
/// the header actions the spec declares, the source card, the privacy note for
/// a sensitive tool, and the related tools the reader may actually open. A tool
/// hands over its sections and nothing else, so no tool can draw its own frame
/// differently from the other 84.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/personalisation.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';
import '../../catalogue/presentation/feature_strings.dart';
import 'tool_strings.dart';

/// What the header's actions do for one tool.
///
/// **Decision F6A-D7.** The reference's share opens the share-card sheet and
/// its export writes a file and says so. Neither system is converted yet, so a
/// tool that passes nothing gets an inert control: drawn where the reference
/// draws it, announcing its name, and claiming nothing it has not done — no
/// "Saved lume-tax-….json" for a file that was never written.
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
class LumeToolScreen extends ConsumerWidget {
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

  static void _inert() {}

  /// `headerActions()` — share, export, then favourite and search while there
  /// is room, at most three.
  List<Widget> _actions(AppLocalizations l) {
    final Set<LumeToolSupport> s = feature.supports;
    final List<Widget> out = <Widget>[
      if (s.contains(LumeToolSupport.sharing))
        LumeIconButton(
          icon: LumeIcons.share,
          label: l.a11yShare,
          onPressed: actions.onShare ?? _inert,
        ),
      if (s.contains(LumeToolSupport.export))
        LumeIconButton(
          icon: LumeIcons.download,
          label: l.a11yExport,
          onPressed: actions.onExport ?? _inert,
        ),
    ];
    if (s.contains(LumeToolSupport.favourites) && out.length < 3) {
      out.add(
        LumeIconButton(
          icon: LumeIcons.bookmark,
          label: l.a11yFavourite,
          onPressed: actions.onFavourite ?? _inert,
        ),
      );
    }
    if (s.contains(LumeToolSupport.search) && out.length < 3) {
      out.add(
        LumeIconButton(
          icon: LumeIcons.search,
          label: l.a11ySearchTool,
          onPressed: actions.onSearch ?? _inert,
        ),
      );
    }
    return out.take(3).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: user.country,
    );
    final LumeEligibility eligibility = ref.watch(eligibilityProvider);
    final DateTime now = LumeClockScope.of(context).now();

    return LumeToolFrame(
      title: LumeFeatureStrings.name(l, feature.id),
      subtitle:
          subtitle ??
          LumeToolStrings.subtitle(
            l,
            feature,
            user,
            countryName(context, ref, user.country),
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
      onBack: onBack,
      actions: _actions(l),
      status: status,
      // The route has already asked; asking again here is the frame's own
      // gate, so a tool built some other way still cannot draw for a reader
      // who may not have it (§64).
      eligible: eligibility.isVisible(feature, user),
      onRetry: onRetry,
      freshness: LumeToolStrings.quality(feature.freshness),
      freshnessLabel: LumeToolStrings.freshness(l, feature.freshness),
      source: LumeToolStrings.source(l, feature),
      updated: LumeToolStrings.updated(
        l,
        f,
        feature.freshness,
        now: now,
        city: user.city,
      ),
      privacy: feature.sensitive
          ? LumePrivateState(title: l.toolPrivateTitle, text: l.toolPrivateText)
          : null,
      related: <LumeRelatedTool>[
        for (final String id in feature.related)
          if (eligibility.visibleById(id, user) case final LumeFeature r)
            LumeRelatedTool(
              id: r.id,
              name: LumeFeatureStrings.name(l, r.id),
              icon: r.icon,
            ),
      ],
      onOpenRelated: onOpenRelated,
      body: body,
    );
  }
}
