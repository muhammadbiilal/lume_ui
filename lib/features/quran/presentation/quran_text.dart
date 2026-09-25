/// Qur'anic Arabic on screen: its own direction and its own locale, whatever
/// the interface's are — the principle Hadith's `LumeResolvedPassage.language`
/// already drives (never the interface locale), reused here directly.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';

/// One line of Qur'anic Arabic — right to left, in the Arabic reading face,
/// spoken by a screen reader as Arabic, whatever language the interface is
/// drawn in.
class LumeQuranArabicText extends StatelessWidget {
  const LumeQuranArabicText(
    this.text, {
    super.key,
    this.size = 22,
    this.weight = FontWeight.w500,
    this.textAlign,
    this.color,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final TextAlign? textAlign;
  final Color? color;

  static const Locale arabicLocale = Locale('ar');

  @override
  Widget build(BuildContext context) {
    final Color ink = color ?? context.lume.text;

    Widget span = Text(
      text,
      textAlign: textAlign,
      style: LumeType.arabic(size: size, weight: weight).copyWith(color: ink),
    );
    span = Semantics(
      container: true,
      attributedLabel: AttributedString(
        text,
        attributes: <StringAttribute>[
          LocaleStringAttribute(
            range: TextRange(start: 0, end: text.length),
            locale: arabicLocale,
          ),
        ],
      ),
      excludeSemantics: true,
      child: span,
    );
    return Directionality(textDirection: TextDirection.rtl, child: span);
  }
}

/// An ayah, read: its reference, the Arabic exactly as the reference holds
/// it, the reference's own English and its transliteration — and, where no
/// verified translation exists for the reader's language, the same honest
/// label Hadith gives one (C82). Shared by the Al-Qur'an tool's reveal panel
/// and Ayah of the Day's own card, so the two read identically.
///
/// Built rather than reused from `LumeReaderCard`: that card draws one
/// passage, and an ayah is always the Arabic *and* the reference's English
/// together — the shape the reference itself always draws, never one in
/// place of the other.
class LumeAyahCard extends StatelessWidget {
  const LumeAyahCard({
    super.key,
    required this.reference,
    required this.arabic,
    required this.translation,
    required this.transliteration,
    this.fallbackNote,
    this.actions = const <Widget>[],
  });

  /// "Ar-Ra‘d · 13:28" — already composed by the caller, so this widget knows
  /// nothing about localisation.
  final String reference;

  final String arabic;
  final String translation;
  final String transliteration;

  /// "Shown in English — no verified translation in this language yet" —
  /// only where the reader's language is neither Arabic nor English.
  final String? fallbackNote;

  final List<Widget> actions;

  static const Key referenceKey = ValueKey<String>('ayahcard.ref');
  static const Key arabicKey = ValueKey<String>('ayahcard.ar');
  static const Key translationKey = ValueKey<String>('ayahcard.tr');
  static const Key transliterationKey = ValueKey<String>('ayahcard.tl');
  static const Key noteKey = ValueKey<String>('ayahcard.note');
  static const Key actionsKey = ValueKey<String>('ayahcard.acts');

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: LumeRadius.brMd,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.xs,
        gradient: LinearGradient(
          begin: const Alignment(-0.17, -1),
          end: const Alignment(0.17, 1),
          colors: <Color>[lume.card, lume.card2],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            label: reference,
            excludeSemantics: true,
            child: Text(
              reference.toUpperCase(),
              key: referenceKey,
              style: LumeType.tracked(
                LumeType.natural(
                  context,
                  context.lumeType.metaSmall,
                ).copyWith(fontWeight: FontWeight.w700),
                0.04,
              ).copyWith(color: lume.accent),
            ),
          ),
          const SizedBox(height: 12),
          LumeQuranArabicText(arabic, key: arabicKey, size: 22),
          const SizedBox(height: 14),
          Semantics(
            container: true,
            attributedLabel: AttributedString(
              translation,
              attributes: <StringAttribute>[
                LocaleStringAttribute(
                  range: TextRange(start: 0, end: translation.length),
                  locale: const Locale('en'),
                ),
              ],
            ),
            excludeSemantics: true,
            child: Text(
              translation,
              key: translationKey,
              style: LumeType.tracked(
                LumeType.fit(
                  context,
                  context.lumeType.body,
                ).copyWith(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500),
                -0.012,
              ).copyWith(color: lume.text),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transliteration,
            key: transliterationKey,
            style: LumeType.natural(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text3, fontStyle: FontStyle.italic),
          ),
          if (fallbackNote != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              fallbackNote!,
              key: noteKey,
              style: LumeType.natural(
                context,
                context.lumeType.metaSmall,
              ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
            ),
          ],
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Row(
              key: actionsKey,
              children: <Widget>[
                for (int i = 0; i < actions.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
