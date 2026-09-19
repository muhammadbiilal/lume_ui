/// How Ledger's figures and words are written — and read back from a form.
///
/// Every amount goes through [LumeFormatting.amount]: exact, never through
/// a `double`, full precision in forms and details, zero digits dropped
/// only in compact places. Direction is always words, never a sign.
library;

import 'package:flutter/widgets.dart' show StringCharacters;

import '../../../core/localization/lume_format.dart';
import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/ledger_book.dart';
import '../domain/ledger_model.dart';

abstract final class LedgerText {
  /// A first-strong isolate, so a name or an amount keeps its own direction
  /// inside a sentence in the other.
  static String isolate(String s) => '\u2068$s\u2069';

  static String kind(AppLocalizations l, LedgerKind k) => switch (k) {
    LedgerKind.lent => l.ledgerKindLent,
    LedgerKind.borrowed => l.ledgerKindBorrowed,
    LedgerKind.repaidToMe => l.ledgerKindRepaidToMe,
    LedgerKind.repaidByMe => l.ledgerKindRepaidByMe,
  };

  /// A currency as a picker names it: its code, and for a withdrawn one
  /// that it is no longer issued — said, not only shown.
  static String currency(AppLocalizations l, LumeCurrency c) =>
      c.active ? c.code : l.currencyWithdrawnValue(c.code);

  static String kindShort(AppLocalizations l, LedgerKind k) => switch (k) {
    LedgerKind.lent => l.ledgerKindLentShort,
    LedgerKind.borrowed => l.ledgerKindBorrowedShort,
    LedgerKind.repaidToMe => l.ledgerKindRepaidToMeShort,
    LedgerKind.repaidByMe => l.ledgerKindRepaidByMeShort,
  };

  /// Whether money left the reader: they lent it, or paid it back.
  static bool moneyOut(LedgerKind k) =>
      k == LedgerKind.lent || k == LedgerKind.repaidByMe;

  static String direction(AppLocalizations l, LedgerDirection d) => switch (d) {
    LedgerDirection.owesYou => l.ledgerOwesYou,
    LedgerDirection.youOwe => l.ledgerYouOweShort,
    LedgerDirection.even => l.ledgerEvenRow,
    LedgerDirection.settled => l.ledgerSettledRow,
  };

  /// A calendar date, written out — no "in 2 days".
  static String date(LumeFormatting f, LumeDate d, {LumeDate? today}) {
    final DateTime t = d.toCalendarDateTime();
    return today != null && today.year == d.year
        ? f.dateLong(t)
        : f.dateLongYear(t);
  }

  /// Up to two letters from the first grapheme of up to two words; `null`
  /// for a name with no letters, which gets a neutral icon instead.
  static String? initials(String name) {
    final RegExp letter = RegExp(r'\p{L}', unicode: true);
    final String out = <String>[
      for (final String w in name.trim().split(RegExp(r'\s+')))
        if (w.isNotEmpty && letter.hasMatch(w.characters.first))
          w.characters.first,
    ].take(2).join();
    return out.isEmpty ? null : out.toUpperCase();
  }

  /// Folds text for search: case, Latin accents, Arabic diacritics and
  /// tatweel, the Arabic and Urdu letter variants a reader types either way,
  /// and isolation marks.
  static String fold(String s) {
    final StringBuffer out = StringBuffer();
    for (final int r in s.toLowerCase().runes) {
      if ((r >= 0x064b && r <= 0x065f) ||
          r == 0x0670 ||
          r == 0x0640 ||
          (r >= 0x2066 && r <= 0x2069) ||
          r == 0x200e ||
          r == 0x200f) {
        continue;
      }
      out.write(switch (r) {
        0x0623 || 0x0625 || 0x0622 || 0x0671 => 'ا',
        0x0649 || 0x06cc || 0x064a => 'ي',
        0x06a9 || 0x0643 => 'ك',
        0x06c1 || 0x06be || 0x0647 || 0x0629 => 'ه',
        _ => _latin[String.fromCharCode(r)] ?? String.fromCharCode(r),
      });
    }
    return out.toString().trim();
  }

