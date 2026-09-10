/* ============================================================
   Lume — ramadan

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'ramadan',

  /* ---------------------------------------------------------
     24.5 Ramadan — seasonal dashboard
     --------------------------------------------------------- */
  build: function (c) {
    var r = c.ramadan();
    var sun = c.sunTimes();
    var set = c.prayerTimes();

    if (!r.active) {
      return UI.section({ body: UI.summaryCard({
          tone: 'night',
          kicker: c.t('ramadan.countdown'),
          value: r.daysUntil + ' <small>' + UI.esc(c.t('common.days')) + '</small>',
          caption: c.t('ramadan.starts', { date: r.startLabel }),
          stats: [
            { value: r.hijriYear, label: c.t('ramadan.year') },
            { value: r.expectedFasts, label: c.t('ramadan.fasts') },
            { value: c.time(sun.sunset.h, sun.sunset.m), label: c.t('ramadan.iftarToday') }
          ]
        }) }) +
        UI.section({ title: c.t('ramadan.prepare'), body: UI.rows([
          UI.richRow({ icon: 'i-check-circle', title: c.t('ramadan.prep.qada'), sub: c.t('ramadan.prep.qadaSub'), act: 'tool:fasting', chevron: true }),
          UI.richRow({ icon: 'i-book', title: c.t('ramadan.prep.quran'), sub: c.t('ramadan.prep.quranSub'), act: 'tool:quran', chevron: true }),
          UI.richRow({ icon: 'i-wallet', title: c.t('ramadan.prep.zakat'), sub: c.t('ramadan.prep.zakatSub'), act: 'tool:zakat', chevron: true })
        ]) }) +
        UI.section({ title: c.t('ramadan.dates'), body: UI.rows(D.ISLAMIC_EVENTS.map(function (e) {
          return UI.compactRow({ icon: 'i-moon-star', label: e.name, sub: e.hijri, value: e.greg });
        })) });
    }

    return UI.section({ body: UI.summaryCard({
        tone: 'night',
        kicker: c.t('ramadan.day', { n: r.day }),
        value: c.time(sun.sunset.h, sun.sunset.m),
        caption: c.t('ramadan.iftarIn', { time: r.iftarIn }),
        stats: [
          { value: c.time(sun.sunrise.h - 1, 42), label: c.t('ramadan.suhoor') },
          { value: c.time(sun.sunset.h, sun.sunset.m), label: c.t('ramadan.iftar') },
          { value: (30 - r.day) + '', label: c.t('ramadan.remaining') }
        ]
      }) }) +
      UI.section({ title: c.t('ramadan.dayTimeline'), body: UI.timeline([
        { time: c.time(sun.sunrise.h - 1, 42), title: c.t('ramadan.suhoorEnds'),
          sub: c.t('ramadan.suhoorSub'), icon: 'i-moon', state: 'done' }
      ].concat(set.map(function (p) {
        var now = new Date().getHours() * 60 + new Date().getMinutes();
        return { time: c.time(p.h, p.m), title: c.t('prayer.' + p.key),
          state: p.h * 60 + p.m < now ? 'done' : '' };
      })).concat([
        { time: c.time(sun.sunset.h, sun.sunset.m), title: c.t('ramadan.iftar'),
          sub: c.t('ramadan.iftarSub'), icon: 'i-utensils', state: '' },
        { time: c.time(20, 45), title: c.t('f.taraweeh'), sub: c.t('ramadan.taraweehSub'),
          icon: 'i-prayer', state: '' }
      ])) }) +
      UI.section({ title: c.t('ramadan.month'), body: UI.card(
        UI.heatmap({ days: r.heat, label: c.t('ramadan.month'),
          less: c.t('common.less'), more: c.t('common.more') })) }) +
      UI.section({ title: c.t('ramadan.progress'), body: UI.card(
        UI.meterRow({ label: c.t('ramadan.fastsKept'), value: r.kept + ' / ' + r.day, pct: r.kept / Math.max(1, r.day) }) +
        UI.meterRow({ label: c.t('ramadan.quranJuz'), value: r.juz + ' / 30', pct: r.juz / 30 }) +
        UI.meterRow({ label: c.t('ramadan.charity'), value: c.money(r.charity) + ' / ' + c.money(r.charityGoal), pct: r.charity / r.charityGoal })) });
  }
};
