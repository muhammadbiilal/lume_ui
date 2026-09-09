/* ============================================================
   Lume — learning

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'learning',

  build: function (c) {
    var l = c.learning();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('learning.thisWeek'),
        value: l.minutes + ' <small>' + UI.esc(c.t('unit.min')) + '</small>',
        caption: c.t('learning.streak', { n: l.streak }),
        aside: UI.progressRing({ value: l.weekPct, centre: Math.round(l.weekPct * 100) + '%', label: c.t('learning.goal') }),
        stats: [
          { value: String(D.COURSES.length), label: c.t('learning.courses') },
          { value: String(l.streak), label: c.t('learning.streakLabel') },
          { value: l.milestone, label: c.t('learning.milestone') }
        ]
      }) }) +
      UI.section({ title: c.t('learning.inProgress'), body: D.COURSES.map(function (x) {
        return UI.card(
          '<div class="course"><span class="course__icon course__icon--' + x.tone + '">' + UI.ico('i-graduation') + '</span>' +
          '<div class="course__body"><p class="course__name">' + UI.esc(x.name) + '</p>' +
          '<p class="course__meta">' + UI.esc(x.provider) + ' · ' + x.mins + ' ' + UI.esc(c.t('unit.min')) + '</p></div>' +
          '<span class="course__pct">' + Math.round(x.progress * 100) + '%</span></div>' +
          UI.progressBar({ value: x.progress, label: x.name }));
      }).join('') }) +
      UI.section({ title: c.t('learning.week'), body: UI.card(
        UI.barChart({ values: l.week, labels: c.weekLabels(), highlight: 6, label: c.t('learning.week') })) }) +
      UI.section({ title: c.t('learning.consistency'), body: UI.card(
        UI.heatmap({ days: l.heat, label: c.t('learning.consistency'),
          less: c.t('common.less'), more: c.t('common.more') })) }) +
      UI.section({ title: c.t('habits.insights'), body: UI.rows(l.insights.map(function (i) {
        return UI.richRow({ icon: i.icon, iconTone: 'accent', title: i.title, sub: i.text });
      })) });
  }
};
