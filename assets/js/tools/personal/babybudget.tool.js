/* ============================================================
   Lume — babybudget

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'babybudget',

  /* ---------------------------------------------------------
     §71 Baby budget · §74 Cycle · §75 Pregnancy
     --------------------------------------------------------- */
  build: function (c) {
    var b = c.babyBudget();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('baby.monthly'),
        value: c.money(b.monthly),
        caption: c.t('baby.vsPlan', { pct: Math.round(b.ratio * 100) + '%' }),
        aside: UI.progressRing({ value: b.ratio, centre: Math.round(b.ratio * 100) + '%', label: c.t('baby.plan') })
      }) }) +
      UI.section({ title: c.t('baby.categories'), body: UI.card(UI.donut({
        label: c.t('baby.categories'), centre: c.money(b.monthly), centreSub: c.t('common.perMonth'),
        slices: b.categories
      })) }) +
      UI.section({ title: c.t('baby.trend'), body: UI.card(
        UI.barChart({ values: b.trend, labels: b.trendLabels, highlight: b.trend.length - 1,
          label: c.t('baby.trend'), caption: c.t('baby.trendCap') })) }) +
      UI.section({ title: c.t('baby.upcoming'), body: UI.rows(b.upcoming.map(function (x) {
        return UI.compactRow({ icon: 'i-baby', label: x.label, sub: x.when, value: c.money(x.amount) });
      })) }) +
      UI.section({ title: c.t('baby.oneOff'), body: UI.rows(b.oneOff.map(function (x) {
        return UI.compactRow({ icon: 'i-cart', label: x.label, sub: x.when, value: c.money(x.amount) });
      })) });
  }
};
