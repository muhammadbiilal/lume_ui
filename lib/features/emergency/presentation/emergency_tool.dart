/// Emergency — the reference tool for the action archetype.
///
/// `tools/daily/emergency.tool.js`: where the reader is, the one number that
/// matters most, the others, the reader's own information, and a note that
/// numbers work without signal. Low density on purpose — the actions must be
/// unmissable.
///
/// Every number is handed to the phone app through [dialerProvider] (D6): a
/// press opens the dialer with the number filled in and never places the
/// call; the number dialled is the number shown and the number announced; a
/// dialer that could not be opened is said out loud rather than swallowed.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/platform_services.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_numerals.dart';
import '../../../core/platform/lume_dialer.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/emergency_directory.dart';
import 'emergency_strings.dart';

class LumeEmergencyTool extends ConsumerStatefulWidget {
  const LumeEmergencyTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeEmergencyTool(request: request);

  static const Key sosKey = ValueKey<String>('emergency.sos');
  static const Key callsKey = ValueKey<String>('emergency.calls');
  static const Key infoKey = ValueKey<String>('emergency.info');
  static const Key noteKey = ValueKey<String>('emergency.note');

  /// The accessible name of a call: the service and the number, the number
  /// isolated left to right so an Urdu or Arabic sentence cannot reorder it.
  static String callLabel(AppLocalizations l, String service, String number) =>
      l.emergencyCall(service, '\u2066$number\u2069');

  @override
  ConsumerState<LumeEmergencyTool> createState() => _LumeEmergencyToolState();
}

