/// Tip & Split — rollout wave 1, on the Tax form-calculator reference.
///
/// `tools/money/tipsplit.tool.js`: the bill, a tip chosen from five, the
/// number of people; what each pays, with the tip, the total and the head
/// count; and one row per person. Worked out by [LumeTipSplit].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/fixtures/lume_reference_rates.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_numbers.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/tip_maths.dart';

class LumeTipsplitTool extends ConsumerStatefulWidget {
  const LumeTipsplitTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeTipsplitTool(request: request);

  static const String id = 'tipsplit';

  static const Key billKey = ValueKey<String>('tipsplit.bill');
  static const Key tipsKey = ValueKey<String>('tipsplit.tips');
  static const Key peopleKey = ValueKey<String>('tipsplit.people');
  static const Key summaryKey = ValueKey<String>('tipsplit.summary');
  static const Key splitKey = ValueKey<String>('tipsplit.split');

  /// `.kard--pad` — 16 inside the card's one-point border.
  static const double cardPadding = 16;

  @override
  ConsumerState<LumeTipsplitTool> createState() => _LumeTipsplitToolState();
}

class _LumeTipsplitToolState extends ConsumerState<LumeTipsplitTool> {
  static const String _id = LumeTipsplitTool.id;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  TextEditingController? _bill;

  TextEditingController _billFor(String currency) =>
      _bill ??= TextEditingController(
        text: _session.field(
          _id,
          'bill',
          () =>
              lumeJsNumber(LumeTipSplit.openingBill(lumeRatePerUsd(currency))),
        ),
      );

  @override
  void dispose() {
    _bill?.dispose();
    super.dispose();
  }

  int get _tip =>
      int.tryParse(_session.read(_id, 'tip') ?? '') ?? LumeTipSplit.defaultTip;

  int get _people =>
      int.tryParse(
        _session.field(_id, 'people', () => '${LumeTipSplit.defaultPeople}'),
      ) ??
      LumeTipSplit.defaultPeople;

  void _write(String key, String value) =>
      setState(() => _session.write(_id, key, value));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final String ccy = f.currency;
    final TextEditingController bill = _billFor(ccy);
    final LumeTipSplit s = LumeTipSplit.of(
      bill: lumeFieldNumber(bill.text),
      tip: _tip,
      people: _people,
    );
    String money(double v) => f.moneyUpTo(v, code: ccy, maxDecimals: 2);
    final DateTime now = LumeClockScope.of(context).now();

    final TextStyle fieldLabel = LumeType.tracked(
      LumeType.fit(
        context,
        context.lumeType.metaSmall,
      ).copyWith(fontWeight: FontWeight.w700),
      0.02,
    ).copyWith(height: 13 / 11, color: context.lume.text3);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // The reference shares an unrelated quote (C68); this shares the split.
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.reminder,
        text:
            '${l.tipPerPerson}: ${money(s.each)} · '
            '${l.tipPeople}: ${f.integer(s.people)} · '
            '${l.tipTotal}: ${money(s.total)}',
        source: f.dateLongYear(now),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeCard(
              padded: false,
              child: Padding(
                // The people row is 44 tall so each stepper target is (D6);
                // six of those points come out of the card's own bottom
                // padding, and the card is six taller than the reference's
                // 32-point row makes it (C83).
                padding: const EdgeInsets.fromLTRB(
                  LumeTipsplitTool.cardPadding,
                  LumeTipsplitTool.cardPadding,
                  LumeTipsplitTool.cardPadding,
                  LumeTipsplitTool.cardPadding - LumeStepper.overhang,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    LumeToolField(
                      key: LumeTipsplitTool.billKey,
                      label: l.tipBill,
                      controller: bill,
                      prefix: ccy,
                      kind: LumeFieldKind.money,
                      wide: true,
                      onChanged: (String v) => _write('bill', v),
                    ),
                    // `.fieldlabel { margin: 14px 0 8px }`.
                    const SizedBox(height: 14),
                    Text(
                      LumeType.overline(context, l.tipTip),
                      semanticsLabel: l.tipTip,
                      style: fieldLabel,
                    ),
                    const SizedBox(height: 8),
                    LumeHorizontalStrip.chips(
                      key: LumeTipsplitTool.tipsKey,
                      semanticLabel: l.tipTip,
                      children: <Widget>[
                        for (final int t in LumeTipSplit.tips)
                          LumeChoiceChip(
                            label: '${f.integer(t)}%',
                            selected: t == s.tip,
                            onTap: () => _write('tip', '$t'),
                          ),
                      ],
                    ),
                    // `.splitrow` — the label and the stepper at either end.
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            LumeType.overline(context, l.tipPeople),
                            semanticsLabel: l.tipPeople,
                            style: fieldLabel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        LumeStepper(
                          key: LumeTipsplitTool.peopleKey,
                          label: l.tipPeople,
                          value: f.integer(s.people),
                          decrementLabel: l.tipFewer,
                          incrementLabel: l.tipMore,
                          onDecrement: s.people > LumeTipSplit.minPeople
                              ? () => _write('people', '${s.people - 1}')
                              : null,
                          onIncrement: s.people < LumeTipSplit.maxPeople
                              ? () => _write('people', '${s.people + 1}')
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeTipsplitTool.summaryKey,
              gradient: context.lumeGradients.accent,
              kicker: l.tipPerPerson,
              value: money(s.each),
              stats: <LumeStat>[
                LumeStat(value: money(s.tipAmount), label: l.tipTip),
                LumeStat(value: money(s.total), label: l.tipTotal),
                LumeStat(value: f.integer(s.people), label: l.tipPeople),
              ],
            ),
          ),
          LumeToolSection(
            title: l.tipSplit,
            child: LumeRows(
              key: LumeTipsplitTool.splitKey,
              children: <Widget>[
                for (int i = 0; i < s.people; i++)
                  LumeCompactRow(
                    icon: LumeIcons.user,
                    label: l.tipPerson(f.integer(i + 1)),
                    value: money(s.each),
                    chevron: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
