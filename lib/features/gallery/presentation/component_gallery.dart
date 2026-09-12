/// The component gallery — every shared widget, every meaningful state.
///
/// **Development only.** It is reachable from the token gallery and from
/// nowhere else: no route points at it, no navigation destination lists it, and
/// `kGalleryIsDevelopmentOnly` is asserted by
/// `test/features/gallery/gallery_test.dart` so it cannot quietly become a
/// production destination.
///
/// It shows the *same widgets the screens use*. There are no replicas here: if
/// a component looks wrong in the gallery it is wrong everywhere, which is the
/// only property that makes a gallery worth keeping.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/locale_provider.dart';
import '../../../app/providers/theme_provider.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_locales.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume.dart';
// The destination furniture is not on the barrel: `lume_table.dart` and
// `lume_destination.dart` both define a `LumeHorizontalStrip`, so the two
// layers are imported by name rather than merged.
import '../../../core/widgets/lume/lume_agenda.dart';
import '../../../core/widgets/lume/lume_day.dart';
import '../../../core/widgets/lume/lume_explore.dart';
import '../../explore/domain/explore_model.dart';
import '../../explore/presentation/explore_art.dart';
import '../../today/presentation/today_art.dart';

/// Asserted by the gallery test. A production route must never resolve here.
const bool kGalleryIsDevelopmentOnly = true;

class ComponentGallery extends ConsumerStatefulWidget {
  const ComponentGallery({super.key});

