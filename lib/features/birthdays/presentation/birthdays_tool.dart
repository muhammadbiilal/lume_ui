/// Birthdays & Anniversaries — `tools/personal/birthdays.tool.js` under
/// `crud-engine.js`.
///
/// The reader's dates lead — search, the two occasion chips, and the records
/// — and the tool's own composition follows: who is next with how many are
/// kept, how many fall in this month and what age is being reached, then
/// everyone coming up, soonest first.
///
/// The reference's version of that is a picture of it. `context.js:1581-1589`
/// is four constants: countdowns (`days: 4/18/51/88`), ages
/// (`turning: 29/6/5/61`) and a `thisMonth: 2` that counts nothing, beside
/// dates they were never derived from; every control in
/// `birthdays.tool.js` — each row, the add button — is a `toast:`. Here every
/// figure is computed from the records the list above is showing, by the
/// arithmetic the reference's *own* record schema already carries
/// (`record-schemas.js:765-802`), and the row and the action do what they
/// say (C86).
///
/// The reference contradicts itself about this on one screen. Its record
/// list holds the schema's three seeds and its toolbar says "3 records";
/// its Coming up section lists four rows from the constants, the fourth
/// being "Ammi", who is not a record at all; and its summary card says
/// "Tracked 4"
/// (`measurements/tool_birthdays_default_pk_390x844_light_en.json`). Here
/// both read the same records, so both say three.
///
/// Nothing here schedules or delivers a notification. A date is counted
/// down while the reader is looking at it, and nothing arrives when they
/// are not.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/presentation/record_family.dart';
import '../../records/presentation/record_tool.dart';
import '../../tools/application/tool_request.dart';
import '../domain/birthday_family.dart';

abstract final class LumeBirthdaysTool {
  static const String id = 'birthdays';
  static const LumeRecordKeys keys = LumeRecordKeys(id);

  static const Key summaryKey = ValueKey<String>('birthdays.summary');
  static const Key upcomingKey = ValueKey<String>('birthdays.upcoming');
  static const Key nothingKey = ValueKey<String>('birthdays.nothing');
  static const Key dayUnknownKey = ValueKey<String>('birthdays.dayUnknown');
  static const Key fabKey = ValueKey<String>('birthdays.fab');

  static Key dateKey(String id) => ValueKey<String>('birthdays.date.$id');

  static Widget open(LumeToolRequest request) => LumeRecordTool<LumeBirthday>(
    request: request,
    family: const LumeBirthdayFamily(),
    compose: _compose,
    floating: (BuildContext context, LumeRecordScope<LumeBirthday> s) =>
        LumeFab(
          key: fabKey,
          label: s.c.l.birthdaysAdd,
          icon: LumeIcons.plus,
          onPressed: s.create,
        ),
  );

  /// Every date whose stored day can be read, soonest occurrence first.
  ///
  /// A record whose day cannot be read is left out rather than sorted
  /// somewhere arbitrary: it has no countdown and no age, so there is
  /// nothing for this section to say about it. It is still in the list
  /// above, where it can be opened and corrected.
  ///
  /// Two dates on the same day are ordered by name and then by id, so the
  /// order is the same on every build.
  static List<LumeBirthday> dated(List<LumeBirthday> all, DateTime today) =>
      <LumeBirthday>[
        for (final LumeBirthday x in all)
          if (x.date != null) x,
      ]..sort((LumeBirthday a, LumeBirthday b) {
        final int by = LumeBirthdayFamily.daysUntil(
          a.date,
          today,
        )!.compareTo(LumeBirthdayFamily.daysUntil(b.date, today)!);
        if (by != 0) return by;
        final int byName = a.name.compareTo(b.name);
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });

  /// What Coming up lists: [dated], kept by the one query the list shares,
  /// over the name and the occasion — the two things the row shows.
  static List<LumeBirthday> upcoming(
    List<LumeBirthday> all,
    String query,
    AppLocalizations l,
    DateTime today,
  ) {
    final String q = query.trim().toLowerCase();
    return <LumeBirthday>[
      for (final LumeBirthday x in dated(all, today))
        if (q.isEmpty ||
            '${x.name} ${x.kind.label(l)}'.toLowerCase().contains(q))
          x,
    ];
  }

  /// The disc a row's initials sit on. Decoration: the tone is taken from
  /// the record's own id, so it is stable across builds and says nothing
  /// about the person — the occasion is written out in the subtitle, and
  /// nothing here is read from colour alone.
  static (Color, Color) tone(BuildContext context, String id) {
    final LumeColors lume = context.lume;
    final List<(Color, Color)> tones = <(Color, Color)>[
      (lume.tone(lume.rose), lume.rose),
      (lume.tintAccent, lume.accent),
      (lume.tone(lume.sky), lume.sky),
      (lume.tone(lume.violet), lume.violet),
    ];
    return tones[id.codeUnits.fold<int>(0, (int a, int c) => a + c) %
        tones.length];
  }

