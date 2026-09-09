/* ============================================================
   Lume — pregnancy

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'pregnancy',

  build: function (c) {
    var p = c.pregnancy();
    return UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: c.t('pregnancy.week'),
        value: String(p.week),
        unit: '/ 40',
        caption: p.trimesterLabel + ' · ' + c.t('pregnancy.due', { date: p.dueDate }),
        aside: UI.progressRing({ value: p.week / 40, centre: Math.round(p.week / 40 * 100) + '%', label: c.t('pregnancy.progress') })
      }) }) +
      UI.section({ title: c.t('pregnancy.thisWeek'), body: UI.card(
        '<p class="kard__lead">' + UI.esc(p.note) + '</p>' +
        UI.metrics([
          { value: p.size, label: c.t('pregnancy.size') },
          { value: p.weight, label: c.t('pregnancy.weight') },
          { value: String(40 - p.week), label: c.t('pregnancy.weeksLeft') }
        ], 3)) }) +
      UI.section({ title: c.t('pregnancy.appointments'), body: UI.timeline(p.appointments.map(function (a) {
        return { time: a.when, title: a.title, sub: a.who, state: a.state };
      })) });
  }
};
