/* ============================================================
   Lume — tax

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'tax',

  /* ---------------------------------------------------------
     §29 Tax — guided calculator, country-configurable
     --------------------------------------------------------- */
  build: function (c) {
    var tx = c.tax();
    var tx0 = tx.config || {};
    if (!tx.config) {
      return UI.section({ body: UI.emptyState({
        icon: 'i-percent',
        title: c.t('tax.unsupported.title', { country: c.L.countryName(c.profile.country) }),
        text: c.t('tax.unsupported.text'),
        action: { label: c.t('settings.changeCountry'), act: 'sheet:personalise', icon: 'i-globe' }
      }) });
    }
    /* No income tax is not "nothing to show": the levies a salary actually
       meets here are what the user came to find out (§91, §112). */
    if (!tx.taxable) {
      var levies = D.leviesFor(c.profile.country);
      var gross = Number(c.field('income') || 3000 * (c.L.RATES[tx0.ccy] || 1));
      return UI.section({ flush: true, body: UI.contextBar([
          { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
          { label: tx0.authority }, { label: tx0.year }]) }) +
        UI.section({ body: UI.summaryCard({
          tone: 'accent',
          kicker: c.t('tax.takeHome'),
          value: c.moneyRaw(gross, tx0.ccy, 0),
          caption: c.t('tax.noneCaption'),
          stats: [
            { value: c.pct(0, 0), label: c.t('tax.incomeTax') },
            { value: c.num(levies[0].rate, { maximumFractionDigits: 2 }) + '%', label: c.t(levies[0].key) },
            { value: tx0.year, label: c.t('tax.year') }
          ]
        }) }) +
        UI.section({ id: 'inputs', body: UI.card(UI.formGrid([
          UI.field({ label: c.t('tax.incomeMonthly'), name: 'tax_income', type: 'number',
            value: gross, prefix: tx0.ccy, wide: true })
        ])) }) +
        UI.section({ body: UI.noteCard({ icon: 'i-info', tone: 'ok',
          title: c.t('tax.none.title'), text: c.t('tax.none.text', { authority: tx0.authority }) }) }) +
        UI.section({ title: c.t('tax.otherLevies'), body: UI.table({
          label: c.t('tax.otherLevies'),
          cols: [{ label: c.t('tax.levy') }, { label: c.t('tax.rate'), align: 'right' }],
          rows: levies.map(function (l) {
            return { cells: [UI.esc(c.t(l.key)),
                             c.num(l.rate, { maximumFractionDigits: 2 }) + '%'] };
          })
        }) }) +
        UI.section({ title: c.t('tax.leviesNote'), body: UI.card(
          '<p class="kard__lead">' + UI.esc(c.t('tax.leviesNoteText')) + '</p>', { tone: 'quiet' }) });
    }

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: tx.config.authority },
        { label: tx.config.year }]) }) +
      UI.section({ body: UI.segmented({ id: 'taxperiod', label: c.t('tax.period'), items: [
        { value: 'month', label: c.t('tax.monthly'), on: tx.period === 'month', act: 'toolstate:tax:period:month' },
        { value: 'year', label: c.t('tax.annual'), on: tx.period === 'year', act: 'toolstate:tax:period:year' }
      ] }) }) +
      UI.section({ id: 'inputs', body: UI.card(UI.formGrid([
        UI.field({ label: tx.period === 'month' ? c.t('tax.incomeMonthly') : c.t('tax.incomeAnnual'),
          name: 'tax_income', type: 'number', value: tx.f.income, prefix: tx.ccy, wide: true }),
        UI.field({ label: c.t('tax.deductions'), name: 'tax_ded', type: 'number', value: tx.f.deductions, prefix: tx.ccy })
      ])) }) +
      UI.section({ id: 'result', body: UI.summaryCard({
        tone: 'accent',
        kicker: tx.period === 'month' ? c.t('tax.dueMonthly') : c.t('tax.dueAnnual'),
        value: '<span data-tax-due>' + c.moneyRaw(tx.dueDisplay, tx.ccy, 0) + '</span>',
        caption: c.t('tax.effective', { rate: c.num(tx.effective * 100, { maximumFractionDigits: 1 }) + '%' }),
        stats: [
          { value: '<span data-tax-net>' + c.moneyRaw(tx.netDisplay, tx.ccy, 0) + '</span>', label: c.t('tax.takeHome') },
          { value: c.moneyRaw(tx.taxableAnnual, tx.ccy, 0), label: c.t('tax.taxable') },
          { value: c.num(tx.marginal * 100, { maximumFractionDigits: 0 }) + '%', label: c.t('tax.marginal') }
        ]
      }) }) +
      UI.section({ id: 'breakdown', title: c.t('tax.slabs'), body: UI.table({
        label: c.t('tax.slabs'),
        cols: [{ label: c.t('tax.band') }, { label: c.t('tax.rate'), align: 'right' },
               { label: c.t('tax.taxedHere'), align: 'right' }],
        rows: tx.bands.map(function (b) {
          return { cells: [UI.esc(b.label), c.num(b.rate * 100, { maximumFractionDigits: 0 }) + '%', c.moneyRaw(b.tax, tx.ccy, 0)] };
        })
      }) }) +
      UI.section({ body: UI.card(UI.donut({
        label: c.t('tax.split'),
        centre: c.moneyRaw(tx.netDisplay, tx.ccy, 0),
        centreSub: c.t('tax.takeHome'),
        slices: [
          { label: c.t('tax.takeHome'), value: tx.netAnnual, color: 'var(--accent)' },
          { label: c.t('tax.tax'), value: tx.dueAnnual, color: 'var(--amber)' }
        ]
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('common.export'), icon: 'i-download', tone: 'accent', act: 'export:tax' },
        { label: c.t('common.share'), icon: 'i-share', act: 'share:tax' }]) });
  }
};