  @override
  ConsumerState<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends ConsumerState<ComponentGallery> {
  double _textScale = 1.0;
  bool _selected = true;
  bool _switched = true;
  bool _checked = true;
  bool _done = false;
  String _segment = 'a';
  String _tab = 'a';
  String _sort = 'a';
  LumeSortDirection _sortDir = LumeSortDirection.ascending;
  final Set<String> _chips = <String>{'all'};

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(_textScale)),
      child: Scaffold(
        backgroundColor: lume.bg,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _GalleryBar(
                textScale: _textScale,
                onTextScale: (double v) => setState(() => _textScale = v),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: LumeSpace.x10),
                  children: <Widget>[
                    _measure(_actions()),
                    _measure(_inputs()),
                    _measure(_selection()),
                    _measure(_surfaces()),
                    _measure(_rows()),
                    _measure(_values()),
                    _measure(_status()),
                    _measure(_states()),
                    _measure(_crud()),
                    _measure(_progress()),
                    _measure(_dataDisplay()),
                    _measure(_today()),
                    _measure(_explore()),
                    _measure(_chrome()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _measure(Widget child) => LumeMeasure(child: child);

  // ---- Groups -----------------------------------------------------------

  // ---- Today and Explore -------------------------------------------------

  Widget _today() => _Group(
    title: 'Today',
    note:
        'The day as a plan: a ring, three figures, a timeline, a list, a strip '
        'of habits and a locked door.',
    children: <Widget>[
      _Case(
        'Ring: empty, part way, done',
        Row(
          children: <Widget>[
            for (final (double, String) cell in <(double, String)>[
              (0.0, '0%'),
              (0.7, '70%'),
              (1.0, '100%'),
            ])
              Padding(
                padding: const EdgeInsetsDirectional.only(end: LumeSpace.x3),
                child: LumeDayRing(
                  fraction: cell.$1,
                  label: cell.$2,
                  unit: 'of day',
                ),
              ),
          ],
        ),
      ),
      const _Case(
        'Ring card',
        LumeRingCard(
          ring: LumeDayRing(fraction: 0.7, label: '70%', unit: 'of day'),
          title: 'On track',
          text: '3 of 5 tasks done, 2 meetings left',
        ),
      ),
      const _Case(
        'Statistics',
        LumeStatRowGrid(
          children: <Widget>[
            LumeStatCard(
              icon: LumeIcons.flame,
              value: '12',
              unit: ' days',
              label: 'Prayer streak',
            ),
            LumeStatCard(
              icon: LumeIcons.book,
              value: '18',
              unit: ' min',
              label: 'Read today',
            ),
            LumeStatCard(
              icon: LumeIcons.checkCircle,
              value: '3',
              unit: '/5',
              label: 'Tasks done',
            ),
          ],
        ),
      ),
      _Case(
        'Agenda: done, now, upcoming, last',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LumeAgendaRow(
              time: '12:07',
              title: 'Dhuhr',
              meta: 'Prayed',
              icon: LumeIcons.checkCircle,
              tone: LumeAgendaTone.done,
              onTap: () {},
            ),
            const LumeAgendaRow(
              time: '3:41 pm',
              title: 'Design review',
              meta: '45 min',
              icon: LumeIcons.users,
              tone: LumeAgendaTone.now,
            ),
            LumeAgendaRow(
              time: '6:27 pm',
              title: 'Maghrib',
              meta: 'Adhan on',
              icon: LumeIcons.moon,
              tone: LumeAgendaTone.upcoming,
              onTap: () {},
              isLast: true,
            ),
          ],
        ),
      ),
      _Case(
        'Tasks: ticked, not ticked, no time of its own',
        LumeCard(
          padded: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeTaskRow(
                label: 'Pay the electricity bill',
                done: true,
                time: '5:00 pm',
                onToggle: () {},
              ),
              LumeTaskRow(
                label: 'Reply to Amir',
                done: _done,
                time: '2:30 pm',
                onToggle: () => setState(() => _done = !_done),
              ),
              LumeTaskRow(
                label: 'Read Al-Kahf',
                done: false,
                time: 'Evening',
                onToggle: () {},
                isLast: true,
              ),
            ],
          ),
        ),
      ),
      const _Case(
        'Habits',
        LumeHabitCard(
          children: <Widget>[
            LumeHabitRow(
              name: 'Fajr',
              days: <bool>[true, true, false, true, true, true, true],
              streak: '5',
              todayIndex: 6,
              semanticLabel: 'Fajr, 6 of the last 7 days, 5 day streak',
            ),
            LumeHabitRow(
              name: 'Water',
              days: <bool>[false, true, true, false, true, false, false],
              streak: '0',
              todayIndex: 6,
              semanticLabel: 'Water, 3 of the last 7 days, no streak',
            ),
          ],
        ),
      ),
      _Case(
        'Private',
        LumePrivateCard(
          title: 'Health, documents and money',
          text:
              'Records, medication and expenses stay locked until you open '
              'them.',
          onTap: () {},
        ),
      ),
    ],
  );

  Widget _explore() => _Group(
    title: 'Explore',
    note:
        'What is around the reader. Every figure here is a fixture, and none '
        'of it is labelled live.',
    children: <Widget>[
      _Case(
        'Quote: with an ayah, and without',
        Column(
          children: <Widget>[
            LumeQuoteCard(
              arabic: 'وَمَن يَتَّقِ اللَّهَ',
              text: 'And whoever fears Allah, He will make for him a way out.',
              attribution: 'At-Talaq 65:2',
              actions: <LumeCardAction>[
                LumeCardAction(
                  icon: LumeIcons.bookmark,
                  semanticLabel: 'Bookmark',
                  selected: true,
                  onPressed: () {},
                ),
                LumeCardAction(
                  icon: LumeIcons.share,
                  semanticLabel: 'Share',
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: LumeSpace.x3),
            const LumeQuoteCard(
              text: 'Small steps, taken daily, are still a road.',
              attribution: 'Lume',
            ),
          ],
        ),
      ),
      _Case(
        'Featured: the two collections',
        Column(
          children: <Widget>[
            LumeFeatureCard(
              tag: 'Featured',
              title: 'Duas for every day',
              text: 'Morning, evening and the small moments in between.',
              meta: const <String>['40 duas', 'With audio', '12 min'],
              art: const LumeFeaturedArt(id: LumeFeatureId.duas),
              onTap: () {},
            ),
            const SizedBox(height: LumeSpace.x3),
            LumeFeatureCard(
              tag: 'Featured',
              title: 'A calmer week',
              text: 'Seven small habits, three minutes each.',
              meta: const <String>['7 days', '3 min each', 'Free'],
              art: const LumeFeaturedArt(id: LumeFeatureId.calmWeek),
              onTap: () {},
            ),
          ],
        ),
      ),
      const _Case(
        'Weather',
        LumeWeatherCard(
          icon: LumeIcons.sun,
          temperature: '34',
          degreeSign: '°',
          description: 'Hazy sun, humid, feels 38°',
          stats: <LumeWeatherStat>[
            LumeWeatherStat(
              icon: LumeIcons.droplet,
              value: '8%',
              semanticLabel: 'Rain 8 per cent',
            ),
            LumeWeatherStat(
              icon: LumeIcons.wind,
              value: '11 km/h',
              semanticLabel: 'Wind 11 kilometres an hour',
            ),
            LumeWeatherStat(
              icon: LumeIcons.moon,
              value: '6:27 pm',
              semanticLabel: 'Sunset 6:27 pm',
            ),
          ],
        ),
      ),
      _Case(
        'List rows: with a value, without one, and last',
        LumeCard(
          padded: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeListRow(
                icon: LumeIcons.fuel,
                title: 'Fuel Prices',
                subtitle: 'Petrol, Hi-Octane, Diesel',
                value: 'Rs 264.61',
                onTap: () {},
              ),
              LumeListRow(
                icon: LumeIcons.train,
                title: 'Trains',
                subtitle: 'Green Line Express, on time',
                onTap: () {},
              ),
              LumeListRow(
                icon: LumeIcons.shield,
                title: 'Emergency',
                subtitle: 'Rescue 1122',
                value: '1122',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
        ),
      ),
      _Case(
        'Articles: the three tones',
        LumeCard(
          padded: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final LumeArticleTone tone in LumeArticleTone.values)
                LumeArticleRow(
                  category: 'Business',
                  title: 'What the new fuel prices mean',
                  meta: '2 h ago',
                  art: LumeArticleArt(tone: tone),
                  onTap: () {},
                  isLast: tone == LumeArticleTone.values.last,
                ),
            ],
          ),
        ),
      ),
      _Case(
        'Score',
        LumeScoreCard(
          homeTeam: 'PAK',
          homeRuns: '287',
          homeWickets: '/4',
          homeOvers: '78.2 ov',
          awayTeam: 'ENG',
          awayRuns: '374',
          awayOvers: '112.5 ov',
          note: 'Pakistan trail by 87 runs',
          versus: 'vs',
          onTap: () {},
        ),
      ),
      const _Case(
        'Collection art, and the sticker',
        Row(
          children: <Widget>[
            SizedBox(
              width: 74,
              height: 74,
              child: LumeCollectionArt(id: 'nightSurahs'),
            ),
            SizedBox(width: LumeSpace.x3),
            SizedBox(
              width: 74,
              height: 74,
              child: LumeCollectionArt(id: 'focus'),
            ),
            SizedBox(width: LumeSpace.x3),
            LumeTodaySticker(),
          ],
        ),
      ),
    ],
  );

  Widget _actions() => _Group(
    title: 'Actions',
    note:
        'A button is 46 tall in every tone. The small variant is narrower, '
        'not shorter.',
    children: <Widget>[
      _Case('accent', LumeButton.accent(label: 'Save', onPressed: () {})),
      _Case('ghost', LumeButton(label: 'Cancel', onPressed: () {})),
      _Case('danger', LumeButton.danger(label: 'Delete', onPressed: () {})),
      _Case(
        'with an icon',
        LumeButton.accent(
          label: 'Continue',
          trailingIcon: LumeIcons.arrowR,
          onPressed: () {},
        ),
      ),
      _Case('small', LumeButton(label: 'Edit', small: true, onPressed: () {})),
      _Case(
        'block',
        LumeButton.accent(label: 'Continue', block: true, onPressed: () {}),
      ),
      const _Case('disabled', LumeButton.accent(label: 'Save')),
      const _Case(
        'busy — keeps its label and its size',
        LumeButton.accent(label: 'Save', busy: true, busyLabel: 'Saving…'),
      ),
      _Case(
        'icon button',
        LumeIconButton(icon: LumeIcons.share, label: 'Share', onPressed: () {}),
      ),
      _Case(
        'icon button with a badge',
        LumeIconButton(
          icon: LumeIcons.bell,
          label: 'Notifications',
          badge: true,
          onPressed: () {},
        ),
      ),
      _Case('text button', LumeTextButton(label: 'Save', onPressed: () {})),
      _Case('floating action', LumeFab(label: 'Add', onPressed: () {})),
      _Case(
        'floating action with a label',
        LumeFab(label: 'Add expense', showLabel: true, onPressed: () {}),
      ),
      _Case(
        'button row',
        LumeButtonRow(
          children: <Widget>[
            LumeButton(label: 'Cancel', onPressed: () {}),
            LumeButton.accent(label: 'Save', onPressed: () {}),
          ],
        ),
      ),
    ],
  );

  Widget _inputs() => _Group(
    title: 'Inputs',
    note:
        'Two field systems: a dense tool field at 42, and a record form '
        'field at 48. Both are here because they are different components.',
    children: <Widget>[
      const _Case('search', LumeSearchField(placeholder: 'Search')),
      const _Case(
        'tool field',
        LumeToolField(
          label: 'Amount',
          prefix: 'PKR',
          hint: 'Up to two decimals',
        ),
      ),
      const _Case(
        'form field',
        LumeFormField(label: 'Title', hint: 'What you spent it on'),
      ),
      const _Case(
        'form field — optional',
        LumeFormField(label: 'Note', optionalLabel: 'Optional'),
      ),
      const _Case(
        'form field — invalid',
        LumeFormField(label: 'Amount', error: 'Enter an amount above zero'),
      ),
      const _Case(
        'form field — disabled',
        LumeFormField(label: 'Currency', value: 'PKR', enabled: false),
      ),
      const _Case(
        'text area',
        LumeFormField(label: 'Notes', kind: LumeFieldKind.multiline),
      ),
      const _Case(
        'money field',
        LumeFormField(label: 'Amount', kind: LumeFieldKind.money, prefix: 'Rs'),
      ),
      _Case(
        'checkbox',
        LumeCheckbox(
          label: 'Remind me the day before',
          value: _checked,
          onChanged: (bool v) => setState(() => _checked = v),
        ),
      ),
      _Case(
        'radio rows',
        Column(
          children: <Widget>[
            LumeRadioRow(
              label: 'Automatic',
              subtitle: 'Follows your country',
              selected: _selected,
              onTap: () => setState(() => _selected = true),
            ),
            LumeRadioRow(
              label: 'Metric',
              selected: !_selected,
              onTap: () => setState(() => _selected = false),
            ),
          ],
        ),
      ),
      _Case(
        'switch',
        LumeSwitch(
          value: _switched,
          semanticLabel: 'Islamic features',
          onChanged: (bool v) => setState(() => _switched = v),
        ),
      ),
      _Case(
        'stepper',
        LumeStepper(
          label: 'People',
          value: '4',
          onDecrement: () {},
          onIncrement: () {},
        ),
      ),
    ],
  );

  Widget _selection() => _Group(
    title: 'Selection',
    note:
        'The selected segment is a raised thumb; the selected tab is an '
        'underline. They are different controls, not one with a flag.',
    children: <Widget>[
      _Case(
        'filter chips',
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final (String id, String label) in <(String, String)>[
              ('all', 'Everything'),
              ('food', 'Food'),
              ('bills', 'Bills'),
            ])
              LumeFilterChip(
                label: label,
                selected: _chips.contains(id),
                onTap: () => setState(() {
                  _chips.contains(id) ? _chips.remove(id) : _chips.add(id);
                }),
              ),
          ],
        ),
      ),
      _Case(
        'filter bar — a scrolling rail of chips',
        LumeFilterBar(
          gutters: false,
          children: <Widget>[
            for (final String l in <String>[
              'Everything',
              'Food',
              'Bills',
              'Transport',
              'Health',
              'Giving',
            ])
              LumeFilterChip(
                label: l,
                selected: _chips.contains(l),
                onTap: () => setState(() {
                  _chips.contains(l) ? _chips.remove(l) : _chips.add(l);
                }),
              ),
          ],
        ),
      ),
      _Case(
        'record chips with counts',
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            LumeRecordChip(
              label: 'All',
              count: 34,
              selected: true,
              onTap: () {},
            ),
            LumeRecordChip(label: 'Food', count: 12, onTap: () {}),
          ],
        ),
      ),
      _Case(
        'segmented',
        LumeSegmented(
          items: const <LumeChoice>[
            LumeChoice(value: 'a', label: 'Week'),
            LumeChoice(value: 'b', label: 'Month'),
            LumeChoice(value: 'c', label: 'Year'),
          ],
          value: _segment,
          onChanged: (String v) => setState(() => _segment = v),
        ),
      ),
      _Case(
        'tabs',
        LumeTabs(
          items: const <LumeChoice>[
            LumeChoice(value: 'a', label: 'All', count: 34),
            LumeChoice(value: 'b', label: 'Due', count: 3),
            LumeChoice(value: 'c', label: 'Done'),
          ],
          value: _tab,
          onChanged: (String v) => setState(() => _tab = v),
        ),
      ),
      _Case(
        'sort bar — press the active one to reverse it',
        LumeSortBar(
          label: 'Sort',
          items: const <LumeChoice>[
            LumeChoice(value: 'a', label: 'Name'),
            LumeChoice(value: 'b', label: 'Date'),
            LumeChoice(value: 'c', label: 'Amount'),
          ],
          value: _sort,
          direction: _sortDir,
          onChanged: (String v, LumeSortDirection d) => setState(() {
            _sort = v;
            _sortDir = d;
          }),
        ),
      ),
    ],
  );

  Widget _surfaces() => _Group(
    title: 'Surfaces',
    children: <Widget>[
      const _Case('card', LumeCard(child: Text('A card'))),
      const _Case(
        'note card — info',
        LumeNoteCard(
          title: 'Saved on this device',
          text: 'Nothing here is sent anywhere.',
        ),
      ),
      const _Case(
        'note card — warning',
        LumeNoteCard(
          title: 'Rates are indicative',
          text: 'Your bank may differ.',
          tone: LumeNoteTone.warn,
        ),
      ),
      _Case(
        'section — header plus body, with the page gutters',
        LumeSection(
          gutters: false,
          title: 'Recent expenses',
          subtitle: 'The last seven days',
          link: 'See all',
          onLinkTap: () {},
          child: const LumeCard(child: Text('The section body')),
        ),
      ),
      _Case(
        'section header',
        LumeSectionHeader(
          title: 'Recent expenses',
          subtitle: 'The last seven days',
          link: 'See all',
          onLinkTap: () {},
        ),
      ),
    ],
  );

  Widget _rows() => _Group(
    title: 'Rows',
    note:
        'Rich and compact rows share a grouping card. A record row is its '
        'own card, which is why record lists are stacks rather than tables.',
    children: <Widget>[
      _Case(
        'rich rows in a card',
        LumeRows(
          children: <Widget>[
            LumeRichRow(
              title: 'USD',
              subtitle: 'US Dollar',
              meta: const <String>['Buy 277.10', 'Sell 279.40'],
              value: '278.50',
              logo: '\$',
              delta: const LumeDelta(
                text: '0.4%',
                direction: LumeDeltaDirection.up,
              ),
              onTap: () {},
              chevron: true,
            ),
            LumeRichRow(
              title: 'Gold 24k',
              subtitle: 'Per tola',
              value: '284,300',
              icon: LumeIcons.coins,
              badge: const LumeBadge(label: 'Live', tone: LumeBadgeTone.live),
              onTap: () {},
            ),
          ],
        ),
      ),
      _Case(
        'compact rows',
        LumeRows(
          children: <Widget>[
            const LumeCompactRow(
              label: 'Fajr',
              value: '05:12',
              icon: LumeIcons.clock,
            ),
            LumeCompactRow(label: 'Dhuhr', value: '12:04', onTap: () {}),
          ],
        ),
      ),
      _Case(
        'record rows',
        LumeRecordList(
          children: <Widget>[
            LumeRecordRow(
              title: 'Groceries',
              subtitle: 'Food and drink',
              meta: const <String>['Today', 'Cash'],
              value: '1,240',
              initial: 'G',
              onTap: () {},
            ),
            LumeRecordRow(
              title: 'Electricity',
              initial: 'E',
              value: '8,900',
              badge: const LumeBadge(label: 'Due', tone: LumeBadgeTone.warn),
              selected: true,
              onTap: () {},
            ),
            LumeRecordRow(
              title: 'Take the bins out',
              done: _done,
              onToggle: (bool v) => setState(() => _done = v),
            ),
            const LumeRecordRow(
              title: 'Water logged offline',
              initial: 'W',
              queuedLabel: 'Queued',
            ),
          ],
        ),
      ),
      const _Case(
        'expandable row',
        LumeCard(
          padded: false,
          child: LumeExpandRow(
            header: Text('How this is calculated'),
            child: Text('The breakdown lives here.'),
          ),
        ),
      ),
    ],
  );

  Widget _values() => const _Group(
    title: 'Values',
    children: <Widget>[
      _Case(
        'summary card',
        LumeSummaryCard(
          kicker: 'Spent this month',
          value: '124,500',
          unit: 'PKR',
          caption: 'Across 34 expenses',
          stats: <LumeStat>[
            LumeStat(value: '34', label: 'Expenses'),
            LumeStat(value: '9', label: 'Categories'),
          ],
        ),
      ),
      _Case(
        'metrics',
        LumeMetrics(
          children: <Widget>[
            LumeMetric(value: '128', label: 'Completed', icon: LumeIcons.check),
            LumeMetric(value: '12', label: 'Due', icon: LumeIcons.clock),
            LumeMetric(
              value: '3',
              label: 'Overdue',
              icon: LumeIcons.alert,
              delta: LumeDelta(text: '2', direction: LumeDeltaDirection.down),
            ),
          ],
        ),
      ),
      _Case(
        'record hero',
        LumeRecordHero(
          kicker: 'Expense',
          value: '1,240',
          title: 'Groceries',
          caption: 'Monday, 7 September',
        ),
      ),
      _Case(
        'fact card',
        LumeCard(
          child: LumeFactCard(
            facts: <LumeFact>[
              LumeFact(label: 'Category', value: 'Food and drink'),
              LumeFact(label: 'Date', value: 'Monday, 7 September'),
              LumeFact(
                label: 'Note',
                value: 'Weekly shop, plus something for the neighbours.',
                block: true,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _status() => const _Group(
    title: 'Status',
    note: 'Every one of these carries a glyph or a shape as well as a colour.',
    children: <Widget>[
      _Case(
        'badges',
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            LumeBadge(label: 'Draft'),
            LumeBadge(label: 'Live', tone: LumeBadgeTone.live),
            LumeBadge(label: 'Paid', tone: LumeBadgeTone.ok),
            LumeBadge(label: 'Due', tone: LumeBadgeTone.warn),
            LumeBadge(label: 'Overdue', tone: LumeBadgeTone.late_),
            LumeBadge(label: 'Off', tone: LumeBadgeTone.off),
          ],
        ),
      ),
      _Case(
        'deltas',
        Wrap(
          spacing: 12,
          children: <Widget>[
            LumeDelta(text: '2.4%', direction: LumeDeltaDirection.up),
            LumeDelta(text: '1.1%', direction: LumeDeltaDirection.down),
            LumeDelta(text: '0.0%', direction: LumeDeltaDirection.flat),
          ],
        ),
      ),
      _Case(
        'freshness',
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: <Widget>[
            LumeFreshness(label: 'Live'),
            LumeFreshness(
              label: 'Delayed 15 min',
              quality: LumeFreshnessQuality.delayed,
            ),
            LumeFreshness(
              label: 'Cached',
              quality: LumeFreshnessQuality.cached,
            ),
          ],
        ),
      ),
      _Case(
        'source line',
        LumeSourceLine(
          source: 'State Bank of Pakistan',
          updated: '5 minutes ago',
          note: 'Indicative',
        ),
      ),
    ],
  );

  Widget _states() => _Group(
    title: 'States',
    note: 'Every state the CRUD guide asks for, and none of them a blank card.',
    children: <Widget>[
      const _Case('skeleton — rows', LumeSkeleton(count: 3)),
      const _Case('skeleton — card', LumeSkeleton(kind: LumeSkeletonKind.card)),
      _Case(
        'tool state — empty',
        LumeToolState(
          title: 'Nothing to show yet',
          text: 'Add your first record.',
          action: LumeButton.accent(label: 'Add', onPressed: () {}),
        ),
      ),
      _Case(
        'tool state — error',
        LumeToolState.error(
          title: 'We could not load this',
          text: 'Check your connection.',
          action: LumeButton.accent(
            label: 'Try again',
            icon: LumeIcons.refresh,
            onPressed: () {},
          ),
        ),
      ),
      _Case(
        'collection — empty',
        LumeCollectionState(
          kind: LumeCollectionStateKind.empty,
          title: 'Nothing on your list',
          text: 'Add a task and it will show up here and on Today.',
          primaryAction: LumeButton.accent(
            label: 'Add a task',
            onPressed: () {},
          ),
        ),
      ),
      _Case(
        'collection — no results',
        LumeCollectionState(
          kind: LumeCollectionStateKind.noResults,
          title: 'No matches',
          text: 'Nothing matches “rent” in this month.',
          primaryAction: LumeButton(label: 'Clear search', onPressed: () {}),
        ),
      ),
      _Case(
        'collection — load error',
        LumeCollectionState(
          kind: LumeCollectionStateKind.error,
          title: 'We could not load your expenses',
          text: 'Check your connection and try again.',
          primaryAction: LumeButton.accent(
            label: 'Try again',
            onPressed: () {},
          ),
          secondaryAction: LumeButton(
            label: 'Show saved records',
            onPressed: () {},
          ),
          footnote: 'Your saved data is still safe on this device.',
        ),
      ),
      _Case(
        'notice — save failure',
        LumeNotice(
          kind: LumeNoticeKind.error,
          title: 'Could not save changes',
          text: 'Nothing you typed was lost.',
          actions: <Widget>[
            LumeNoticeAction(label: 'Try again', onPressed: () {}),
          ],
        ),
      ),
      _Case(
        'notice — conflict',
        LumeNotice(
          kind: LumeNoticeKind.warning,
          title: 'This record changed elsewhere',
          text: 'A newer version exists. Review yours, or reload theirs.',
          actions: <Widget>[
            LumeNoticeAction(label: 'Review', onPressed: () {}),
            LumeNoticeAction(label: 'Reload', onPressed: () {}),
          ],
        ),
      ),
      const _Case(
        'offline',
        LumeOfflineBanner(
          title: 'You are offline',
          text: 'Showing records saved on this device.',
        ),
      ),
      _Case(
        'private',
        LumePrivateState(
          title: 'Health, documents and money',
          text: 'Only on this device, only for you.',
          revealLabel: 'Show',
          onReveal: () {},
        ),
      ),
      const _Case('toast', LumeToast(data: LumeToastData(message: 'Saved'))),
      _Case(
        'toast with undo',
        LumeToast(
          data: LumeToastData(
            message: 'Expense deleted',
            actionLabel: 'Undo',
            onAction: () {},
          ),
        ),
      ),
    ],
  );

  Widget _crud() => _Group(
    title: 'CRUD',
    children: <Widget>[
      const _Case('list count', LumeListCount(label: '34 expenses')),
      const _Case('record id', LumeRecordId(label: 'Added 7 Sep · #1024')),
      _Case(
        'detail actions',
        LumeDetailActions(
          editLabel: 'Edit',
          onEdit: () {},
          deleteLabel: 'Delete',
          onDelete: () {},
        ),
      ),
      const _Case(
        'form card',
        LumeFormCard(
          title: 'New expense',
          children: <Widget>[
            LumeFormField(label: 'What was it?'),
            LumeFormField(label: 'Amount', kind: LumeFieldKind.money),
          ],
        ),
      ),
      _Case(
        'submit bar',
        LumeSubmitBar(
          saveLabel: 'Save expense',
          onSave: () {},
          cancelLabel: 'Cancel',
          onCancel: () {},
          note: 'Saved on this device only.',
        ),
      ),
      const _Case(
        'submit bar — saving',
        LumeSubmitBar(
          saveLabel: 'Save expense',
          busy: true,
          busyLabel: 'Saving…',
          cancelLabel: 'Cancel',
        ),
      ),
      _Case(
        'delete — recoverable',
        LumeCard(
          child: LumeDeleteConfirmation(
            title: 'Delete Groceries?',
            consequence: 'You can undo this straight afterwards.',
            confirmLabel: 'Delete',
            cancelLabel: 'Keep it',
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      ),
      _Case(
        'delete — irreversible',
        LumeCard(
          child: LumeDeleteConfirmation(
            title: 'Delete Passport?',
            consequence: 'This cannot be undone, and there is no copy.',
            confirmLabel: 'Delete permanently',
            cancelLabel: 'Keep it',
            kind: LumeDeleteKind.irreversible,
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      ),
      const _Case(
        'master-detail',
        SizedBox(
          height: 160,
          child: LumeMasterDetail(
            list: LumeCard(child: Text('The list pane')),
            detail: LumeCollectionState(
              kind: LumeCollectionStateKind.pane,
              title: 'Select a record',
              text: 'Choose one from the list to see it here.',
            ),
          ),
        ),
      ),
      const _Case(
        'sheet',
        LumeSheet(
          title: 'Choose a category',
          child: Text('The body of the sheet.'),
        ),
      ),
    ],
  );

  Widget _progress() => _Group(
    title: 'Progress',
    children: <Widget>[
      const _Case('bar', LumeProgressBar(value: 0.4, label: 'Water')),
      const _Case(
        'meter row',
        LumeMeterRow(
          label: 'Water today',
          value: '6 of 10',
          progress: 0.6,
          footnote: 'Two more before bed keeps the streak.',
        ),
      ),
      _Case(
        'ring',
        LumeProgressRing(
          value: 0.65,
          label: 'Read',
          centre: Text(
            '65%',
            style: LumeType.numeric(
              LumeType.fit(context, context.lumeType.cardTitle),
            ).copyWith(color: context.lume.text),
          ),
        ),
      ),
      const _Case(
        'segmented progress',
        LumeSegmentedProgress(total: 9, completed: 4),
      ),
      const _Case(
        'journey',
        LumeJourney(
          steps: <LumeJourneyStep>[
            LumeJourneyStep(label: 'Sent', done: true),
            LumeJourneyStep(label: 'In transit', current: true),
            LumeJourneyStep(label: 'Out for delivery'),
            LumeJourneyStep(label: 'Delivered'),
          ],
        ),
      ),
      const _Case(
        'timeline',
        LumeTimeline(
          entries: <LumeTimelineEntry>[
            LumeTimelineEntry(
              time: '09:00',
              title: 'Depart Lahore',
              subtitle: 'Platform 3',
              state: LumeTimelineState.done,
            ),
            LumeTimelineEntry(
              time: '11:20',
              title: 'Faisalabad',
              state: LumeTimelineState.now,
            ),
            LumeTimelineEntry(time: '13:40', title: 'Arrive Islamabad'),
          ],
        ),
      ),
    ],
  );

  Widget _dataDisplay() => _Group(
    title: 'Data display',
    children: <Widget>[
      const _Case(
        'table',
        LumeTable(
          label: 'Prayer times',
          columns: <LumeColumn>[
            LumeColumn(label: 'Prayer', strong: true),
            LumeColumn(label: 'Begins', numeric: true),
            LumeColumn(label: 'Jamaat', numeric: true),
          ],
          rows: <List<String>>[
            <String>['Fajr', '05:12', '05:40'],
            <String>['Dhuhr', '12:04', '13:15'],
            <String>['Asr', '15:31', '16:00'],
          ],
        ),
      ),
      _Case(
        'image cards',
        LumeHorizontalStrip(
          gutters: false,
          children: <Widget>[
            LumeImageCard(
              title: 'What the new fuel prices mean',
              kicker: 'News',
              meta: '4 min read',
              seed: 3,
              onTap: () {},
            ),
            LumeImageCard(
              title: 'A quieter way to plan the week',
              kicker: 'Guide',
              meta: '6 min read',
              seed: 7,
              onTap: () {},
            ),
          ],
        ),
      ),
      _Case(
        'related tools',
        LumeRelatedTools(
          tools: const <LumeRelatedTool>[
            LumeRelatedTool(
              id: 'calculator',
              name: 'Calculator',
              icon: LumeIcons.calculator,
            ),
            LumeRelatedTool(
              id: 'converter',
              name: 'Unit Converter',
              icon: LumeIcons.ruler,
            ),
            LumeRelatedTool(
              id: 'currency',
              name: 'Currency',
              icon: LumeIcons.currency,
            ),
          ],
          onOpen: (_) {},
        ),
      ),
    ],
  );

  Widget _chrome() => _Group(
    title: 'Chrome',
    children: <Widget>[
      _Case(
        'toolbar',
        LumeToolbar(
          title: 'Currency and gold',
          subtitle: 'Live interbank rates',
          onBack: () {},
          actions: <Widget>[
            LumeIconButton(
              icon: LumeIcons.share,
              label: 'Share',
              onPressed: () {},
            ),
          ],
        ),
      ),
      const _Case(
        'context bar',
        LumeContextBar(
          gutters: false,
          items: <LumeContextItem>[
            LumeContextItem(label: 'Islamabad', icon: LumeIcons.pin),
            LumeContextItem(label: 'PKR'),
          ],
        ),
      ),
      _Case('back button', LumeBackButton(onPressed: () {})),
      const _Case('back button — disabled', LumeBackButton()),
    ],
  );
}

/// The gallery's own chrome. Theme, language and text scale, so every axis is
/// checkable without a rebuild.
class _GalleryBar extends ConsumerWidget {
  const _GalleryBar({required this.textScale, required this.onTextScale});

  final double textScale;
  final ValueChanged<double> onTextScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LumeColors lume = context.lume;
    final ThemeMode mode = ref.watch(themeModeProvider);
    final Locale? locale = ref.watch(localeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LumeSpace.pageCompact,
        vertical: LumeSpace.x3,
      ),
      decoration: BoxDecoration(
        color: lume.card,
        border: Border(
          bottom: BorderSide(color: lume.border, width: LumeSpace.border),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: LumeSpace.x2,
        runSpacing: LumeSpace.x2,
        children: <Widget>[
          Text(
            'Components · ${context.widthClass.name}',
            style: context.lumeType.section.copyWith(color: lume.text),
          ),
          LumeFilterChip(
            label: mode == ThemeMode.dark ? 'Dark' : 'Light',
            icon: mode == ThemeMode.dark ? LumeIcons.moon : LumeIcons.sun,
            onTap: () => ref.read(themeModeProvider.notifier).state =
                mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
          ),
          LumeFilterChip(
            label: LumeLocales.forCode(locale?.languageCode ?? 'en').native,
            icon: LumeIcons.globe,
            onTap: () {
              const List<String> codes = <String>['en', 'ur', 'ar'];
              final int i = codes.indexOf(locale?.languageCode ?? 'en');
              ref.read(localeProvider.notifier).state = Locale(
                codes[(i + 1) % codes.length],
              );
            },
          ),
          LumeFilterChip(
            label: '${(textScale * 100).round()}%',
            icon: LumeIcons.ruler,
            onTap: () =>
                onTextScale(textScale >= 2.0 ? 1.0 : (textScale + 0.5)),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children, this.note});

  final String title;
  final String? note;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Padding(
      padding: const EdgeInsets.only(top: LumeSpace.gapSection),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            LumeType.overline(context, title),
            style: LumeType.overlineStyle(
              context,
              context.lumeType,
            ).copyWith(color: lume.accent700),
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: LumeSpace.x1),
            Text(
              note!,
              style: LumeType.fit(
                context,
                context.lumeType.metaSmall,
              ).copyWith(color: lume.text3),
            ),
          ],
          const SizedBox(height: LumeSpace.x3),
          ...children,
        ],
      ),
    );
  }
}

class _Case extends StatelessWidget {
  const _Case(this.label, this.child);

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Padding(
      padding: const EdgeInsets.only(bottom: LumeSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text3),
          ),
          const SizedBox(height: 6),
          Align(alignment: AlignmentDirectional.centerStart, child: child),
        ],
      ),
    );
  }
}

/// A tiny helper the gallery bar uses so its icon stays a Lume icon.
class GalleryGlyph extends StatelessWidget {
  const GalleryGlyph(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) =>
      LumeIcon(name, color: context.lume.text2);
}
