/* ============================================================
   Lume — prayer

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'prayer',

  /* ---------------------------------------------------------
     24.1 Prayer Times — spiritual dashboard, high density
     --------------------------------------------------------- */
  build: function (c) {
    var set = c.prayerTimes();
    var st = c.prayerState();
    var sun = c.sunTimes();

    var hero = UI.summaryCard({
      tone: 'prayer',
      kicker: c.t('prayer.next'),
      value: UI.esc(c.t('prayer.' + st.next.key)),
      unit: c.time(st.next.h, st.next.m),
      caption: '<span class="summary__count" data-prayer-count>' + UI.esc(st.countdown) + '</span>',
      aside: UI.progressRing({ value: st.progress, centre: st.pctLabel, label: c.t('prayer.progress') }),
      foot: UI.progressBar({ value: st.progress, label: c.t('prayer.progress') })
    });

    /* The five-prayer timeline is the primary information block: what
       has passed, what is next, what remains (§24.1). */
    var line = UI.timeline(set.map(function (p, i) {
      var state = i < st.index ? 'done' : i === st.index ? 'now' : '';
      return {
        time: c.time(p.h, p.m),
        title: c.t('prayer.' + p.key),
        sub: i === st.index ? c.t('prayer.upnext') : (i < st.index ? c.t('prayer.passed') : ''),
        state: state,
        icon: i < st.index ? 'i-check' : null,
        value: i === st.index ? UI.statusBadge({ label: st.short, tone: 'live' }) : ''
      };
    }));

    var sunCard = UI.card(
      '<div class="duo">' +
        '<div class="duo__half"><span class="duo__icon">' + UI.ico('i-sun') + '</span>' +
          '<b>' + c.time(sun.sunrise.h, sun.sunrise.m) + '</b><i>' + UI.esc(c.t('sun.sunrise')) + '</i></div>' +
        '<div class="duo__half"><span class="duo__icon">' + UI.ico('i-moon') + '</span>' +
          '<b>' + c.time(sun.sunset.h, sun.sunset.m) + '</b><i>' + UI.esc(c.t('sun.sunset')) + '</i></div>' +
      '</div>');

    var method = UI.rows([
      UI.compactRow({ icon: 'i-sliders', label: c.t('prayer.method'), value: c.profile.method, act: 'sheet:personalise' }),
      UI.compactRow({ icon: 'i-scales', label: c.t('prayer.asrmethod'), value: c.t('prayer.asr.standard') }),
      UI.compactRow({ icon: 'i-pin', label: c.t('settings.location'), value: c.profile.city, act: 'sheet:personalise' }),
      UI.compactRow({ icon: 'i-globe', label: c.t('settings.timezone'), value: c.L.timezone() })
    ]);

    /* Upcoming days: three days of Fajr and Maghrib drift, which is what
       people actually plan around. */
    var upcoming = UI.table({
      label: c.t('prayer.upcoming'),
      cols: [{ label: c.t('common.day') }, { label: c.t('prayer.fajr'), align: 'right' },
             { label: c.t('prayer.dhuhr'), align: 'right' }, { label: c.t('prayer.maghrib'), align: 'right' }],
      rows: c.upcomingPrayerDays(4).map(function (d) {
        return { cells: [UI.esc(d.label), c.time(d.fajr.h, d.fajr.m), c.time(d.dhuhr.h, d.dhuhr.m),
                         c.time(d.maghrib.h, d.maghrib.m)] };
      })
    });

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: c.profile.city, act: 'sheet:personalise' },
        { label: c.dateLong(new Date()) },
        { label: c.hijri().label }
      ]) }) +
      UI.section({ body: hero }) +
      UI.section({ title: c.t('prayer.today'), body: line }) +
      UI.section({ title: c.t('sun.title'), body: sunCard }) +
      UI.section({ title: c.t('prayer.upcoming'), body: upcoming }) +
      UI.section({ title: c.t('prayer.settings'), body: method });
  }
};
