/* ============================================================
   Lume — loan

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'loan',

  /* ---------------------------------------------------------
     §34 Loan / EMI — calculator + amortisation
     --------------------------------------------------------- */
  build: function (c) {
    var l = c.loan();
    return UI.section({ id: 'inputs', title: c.t('tool.inputs'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('loan.principal'), name: 'ln_principal', type: 'number', value: l.f.principal, prefix: l.ccy, wide: true }),
        UI.field({ label: c.t('loan.rate'), name: 'ln_rate', type: 'number', value: l.f.rate, suffix: '%', step: '0.1' }),
        UI.field({ label: c.t('loan.tenure'), name: 'ln_years', type: 'number', value: l.f.years, suffix: c.t('common.years') })
      ])) }) +
      UI.section({ id: 'result', body: UI.summaryCard({
        tone: 'accent',
        kicker: c.t('loan.monthly'),
        value: '<span data-ln-emi>' + c.moneyRaw(l.emi, l.ccy, 0) + '</span>',
        caption: c.t('loan.over', { n: l.f.years * 12 }),
        stats: [
          { value: '<span data-ln-interest>' + c.moneyRaw(l.totalInterest, l.ccy, 0) + '</span>', label: c.t('loan.totalInterest') },
          { value: '<span data-ln-total>' + c.moneyRaw(l.totalPaid, l.ccy, 0) + '</span>', label: c.t('loan.totalPaid') },
          { value: c.num(l.interestShare * 100, { maximumFractionDigits: 0 }) + '%', label: c.t('loan.interestShare') }
        ]
      }) }) +
      UI.section({ body: UI.card(UI.donut({
        label: c.t('loan.split'),
        centre: c.moneyRaw(l.totalPaid, l.ccy, 0), centreSub: c.t('loan.totalPaid'),
        slices: [
          { label: c.t('loan.principalShort'), value: l.f.principal, color: 'var(--accent)' },
          { label: c.t('loan.interest'), value: l.totalInterest, color: 'var(--violet)' }
        ]
      })) }) +
      UI.section({ title: c.t('loan.amortisation'), body: UI.table({
        label: c.t('loan.amortisation'),
        cols: [{ label: c.t('common.year') }, { label: c.t('loan.principalShort'), align: 'right' },
               { label: c.t('loan.interest'), align: 'right' }, { label: c.t('loan.balance'), align: 'right' }],
        rows: l.schedule.map(function (r) {
          return { cells: [String(r.year), c.moneyRaw(r.principal, l.ccy, 0),
                           c.moneyRaw(r.interest, l.ccy, 0), c.moneyRaw(r.balance, l.ccy, 0)] };
        })
      }) }) +
      UI.section({ title: c.t('loan.compare'), body: UI.rows(l.compare.map(function (x) {
        return UI.compactRow({ icon: 'i-bank', label: x.label, sub: x.sub, value: c.moneyRaw(x.emi, l.ccy, 0) });
      })) });
  }
};
