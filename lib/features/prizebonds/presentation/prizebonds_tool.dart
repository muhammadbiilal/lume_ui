/// Prize Bonds — Pakistan's national savings bearer-bond scheme.
///
/// `tools/money/prizebonds.tool.js` over `D.PRIZE_BONDS`: a context bar, the
/// next draw's summary, a bond-number check form, the upcoming draws, a
/// prize-tiers table, the prize shape by denomination, and the reader's saved
/// numbers. The reference gates the whole tool on `D.PRIZE_BONDS[country]`
/// existing — every reader outside Pakistan sees its `unavailable`
/// composition instead of an invented equivalent, because prize bonds are a
/// Pakistan-specific government savings instrument, not something every
/// market has its own version of.
///
/// Corrected: the reference's `selectField` for denomination becomes a
/// [LumeSegmented] — four options read better as a segmented control on a
/// touch screen than a native `<select>`; the value it carries is unchanged.
///
/// **Honesty note:** the reference reads `c.state('saved')` once, in `build`,
/// and nothing anywhere in the module (or the app around it) ever writes to
/// that key — the check button only ever toasts "no prize", it never adds
/// the checked number to a saved list. "Your numbers" therefore renders
/// empty in the reference in every reachable state, and this port keeps that
/// honestly rather than inventing a save action the reference never wires up.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chart.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/prizebonds_fixtures.dart';
import 'prizebonds_text.dart';

class LumePrizebondsTool extends ConsumerStatefulWidget {
  const LumePrizebondsTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumePrizebondsTool(request: request);

  static const String id = 'prizebonds';

  static const Key summaryKey = ValueKey<String>('prizebonds.summary');
  static const Key denomKey = ValueKey<String>('prizebonds.denom');
  static const Key numberKey = ValueKey<String>('prizebonds.number');
  static const Key checkKey = ValueKey<String>('prizebonds.check');
  static const Key drawsKey = ValueKey<String>('prizebonds.draws');
  static const Key tiersKey = ValueKey<String>('prizebonds.tiers');
  static const Key shapeKey = ValueKey<String>('prizebonds.shape');
  static const Key savedKey = ValueKey<String>('prizebonds.saved');
  static const Key unavailableKey = ValueKey<String>('prizebonds.unavailable');

  /// `pb_denom`'s value when the reader has chosen nothing — `value: '750'`.
  static const String defaultDenom = '750';

  @override
  ConsumerState<LumePrizebondsTool> createState() =>
      _LumePrizebondsToolState();
}

