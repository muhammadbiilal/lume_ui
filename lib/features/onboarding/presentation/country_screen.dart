/// "Where are you based?" — the `locpicker`, as a widget.
///
/// One presentation widget, driven by a [LumeCountryPickerModel] and a
/// [LumeCountryPickerController]. It renders; it does not decide. Which
/// sections exist and what is in them is [LumeCountryPicker]'s answer, and
/// where the countries came from is the adapter's — so the same widget serves
/// the fixture today and a Dayroz provider later.
///
/// Measured from the rendered prototype at 390 (light, LTR):
///
/// | | value |
/// |---|---|
/// | `.search--sm` | 44 tall, 12 side padding, 12 radius, 13 px input, 9 gap |
/// | `.locgroup` | 10 / 700 / +0.07em, uppercase, `text3`, 14 / 2 / 7 margins |
/// | `.loclist` | 16 radius, `card`, 1 px border, clipped |
/// | `.locrow` | 41 tall, 11 / 13 padding, 11 gap, 1 px divider except last |
/// | `.locrow__code` | 30 min width, 10 / 800 / +0.04em, `text3` |
/// | `.locrow__name` | 14 / 600 / −0.022em, fills |
/// | `.locrow__meta` | 11 / 600, `text3` |
/// | `.locrow.is-on` | `tintAccent` ground; name 700 and accent; code accent |
/// | `.locempty` | 26 / 10 padding, centred, 13 / 500, `text3` |
///
/// **What this is not.** The brief rules out a flag grid, country tiles, large
/// cards, a three-column layout and a generic green button — none of which the
/// reference has. It is a vertical list of rows, each carrying a code, a name
/// and a currency, over a search field.
library;

import 'package:flutter/material.dart';

import '../../../core/localization/lume_numerals.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../domain/country_picker_model.dart';

/// The measured constants for the location list.
abstract final class LumeLocPickerMetrics {
  /// `.onb-step--list .locpicker { margin-top: 16px }`.
  static const double pickerTop = 16;

  /// `.locscroll { margin-top: 10px }`.
  static const double scrollTop = 10;

  /// `.search { margin: 0 var(--pad) }`.
  ///
  /// The base rule gives the field its own gutter so it can sit directly in a
  /// screen. Inside the picker, which already has one, that insets it a second
  /// time — the field is 310 wide where the list below it is 350. Odd, and
  /// what the prototype draws.
  static const double searchInset = LumeSpace.pageCompact;

  /// `.locgroup { margin: 14px 2px 7px }`, and 2 above when it is first.
  static const double groupTop = 14;
  static const double groupTopFirst = 2;
  static const double groupBottom = 7;
  static const double groupSide = 2;

  /// `.locrow`.
  static const double rowMinHeight = 41;
  static const double rowPaddingY = 11;
  static const double rowPaddingX = 13;
  static const double rowGap = 11;

  /// `.locrow__code { min-width: 30px }`.
  static const double codeMinWidth = 30;

  /// `.locempty { padding: 26px 10px }`.
  static const double emptyPaddingY = 26;
  static const double emptyPaddingX = 10;
}

/// The country step's list, search field and states.
class LumeCountryPickerView extends StatelessWidget {
  const LumeCountryPickerView({
    super.key,
    required this.model,
    required this.onSelect,
    required this.onQueryChanged,
    required this.searchPlaceholder,
    required this.noResultsText,
    this.searchController,
    this.scrollController,
  });

  final LumeCountryPickerModel model;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onQueryChanged;

  /// `pers.searchCountries`.
  final String searchPlaceholder;

  /// `search.nothing`.
  final String noResultsText;

