/// BMI Calculator — the reference's own maths, without its fabricated trend.
///
/// `tools/personal/bmi.tool.js` composes four things over `context.js:1147-
/// 1185`: the height and weight fields, a summary card leading with the
/// reading and its band, the four WHO-style bands drawn as a scale, and a
/// healthy-weight range with its midpoint. All four are here. The fifth thing
/// the reference draws — a five-point "history" invented from the current
/// reading rather than read back from any past one — is not: see
/// `domain/bmi_maths.dart` for why, on the same reasoning Unit Converter's own
/// dropped "Recent" section already carries in this codebase.
///
/// This is a pure calculator: nothing it shows is written anywhere between
/// openings except the two typed fields, kept in [LumeToolSession] exactly as
/// Age and Unit Converter keep theirs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_field_grid.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../converter/domain/unit_table.dart';
import '../../tools/application/tool_numbers.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/bmi_maths.dart';

class LumeBmiTool extends ConsumerStatefulWidget {
  const LumeBmiTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeBmiTool(request: request);

  /// The catalogue id, and the key the session is kept under.
  static const String id = 'bmi';

  static const Key heightKey = ValueKey<String>('bmi.height');
  static const Key weightKey = ValueKey<String>('bmi.weight');
  static const Key summaryKey = ValueKey<String>('bmi.summary');
  static const Key scaleKey = ValueKey<String>('bmi.scale');
  static const Key healthyKey = ValueKey<String>('bmi.healthy');

  static Key scaleRowKey(LumeBmiBand band) =>
      ValueKey<String>('bmi.scale.${band.name}');

  @override
  ConsumerState<LumeBmiTool> createState() => _LumeBmiToolState();
}

class _LumeBmiToolState extends ConsumerState<LumeBmiTool> {
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  TextEditingController? _height;
  TextEditingController? _weight;

  /// `fieldsFor('bmi', { height: imperial ? 69 : 175, ... })` — opens on the
  /// reference's own figure for the reader's unit system, then is remembered
  /// exactly as [LumeToolSession] remembers every other field.
  TextEditingController _heightField(bool imperial) =>
      _height ??= TextEditingController(
        text: _session.field(
          LumeBmiTool.id,
          'height',
          () => lumeJsNumber(
            imperial
                ? LumeBmiResult.defaultHeightImperial
                : LumeBmiResult.defaultHeightMetric,
          ),
        ),
      );

  TextEditingController _weightField(bool imperial) =>
      _weight ??= TextEditingController(
        text: _session.field(
          LumeBmiTool.id,
          'weight',
          () => lumeJsNumber(
            imperial
                ? LumeBmiResult.defaultWeightImperial
                : LumeBmiResult.defaultWeightMetric,
          ),
        ),
      );

  @override
  void dispose() {
    _height?.dispose();
    _weight?.dispose();
    super.dispose();
  }

  void _edited(String key, String value) =>
      setState(() => _session.write(LumeBmiTool.id, key, value));

  /// `t('bmi.band.*')`.
  String _bandLabel(AppLocalizations l, LumeBmiBand band) => switch (band) {
    LumeBmiBand.underweight => l.bmiBandUnderweight,
    LumeBmiBand.healthy => l.bmiBandHealthy,
    LumeBmiBand.overweight => l.bmiBandOverweight,
    LumeBmiBand.obese => l.bmiBandObese,
  };

  /// The reference's own tones (`context.js:1149-1152`: info, ok, warn, late).
  LumeBadgeTone _tone(LumeBmiBand band) => switch (band) {
    LumeBmiBand.underweight => LumeBadgeTone.info,
    LumeBmiBand.healthy => LumeBadgeTone.ok,
    LumeBmiBand.overweight => LumeBadgeTone.warn,
    LumeBmiBand.obese => LumeBadgeTone.late_,
  };

  /// The colour a tone reads as elsewhere on the card — [LumeBadge]'s own
  /// foreground ink, so the gauge underneath agrees with the badge above it.
  Color _toneColor(LumeColors lume, LumeBadgeTone tone) => switch (tone) {
    LumeBadgeTone.info => lume.sky,
    LumeBadgeTone.ok => lume.up,
    LumeBadgeTone.warn => lume.amberInk,
    LumeBadgeTone.late_ => lume.roseInk,
    _ => lume.accent,
  };

