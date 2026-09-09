/* ============================================================
   Lume — water

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'water',

  build: function (c) {
    var w = c.water();
    return UI.section({ body: UI.summaryCard({
        tone: 'sky',
        kicker: c.t('water.today'),
        value: w.consumedLabel,
        caption: c.t('water.ofTarget', { target: w.targetLabel }),
        aside: UI.progressRing({ value: w.pct, centre: Math.round(w.pct * 100) + '%', label: c.t('water.progress') }),
        stats: [
          { value: w.remainingLabel, label: c.t('water.remaining') },
          { value: String(w.glasses), label: c.t('water.glasses') },
          { value: String(w.streak), label: c.t('water.streak') }
        ]
      }) }) +
      UI.section({ body: UI.buttonRow([
        { label: '+ ' + w.unitSmall, tone: 'accent', icon: 'i-plus', act: 'water:small' },
        { label: '+ ' + w.unitLarge, icon: 'i-droplet', act: 'water:large' }]) }) +
      UI.section({ title: c.t('water.timeline'), body: UI.timeline(w.log.map(function (l) {
        return { time: l.at, title: l.amount, sub: l.kind, state: 'done', icon: 'i-droplet' };
      })) }) +
      UI.section({ title: c.t('water.week'), body: UI.card(
        UI.barChart({ values: w.week, labels: c.weekLabels(), highlight: 6,
          label: c.t('water.week'), max: w.target })) });
  }
};
