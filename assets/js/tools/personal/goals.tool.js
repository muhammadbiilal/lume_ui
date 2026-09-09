/* ============================================================
   Lume — goals

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'goals',

  /* ---------------------------------------------------------
     §77 Savings goals — goal dashboard
     --------------------------------------------------------- */
  build: function (c) {
    var g = c.goals();
    if (!g.list.length) {
      return UI.section({ body: UI.emptyState({
        icon: 'i-target', title: c.t('goals.empty.title'), text: c.t('goals.empty.text'),
        action: { label: c.t('goals.create'), act: 'toast:' + c.t('goals.creating'), icon: 'i-plus' } }) });
    }
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('goals.saved'),
        value: c.money(g.saved),
        caption: c.t('goals.ofTarget', { target: c.money(g.target) }),
        aside: UI.progressRing({ value: g.ratio, centre: Math.round(g.ratio * 100) + '%', label: c.t('goals.progress') }),
        stats: [
          { value: String(g.list.length), label: c.t('goals.active') },
          { value: c.money(g.monthly), label: c.t('goals.monthly') },
          { value: g.nextComplete, label: c.t('goals.nextDone') }
        ]
      }) }) +
      UI.section({ title: c.t('goals.yours'), body: g.list.map(function (x) {
        return UI.card(
          '<div class="goal">' +
            '<span class="goal__icon goal__icon--' + x.tone + '">' + UI.ico(x.icon) + '</span>' +
            '<div class="goal__body">' +
              '<p class="goal__name">' + UI.esc(x.name) + '</p>' +
              '<p class="goal__meta">' + c.money(x.saved) + ' ' + UI.esc(c.t('common.of')) + ' ' + c.money(x.target) +
                ' · ' + UI.esc(c.t('goals.by', { date: x.by })) + '</p>' +
            '</div>' +
            '<span class="goal__pct">' + Math.round(x.pct * 100) + '%</span>' +
          '</div>' +
          UI.progressBar({ value: x.pct, label: x.name }) +
          '<p class="goal__foot">' + UI.esc(c.t('goals.remaining', { amount: c.money(x.target - x.saved) })) + ' · ' +
            UI.esc(c.t('goals.projection', { date: x.projected })) + '</p>');
      }).join('') }) +
      UI.section({ title: c.t('goals.contributions'), body: UI.card(
        UI.barChart({ values: g.history, labels: g.historyLabels, highlight: g.history.length - 1,
          label: c.t('goals.contributions') })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('goals.contribute'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('goals.contributing') },
        { label: c.t('common.share'), icon: 'i-share', act: 'share:goals' }]) });
  }
};
