/// Learning & Growth — the reference tool for the tracker archetype.
///
/// `tools/personal/learning.tool.js`, in its order: the week's summary with a
/// goal ring, the courses in progress, a bar chart of the week, a consistency
/// heatmap, and two insights. It has one state: the reference renders no empty,
/// loading or error composition for it.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_numerals.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_chart.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/learning_fixtures.dart';

class LumeLearningTool extends StatelessWidget {
  const LumeLearningTool({super.key, required this.request, this.week});

  final LumeToolRequest request;

  /// The figures; the reference's fixture unless a test supplies its own.
  final LumeLearningWeek? week;

  /// The registry's builder.
  static Widget open(LumeToolRequest request) =>
      LumeLearningTool(request: request);

  static const Key summaryKey = ValueKey<String>('learning.summary');
  static const Key coursesKey = ValueKey<String>('learning.courses');
  static const Key weekKey = ValueKey<String>('learning.week');
  static const Key consistencyKey = ValueKey<String>('learning.consistency');
  static const Key insightsKey = ValueKey<String>('learning.insights');

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: request.user.country,
    );
    final LumeLearningWeek w = week ?? kReferenceLearningWeek;
    String n(num v) => f.integer(v);

    return LumeToolScreen(
      feature: request.feature,
      user: request.user,
      onBack: request.onBack,
      onOpenRelated: request.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeSummaryCard(
              key: summaryKey,
              kicker: l.learningThisWeek,
              value: n(w.minutes),
              valueSmall: l.unitMinutes,
              caption: l.learningStreak(n(w.streak)),
              aside: LumeProgressRing(
                value: w.goalShare,
                centreValue: '${n((w.goalShare * 100).round())}%',
                label: l.learningGoal,
              ),
              stats: <LumeStat>[
                LumeStat(value: n(w.courses.length), label: l.learningCourses),
                LumeStat(value: n(w.streak), label: l.learningStreakLabel),
                LumeStat(
                  value: l.learningMilestoneValue(n(w.milestoneMinutes)),
                  label: l.learningMilestone,
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.learningInProgress,
            child: Column(
              key: coursesKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < w.courses.length; i++) ...<Widget>[
                  // `.kard + .kard { margin-top: 12px }`.
                  if (i > 0) const SizedBox(height: LumeSpace.x3),
                  _CourseCard(course: w.courses[i], f: f, l: l, lume: lume),
                ],
              ],
            ),
          ),
          LumeToolSection(
            title: l.learningWeek,
            child: LumeCard(
              child: LumeBarChart(
                key: weekKey,
                label: l.learningWeek,
                values: w.week,
                labels: f.weekdayNarrowFromMonday(),
                highlight: 6,
              ),
            ),
          ),
          LumeToolSection(
            title: l.learningConsistency,
            child: LumeCard(
              child: LumeHeatmap(
                key: consistencyKey,
                label: l.learningConsistency,
                summary: '${n(w.activeDays)} / ${n(w.consistency.length)}',
                levels: w.consistency,
                less: l.commonLess,
                more: l.commonMore,
                levelLabels: <String>[
                  l.heatLevelNone,
                  l.heatLevelSome,
                  l.heatLevelMost,
                  l.heatLevelAll,
                ],
              ),
            ),
          ),
          LumeToolSection(
            title: l.toolInsights,
            child: LumeRows(
              key: insightsKey,
              children: <Widget>[
                LumeRichRow(
                  icon: LumeIcons.clock,
                  iconTone: lume.tintAccent,
                  iconInk: lume.accent,
                  title: l.learningInsight1Title,
                  subtitle: l.learningInsight1Text,
                ),
                LumeRichRow(
                  icon: LumeIcons.trending,
                  iconTone: lume.tintAccent,
                  iconInk: lume.accent,
                  title: l.learningInsight2Title,
                  subtitle: l.learningInsight2Text,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A course in a card: `.course` over its `.pbar`.
///
/// Measured: a 36-point tile at radius 12 with a 17-point glyph; the name
/// 13 / 700 / −0.026em over the meta 11 / 500, 2 apart; the share 14 / 800 /
/// −0.035em; 12 between the row and its bar.
class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.f,
    required this.l,
    required this.lume,
  });

  final LumeCourse course;
  final LumeFormatting f;
  final AppLocalizations l;
  final LumeColors lume;

  @override
  Widget build(BuildContext context) {
    final (Color tile, Color ink) = switch (course.tone) {
      LumeCourseTone.accent => (lume.tintAccent, lume.accent),
      // `--tone-violet` is violet at 16 %, `--tone-amber` amber at 18 %.
      LumeCourseTone.violet => (
        lume.violet.withValues(alpha: 0.16),
        lume.violet,
      ),
      LumeCourseTone.amber => (lume.amber.withValues(alpha: 0.18), lume.amber),
    };
    final String share = '${f.integer((course.progress * 100).round())}%';

    return LumeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tile,
                  borderRadius: LumeRadius.brIcon,
                ),
                child: LumeIcon(LumeIcons.graduation, size: 17, color: ink),
              ),
              const SizedBox(width: LumeSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      course.name,
                      style: LumeType.tracked(
                        LumeType.natural(
                          context,
                          context.lumeType.body,
                          size: 13,
                        ).copyWith(fontWeight: FontWeight.w700),
                        -0.026,
                      ).copyWith(color: lume.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.learningCourseMeta(
                        course.provider,
                        f.integer(course.minutes),
                      ),
                      style: LumeType.natural(
                        context,
                        context.lumeType.metaSmall,
                      ).copyWith(color: lume.text3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LumeSpace.x3),
              LumeNumerals(
                share,
                style: LumeType.tracked(
                  LumeType.natural(
                    context,
                    context.lumeType.body,
                  ).copyWith(fontWeight: FontWeight.w800),
                  -0.035,
                ).copyWith(color: lume.text),
              ),
            ],
          ),
          const SizedBox(height: LumeSpace.x3),
          LumeProgressBar(
            value: course.progress,
            label: course.name,
            valueText: share,
          ),
        ],
      ),
    );
  }
}
