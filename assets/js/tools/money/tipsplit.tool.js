/* ============================================================
   Lume — tipsplit

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'tipsplit',

  /* ---------------------------------------------------------
     §35 Tip & split — focused calculator, kept fast
     --------------------------------------------------------- */
  build: function (c) {
    var s = c.tipSplit();
    return UI.section({ body: UI.card(UI.formGrid([
        UI.field({ label: c.t('tip.bill'), name: 'tp_bill', type: 'number', value: s.f.bill, prefix: s.ccy, wide: true })
      ]) +
      '<p class="fieldlabel">' + UI.esc(c.t('tip.tip')) + '</p>' +
      '<div class="chips chips--tight">' + [0, 5, 10, 15, 20].map(function (p) {
        return '<button class="chip' + (p === s.f.tip ? ' is-on' : '') + '" data-act="toolstate:tipsplit:tip:' + p + '">' + p + '%</button>';
      }).join('') + '</div>' +
      '<div class="splitrow"><span class="fieldlabel">' + UI.esc(c.t('tip.people')) + '</span>' +
        UI.stepper({ name: 'tp_people', value: s.f.people, label: c.t('tip.people') }) + '</div>') }) +
      UI.section({ body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('tip.perPerson'),
        value: '<span data-tp-each>' + c.moneyRaw(s.each, s.ccy, 2) + '</span>',
        stats: [
          { value: c.moneyRaw(s.tipAmount, s.ccy, 2), label: c.t('tip.tipAmount') },
          { value: c.moneyRaw(s.total, s.ccy, 2), label: c.t('tip.total') },
          { value: String(s.f.people), label: c.t('tip.people') }
        ]
      }) }) +
      UI.section({ title: c.t('tip.custom'), body: UI.rows(s.custom.map(function (x) {
        return UI.compactRow({ icon: 'i-user', label: x.name, value: c.moneyRaw(x.amount, s.ccy, 2) });
      })) });
  }
};