  static List<Widget> _compose(
    BuildContext context,
    LumeRecordScope<LumeBirthday> s,
  ) {
    final LumeRecordContext c = s.c;
    final AppLocalizations l = c.l;

    // Every figure below is a number of days from the reader's own calendar
    // date. With no such date there is nothing honest to count, so the
    // sections that count give way to which zone could not be read.
    if (!c.dayKnown) {
      return <Widget>[
        LumeToolSection(
          title: l.birthdaysUpcoming,
          child: LumeRecordDayUnknown(key: dayUnknownKey, c: c),
        ),
      ];
    }

    const LumeBirthdayFamily family = LumeBirthdayFamily();
    // The summary describes the whole collection; Coming up follows the
    // search, as the list does. A query narrows what is listed without
    // changing what is true of the reader's dates.
    final List<LumeBirthday> all = dated(s.items, c.today);
    final List<LumeBirthday> rows = upcoming(s.items, s.query, l, c.today);

    // A build that does not reproduce the reference opens this collection
    // empty, and so does any reader who has not added a date yet. Drawing
    // the card then would be three zeros and a blank name presented as a
    // reading, so the card is not drawn at all.
    if (all.isEmpty) {
      return <Widget>[
        LumeToolSection(
          title: l.birthdaysUpcoming,
          child: LumeToolState(
            key: nothingKey,
            icon: LumeIcons.cake,
            title: l.birthdaysNothingTitle,
            text: l.birthdaysNothingText,
          ),
        ),
      ];
    }

    final LumeBirthday next = all.first;
    final DateTime on = LumeBirthdayFamily.nextOn(next.date, c.today)!;
    final int? turning = LumeBirthdayFamily.turning(next.date, on);
    final int thisMonth = all
        .where(
          (LumeBirthday x) => LumeBirthdayFamily.inMonthOf(x.date, c.today),
        )
        .length;

    // Measured: "in 4 days · 11 Sept" — `common.inDays` and the date
    // (`birthdays.tool.js:17`), and the date here carries no weekday where
    // the record row's does. Past a month `when` gives the date itself and
    // the caption would say it twice, so only the date is left.
    final int days = LumeBirthdayFamily.daysUntil(next.date, c.today)!;
    final String written = c.f.dateMedium(on);
    final String caption = days > 30
        ? written
        : '${LumeFamilyText.when(c, on)} · $written';

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: summaryKey,
          kicker: l.birthdaysNext,
          value: next.name,
          caption: caption,
          stats: <LumeStat>[
            LumeStat(value: c.f.integer(all.length), label: l.birthdaysTracked),
            LumeStat(
              value: c.f.integer(thisMonth),
              label: l.birthdaysThisMonth,
            ),
            LumeStat(
              value: turning == null ? '—' : next.kind.figure(l, c.f, turning),
              label: l.birthdaysTurning,
            ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.birthdaysUpcoming,
        child: rows.isEmpty
            ? LumeToolState(
                key: nothingKey,
                icon: LumeIcons.cake,
                title: l.birthdaysNothingTitle,
                // The second line — "Dates you add appear here" — is true of
                // an empty collection and not of a search that found none of
                // three. The record list above has already said the search
                // matched nothing, so this says only what is true.
                text: s.query.trim().isEmpty ? l.birthdaysNothingText : null,
              )
            : LumeRows(
                key: upcomingKey,
                children: <Widget>[
                  for (final LumeBirthday x in rows)
                    _row(context, family, x, c, s),
                ],
              ),
      ),
    ];
  }

  static Widget _row(
    BuildContext context,
    LumeBirthdayFamily family,
    LumeBirthday x,
    LumeRecordContext c,
    LumeRecordScope<LumeBirthday> s,
  ) {
    final DateTime on = LumeBirthdayFamily.nextOn(x.date, c.today)!;
    final int? turning = LumeBirthdayFamily.turning(x.date, on);
    // `logo: x.initials` — one letter, the same disc the record row above
    // draws for the same person (`LumeFamilyText.initial`, measured as
    // "A"/"O"/"M"). The reference's two-letter pairs are hand-written into
    // the constants and contradict its own record discs on the same screen;
    // 'AY' is the first two letters of one word, and 'ZS' (context.js:1584)
    // is derivable from nothing that row shows — the name beside it is the
    // translated word "Anniversary".
    final String initials = LumeFamilyText.initial(x.name);
    final (Color tint, Color ink) = tone(context, x.id);

    return LumeRichRow(
      key: dateKey(x.id),
      logo: initials,
      iconTone: tint,
      iconInk: ink,
      title: x.name,
      subtitle: x.kind.label(c.l),
      // Measured: "11 Sept" and "turns 29" — the date without its weekday.
      meta: <String>[
        c.f.dateMedium(on),
        if (turning != null) x.kind.count(c.l, turning),
      ],
      value: family.countdown(c, on),
      chevron: true,
      onTap: () => s.open(x.id),
    );
  }
}
