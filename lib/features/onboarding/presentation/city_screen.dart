/// "Which city are you in?" — the city `locpicker`.
///
/// The same list, the same search field and the same rows as the country step,
/// with three differences the prototype makes:
///
/// * a **"use my current location"** action sits above the list, always;
/// * a country with regions groups by region while nothing is typed, and
///   flattens the moment something is;
/// * a row leads with nothing and trails with its region, where a country row
///   leads with a code and trails with a currency.
///
/// The `.locback` button the personalisation sheet shows is **absent**: the
/// onboarding instance passes `stage: 'city'`, and the step's own header Back
/// is the way out.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../domain/city_picker_model.dart';
import 'country_screen.dart';

/// `.locrow--action` — the row that is a verb rather than a place.
abstract final class LumeLocateMetrics {
  /// `.locrow--action { margin-top: 10px; border: 1px; border-radius: r-md }`.
  static const double top = 10;

  /// `.locrow__icon { width: 26px; height: 26px }`, glyph 14.
  static const double icon = 26;
  static const double glyph = 14;
}

/// The city step's list, search field and states.
class LumeCityPickerView extends StatelessWidget {
  const LumeCityPickerView({
    super.key,
    required this.model,
    required this.onSelect,
    required this.onQueryChanged,
    required this.searchPlaceholder,
    required this.noResultsText,
    required this.useLocationLabel,
    this.header,
    this.onUseLocation,
    this.searchController,
    this.scrollController,
    this.pinHead = true,
  });

  final LumeCityPickerModel model;

  /// Given the city and the region it sits in — the profile records both.
  final void Function(String city, String? region) onSelect;

  final ValueChanged<String> onQueryChanged;

  /// `pers.searchCities`.
  final String searchPlaceholder;
  final String noResultsText;

  /// `pers.useLocation`.
  final String useLocationLabel;

  /// `null` leaves the row visible and inert, which is what a device that has
  /// refused the permission should show — the offer is still there.
  final VoidCallback? onUseLocation;

  /// The step's lead, handed over when it scrolls with the list. See [pinHead].
  final Widget? header;

  final TextEditingController? searchController;
  final ScrollController? scrollController;

  /// Whether the search field and the locate row stay put while the list moves
  /// under them. The country step documents the measurement behind `false`.
  final bool pinHead;

  @override
  Widget build(BuildContext context) {
    final Widget head = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ?header,
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
        _UseLocation(label: useLocationLabel, onPressed: onUseLocation),
        const SizedBox(height: LumeLocPickerMetrics.scrollTop),
      ],
    );

    if (!pinHead) {
      return _List(
        model: model,
        onSelect: onSelect,
        controller: scrollController,
        head: head,
        empty: model.hasResults ? null : noResultsText,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        head,
        Expanded(
          child: model.hasResults
              ? _List(
                  model: model,
                  onSelect: onSelect,
                  controller: scrollController,
                )
              : LumeLocationEmpty(text: noResultsText),
        ),
      ],
    );
  }
}

/// The sections, lazily, with the head riding along when it is not pinned.
class _List extends StatelessWidget {
  const _List({
    required this.model,
    required this.onSelect,
    required this.controller,
    this.head,
    this.empty,
  });

  final LumeCityPickerModel model;
  final void Function(String city, String? region) onSelect;
  final ScrollController? controller;
  final Widget? head;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final int lead = head == null ? 0 : 1;
    final int body = empty == null ? model.sections.length : 1;

    return ListView.builder(
      controller: controller,
      primary: false,
      padding: EdgeInsets.zero,
      itemCount: lead + body,
      itemBuilder: (BuildContext context, int i) {
        if (i < lead) return head!;
        final int at = i - lead;
        if (empty != null) {
          return LumeLocationEmpty(text: empty!, scrolls: false);
        }
        return _Section(
          section: model.sections[at],
          first: at == 0,
          selected: model.selected,
          onSelect: onSelect,
        );
      },
    );
  }
}

class _UseLocation extends StatelessWidget {
  const _UseLocation({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Padding(
      padding: const EdgeInsets.only(top: LumeLocateMetrics.top),
      child: LumePressable(
        onTap: onPressed,
        semanticLabel: label,
        borderRadius: LumeRadius.brMd,
        minSize: LumeSpace.tap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: LumeLocPickerMetrics.rowMinHeight,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: LumeLocPickerMetrics.rowPaddingY,
            horizontal: LumeLocPickerMetrics.rowPaddingX,
          ),
          decoration: BoxDecoration(
            color: lume.card,
            borderRadius: LumeRadius.brMd,
            border: Border.all(color: lume.border, width: LumeSpace.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: LumeLocateMetrics.icon,
                height: LumeLocateMetrics.icon,
                decoration: BoxDecoration(
                  color: lume.tintAccent,
                  borderRadius: LumeRadius.brIcon,
                ),
                child: Center(
                  widthFactor: 1,
                  child: LumeIcon(
                    LumeIcons.navigation,
                    size: LumeLocateMetrics.glyph,
                    color: lume.accent,
                  ),
                ),
              ),
              const SizedBox(width: LumeLocPickerMetrics.rowGap),
              Expanded(
                child: Text(
                  label,
                  style:
                      LumeType.tracked(
                        LumeType.fit(context, context.lumeType.body),
                        -0.022,
                      ).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 18 / 14,
                        color: lume.text,
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

class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.first,
    required this.selected,
    required this.onSelect,
  });

  final LumeCitySection section;
  final bool first;
  final String selected;
  final void Function(String city, String? region) onSelect;

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
              // The glyphs are capitals; the announcement is not. A screen
              // reader given an all-capitals string may spell it out.
              semanticsLabel: section.title,
              style: LumeType.tracked(
                LumeType.fit(context, context.lumeType.label),
                0.07,
              ).copyWith(fontSize: 10, height: 12 / 10, color: lume.text3),
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
                for (int i = 0; i < section.cities.length; i++)
                  LumeLocationRow(
                    name: section.cities[i].name,
                    // A region groups the list *or* labels the row, never
                    // both: repeating the heading on every row under it would
                    // be noise.
                    meta: section.title == null
                        ? section.cities[i].region
                        : null,
                    selected: section.cities[i].name == selected,
                    divider: i != section.cities.length - 1,
                    onTap: () => onSelect(
                      section.cities[i].name,
                      section.cities[i].region,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