class _LumePrizebondsToolState extends ConsumerState<LumePrizebondsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session;
  late final TextEditingController _number;

  // A non-PK reader never reaches the body that touches these — a lazy
  // `late final`, first read inside dispose(), would initialize itself
  // there instead, after `ref` is no longer usable ("Cannot use 'ref' after
  // the widget was disposed"). Eager init in initState() avoids that,
  // matching the same fix already made for Mobile Packages (wave 9).
  @override
  void initState() {
    super.initState();
    _session = ref.read(toolSessionProvider);
    _number = TextEditingController(
      text: _session.read(LumePrizebondsTool.id, 'number') ?? '',
    );
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  String _denomOf(LumePrizeBondScheme scheme) {
    final String saved = _session.read(LumePrizebondsTool.id, 'denom') ??
        LumePrizebondsTool.defaultDenom;
    return scheme.bonds.any((LumePrizeBond b) => '${b.denom}' == saved)
        ? saved
        : '${scheme.bonds.first.denom}';
  }

  void _setDenom(String v) =>
      setState(() => _session.write(LumePrizebondsTool.id, 'denom', v));

  void _setNumber(String v) =>
      setState(() => _session.write(LumePrizebondsTool.id, 'number', v));

  void _check(AppLocalizations l) =>
      _host.currentState?.say(l.prizebondsNoWin, tone: LumeToastTone.info);

  void _openDraw(LumePrizeBond b) => _host.currentState?.say(
    LumePrizebondsText.drawToast(b),
    tone: LumeToastTone.info,
  );

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final LumePrizeBondScheme? scheme = LumePrizeBondScheme.forCountry(
      r.user.country,
    );

    if (scheme == null) {
      return LumeToolScreen(
        key: _host,
        feature: r.feature,
        user: r.user,
        onBack: r.onBack,
        onOpenRelated: r.onOpenRelated,
        body: LumeToolSection(
          child: LumeCollectionState(
            key: LumePrizebondsTool.unavailableKey,
            kind: LumeCollectionStateKind.empty,
            icon: LumeIcons.ticket,
            title: l.prizebondsUnavailableTitle,
            text: l.prizebondsUnavailableText,
            primaryAction: LumeButton.accent(
              label: l.toolChangeCountry,
              icon: LumeIcons.globe,
              onPressed: () => showLumePersonalise(context),
            ),
          ),
        ),
      );
    }

    // `L.country().currency` — the scheme's own currency, not necessarily
    // the reader's preferred one.
    final String ccy =
        ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.currencyOf(r.user.country) ??
        f.currency;
    String money(double v) => f.money(v, code: ccy);

    final String denom = _denomOf(scheme);
    final List<LumePrizeBond> bonds = scheme.bonds;
    final LumePrizeBond next = scheme.next;

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
                LumeContextItem(
                  label: LumeToolScreen.countryName(
                    context,
                    ref,
                    r.user.country,
                  ),
                  icon: LumeIcons.globe,
                  onTap: () => showLumePersonalise(context),
                ),
                LumeContextItem(label: l.prizebondsScheme),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumePrizebondsTool.summaryKey,
              gradient: context.lumeGradients.accent,
              kicker: l.prizebondsNextDraw,
              value: next.date,
              caption: l.prizebondsNextDrawSub(
                money(next.denom.toDouble()),
                next.draw,
              ),
              stats: <LumeStat>[
                LumeStat(
                  value: money(scheme.prizePool),
                  label: l.prizebondsPrizePool,
                ),
                LumeStat(
                  value: f.number(scheme.totalWinners),
                  label: l.prizebondsTotalWinners,
                ),
                LumeStat(
                  value: f.number(bonds.length),
                  label: l.prizebondsDenominations,
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.prizebondsCheckLead,
                    style: context.lumeType.body.copyWith(
                      color: context.lume.text2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LumeSegmented(
                    key: LumePrizebondsTool.denomKey,
                    semanticLabel: l.prizebondsDenomination,
                    value: denom,
                    onChanged: _setDenom,
                    items: <LumeChoice>[
                      for (final LumePrizeBond b in bonds)
                        LumeChoice(
                          value: '${b.denom}',
                          label: money(b.denom.toDouble()),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LumeToolField(
                    key: LumePrizebondsTool.numberKey,
                    label: l.prizebondsNumber,
                    controller: _number,
                    placeholder: '000000',
                    kind: LumeFieldKind.number,
                    wide: true,
                    onChanged: _setNumber,
                  ),
                  const SizedBox(height: 14),
                  LumeButton.accent(
                    key: LumePrizebondsTool.checkKey,
                    label: l.prizebondsCheck,
                    icon: LumeIcons.search,
                    block: true,
                    onPressed: () => _check(l),
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            title: l.prizebondsDraws,
            child: LumeRows(
              key: LumePrizebondsTool.drawsKey,
              children: <Widget>[
                for (final LumePrizeBond b in bonds)
                  LumeRichRow(
                    logo: '${b.denom}',
                    title: '${money(b.denom.toDouble())} ${l.prizebondsBond}',
                    subtitle: b.draw,
                    meta: <String>[
                      b.date,
                      l.prizebondsWinners(f.number(b.winners)),
                    ],
                    value: money(b.first),
                    valueSub: l.prizebondsFirstPrize,
                    onTap: () => _openDraw(b),
                    chevron: true,
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.prizebondsPrizeTiers,
            child: LumeTable(
              key: LumePrizebondsTool.tiersKey,
              label: l.prizebondsPrizeTiers,
              columns: <LumeColumn>[
                LumeColumn(label: l.prizebondsBond),
                LumeColumn(label: l.prizebondsFirst, numeric: true),
                LumeColumn(label: l.prizebondsSecond, numeric: true),
                LumeColumn(label: l.prizebondsThird, numeric: true),
              ],
              rows: <List<String>>[
                for (final LumePrizeBond b in bonds)
                  <String>[
                    money(b.denom.toDouble()),
                    money(b.first),
                    money(b.second),
                    money(b.third),
                  ],
              ],
            ),
          ),
          LumeToolSection(
            title: l.prizebondsPrizeShape,
            child: LumeCard(
              child: LumeBarChart(
                key: LumePrizebondsTool.shapeKey,
                values: <double>[for (final LumePrizeBond b in bonds) b.first],
                labels: <String>[
                  for (final LumePrizeBond b in bonds) money(b.denom.toDouble()),
                ],
                label: l.prizebondsPrizeShape,
                caption: Text(
                  l.prizebondsPrizeShapeCap,
                  style: context.lumeType.metaSmall.copyWith(
                    color: context.lume.text3,
                  ),
                ),
              ),
            ),
          ),
          LumeToolSection(
            title: l.prizebondsYourNumbers,
            // The reference never writes to `state('saved')` — see the
            // library note above — so this is always the empty state, never
            // a populated list.
            child: LumeToolState(
              key: LumePrizebondsTool.savedKey,
              icon: LumeIcons.ticket,
              title: l.prizebondsNoneSaved,
              text: l.prizebondsNoneSavedText,
            ),
          ),
        ],
      ),
    );
  }
}
