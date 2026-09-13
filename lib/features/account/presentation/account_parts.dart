/// The pieces every account route is built from.
///
/// `ui/account-ui.js` assembles all twenty-one routes out of six things: a
/// list of settings rows, a radio group, a note, a form field, a button row
/// and a section. These are those six, so a route reads as a composition
/// rather than as a screen.
library;

import 'package:flutter/material.dart';

import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_settings.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../application/account_form.dart';
import '../domain/notification_prefs.dart';

/// What one account route is: a title, an optional subtitle, and a body.
///
/// The host draws the header; the route decides what goes in it. Returning a
/// value rather than a widget is what lets the route-manifest test ask every
/// one of the twenty-one what it is called without rendering it.
@immutable
class LumeAccountView {
  const LumeAccountView({
    required this.title,
    required this.body,
    this.subtitle,
    this.initialValues = const <String, String>{},
  });

  final String title;
  final String? subtitle;

  /// Built lazily, so listing the routes costs nothing.
  final List<Widget> Function(BuildContext context) body;

  /// What the route's form opens on. Empty for a route with no form.
  final Map<String, String> initialValues;
}

/// `UI.section` — the 24-point separation every block sits in.
class LumeAccountSection extends StatelessWidget {
  const LumeAccountSection({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.tight = false,
  });

  final Widget child;

  /// `UI.section({ title })` — the head over a block. Only the Time route
  /// uses one, and without it its two radio groups run together with nothing
  /// to say which is the clock and which is the zone.
  final String? title;

  /// The line under it. Two of the Notifications screen's five heads carry
  /// one, and it says what the switches below are for.
  final String? subtitle;

  /// `sect--tight` — 12 rather than 24, for a block that belongs to the one
  /// above it.
  final bool tight;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: tight ? LumeSpace.gapCard : LumeSpace.x6),
    child: LumeMeasure(
      child: title == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LumeSectionHeader(title: title!, subtitle: subtitle),
                child,
              ],
            ),
    ),
  );
}

/// Quiet hours — `renderNotifPrefs`' three rows: the switch, then the
/// "from" and "Until" steppers.
///
/// The reference draws the account's Notifications route and the notification
/// centre's preferences sheet from the same function, so Flutter builds both
/// from this one list over the one [LumeNotificationPrefs] the store holds.
/// Each door passes the write it already makes; neither keeps quiet-hours
/// state of its own. The steppers are never disabled — the reference leaves
/// them live whether quiet hours are on or off.
List<Widget> lumeQuietHoursRows({
  required AppLocalizations l,
  required LumeFormatting f,
  required LumeNotificationPrefs prefs,
  required ValueChanged<bool> onQuiet,
  required void Function({required bool from, required int by}) onStep,
}) => <Widget>[
  LumeSettingsRow(
    title: l.notifPrefQuietOn,
    subtitle:
        '${f.hourLabel(prefs.quietFrom)} – '
        '${f.hourLabel(prefs.quietTo)}',
    toggle: prefs.quiet,
    onTap: () => onQuiet(!prefs.quiet),
  ),
  LumeStepperRow(
    title: l.notifPrefFrom,
    stepper: LumeStepper(
      label: l.notifPrefFrom,
      value: f.hourLabel(prefs.quietFrom),
      decrementLabel: l.notifPrefEarlier,
      incrementLabel: l.notifPrefLater,
      onDecrement: () => onStep(from: true, by: -1),
      onIncrement: () => onStep(from: true, by: 1),
    ),
  ),
  LumeStepperRow(
    title: l.notifPrefTo,
    isLast: true,
    stepper: LumeStepper(
      label: l.notifPrefTo,
      value: f.hourLabel(prefs.quietTo),
      decrementLabel: l.notifPrefEarlier,
      incrementLabel: l.notifPrefLater,
      onDecrement: () => onStep(from: false, by: -1),
      onIncrement: () => onStep(from: false, by: 1),
    ),
  ),
];

/// A `.list-row` whose end is a stepper.
///
/// Not a [LumeSettingsRow]: that row speaks as one sentence and hides its
/// children, and a stepper's two buttons have to be heard on their own.
class LumeStepperRow extends StatelessWidget {
  const LumeStepperRow({
    super.key,
    required this.title,
    required this.stepper,
    this.isLast = false,
  });

  final String title;
  final Widget stepper;
  final bool isLast;

