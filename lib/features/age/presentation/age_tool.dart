/// Age Calculator — rollout wave 1, on the Tax form-calculator reference.
///
/// `tools/everyday/age.tool.js`: a date of birth; the age in whole years with
/// its months and days; days, weeks and hours lived; the next birthday as a
/// meter; three milestones. Worked out by [LumeAge] on the injected clock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_iso_day.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/age_maths.dart';

class LumeAgeTool extends ConsumerStatefulWidget {
  const LumeAgeTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) => LumeAgeTool(request: request);

  static const String id = 'age';

  static const Key dobKey = ValueKey<String>('age.dob');
  static const Key summaryKey = ValueKey<String>('age.summary');
  static const Key nextKey = ValueKey<String>('age.next');
  static const Key milestonesKey = ValueKey<String>('age.milestones');

  @override
  ConsumerState<LumeAgeTool> createState() => _LumeAgeToolState();
}

class _LumeAgeToolState extends ConsumerState<LumeAgeTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);

  /// `parseISO(f.dob) || new Date(1993, 3, 18)`.
  DateTime get _birth =>
      lumeParseIsoDay(
        _session.field(LumeAgeTool.id, 'dob', () => LumeAge.defaultBirth),
      ) ??
      DateTime(1993, 4, 18);

  Future<void> _pick(DateTime today) async {
    final DateTime birth = _birth;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birth.isAfter(today) ? today : birth,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: AppLocalizations.of(context).ageDob,
    );
    if (picked == null || !mounted) return;
    setState(() => _session.write(LumeAgeTool.id, 'dob', lumeIsoDate(picked)));
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime birth = _birth;
    // A birth after today has no age; the field says so and the figures stay
    // at today rather than going negative, as the reference's do.
    final bool future = birth.isAfter(today);
    final LumeAge a = LumeAge.of(future ? today : birth, today);
    final String unit = l.ageYearsUnit(a.years);
    final String exact = l.ageExact(
      l.ageMonthsCount(a.months),
      l.ageDaysCount(a.days),
    );

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // The reference shares an unrelated quote (C68); this shares the age
      // on screen and the day it was worked out.
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.reminder,
        text: '${l.ageYouAre} ${f.integer(a.years)} $unit · $exact',
        source: f.dateLongYear(today),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeCard(
              child: LumeToolField(
                key: LumeAgeTool.dobKey,
                label: l.ageDob,
                value: f.dateNumeric(birth),
                kind: LumeFieldKind.date,
                wide: true,
                hint: future ? l.ageFuture : null,
                onTap: () => _pick(today),
              ),
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeAgeTool.summaryKey,
              kicker: l.ageYouAre,
              value: f.integer(a.years),
              unit: unit,
              caption: exact,
              stats: <LumeStat>[
                LumeStat(value: f.integer(a.totalDays), label: l.ageDaysLived),
                LumeStat(value: f.integer(a.totalWeeks), label: l.ageWeeks),
                LumeStat(value: f.integer(a.totalHours), label: l.ageHours),
              ],
            ),
          ),
          LumeToolSection(
            title: l.ageNextBirthday,
            child: LumeCard(
              child: LumeMeterRow(
                key: LumeAgeTool.nextKey,
                label: f.dateLong(a.next),
                value: l.ageUntil(a.untilNext, f.integer(a.untilNext)),
                progress: a.yearDone,
              ),
            ),
          ),
          LumeToolSection(
            title: l.ageMilestones,
            child: LumeRows(
              key: LumeAgeTool.milestonesKey,
              children: <Widget>[
                for (final (int n, DateTime at) in a.milestones)
                  LumeCompactRow(
                    icon: LumeIcons.star,
                    label: l.ageMilestone('$n'),
                    value: f.dateMediumYear(at),
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