class _LumeEmergencyToolState extends ConsumerState<LumeEmergencyTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();

  /// `href="tel:…"` — the dialer, and a sentence only when it did not open.
  Future<void> _dial(AppLocalizations l, String number) async {
    final LumeDialOutcome outcome = await ref.read(dialerProvider).dial(number);
    if (!mounted) return;
    final String? said = switch (outcome) {
      // The reference says nothing when the dialer opens, and nothing is
      // known about what the reader did next.
      LumeDialOutcome.opened || LumeDialOutcome.cancelled => null,
      LumeDialOutcome.unavailable => l.emergencyDialUnavailable(number),
      LumeDialOutcome.malformed ||
      LumeDialOutcome.failed => l.emergencyDialFailed(number),
    };
    if (said != null) _host.currentState?.say(said);
  }

  /// `toast:emergency.locationShared` — said only once it is true (C67): the
  /// city and country, and nothing finer, on the clipboard.
  Future<void> _copyLocation(AppLocalizations l, String place) async {
    await Clipboard.setData(ClipboardData(text: place));
    if (!mounted) return;
    _host.currentState?.say(l.emergencyLocationShared);
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final List<LumeEmergencyService> list = LumeEmergencyDirectory.forCountry(
      r.user.country,
    );
    final LumeEmergencyService primary = list.first;
    final String city = r.user.city;
    final String place =
        '$city, ${LumeToolScreen.countryName(context, ref, r.user.country)}';

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
              items: <LumeContextItem>[
                LumeContextItem(label: place, icon: LumeIcons.pin),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSosCard(
              key: LumeEmergencyTool.sosKey,
              name: LumeEmergencyStrings.name(l, primary.name),
              kind: LumeEmergencyStrings.kind(l, primary.kind),
              number: primary.number,
              semanticLabel: LumeEmergencyTool.callLabel(
                l,
                LumeEmergencyStrings.name(l, primary.name),
                primary.number,
              ),
              onTap: () => _dial(l, primary.number),
            ),
          ),
          LumeToolSection(
            title: l.emergencyServices,
            child: LumeCallGrid(
              key: LumeEmergencyTool.callsKey,
              children: <Widget>[
                for (final LumeEmergencyService s in list.skip(1))
                  LumeCallTile(
                    icon: s.icon,
                    name: LumeEmergencyStrings.name(l, s.name),
                    number: s.number,
                    kind: LumeEmergencyStrings.kind(l, s.kind),
                    semanticLabel: LumeEmergencyTool.callLabel(
                      l,
                      LumeEmergencyStrings.name(l, s.name),
                      s.number,
                    ),
                    onTap: () => _dial(l, s.number),
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.emergencyYourInfo,
            child: LumeRows(
              key: LumeEmergencyTool.infoKey,
              children: <Widget>[
                LumeCompactRow(
                  icon: LumeIcons.pulse,
                  label: l.emergencyMedical,
                  value: l.emergencySetUp,
                  onTap: () => r.onOpenRelated?.call('health'),
                ),
                LumeCompactRow(
                  icon: LumeIcons.folder,
                  label: l.emergencyDocuments,
                  value: l.commonLocked,
                  onTap: () => r.onOpenRelated?.call('documents'),
                ),
                LumeCompactRow(
                  icon: LumeIcons.pin,
                  label: l.emergencyShareLocation,
                  value: city,
                  onTap: () => _copyLocation(l, place),
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeNoteCard(
              key: LumeEmergencyTool.noteKey,
              tone: LumeNoteTone.info,
              icon: LumeIcons.info,
              title: l.emergencyNoteTitle,
              text: l.emergencyNoteText,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.sos` — the primary number, on the SOS gradient.
///
/// Stylesheet: 20 / 18 padding, radius 20, `linear-gradient(140deg)`,
/// `shadow-md`; a 46-point tile at 18 % white with a 23-point glyph; the name
/// 17 / 800 / −.032em over the kind 11 / 500 at .82, 2 apart; the number
/// 24 / 800 / −.045em in tabular figures; 14 between the three.
class LumeSosCard extends StatelessWidget {
  const LumeSosCard({
    super.key,
    required this.name,
    required this.kind,
    required this.number,
    required this.semanticLabel,
    this.onTap,
  });

  final String name;
  final String kind;
  final String number;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color on = context.lumeGradients.sos.on;
    TextStyle text(double size, FontWeight weight, double em) =>
        LumeType.tracked(
          LumeType.natural(context, context.lumeType.body, size: size),
          em,
        ).copyWith(fontWeight: weight, color: on);

    return LumePressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      button: false,
      borderRadius: LumeRadius.brLg,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: LumeRadius.brLg,
              gradient: context.lumeGradients.sos.css(
                140,
                Size(box.maxWidth, 86),
              ),
              boxShadow: context.lumeShadows.md,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0x2EFFFFFF),
                      borderRadius: LumeRadius.brMd,
                    ),
                    child: LumeIcon(LumeIcons.shield, size: 23, color: on),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(name, style: text(17, FontWeight.w800, -0.032)),
                        const SizedBox(height: 2),
                        Opacity(
                          opacity: 0.82,
                          child: Text(
                            kind,
                            style: text(11, FontWeight.w500, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  LumeNumerals(
                    number,
                    style: LumeType.numeric(text(24, FontWeight.w800, -0.045)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.calls` — two columns, 10 apart both ways.
class LumeCallGrid extends StatelessWidget {
  const LumeCallGrid({super.key, required this.children});

  final List<Widget> children;

  static const double gap = 10;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (int row = 0; row < children.length; row += 2) ...<Widget>[
        if (row > 0) const SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: children[row]),
              const SizedBox(width: gap),
              Expanded(
                child: row + 1 < children.length
                    ? children[row + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

/// `.call` — one other number.
///
/// Stylesheet: 14 / 13 padding inside a one-point border, radius 12, the card
/// fill; a 19-point glyph in `--down`, 5 below it; then the name 12 / 700 /
/// −.022em, the number 17 / 800 / −.04em tabular, the kind 10 / 500 muted, 3
/// apart.
class LumeCallTile extends StatelessWidget {
  const LumeCallTile({
    super.key,
    required this.icon,
    required this.name,
    required this.number,
    required this.kind,
    required this.semanticLabel,
    this.onTap,
  });

  final String icon;
  final String name;
  final String number;
  final String kind;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    TextStyle text(double size, FontWeight weight, double em, Color color) =>
        LumeType.tracked(
          LumeType.natural(context, context.lumeType.body, size: size),
          em,
        ).copyWith(fontWeight: weight, color: color);

    return LumePressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      button: false,
      borderRadius: LumeRadius.brSm,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: lume.card,
            borderRadius: LumeRadius.brSm,
            border: Border.all(color: lume.border, width: LumeSpace.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              13 + LumeSpace.border,
              14 + LumeSpace.border,
              13 + LumeSpace.border,
              14 + LumeSpace.border,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LumeIcon(icon, size: 19, color: lume.down),
                const SizedBox(height: 5 + 3),
                Text(name, style: text(12, FontWeight.w700, -0.022, lume.text)),
                const SizedBox(height: 3),
                LumeNumerals(
                  number,
                  style: LumeType.numeric(
                    text(17, FontWeight.w800, -0.04, lume.text),
                  ),
                ),
                const SizedBox(height: 3),
                Text(kind, style: text(10, FontWeight.w500, 0, lume.text3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
