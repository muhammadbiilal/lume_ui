/// Mobile Packages — a single-country comparison explorer.
///
/// `tools/money/packages.tool.js` over `tool-data.js` `MOBILE_PACKAGES`: a
/// search, an operator filter, a sort by price/data/validity, a compare
/// table, then each bundle's own expandable detail. The reference reads
/// `MOBILE_PACKAGES[c.profile.country]` and draws its own empty state when the
/// key is missing (`packages.unavailable.*`) — every market but Pakistan, at
/// present. Kept as the reference has it: this is the one money tool with no
/// multi-country data to fall back to, so a reader outside Pakistan sees the
/// honest unavailable state the project uses for a tool outside their setup,
/// rather than another country's operators.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_numerals.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/packages_fixtures.dart';
import 'packages_text.dart';

class LumePackagesTool extends ConsumerStatefulWidget {
  const LumePackagesTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumePackagesTool(request: request);

  static const String id = 'packages';

  static const Key searchKey = ValueKey<String>('packages.search');
  static const Key filterKey = ValueKey<String>('packages.filter');
  static const Key sortKey = ValueKey<String>('packages.sort');
  static const Key tableKey = ValueKey<String>('packages.table');
  static const Key emptyKey = ValueKey<String>('packages.empty');
  static const Key detailKey = ValueKey<String>('packages.detail');
  static const Key unavailableKey = ValueKey<String>('packages.unavailable');

  static Key detailRowKey(LumeMobilePackage p) =>
      ValueKey<String>('packages.detail.${p.operatorName}.${p.name}');

  /// `c.sortBy(shown, { price, data, valid }, sortBy, sortDir)`.
  static int compare(LumeMobilePackage a, LumeMobilePackage b, String sortBy) =>
      switch (sortBy) {
        'data' => a.dataGb.compareTo(b.dataGb),
        'valid' => a.validDays.compareTo(b.validDays),
        _ => a.price.compareTo(b.price),
      };

  /// `list.filter(op, query)` — the reference's own order: operator first,
  /// then the query over operator and bundle name.
  static List<LumeMobilePackage> filter(
    List<LumeMobilePackage> list, {
    required String operator,
    required String query,
  }) {
    final String q = query.trim().toLowerCase();
    return <LumeMobilePackage>[
      for (final LumeMobilePackage p in list)
        if ((operator == 'all' || p.operatorName == operator) &&
            (q.isEmpty || LumePackagesText.searchable(p).contains(q)))
          p,
    ];
  }

  @override
  ConsumerState<LumePackagesTool> createState() => _LumePackagesToolState();
}

class _LumePackagesToolState extends ConsumerState<LumePackagesTool> {
  static const String _id = LumePackagesTool.id;

  static const double _sortOverhang =
      (LumeSpace.tap - LumeSortBar.optionHeight) / 2;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session;
  late final TextEditingController _query;
  final FocusNode _searchFocus = FocusNode();

  // Both are initialised here, unconditionally, rather than as lazy `late
  // final` fields read for the first time inside `_body`: a reader outside
  // Pakistan never reaches `_body`, and a `late final` never touched before
  // `dispose` initialises itself *at* dispose — after the widget is gone,
  // when `ref.read` throws. Eligibility already keeps such a reader from
  // seeing this tool at all (§64's frame gate); this keeps the state itself
  // safe regardless of how it is reached.
  @override
  void initState() {
    super.initState();
    _session = ref.read(toolSessionProvider);
    _query = TextEditingController(text: _session.read(_id, 'q') ?? '');
  }

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String? _read(String k) => _session.read(_id, k);
  void _write(String k, String v) => _session.write(_id, k, v);

