/// Faraid — the reference tool for a three-heir-category inheritance
/// calculator, structured like Zakat (its closest twin: a real formula, over
/// what the reader types, worked out by a pure `domain/` library).
///
/// `tools/islamic/faraid.tool.js` over `context.js` `faraid()`: the estate,
/// debts and a capped bequest reduce to a net figure, and a wife, sons and
/// daughters divide it by the classical fixed-share/residuary rules. See
/// `domain/faraid_maths.dart` for exactly which combinations are verified
/// correct, which one the reference leaves silently incomplete (a wife with
/// no children — the leftover three quarters is never mentioned anywhere),
/// and how this port discloses that gap instead of hiding it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/fixtures/lume_reference_rates.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_field_grid.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_money.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_numbers.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/faraid_maths.dart';

class LumeFaraidTool extends ConsumerStatefulWidget {
  const LumeFaraidTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeFaraidTool(request: request);

  static const String id = 'faraid';

  static const Key grossKey = ValueKey<String>('faraid.gross');
  static const Key debtsKey = ValueKey<String>('faraid.debts');
  static const Key bequestKey = ValueKey<String>('faraid.bequest');
  static const Key wivesKey = ValueKey<String>('faraid.wives');
  static const Key sonsKey = ValueKey<String>('faraid.sons');
  static const Key daughtersKey = ValueKey<String>('faraid.daughters');
  static const Key summaryKey = ValueKey<String>('faraid.summary');
  static const Key breakdownKey = ValueKey<String>('faraid.breakdown');
  static const Key unallocatedNoteKey = ValueKey<String>(
    'faraid.unallocatedNote',
  );

  /// `String(n)` — no trailing `.0` on a whole number.
  static String jsNumber(double v) => lumeJsNumber(v);

  /// `Number(text)` — an empty field is zero.
  static double parse(String text) => lumeFieldNumber(text);

  @override
  ConsumerState<LumeFaraidTool> createState() => _LumeFaraidToolState();
}

class _LumeFaraidToolState extends ConsumerState<LumeFaraidTool> {
  static const String _id = LumeFaraidTool.id;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{};

  TextEditingController _field(String key, String Function() fallback) =>
      _fields[key] ??= TextEditingController(
        text: _session.field(_id, key, fallback),
      );

