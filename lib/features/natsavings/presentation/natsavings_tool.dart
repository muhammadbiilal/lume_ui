/// National Savings — `tools/money/natsavings.tool.js`, composed in the
/// reference's own order: where the reader is and which scheme, the best
/// rate on offer, a search over the products, a sort bar over three
/// dimensions, the product rows, and an estimate card. One country, PK, has
/// a schedule; every other reads `null` — `D.NAT_SAVINGS[c.profile.country]`
/// is `LumeNatSavingsScheme.forCountry` (see `natsavings_fixtures.dart`'s
/// Dayroz obligation).
///
/// **Corrected, as Prize Bonds' own port is (its sibling PK-only money tool,
/// built to the same pattern):** the reference's unsupported branch is a bare
/// `UI.emptyState`, with no context bar and no action. This port instead uses
/// the project's own [LumeCollectionState] with a "Change country" action —
/// consistent with every other country-gated money tool here (Tax, Prize
/// Bonds) — rather than leaving a reader with no way out of the screen.
///
/// **Corrected:** the reference's `selectField` for the estimate's product
/// becomes a [LumeSegmented], the same substitution Prize Bonds' own
/// denomination select makes — a set of discrete options reads better as a
/// segmented control on a touch screen than a native `<select>`; the value it
/// carries is unchanged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_numbers.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/natsavings_fixtures.dart';
import 'natsavings_text.dart';

/// The tool.
class LumeNatSavingsTool extends ConsumerStatefulWidget {
  const LumeNatSavingsTool({super.key, required this.request});

  final LumeToolRequest request;

  /// The registry's builder.
  static Widget open(LumeToolRequest request) =>
      LumeNatSavingsTool(request: request);

  static const String id = 'natsavings';

  static const Key summaryKey = ValueKey<String>('natsavings.summary');
  static const Key searchKey = ValueKey<String>('natsavings.search');
  static const Key sortKey = ValueKey<String>('natsavings.sort');
  static const Key listKey = ValueKey<String>('natsavings.products');
  static const Key noMatchKey = ValueKey<String>('natsavings.noMatch');
  static const Key unavailableKey = ValueKey<String>('natsavings.unavailable');
  static const Key amountKey = ValueKey<String>('natsavings.amount');
  static const Key productKey = ValueKey<String>('natsavings.product');
  static const Key estimateKey = ValueKey<String>('natsavings.estimate');

  /// `ns_amount`'s value when the reader has typed nothing — `1000000`,
  /// whatever the market (the reference never scales it by a rate).
  static const String defaultAmount = '1000000';

  @override
  ConsumerState<LumeNatSavingsTool> createState() =>
      _LumeNatSavingsToolState();
}

