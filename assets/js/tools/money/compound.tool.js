/* ============================================================
   Lume — compound

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'compound',

  /* ---------------------------------------------------------
     §80 Compound interest — a premium addition with real maths
     --------------------------------------------------------- */
  build: function (c) {
    var k = c.compound();
    return UI.section({ id: 'inputs', title: c.t('tool.inputs'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('compound.initial'), name: 'ci_initial', type: 'number', value: k.f.initial, prefix: k.ccy }),
        UI.field({ label: c.t('compound.monthly'), name: 'ci_monthly', type: 'number', value: k.f.monthly, prefix: k.ccy }),
        UI.field({ label: c.t('compound.rate'), name: 'ci_rate', type: 'number', value: k.f.rate, suffix: '%', step: '0.1' }),
        UI.field({ label: c.t('compound.years'), name: 'ci_years', type: 'number', value: k.f.years, suffix: c.t('common.years') })
      ])) }) +
      UI.section({ body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('compound.finalValue'),
        value: '<span data-ci-total>' + c.moneyRaw(k.total, k.ccy, 0) + '</span>',
        caption: c.t('compound.after', { n: k.f.years }),
        stats: [
          { value: c.moneyRaw(k.contributed, k.ccy, 0), label: c.t('compound.contributed') },
          { value: c.moneyRaw(k.growth, k.ccy, 0), label: c.t('compound.growth') },
          { value: c.num(k.growth / Math.max(1, k.contributed) * 100, { maximumFractionDigits: 0 }) + '%', label: c.t('compound.return') }
        ]
      }) }) +
      UI.section({ title: c.t('compound.projection'), body: UI.card(
        UI.lineChart({ values: k.series, labels: ['0', Math.round(k.f.years / 2) + 'y', k.f.years + 'y'],
          label: c.t('compound.projection') })) }) +
      UI.section({ title: c.t('compound.byYear'), body: UI.table({
        label: c.t('compound.byYear'),
        cols: [{ label: c.t('common.year') }, { label: c.t('compound.contributed'), align: 'right' },
               { label: c.t('compound.value'), align: 'right' }],
        rows: k.table.map(function (r) {
          return { cells: [String(r.year), c.moneyRaw(r.contributed, k.ccy, 0), c.moneyRaw(r.value, k.ccy, 0)] };
        })
      }) });
  }
};
