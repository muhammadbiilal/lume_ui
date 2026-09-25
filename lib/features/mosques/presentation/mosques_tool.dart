/// Nearby Mosques — honestly, this app has no live places directory.
///
/// `tools/islamic/mosques.tool.js` draws a map, a search bar, a radius filter
/// and a list of "nearby" mosques, but every one of those rows is invented per
/// city (`LumeMosquesSearch`'s own library note has the detail) — there is no
/// real mosque, no real distance and no real facility behind any of it. §"no
/// fabricated data" rules that out as something to port; §64 rules out
/// quietly dropping the tool's own body and leaving nothing.
///
/// What is here instead: the reader's own place, said plainly, and one honest
/// action — a real Google Maps search for mosques near it, handed to the
/// reader's own maps app through the same checked [LumeLinkOpener] Lume
/// already uses for every other outbound address. Nothing is fetched, listed
/// or measured here; the maps app does that with its own real data.
///
/// Faith-gated at the catalogue (`faith: true`); [LumeToolScreen] itself
/// blocks a non-Muslim reader's body before this widget's own build ever
/// draws a row (§64, the same defence Qibla relies on).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/platform_services.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/platform/lume_link_opener.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/mosques_search.dart';

class LumeMosquesTool extends ConsumerStatefulWidget {
  const LumeMosquesTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeMosquesTool(request: request);

  static const String id = 'mosques';

  static const Key contextKey = ValueKey<String>('mosques.context');
  static const Key unavailableKey = ValueKey<String>('mosques.unavailable');

  @override
  ConsumerState<LumeMosquesTool> createState() => _LumeMosquesToolState();
}

class _LumeMosquesToolState extends ConsumerState<LumeMosquesTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();

  /// Hands the real, checked search address to the platform. Nothing here is
  /// listed or measured — that is the maps app's own job, with its own data.
  Future<void> _openMaps(AppLocalizations l, String place) async {
    final LumeOpenOutcome outcome = await ref
        .read(linkOpenerProvider)
        .open(LumeMosquesSearch.mapsUri(place));
    if (!mounted) return;
    final String? said = switch (outcome) {
      LumeOpenOutcome.opened => null,
      LumeOpenOutcome.unavailable => l.mosquesMapsUnavailable,
      // `mapsUri` only ever builds an `https` address with a host, so the
      // allowlist never actually refuses it — kept here only so the switch
      // stays exhaustive if that ever stops being true.
      LumeOpenOutcome.refused || LumeOpenOutcome.failed => l.mosquesMapsFailed,
    };
    if (said != null) _host.currentState?.say(said, tone: LumeToastTone.info);
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final String countryName = LumeToolScreen.countryName(
      context,
      ref,
      r.user.country,
    );
    final String city = r.user.city;
    final String place = city.isEmpty
        ? countryName
        : (countryName.isEmpty ? city : '$city, $countryName');

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              key: LumeMosquesTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(label: place, icon: LumeIcons.pin),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeCollectionState(
              key: LumeMosquesTool.unavailableKey,
              kind: LumeCollectionStateKind.empty,
              icon: LumeIcons.mosque,
              title: l.mosquesUnavailableTitle,
              text: l.mosquesUnavailableText,
              primaryAction: LumeButton.accent(
                label: l.mosquesOpenMaps,
                icon: LumeIcons.navigation,
                onPressed: place.isEmpty ? null : () => _openMaps(l, place),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