  @override
  void dispose() {
    for (final TextEditingController c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _edited(String key, String value) =>
      setState(() => _session.write(_id, key, value));

  /// An entered field as [LumeMoney] of [currency] — a blank or unreadable
  /// field is zero, matching [LumeFaraidTool.parse]'s `Number(text) || 0`.
  /// Never clamped beyond that (including negative): the same reading
  /// `_money()` in Zakat gives every money field it owns.
  LumeMoney _money(TextEditingController c, LumeCurrency currency) {
    final double v = LumeFaraidTool.parse(c.text);
    if (!v.isFinite) return LumeMoney.zero(currency);
    return LumeMoney.sum((v * currency.scale).round(), currency);
  }

  /// A heir count as a non-negative integer. The reference's own
  /// `Math.max(0, Number(f.wife) || 0)` clamps a heir count to zero or more
  /// but never to a whole number — that only matters for a free-text field,
  /// and this one is a stepper-style count, so a half-typed decimal rounds
  /// to the nearest whole heir rather than being carried as a fraction of a
  /// person.
  int _count(TextEditingController c) {
    final double v = LumeFaraidTool.parse(c.text);
    if (!v.isFinite || v <= 0) return 0;
    return v.round();
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final String ccy =
        ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.currencyOf(r.user.country) ??
        f.currency;
    final LumeCurrency currency =
        LumeCurrency.tryOf(ccy) ?? LumeCurrency.of('USD');
    final double usdRate = lumeRatePerUsd(currency.code);

    final TextEditingController gross = _field(
      'gross',
      () => LumeFaraidTool.jsNumber(
        LumeFaraidRules.openingGross(usdRate, currency).minor /
            currency.scale,
      ),
    );
    final TextEditingController debts = _field(
      'debts',
      () => LumeFaraidTool.jsNumber(
        LumeFaraidRules.openingDebts(usdRate, currency).minor /
            currency.scale,
      ),
    );
    final TextEditingController bequest = _field(
      'bequest',
      () => LumeFaraidTool.jsNumber(0),
    );
    final TextEditingController wives = _field(
      'wife',
      () => LumeFaraidTool.jsNumber(
        LumeFaraidRules.defaultWives.toDouble(),
      ),
    );
    final TextEditingController sons = _field(
      'son',
      () => LumeFaraidTool.jsNumber(LumeFaraidRules.defaultSons.toDouble()),
    );
    final TextEditingController daughters = _field(
      'daughter',
      () => LumeFaraidTool.jsNumber(
        LumeFaraidRules.defaultDaughters.toDouble(),
      ),
    );

    final LumeFaraidResult result = LumeFaraidRules.compute(
      inputs: LumeFaraidInputs(
        gross: _money(gross, currency),
        debts: _money(debts, currency),
        bequestRequested: _money(bequest, currency),
        wives: _count(wives),
        sons: _count(sons),
        daughters: _count(daughters),
      ),
    );

    LumeFaraidShare? unallocated;
    for (final LumeFaraidShare s in result.shares) {
      if (s.kind == LumeFaraidShareKind.unallocated) {
        unallocated = s;
        break;
      }
    }

    String money(LumeMoney m) {
      final String sign = m.isNegative ? '−' : '';
      return '$sign${f.money(m.magnitude.minor / currency.scale, code: currency.code)}';
    }

    String heirLabel(LumeFaraidShareKind kind) => switch (kind) {
      LumeFaraidShareKind.wife => l.faraidWife,
      LumeFaraidShareKind.sons => l.faraidSons,
      LumeFaraidShareKind.daughters => l.faraidDaughters,
      LumeFaraidShareKind.unallocated => l.faraidUnallocated,
    };

    // '1/8' and '1/4' are plain digits in the reference too, never run
    // through its own `t()` — only "Residuary" is a translated label there.
    String fractionLabel(LumeFaraidFraction fr) => switch (fr) {
      LumeFaraidFraction.eighth => '1/8',
      LumeFaraidFraction.quarter => '1/4',
      LumeFaraidFraction.residuary => l.faraidResiduary,
      LumeFaraidFraction.unallocated => '—',
    };

    String reasonFor(LumeFaraidShareKind kind) => switch (kind) {
      LumeFaraidShareKind.wife => l.faraidReasonWife,
      LumeFaraidShareKind.sons => l.faraidReasonSons,
      LumeFaraidShareKind.daughters => l.faraidReasonDaughters,
      LumeFaraidShareKind.unallocated => l.faraidReasonUnallocated,
    };

    final bool capped =
        result.bequest.compareTo(result.inputs.bequestRequested) < 0;

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.reminder,
        text: '${l.faraidNet}: ${money(result.net)}',
        source: l.faraidNoteTitle,
      ),
      // `exportRows('faraid')` — heirs, value, currency.
      exportFile: () => LumeExportFile.csv(
        tool: _id,
        day: LumeClockScope.of(context).now(),
        rows: <List<Object?>>[
          <Object?>[l.faraidHeirs, l.commonValue, currency.code],
          for (final LumeFaraidShare share in result.shares)
            <Object?>[
              heirLabel(share.kind),
              (share.amount.minor / currency.scale).round(),
              currency.code,
            ],
        ],
      ),
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
              ],
            ),
          ),
          LumeToolSection(
            child: LumeNoteCard(
              tone: LumeNoteTone.info,
              icon: LumeIcons.info,
              title: l.faraidNoteTitle,
              text: l.faraidNoteText,
            ),
          ),
          LumeToolSection(
            title: l.faraidEstate,
            child: LumeCard(
              child: LumeFieldGrid(
                wide: const <int>{2},
                children: <Widget>[
                  LumeToolField(
                    key: LumeFaraidTool.grossKey,
                    label: l.faraidGross,
                    controller: gross,
                    prefix: currency.code,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('gross', v),
                  ),
                  LumeToolField(
                    key: LumeFaraidTool.debtsKey,
                    label: l.faraidDebts,
                    controller: debts,
                    prefix: currency.code,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('debts', v),
                  ),
                  LumeToolField(
                    key: LumeFaraidTool.bequestKey,
                    label: l.faraidBequest,
                    controller: bequest,
                    prefix: currency.code,
                    kind: LumeFieldKind.money,
                    hint: l.faraidBequestHint,
                    onChanged: (String v) => _edited('bequest', v),
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            title: l.faraidHeirs,
            child: LumeCard(
              child: LumeFieldGrid(
                children: <Widget>[
                  LumeToolField(
                    key: LumeFaraidTool.wivesKey,
                    label: l.faraidWife,
                    controller: wives,
                    kind: LumeFieldKind.number,
                    hint: l.faraidRuleWife,
                    onChanged: (String v) => _edited('wife', v),
                  ),
                  LumeToolField(
                    key: LumeFaraidTool.sonsKey,
                    label: l.faraidSons,
                    controller: sons,
                    kind: LumeFieldKind.number,
                    hint: l.faraidRuleSons,
                    onChanged: (String v) => _edited('son', v),
                  ),
                  LumeToolField(
                    key: LumeFaraidTool.daughtersKey,
                    label: l.faraidDaughters,
                    controller: daughters,
                    kind: LumeFieldKind.number,
                    hint: l.faraidRuleDaughters,
                    onChanged: (String v) => _edited('daughter', v),
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeFaraidTool.summaryKey,
              gradient: context.lumeGradients.accent,
              kicker: l.faraidNet,
              value: money(result.net),
              caption: capped ? l.faraidCaptionCapped : l.faraidCaptionReady,
              stats: <LumeStat>[
                LumeStat(value: money(result.inputs.gross), label: l.faraidGross),
                LumeStat(value: money(result.inputs.debts), label: l.faraidDebts),
                LumeStat(value: money(result.bequest), label: l.faraidBequest),
              ],
            ),
          ),
          if (unallocated != null)
            LumeToolSection(
              child: LumeNoteCard(
                key: LumeFaraidTool.unallocatedNoteKey,
                tone: LumeNoteTone.warn,
                icon: LumeIcons.info,
                title: l.faraidUnallocated,
                text: l.faraidReasonUnallocated,
              ),
            ),
          LumeToolSection(
            title: l.faraidDistribution,
            child: LumeTable(
              key: LumeFaraidTool.breakdownKey,
              label: l.faraidDistribution,
              columns: <LumeColumn>[
                LumeColumn(label: l.faraidHeirs),
                LumeColumn(label: l.commonValue, numeric: true),
              ],
              rows: <List<String>>[
                for (final LumeFaraidShare share in result.shares)
                  <String>[
                    '${heirLabel(share.kind)} (${fractionLabel(share.fraction)})',
                    money(share.amount),
                  ],
              ],
            ),
          ),
          LumeToolSection(
            title: l.faraidExplain,
            child: LumeRows(
              children: <Widget>[
                for (final LumeFaraidShare share in result.shares)
                  LumeExpandRow(
                    header: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            heirLabel(share.kind),
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${fractionLabel(share.fraction)} · ${money(share.amount)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    child: Text(
                      reasonFor(share.kind),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeButtonRow(
              children: <Widget>[
                LumeButton.accent(
                  label: l.commonExport,
                  icon: LumeIcons.download,
                  onPressed: () => _host.currentState?.export(),
                ),
                LumeButton(
                  label: l.commonShare,
                  icon: LumeIcons.share,
                  onPressed: () => _host.currentState?.share(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
