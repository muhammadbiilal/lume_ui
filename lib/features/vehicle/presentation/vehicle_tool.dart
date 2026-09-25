/// Vehicle & Fines — `tools/daily/vehicle.tool.js` over `D.VEHICLES` and
/// `context.js`'s `vehicleCosts()`, composed in the reference's own order: a
/// fleet summary, a real search over the fleet, the fleet's own rows, a
/// registration-check field that answers nothing it is given, and a
/// reminders timeline for token tax and insurance.
///
/// **Kept exactly as the reference has it, on purpose:** "Check any
/// registration"'s field is read by nothing — `UI.field({ name: 'veh_reg' })`
/// has no matching read anywhere in `vehicle.tool.js` — and "Look up" answers
/// any input, or none, with the same fixed toast (`vehicle.lookingUp`). This
/// is the same pattern already ported honestly for Parcel Tracker's "Track"
/// and Trains' "Find trains": there is no vehicle-registry lookup behind it,
/// so this port does not invent one that only *looks* real by quietly
/// matching the fixture plates against whatever was typed.
///
/// **The fleet list's own search is real**, unlike the field above it: the
/// reference filters `D.VEHICLES` by `plate + ' ' + make` against
/// `c.state('q')`, and [lumeVehicleFilter] does the same.
///
/// **One addition beyond the reference:** a query matching nothing shows
/// this project's own no-match state rather than a silently empty list — the
/// same correction National Savings' and Prize Bonds' own ports already
/// make for their search fields, this wave.
///
/// See `data/vehicle_fixtures.dart` for the fleet, the Pakistan-only scope
/// decision, and how the reference's own USD-authored, RATES-converted
/// token/insurance/fine figures are handled.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/vehicle_fixtures.dart';

class LumeVehicleTool extends ConsumerStatefulWidget {
  const LumeVehicleTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeVehicleTool(request: request);

  static const String id = 'vehicle';

  static const Key summaryKey = ValueKey<String>('vehicle.summary');
  static const Key searchKey = ValueKey<String>('vehicle.search');
  static const Key listKey = ValueKey<String>('vehicle.list');
  static const Key noMatchKey = ValueKey<String>('vehicle.noMatch');
  static const Key checkFieldKey = ValueKey<String>('vehicle.checkField');
  static const Key checkButtonKey = ValueKey<String>('vehicle.checkButton');
  static const Key remindersKey = ValueKey<String>('vehicle.reminders');

  static Color toneOf(LumeColors lume, LumeVehicleTone t) => switch (t) {
    LumeVehicleTone.sky => lume.tone(lume.sky),
    LumeVehicleTone.amber => lume.toneAmber,
  };

  /// `L.distance(km)` — kept local to this tool rather than imported from
  /// another feature's presentation file, the same choice Qibla's own port
  /// makes: kilometres (or miles) under ten read to a tenth, everything else
  /// rounds to the whole unit, both aware of [LumeFormatting.units]. The
  /// reference's own sub-kilometre "metres" branch is not ported — no
  /// odometer in this fixture is ever under a kilometre.
  static String distance(AppLocalizations l, LumeFormatting f, int km) {
    if (f.units == LumeUnits.imperial) {
      final double mi = km * 0.621;
      return '${mi < 10 ? mi.toStringAsFixed(1) : mi.round()} ${l.unitMi}';
    }
    return '${km < 10 ? km.toStringAsFixed(1) : km} ${l.unitKm}';
  }

  @override
  ConsumerState<LumeVehicleTool> createState() => _LumeVehicleToolState();
}