  void _search(String q) => setState(() => _write('q', q));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final List<LumeMobilePackage>? list = LumeMobilePackages.forCountry(
      r.user.country,
    );

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
      body: list == null
          ? LumeToolSection(
              child: LumeToolState(
                key: LumePackagesTool.unavailableKey,
                icon: LumeIcons.signal,
                title: l.packagesUnavailableTitle,
                text: l.toolUnavailableText,
              ),
            )
          : _body(context, l, r, list),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l,
    LumeToolRequest r,
    List<LumeMobilePackage> list,
  ) {
    final LumeColors lume = context.lume;
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final double gutter = LumeLayout.pageGutter(context.measureClass);
    // `c.L.country().currency` — the country's own currency. Always PKR in
    // practice, since this list exists only for Pakistan.
    final String ccy =
        ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.currencyOf(r.user.country) ??
        f.currency;
    String money(int v) => f.money(v, code: ccy);

    final String op = _read('op') ?? 'all';
    final String sortBy = _read('sortBy') ?? 'price';
    final LumeSortDirection sortDir = _read('sortDir') == 'desc'
        ? LumeSortDirection.descending
        : LumeSortDirection.ascending;

    // Distinct operators, in the fixture's own order — one chip per carrier
    // rather than the reference's one chip per bundle (there is exactly one
    // bundle per carrier today, so the two agree; a future market with two
    // bundles from the same carrier would not get a duplicate chip here).
    final List<String> operators = <String>{
      for (final LumeMobilePackage p in list) p.operatorName,
    }.toList();

    final List<LumeMobilePackage> shown =
        LumePackagesTool.filter(list, operator: op, query: _query.text)..sort(
          (LumeMobilePackage a, LumeMobilePackage b) =>
              sortDir == LumeSortDirection.ascending
              ? LumePackagesTool.compare(a, b, sortBy)
              : LumePackagesTool.compare(b, a, sortBy),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LumeToolSection(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: LumeSearchField(
              key: LumePackagesTool.searchKey,
              controller: _query,
              focusNode: _searchFocus,
              placeholder: l.packagesSearch,
              onChanged: _search,
            ),
          ),
        ),
        LumeToolSection(
          spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
          child: LumeFilterBar(
            key: LumePackagesTool.filterKey,
            gutters: false,
            children: <Widget>[
              LumeFilterChip(
                label: l.commonAll,
                selected: op == 'all',
                onTap: () => setState(() => _write('op', 'all')),
              ),
              for (final String o in operators)
                LumeFilterChip(
                  label: o,
                  selected: op == o,
                  onTap: () => setState(() => _write('op', o)),
                ),
            ],
          ),
        ),
        LumeToolSection(
          spaceAbove:
              LumeToolSection.gap - LumeFilterBar.overhang - _sortOverhang,
          child: LumeSortBar(
            key: LumePackagesTool.sortKey,
            label: l.commonSort,
            value: sortBy,
            direction: sortDir,
            items: <LumeChoice>[
              LumeChoice(value: 'price', label: l.packagesPrice),
              LumeChoice(value: 'data', label: l.packagesData),
              LumeChoice(value: 'valid', label: l.packagesValidity),
            ],
            onChanged: (String v, LumeSortDirection d) => setState(() {
              _write('sortBy', v);
              _write(
                'sortDir',
                d == LumeSortDirection.ascending ? 'asc' : 'desc',
              );
            }),
          ),
        ),
        if (shown.isEmpty)
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - _sortOverhang,
            child: LumeToolState(
              key: LumePackagesTool.emptyKey,
              icon: LumeIcons.signal,
              title: l.packagesNoMatch,
              text: l.packagesNoMatchText,
            ),
          )
        else ...<Widget>[
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - _sortOverhang,
            title: l.packagesCompare,
            child: LumeTable(
              key: LumePackagesTool.tableKey,
              label: l.packagesCompare,
              columns: <LumeColumn>[
                LumeColumn(label: l.packagesPackage),
                LumeColumn(label: l.packagesData, numeric: true),
                LumeColumn(label: l.packagesMins, numeric: true),
                LumeColumn(label: l.packagesPrice, numeric: true),
              ],
              rows: <List<String>>[
                for (final LumeMobilePackage p in shown)
                  <String>[
                    LumePackagesText.title(p),
                    p.data,
                    p.mins,
                    money(p.price),
                  ],
              ],
            ),
          ),
          LumeToolSection(
            title: l.packagesDetail,
            child: LumeRows(
              key: LumePackagesTool.detailKey,
              children: <Widget>[
                for (final LumeMobilePackage p in shown)
                  LumeExpandRow(
                    key: LumePackagesTool.detailRowKey(p),
                    header: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            LumePackagesText.title(p),
                            style:
                                LumeType.tracked(
                                  LumeType.natural(
                                    context,
                                    context.lumeType.meta,
                                    size: 13,
                                  ),
                                  -0.022,
                                ).copyWith(
                                  color: lume.text,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        LumeNumerals(
                          money(p.price),
                          style:
                              LumeType.numeric(
                                LumeType.tracked(
                                  LumeType.natural(
                                    context,
                                    context.lumeType.label,
                                  ),
                                  -0.02,
                                ),
                              ).copyWith(
                                color: lume.text2,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        LumeCompactRow(label: l.packagesData, value: p.data),
                        LumeCompactRow(label: l.packagesMins, value: p.mins),
                        LumeCompactRow(label: l.packagesSms, value: p.sms),
                        LumeCompactRow(
                          label: l.packagesValidity,
                          value: p.valid,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
