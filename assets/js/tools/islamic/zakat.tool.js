/* ============================================================
   Lume — zakat

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'zakat',

  /* ---------------------------------------------------------
     24.16 Zakat — calculator + financial breakdown
     --------------------------------------------------------- */
  build: function (c) {
    var z = c.zakat();
    return UI.section({ flush: true, body: UI.contextBar([
        { label: c.t('zakat.nisabGold') + ': ' + c.moneyRaw(z.nisabGold, c.L.currencyCode(), 0) },
        { label: c.t('zakat.rate') + ': 2.5%' }]) }) +
      UI.section({ id: 'inputs', title: c.t('zakat.assets'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('zakat.cash'), name: 'z_cash', type: 'number', value: z.f.cash, prefix: c.L.currencyCode() }),
        UI.field({ label: c.t('zakat.gold'), name: 'z_gold', type: 'number', value: z.f.gold, suffix: c.t('unit.gram') }),
        UI.field({ label: c.t('zakat.silver'), name: 'z_silver', type: 'number', value: z.f.silver, suffix: c.t('unit.gram') }),
        UI.field({ label: c.t('zakat.investments'), name: 'z_inv', type: 'number', value: z.f.inv, prefix: c.L.currencyCode() }),
        UI.field({ label: c.t('zakat.business'), name: 'z_biz', type: 'number', value: z.f.biz, prefix: c.L.currencyCode() }),
        UI.field({ label: c.t('zakat.liabilities'), name: 'z_liab', type: 'number', value: z.f.liab, prefix: c.L.currencyCode() })
      ])) }) +
      UI.section({ id: 'result', body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('zakat.payable'),
        value: '<span data-zakat-total>' + c.moneyRaw(z.due, c.L.currencyCode(), 0) + '</span>',
        caption: z.eligible ? c.t('zakat.aboveNisab') : c.t('zakat.belowNisab'),
        stats: [
          { value: '<span data-zakat-net>' + c.moneyRaw(z.net, c.L.currencyCode(), 0) + '</span>', label: c.t('zakat.netAssets') },
          { value: c.moneyRaw(z.nisabGold, c.L.currencyCode(), 0), label: c.t('zakat.nisab') },
          { value: '2.5%', label: c.t('zakat.rate') }
        ]
      }) }) +
      UI.section({ id: 'breakdown', title: c.t('zakat.breakdown'), body: UI.table({
        label: c.t('zakat.breakdown'),
        cols: [{ label: c.t('zakat.item') }, { label: c.t('zakat.value'), align: 'right' }],
        rows: z.lines.map(function (l) {
          return { cells: [UI.esc(l.label), c.moneyRaw(l.value, c.L.currencyCode(), 0)] };
        })
      }) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('common.share'), icon: 'i-share', tone: 'accent', act: 'share:zakat' },
        { label: c.t('common.export'), icon: 'i-download', act: 'export:zakat' }]) });
  }
};