class _LumeNatSavingsToolState extends ConsumerState<LumeNatSavingsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(LumeNatSavingsTool.id, 'q') ?? '',
  );
  late final TextEditingController _amount;
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: _session.field(
        LumeNatSavingsTool.id,
        'amount',
        () => LumeNatSavingsTool.defaultAmount,
      ),
    );
  }

  @override
  void dispose() {
    _query.dispose();
    _amount.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String get _sort => _session.read(LumeNatSavingsTool.id, 'sort') ?? 'rate';

  bool get _descending => _session.read(LumeNatSavingsTool.id, 'dir') != 'asc';

  /// `ns_product`'s value — the best rate until the reader picks another,
  /// and never a name outside this scheme's own list.
  String _productName(LumeNatSavingsScheme scheme) {
    final String saved =
        _session.read(LumeNatSavingsTool.id, 'product') ?? scheme.best.name;
    return scheme.instruments.any((LumeSavingsInstrument p) => p.name == saved)
        ? saved
        : scheme.best.name;
  }

  void _search(String q) =>
      setState(() => _session.write(LumeNatSavingsTool.id, 'q', q));

  void _setAmount(String v) =>
      setState(() => _session.write(LumeNatSavingsTool.id, 'amount', v));

  void _setSort(String value, LumeSortDirection direction) => setState(() {
    _session.write(LumeNatSavingsTool.id, 'sort', value);
    _session.write(
      LumeNatSavingsTool.id,
      'dir',
      direction == LumeSortDirection.descending ? 'desc' : 'asc',
    );
  });

  void _setProduct(String name) =>
      setState(() => _session.write(LumeNatSavingsTool.id, 'product', name));

  void _openProduct(LumeSavingsInstrument p, LumeFormatting f) =>
      _host.currentState?.say(
        LumeNatSavingsText.rowToast(p, f.number(p.rate, decimals: 2)),
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
    final LumeNatSavingsScheme? scheme = LumeNatSavingsScheme.forCountry(
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
            key: LumeNatSavingsTool.unavailableKey,
            kind: LumeCollectionStateKind.empty,
            icon: LumeIcons.shield,
            title: l.savingsUnavailableTitle,
            text: l.savingsUnavailableText,
            primaryAction: LumeButton.accent(
              label: l.toolChangeCountry,
              icon: LumeIcons.globe,
              onPressed: () => showLumePersonalise(context),
            ),
          ),
        ),
      );
    }

    // `L.country().currency` — the scheme's own currency, not necessarily the
    // reader's preferred one.
    final String ccy =
        ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.currencyOf(r.user.country) ??
        f.currency;
    String money(double v) => f.money(v, code: ccy);

    final LumeSavingsInstrument best = scheme.best;
    final List<LumeSavingsInstrument> filtered = lumeNatSavingsFilter(
      scheme.instruments,
      _query.text,
    );
    final List<LumeSavingsInstrument> shown = lumeNatSavingsSort(
      filtered,
      sort: _sort,
      descending: _descending,
    );

    final String productName = _productName(scheme);
    final LumeSavingsInstrument selected = scheme.instruments.firstWhere(
      (LumeSavingsInstrument p) => p.name == productName,
    );
    final double amount = lumeFieldNumber(_amount.text);
    final double yearlyProfit = amount * selected.rate / 100;
    final double monthlyProfit = yearlyProfit / 12;

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
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
                LumeContextItem(label: l.savingsScheme),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeNatSavingsTool.summaryKey,
              gradient: context.lumeGradients.accent,
              kicker: l.savingsBestRate,
              value: '${f.number(best.rate, decimals: 2)}%',
              caption: best.name,
              stats: <LumeStat>[
                LumeStat(value: best.term, label: l.savingsTerm),
                LumeStat(value: best.payout, label: l.savingsPayout),
                LumeStat(value: money(best.min), label: l.savingsMinimum),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSearchField(
              key: LumeNatSavingsTool.searchKey,
              controller: _query,
              focusNode: _searchFocus,
              placeholder: l.savingsSearch,
              onChanged: _search,
            ),
          ),
          LumeToolSection(
            child: LumeSortBar(
              key: LumeNatSavingsTool.sortKey,
              label: l.commonSort,
              value: _sort,
              direction: _descending
                  ? LumeSortDirection.descending
                  : LumeSortDirection.ascending,
              items: <LumeChoice>[
                LumeChoice(
                  value: 'rate',
                  label: LumeNatSavingsText.sortLabel(l, 'rate'),
                ),
                LumeChoice(
                  value: 'term',
                  label: LumeNatSavingsText.sortLabel(l, 'term'),
                ),
                LumeChoice(
                  value: 'min',
                  label: LumeNatSavingsText.sortLabel(l, 'min'),
                ),
              ],
              onChanged: _setSort,
            ),
          ),
          LumeToolSection(
            title: l.savingsProducts,
            child: shown.isEmpty
                ? LumeToolState(
                    key: LumeNatSavingsTool.noMatchKey,
                    icon: LumeIcons.search,
                    title: l.recNoMatch,
                    text: '',
                  )
                : LumeRows(
                    key: LumeNatSavingsTool.listKey,
                    children: <Widget>[
                      for (final LumeSavingsInstrument p in shown)
                        LumeRichRow(
                          icon: LumeIcons.shield,
                          iconTone: context.lume.tintAccent,
                          title: p.name,
                          subtitle: p.eligible,
                          meta: <String>[
                            p.term,
                            p.payout,
                            LumeNatSavingsText.minNote(l, money(p.min)),
                          ],
                          value: '${f.number(p.rate, decimals: 2)}%',
                          valueSub: l.savingsPerYear,
                          chevron: true,
                          onTap: () => _openProduct(p, f),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.savingsEstimate,
            child: LumeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LumeToolField(
                    key: LumeNatSavingsTool.amountKey,
                    label: l.savingsAmount,
                    controller: _amount,
                    prefix: ccy,
                    kind: LumeFieldKind.number,
                    wide: true,
                    onChanged: _setAmount,
                  ),
                  const SizedBox(height: 14),
                  LumeSegmented(
                    key: LumeNatSavingsTool.productKey,
                    semanticLabel: l.savingsProduct,
                    value: selected.name,
                    onChanged: _setProduct,
                    items: <LumeChoice>[
                      for (final LumeSavingsInstrument p in scheme.instruments)
                        LumeChoice(value: p.name, label: p.name),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LumeMetrics(
                    key: LumeNatSavingsTool.estimateKey,
                    children: <Widget>[
                      LumeMetric(
                        value: money(monthlyProfit),
                        label: l.savingsMonthlyProfit,
                      ),
                      LumeMetric(
                        value: money(yearlyProfit),
                        label: l.savingsYearlyProfit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