class _LumeVehicleToolState extends ConsumerState<LumeVehicleTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(LumeVehicleTool.id, 'q') ?? '',
  );
  late final TextEditingController _reg = TextEditingController(
    text: _session.read(LumeVehicleTool.id, 'veh_reg') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _query.dispose();
    _reg.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _search(String q) =>
      setState(() => _session.write(LumeVehicleTool.id, 'q', q));

  void _setReg(String v) =>
      setState(() => _session.write(LumeVehicleTool.id, 'veh_reg', v));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );

    // `L.currencyCode()` — the reader's own preferred currency where set, the
    // country's own otherwise; see `vehicle_fixtures.dart` for why the
    // figures themselves are only ever meaningful in PKR through this
    // catalogue-gated tool.
    final String ccyCode =
        ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.currencyOf(r.user.country) ??
        f.currency;
    final LumeCurrency currency =
        LumeCurrency.tryOf(ccyCode) ?? LumeCurrency.of('PKR');
    String money(LumeMoney m) =>
        f.money(m.minor / m.currency.scale, code: m.currency.code);

    final List<LumeVehicle> vehicles = lumeVehicleFilter(
      kVehicles,
      _query.text,
    );
    final int openFines = kVehicles.fold<int>(
      0,
      (int a, LumeVehicle v) => a + v.fines,
    );
    final LumeVehicle first = kVehicles.first;

    final List<LumeTimelineEntry> reminders = <LumeTimelineEntry>[
      for (int i = 0; i < kVehicles.length; i++)
        LumeTimelineEntry(
          time: kVehicles[i].token,
          title: l.vehicleTokenTax,
          subtitle: kVehicles[i].plate,
          meta: l.commonInDays(kVehicles[i].tokenDays),
          state: kVehicles[i].tokenDays < 30
              ? LumeTimelineState.now
              : LumeTimelineState.upcoming,
          value: money(LumeVehicleCosts.tokenFor(i, currency)),
        ),
      for (final LumeVehicle v in kVehicles)
        if (v.insurance != null)
          LumeTimelineEntry(
            time: v.insurance!,
            title: l.vehicleInsuranceRenewal,
            subtitle: v.plate,
            value: money(LumeVehicleCosts.insurance(currency)),
          ),
    ];

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
            child: LumeSummaryCard(
              key: LumeVehicleTool.summaryKey,
              gradient: context.lumeGradients.accent,
              kicker: l.vehicleFleet,
              value: f.integer(kVehicles.length),
              caption: openFines > 0
                  ? l.vehicleOpenFines(openFines)
                  : l.vehicleNoFines,
              stats: <LumeStat>[
                LumeStat(
                  value: money(LumeVehicleCosts.fineTotal(kVehicles, currency)),
                  label: l.vehicleOutstanding,
                ),
                LumeStat(value: first.token, label: l.vehicleNextToken),
                LumeStat(
                  value: LumeVehicleTool.distance(l, f, first.odometerKm),
                  label: l.vehicleOdometer,
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSearchField(
              key: LumeVehicleTool.searchKey,
              controller: _query,
              focusNode: _searchFocus,
              placeholder: l.vehicleSearch,
              onChanged: _search,
            ),
          ),
          LumeToolSection(
            title: l.vehicleYours,
            child: vehicles.isEmpty
                ? LumeToolState(
                    key: LumeVehicleTool.noMatchKey,
                    icon: LumeIcons.search,
                    title: l.recNoMatch,
                    text: '',
                  )
                : LumeRows(
                    key: LumeVehicleTool.listKey,
                    children: <Widget>[
                      for (final LumeVehicle v in vehicles)
                        LumeRichRow(
                          logo: v.logo,
                          iconTone: LumeVehicleTool.toneOf(
                            context.lume,
                            v.tone,
                          ),
                          title: v.plate,
                          subtitle: '${v.make} · ${v.year}',
                          meta: <String>[
                            '${l.vehicleToken} ${v.token}',
                            '${l.vehicleInsurance} ${v.insurance ?? '—'}',
                          ],
                          badge: v.fines > 0
                              ? LumeBadge(
                                  label: l.vehicleFines(v.fines),
                                  tone: LumeBadgeTone.warn,
                                )
                              : LumeBadge(
                                  label: l.vehicleClear,
                                  tone: LumeBadgeTone.ok,
                                ),
                          value: LumeVehicleTool.distance(l, f, v.odometerKm),
                          chevron: true,
                          // `act: 'toast:' + v.plate` — the reference toasts
                          // the plate itself; there is no vehicle-detail
                          // screen behind this row.
                          onTap: () => _host.currentState?.say(v.plate),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.vehicleCheck,
            child: LumeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LumeToolField(
                    key: LumeVehicleTool.checkFieldKey,
                    label: l.vehicleRegistration,
                    controller: _reg,
                    placeholder: 'ABC-123',
                    wide: true,
                    onChanged: _setReg,
                  ),
                  const SizedBox(height: 14),
                  LumeButtonRow(
                    children: <Widget>[
                      LumeButton.accent(
                        key: LumeVehicleTool.checkButtonKey,
                        label: l.vehicleLookup,
                        icon: LumeIcons.search,
                        block: true,
                        // The reference's own fixed toast: it answers
                        // whatever was typed, or nothing, the same way —
                        // there is no register behind it.
                        onPressed: () =>
                            _host.currentState?.say(l.vehicleLookingUp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            title: l.vehicleReminders,
            child: LumeTimeline(
              key: LumeVehicleTool.remindersKey,
              entries: reminders,
            ),
          ),
        ],
      ),
    );
  }
}
