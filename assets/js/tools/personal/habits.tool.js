/* ============================================================
   Lume — habits

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'habits',

  /* ---------------------------------------------------------
     §62 Daily streak · §72 Habits · §73 Water
     --------------------------------------------------------- */
  build: function (c) {
    var h = c.habits();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('habits.today'),
        value: h.doneToday + ' <small>/ ' + h.list.length + '</small>',
        caption: c.t('habits.streak', { n: h.streak }),
        aside: UI.progressRing({ value: h.doneToday / h.list.length,
          centre: Math.round(h.doneToday / h.list.length * 100) + '%', label: c.t('habits.today') }),
        stats: [
          { value: String(h.streak), label: c.t('habits.currentStreak') },
          { value: String(h.best), label: c.t('habits.bestStreak') },
          { value: Math.round(h.rate * 100) + '%', label: c.t('habits.completion') }
        ]
      }) }) +
      UI.section({ title: c.t('habits.yours'), body: UI.card('<div class="habitgrid">' +
        h.list.map(function (x) {
          return '<div class="habitrow">' +
            '<span class="habitrow__name">' + UI.esc(x.name) + '</span>' +
            '<span class="habitrow__days">' + x.days.map(function (on, i) {
              return '<i class="habitrow__day' + (on ? ' is-on' : '') + (i === 6 ? ' is-today' : '') + '"></i>';
            }).join('') + '</span>' +
            '<span class="habitrow__streak">' + UI.ico('i-flame') + x.streak + '</span>' +
          '</div>';
        }).join('') + '</div>') }) +
      UI.section({ title: c.t('habits.month'), body: UI.card(
        UI.heatmap({ days: h.heat, label: c.t('habits.month'), less: c.t('common.less'), more: c.t('common.more') })) }) +
      UI.section({ title: c.t('habits.insights'), body: UI.rows(h.insights.map(function (i) {
        return UI.richRow({ icon: i.icon, iconTone: 'accent', title: i.title, sub: i.text });
      })) });
  }
};