  static const Map<String, String> _latin = <String, String>{
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
    'ş': 's',
    'ğ': 'g',
    'ı': 'i',
  };
}

/// What reading an amount the reader typed came to.
class LedgerParsedAmount {
  const LedgerParsedAmount.ok(LumeMoney this.money) : error = null;
  const LedgerParsedAmount.error(String this.error) : money = null;

  final LumeMoney? money;
  final String? error;
}

/// The reader's text as an amount of [currency]: their own digits (Arabic
/// and Urdu digits included), their locale's decimal separator or a point,
/// grouping ignored — then exactly at the currency's exponent. More places
/// is an error that says how many the currency takes; nothing is rounded.
LedgerParsedAmount ledgerParseAmount(
  AppLocalizations l,
  String text,
  LumeCurrency currency, {
  required String decimalSeparator,
  required String groupSeparator,
}) {
  final StringBuffer ascii = StringBuffer();
  for (final int r in text.trim().runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      ascii.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06f0 && r <= 0x06f9) {
      ascii.writeCharCode(0x30 + r - 0x06f0);
    } else if (r == 0x066b) {
      ascii.write('.');
    } else if (r == 0x066c || r == 0x00a0 || r == 0x202f || r == 0x20) {
      continue;
    } else {
      ascii.writeCharCode(r);
    }
  }
  String s = ascii.toString();
  if (groupSeparator.isNotEmpty && groupSeparator != '.') {
    s = s.replaceAll(groupSeparator, '');
  }
  if (decimalSeparator != '.') s = s.replaceAll(decimalSeparator, '.');
  if (s.isEmpty) return LedgerParsedAmount.error(l.ledgerErrAmount);
  try {
    final LumeMoney m = LumeMoney.parse(s, currency);
    if (m.isZero) return LedgerParsedAmount.error(l.ledgerErrAmount);
    return LedgerParsedAmount.ok(m);
  } on LumeMoneyException catch (e) {
    return LedgerParsedAmount.error(switch (e.failure) {
      LumeMoneyFailure.precision => l.ledgerErrPrecision(
        currency.code,
        currency.exponent,
      ),
      LumeMoneyFailure.overflow => l.ledgerErrTooLarge,
      _ => l.ledgerErrNumber,
    });
  }
}

/// The reminder text for one balance: its amount, the date of the oldest
/// open loan, and the due date the row shows, if any — in the reader's
/// language, the name isolated. Nothing else: no notes, no other people or
/// currencies, no ids.
String ledgerReminderText(
  AppLocalizations l,
  LumeFormatting f,
  LedgerBalance b, {
  required bool withCode,
}) {
  final List<LedgerPrincipalState> open = b.open(LedgerKind.lent);
  final LumeDate from = open
      .map((LedgerPrincipalState p) => p.entry.on)
      .reduce((LumeDate a, LumeDate c) => a.isBefore(c) ? a : c);
  // The due date of what they owe: the oldest overdue, else the next —
  // never one of the reader's own debts to them.
  final List<LedgerPrincipalState> overdue = <LedgerPrincipalState>[
    for (final LedgerPrincipalState p in open)
      if (p.overdue ?? false) p,
  ];
  final List<LumeDate> dues = <LumeDate>[
    for (final LedgerPrincipalState p in overdue.isEmpty ? open : overdue)
      ?p.entry.due,
  ]..sort();
  final String name = LedgerText.isolate(b.party.name);
  final String amount = f.amount(
    LumeMoney.total(
      open.map((LedgerPrincipalState p) => p.remaining),
      b.currency,
    ),
    withCode: withCode,
    isolate: true,
  );
  final String date = LedgerText.date(f, from);
  return dues.isEmpty
      ? l.ledgerRemindBody(name, amount, date)
      : l.ledgerRemindBodyDue(
          name,
          amount,
          date,
          LedgerText.date(f, dues.first),
        );
}

/// Whether a balance can be the subject of a reminder: one person, one
/// currency, something they owe the reader on an open loan.
bool ledgerRemindable(LedgerBalance b) =>
    !b.damaged && b.open(LedgerKind.lent).isNotEmpty;
