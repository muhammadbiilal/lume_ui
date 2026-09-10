/* ============================================================
   Lume — natsavings

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'natsavings',

  /* ---------------------------------------------------------
     §30 National Savings — financial data explorer
     --------------------------------------------------------- */
  build: function (c) {
    var list = D.NAT_SAVINGS[c.profile.country];
    if (!list) return UI.section({ body: UI.emptyState({
      icon: 'i-shield', title: c.t('savings.unavailable.title'), text: c.t('savings.unavailable.text') }) });
    var ccy = c.L.country().currency;
    var best = list.slice().sort(function (a, b) { return b.rate - a.rate; })[0];

    var query = (c.state('q') || '').trim().toLowerCase();
    var products = list.filter(function (p) {
      return !query || (p.name + ' ' + p.eligible).toLowerCase().indexOf(query) !== -1;
    });

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country) },
        { label: c.t('savings.scheme') }]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('savings.bestRate'),
        value: c.num(best.rate, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '<small>%</small>',
        caption: best.name,
        stats: [
          { value: best.term, label: c.t('savings.term') },
          { value: best.payout, label: c.t('savings.payout') },
          { value: c.moneyRaw(best.min, ccy, 0), label: c.t('savings.minimum') }
        ]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('savings.search'), target: 'natsavings', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.sortBar({ tool: 'natsavings', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'rate', label: c.t('savings.rate') },
          { value: 'term', label: c.t('savings.term') },
          { value: 'min', label: c.t('savings.minimum') }
        ], 'rate', 'desc') }) }) +
      UI.section({ title: c.t('savings.products'), body: UI.rows(c.sortBy(products, {
        rate: function (p) { return p.rate; },
        term: function (p) { return parseInt(p.term, 10); },
        min: function (p) { return p.min; }
      }, 'rate', 'desc').map(function (p) {
        return UI.richRow({
          icon: 'i-shield', iconTone: 'accent',
          title: p.name,
          sub: p.eligible,
          meta: [p.term, p.payout, c.t('savings.min') + ' ' + c.moneyRaw(p.min, ccy, 0)],
          value: c.num(p.rate, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + '%',
          valueSub: c.t('savings.perYear'),
          act: 'toast:' + p.name + ' · ' + c.num(p.rate, { maximumFractionDigits: 2 }) + '%'
        });
      })) }) +
      UI.section({ title: c.t('savings.estimate'), body: UI.card(
        UI.formGrid([
          UI.field({ label: c.t('savings.amount'), name: 'ns_amount', type: 'number', value: 1000000, prefix: ccy }),
          UI.selectField({ label: c.t('savings.product'), name: 'ns_product', value: best.name,
            options: list.map(function (p) { return { value: p.name, label: p.name }; }) })
        ]) +
        UI.metrics([
          { value: c.moneyRaw(1000000 * best.rate / 100 / 12, ccy, 0), label: c.t('savings.monthlyProfit') },
          { value: c.moneyRaw(1000000 * best.rate / 100, ccy, 0), label: c.t('savings.yearlyProfit') }
        ], 2)) });
  }
};
