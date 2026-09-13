/// The pieces every account route is built from.
///
/// `ui/account-ui.js` assembles all twenty-one routes out of six things: a
/// list of settings rows, a radio group, a note, a form field, a button row
/// and a section. These are those six, so a route reads as a composition
/// rather than as a screen.
library;

import 'package:flutter/material.dart';

import '../../../core/layout/lume_measure.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../application/account_form.dart';

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