  /// How far a stepper's targets reach above and below its 32-point pill.
  static const double _stepperBand =
      (LumeStepper.targetSize - LumeStepper.height) / 2;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Container(
      constraints: const BoxConstraints(minHeight: LumeSpace.tap),
      // `.stepper` is 32 tall and its buttons' targets are 44; the stepper's
      // box also reaches `overhang` past each end of the pill. Those points
      // come out of the row's own padding — six above and below, six at the
      // end — so the row is the reference's 59 and the pill's ends sit where
      // the reference draws them, while every target stays inside the
      // stepper's box, where a tap can reach it.
      padding: EdgeInsetsDirectional.fromSTEB(
        LumeSettingsMetrics.rowPadding.left,
        LumeSettingsMetrics.rowPadding.top - _stepperBand,
        LumeSettingsMetrics.rowPadding.right - LumeStepper.overhang,
        LumeSettingsMetrics.rowPadding.bottom - _stepperBand,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: lume.border, width: LumeSpace.border),
              ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: LumeType.tracked(
                LumeType.natural(context, context.lumeType.meta, size: 14),
                -0.022,
              ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
            ),
          ),
          // `.list-row { gap: 13px }` to the pill, not to the target band.
          const SizedBox(
            width: LumeSettingsMetrics.rowGap - LumeStepper.overhang,
          ),
          stepper,
        ],
      ),
    );
  }
}

/// `.list` — a card of settings rows, with the hairlines between them.
class LumeAccountList extends StatelessWidget {
  const LumeAccountList({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => LumeCard(
    padded: false,
    child: Column(mainAxisSize: MainAxisSize.min, children: rows),
  );
}

/// A field wired to [LumeAccountForm].
///
/// The only place the account section builds an input, so a form's fields
/// cannot drift apart: every one reads its value, its error and its reveal
/// state from the same controller.
class LumeAccountField extends StatelessWidget {
  /// The key a field carries, from the name its value is stored under.
  static Key fieldKey(String name) => ValueKey<String>('field.$name');

  const LumeAccountField({
    super.key,
    required this.form,
    required this.name,
    required this.label,
    required this.error,
    this.hint,
    this.placeholder,
    this.optionalLabel,
    this.obscure = false,
    this.revealShowLabel,
    this.revealHideLabel,
    this.keyboardType,
    this.autofillHints,
    this.maxLength,
    this.onSubmitted,
    this.onLeave,
    this.textInputAction = TextInputAction.next,
    this.autofocus = false,
    this.focusNode,
  });

  final LumeAccountForm form;

  /// The key the controller stores this field under.
  final String name;

  final String label;

  /// Turns the controller's message key into a sentence. The controller holds
  /// no localisations, so the screen resolves them.
  final String? Function(LumeFormIssue issue) error;

  final String? hint;
  final String? placeholder;
  final String? optionalLabel;

  final bool obscure;
  final String? revealShowLabel;
  final String? revealHideLabel;

  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final int? maxLength;
  final VoidCallback? onSubmitted;

  /// Blur. The route decides which checks a field can be judged on alone.
  final void Function(String name)? onLeave;

  /// What the keyboard's own key does. `next` moves to the field below;
  /// `done` on the last field of a form sends it, which is the whole reason
  /// [onSubmitted] exists.
  final TextInputAction textInputAction;

  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final LumeFormIssue? issue = form.errorOn(name);
    return LumeInputField(
      // Addressable by the name the controller stores it under, so a test can
      // say "the phone field" rather than finding it by the words above it —
      // which are a rich label and change with the language.
      key: fieldKey(name),
      // The account's forms are the *product's* field, not the authentication
      // flow's: an uppercase 11-point label over a 48-point box.
      variant: LumeFieldVariant.form,
      label: label,
      value: form.read(name),
      onChanged: (String v) => form.edit(name, v),
      onEditingComplete: onLeave == null ? null : () => onLeave!(name),
      onSubmitted: onSubmitted,
      error: issue == null ? null : error(issue),
      hint: hint,
      placeholder: placeholder,
      optionalLabel: optionalLabel,
      valid: form.isValid(name),
      obscure: obscure,
      revealed: form.isRevealed(name),
      onToggleReveal: obscure ? () => form.toggleReveal(name) : null,
      revealShowLabel: revealShowLabel,
      revealHideLabel: revealHideLabel,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      maxLength: maxLength,
      textInputAction: textInputAction,
      autofocus: autofocus,
      focusNode: focusNode,
      // Every control that would start a second submission is inert while one
      // is outstanding, the field included.
      enabled: !form.busy,
    );
  }
}

/// `.fgrid` — the stack a form's fields sit in.
class LumeAccountFields extends StatelessWidget {
  const LumeAccountFields({super.key, required this.children, this.gap = 14});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (int i = 0; i < children.length; i++) ...<Widget>[
        if (i > 0) SizedBox(height: gap),
        children[i],
      ],
    ],
  );
}
