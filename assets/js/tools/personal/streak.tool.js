/* ============================================================
   Lume — streak

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'streak',

  build: function (c) {
    var s = c.streaks();
    return UI.section({ body: UI.summaryCard({
        tone: 'flame',
        kicker: c.t('streak.current'),
        value: s.current + ' <small>' + UI.esc(c.t('common.days')) + '</small>',
        caption: c.t('streak.best', { n: s.best }),
        stats: [
          { value: String(s.thisMonth), label: c.t('streak.thisMonth') },
          { value: Math.round(s.rate * 100) + '%', label: c.t('streak.rate') },
          { value: s.nextMilestone + '', label: c.t('streak.next') }
        ]
      }) }) +
      UI.section({ title: c.t('streak.calendar'), body: UI.card(
        UI.heatmap({ days: s.heat, label: c.t('streak.calendar'), less: c.t('common.less'), more: c.t('common.more') })) }) +
      UI.section({ title: c.t('streak.milestones'), body: UI.rows(s.milestones.map(function (m) {
        return UI.compactRow({ icon: m.done ? 'i-check-circle' : 'i-star', label: m.label,
          value: m.done ? c.t('common.done') : c.t('common.inDays', { n: m.inDays }) });
      })) });
  }
};