  final TextEditingController? searchController;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: LumeLocPickerMetrics.pickerTop),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LumeLocPickerMetrics.searchInset,
          ),
          child: LumeSearchField(
            small: true,
            placeholder: searchPlaceholder,
            semanticLabel: searchPlaceholder,
            controller: searchController,
            value: searchController == null ? model.query : null,
            onChanged: onQueryChanged,
            onClear: model.isSearching
                ? () {
                    searchController?.clear();
                    onQueryChanged('');
                  }
                : null,
          ),
        ),
        const SizedBox(height: LumeLocPickerMetrics.scrollTop),
        Expanded(
          child: model.hasResults
              ? _List(
                  model: model,
                  onSelect: onSelect,
                  controller: scrollController,
                )
              : _Empty(text: noResultsText),
        ),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.model,
    required this.onSelect,
    required this.controller,
  });

  final LumeCountryPickerModel model;
  final ValueChanged<String> onSelect;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      primary: false,
      padding: EdgeInsets.zero,
      itemCount: model.sections.length,
      itemBuilder: (BuildContext context, int i) => _Section(
        section: model.sections[i],
        first: i == 0,
        selected: model.selected,
        onSelect: onSelect,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.first,
    required this.selected,
    required this.onSelect,
  });

  final LumeCountrySection section;
  final bool first;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (section.title != null)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: first
                  ? LumeLocPickerMetrics.groupTopFirst
                  : LumeLocPickerMetrics.groupTop,
              bottom: LumeLocPickerMetrics.groupBottom,
              start: LumeLocPickerMetrics.groupSide,
              end: LumeLocPickerMetrics.groupSide,
            ),
            child: Text(
              section.title!.toUpperCase(),
              style: LumeType.tracked(
                LumeType.fit(context, context.lumeType.label),
                0.07,
              ).copyWith(fontSize: 10, color: lume.text3),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: lume.card,
            borderRadius: LumeRadius.brMd,
            border: Border.all(color: lume.border, width: LumeSpace.border),
          ),
          child: ClipRRect(
            borderRadius: LumeRadius.brMd,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < section.countries.length; i++)
                  LumeCountryRow(
                    country: section.countries[i],
                    selected: section.countries[i].code == selected,
                    // `.locrow:last-child { border-bottom: 0 }`.
                    divider: i != section.countries.length - 1,
                    onTap: () => onSelect(section.countries[i].code),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `.locrow` — code, name, currency.
class LumeCountryRow extends StatelessWidget {
  const LumeCountryRow({
    super.key,
    required this.country,
    required this.selected,
    required this.onTap,
    this.divider = true,
  });

  final LumeCountry country;
  final bool selected;
  final VoidCallback onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      button: true,
      selected: selected,
      label: '${country.name}, ${country.currency}',
      child: LumePressable(
        onTap: onTap,
        excludeSemantics: true,
        borderRadius: BorderRadius.zero,
        // 41, which is the row the prototype draws, and three under §9's own
        // floor. Unlike the stepper's 26 and Skip's 32 there is nowhere to
        // overhang — the rows are adjacent, so a taller target would either
        // overlap its neighbour's or change the list's rhythm, which is the
        // thing this phase is measuring. Raised as Q9 rather than decided
        // here: the target is 350 points wide, so the miss the floor guards
        // against is not the miss on offer.
        minSize: LumeLocPickerMetrics.rowMinHeight,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: LumeLocPickerMetrics.rowMinHeight,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: LumeLocPickerMetrics.rowPaddingY,
            horizontal: LumeLocPickerMetrics.rowPaddingX,
          ),
          decoration: BoxDecoration(
            color: selected ? lume.tintAccent : Colors.transparent,
            border: divider
                ? Border(
                    bottom: BorderSide(
                      color: lume.border,
                      width: LumeSpace.border,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: <Widget>[
              // The code is a Latin two-letter identifier and stays Latin and
              // left-to-right in an Urdu page — the same isolation `rtl.css`
              // gives `.locrow__code`.
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: LumeLocPickerMetrics.codeMinWidth,
                ),
                child: LumeLtr(
                  child: Text(
                    country.code,
                    style:
                        LumeType.tracked(
                          LumeType.fit(context, context.lumeType.label),
                          0.04,
                        ).copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          // `.locrow__code` is 12 tall: 10 px on a normal line
                          // box.
                          height: 12 / 10,
                          color: selected ? lume.accent : lume.text3,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: LumeLocPickerMetrics.rowGap),
              Expanded(
                child: Text(
                  country.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      LumeType.tracked(
                        LumeType.fit(context, context.lumeType.body),
                        -0.022,
                      ).copyWith(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        // `.locrow__name` is 18 tall, which is what sets the
                        // row's 41. The body role's own height would make it
                        // 45 and add four points to every row in the list.
                        height: 18 / 14,
                        color: selected ? lume.accent : lume.text,
                      ),
                ),
              ),
              const SizedBox(width: LumeLocPickerMetrics.rowGap),
              LumeLtr(
                child: Text(
                  country.currency,
                  style: LumeType.fit(context, context.lumeType.meta).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    // `.locrow__meta` is 13 tall.
                    height: 13 / 11,
                    color: lume.text3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.locempty` — a search that matched nothing.
class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: LumeLocPickerMetrics.emptyPaddingY,
          horizontal: LumeLocPickerMetrics.emptyPaddingX,
        ),
        child: Semantics(
          liveRegion: true,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: LumeType.fit(context, context.lumeType.body).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: lume.text3,
            ),
          ),
        ),
      ),
    );
  }
}
