/* ============================================================
   Lume — praytrack

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'praytrack',

  /* ---------------------------------------------------------
     24.4 Prayer Tracker — habit dashboard
     --------------------------------------------------------- */
  build: function (c) {
    var tr = c.prayerTracker();
    var set = c.prayerTimes();

    return UI.section({ body: UI.summaryCard({
        kicker: c.t('track.today'),
        value: tr.doneToday + ' <small>/ 5</small>',
        caption: c.t('track.streak', { n: tr.streak }),
        aside: UI.progressRing({ value: tr.doneToday / 5, centre: Math.round(tr.doneToday / 5 * 100) + '%', label: c.t('track.today') }),
        stats: [
          { value: tr.streak, label: c.t('track.streakLabel') },
          { value: Math.round(tr.month * 100) + '%', label: c.t('track.month') },
          { value: tr.qada, label: c.t('track.qada') }
        ]
      }) }) +
      UI.section({ title: c.t('track.mark'), body: UI.rows(set.map(function (p, i) {
        var done = i < tr.doneToday;
        return UI.richRow({
          icon: done ? 'i-check-circle' : 'i-prayer', iconTone: done ? 'accent' : null,
          title: c.t('prayer.' + p.key),
          sub: c.time(p.h, p.m),
          value: done ? UI.statusBadge({ label: c.t('track.done'), tone: 'ok' })
                      : UI.statusBadge({ label: c.t('track.pending'), tone: 'neutral' }),
          act: 'track:' + p.key
        });
      })) }) +
      UI.section({ title: c.t('track.heat'), body: UI.card(
        UI.heatmap({ days: tr.heat, label: c.t('track.heat'), less: c.t('common.less'), more: c.t('common.more') }),
        { pad: true }) }) +
      UI.section({ title: c.t('track.stats'), body: UI.card(
        UI.barChart({ values: tr.byPrayer, labels: ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
          label: c.t('track.byPrayer'), caption: c.t('track.byPrayerCap') })) }) +
      UI.section({ title: c.t('track.qadaPlan'), body: UI.card(
        UI.meterRow({ label: c.t('track.qadaOutstanding'), value: tr.qada + ' ' + c.t('track.prayers'),
          pct: 1 - tr.qada / 40, foot: c.t('track.qadaHint') }) +
        UI.buttonRow([{ label: c.t('track.logQada'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('track.qadaLogged') }])) });
  }
};