  /// `bandRange(b)`, in words rather than `<`/`>` (`context.js:1155-1159`).
  String _rangeLabel(AppLocalizations l, LumeFormatting f, LumeBmiBandRange r) {
    if (r.lo == null) return l.bmiUnder(f.number(r.hi!, decimals: 1));
    if (r.hi == null) return l.bmiOver(f.number(r.lo!, decimals: 1));
    return l.bmiRange(
      f.number(r.lo!, decimals: 1),
      f.number(r.hi!, decimals: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final bool imperial = f.units == LumeUnits.imperial;
    final TextEditingController height = _heightField(imperial);
    final TextEditingController weight = _weightField(imperial);

    final LumeBmiResult bmi = LumeBmiResult.of(
      height: lumeFieldNumber(height.text),
      weight: lumeFieldNumber(weight.text),
      imperial: imperial,
    );
    final LumeBadgeTone tone = _tone(bmi.band);
    final String bandLabel = _bandLabel(l, bmi.band);

    final String heightUnit = imperial
        ? lumeUnit('in').symbol
        : lumeUnit('cm').symbol;
    final String weightUnit = imperial
        ? lumeUnit('lb').symbol
        : lumeUnit('kg').symbol;

    // `w(k)`, `context.js:1171-1174` — rounded, in the reader's own unit.
    String weightText(double kg) =>
        '${f.integer(lumeBmiDisplayWeight(kg, imperial: imperial))} $weightUnit';

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // `UI.section({ id: 'inputs', body: card(formGrid([...])) })`.
          LumeToolSection(
            child: LumeCard(
              child: LumeFieldGrid(
                children: <Widget>[
                  LumeToolField(
                    key: LumeBmiTool.heightKey,
                    label: l.bmiFieldHeight,
                    controller: height,
                    suffix: heightUnit,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('height', v),
                  ),
                  LumeToolField(
                    key: LumeBmiTool.weightKey,
                    label: l.bmiFieldWeight,
                    controller: weight,
                    suffix: weightUnit,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('weight', v),
                  ),
                ],
              ),
            ),
          ),

          // `UI.summaryCard({ tone:'accent', kicker, value, caption: badge,
          // aside: ring })` — the badge and the gauge both carry the band's
          // tone, so neither the value nor the caption is colour alone.
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeBmiTool.summaryKey,
              kicker: l.bmiYourBmi,
              value: f.fixed(bmi.value, 1),
              aside: LumeBadge(label: bandLabel, tone: tone),
              footer: LumeProgressBar(
                value: bmi.gauge,
                label: l.bmiYourBmi,
                valueText: '${f.fixed(bmi.value, 1)} $bandLabel',
                tone: _toneColor(lume, tone),
              ),
            ),
          ),

          // `b.bands.map(...)` — the four WHO-style bands, the reader's own
          // highlighted.
          LumeToolSection(
            title: l.bmiScale,
            child: LumeCard(
              key: LumeBmiTool.scaleKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final (int i, LumeBmiBandRange range)
                      in lumeBmiBands.indexed) ...<Widget>[
                    if (i > 0) const SizedBox(height: 6),
                    _BmiScaleRow(
                      key: LumeBmiTool.scaleRowKey(range.band),
                      label: _bandLabel(l, range.band),
                      range: _rangeLabel(l, f, range),
                      tone: _tone(range.band),
                      current: range.band == bmi.band,
                      currentLabel: l.bmiCurrent,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // `UI.section({ title: healthy, body: rows([...]) })`.
          LumeToolSection(
            title: l.bmiHealthyTitle,
            child: LumeRows(
              key: LumeBmiTool.healthyKey,
              children: <Widget>[
                LumeCompactRow(
                  icon: LumeIcons.target,
                  label: l.bmiHealthyRange,
                  value:
                      '${weightText(bmi.healthyLowKg)} – '
                      '${weightText(bmi.healthyHighKg)}',
                  chevron: false,
                ),
                LumeCompactRow(
                  icon: LumeIcons.scales,
                  label: l.bmiIdealWeight,
                  value: weightText(bmi.idealKg),
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

/// One row of the scale — a band's name, its range, and whether the reader's
/// own reading falls in it.
///
/// `current` is never colour alone: the highlighted row also carries a second,
/// explicit [LumeBadge] naming it so, on top of the tint.
class _BmiScaleRow extends StatelessWidget {
  const _BmiScaleRow({
    super.key,
    required this.label,
    required this.range,
    required this.tone,
    required this.current,
    required this.currentLabel,
  });

  final String label;
  final String range;
  final LumeBadgeTone tone;
  final bool current;
  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      label: current ? '$label, $range, $currentLabel' : '$label, $range',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: current ? lume.tintAccent : null,
            borderRadius: LumeRadius.brXs,
          ),
          child: Row(
            children: <Widget>[
              LumeBadge(label: label, tone: tone),
              if (current) ...<Widget>[
                const SizedBox(width: 8),
                LumeBadge(label: currentLabel, tone: LumeBadgeTone.neutral),
              ],
              const Spacer(),
              Flexible(
                child: Text(
                  range,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: lume.text3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
