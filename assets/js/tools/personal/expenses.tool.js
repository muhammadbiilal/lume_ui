/* ============================================================
   Lume — expenses

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'expenses',

  /* ---------------------------------------------------------
     §76 Expenses — financial dashboard, very high density
     --------------------------------------------------------- */
  build: function (c) {
    var e = c.expenses();
    var range = c.state('range') || 'month';
    var cat = c.filter('cat', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();

    var tx = e.transactions.filter(function (x) {
      if (cat !== 'all' && x.catId !== cat) return false;
      if (query && (x.title + ' ' + x.catLabel + ' ' + x.method).toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    tx = c.sortBy(tx, {
      date: function (x) { return x.order; },
      amount: function (x) { return Math.abs(x.amount); },
      cat: function (x) { return x.catLabel; }
    }, 'date', 'desc');

    return UI.section({ body: UI.segmented({ id: 'exprange', label: c.t('expenses.range'), items: [
        { value: 'week', label: c.t('common.week'), on: range === 'week', act: 'toolstate:expenses:range:week' },
        { value: 'month', label: c.t('common.month'), on: range === 'month', act: 'toolstate:expenses:range:month' },
        { value: 'year', label: c.t('common.year'), on: range === 'year', act: 'toolstate:expenses:range:year' }
      ] }) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('expenses.spent'),
        value: c.money(e.spent),
        caption: c.t('expenses.ofBudget', { budget: c.money(e.budget), pct: Math.round(e.ratio * 100) + '%' }),
        aside: UI.progressRing({ value: e.ratio, centre: Math.round(e.ratio * 100) + '%', label: c.t('expenses.budgetUse') }),
        stats: [
          { value: c.money(e.income), label: c.t('expenses.income') },
          { value: c.money(e.balance), label: c.t('expenses.balance') },
          { value: c.money(e.dailyAvg), label: c.t('expenses.dailyAvg') }
        ],
        foot: UI.progressBar({ value: e.ratio, tone: e.ratio > 0.9 ? 'warn' : null, label: c.t('expenses.budgetUse') })
      }) }) +
      UI.section({ title: c.t('expenses.trend'), body: UI.card(
        UI.barChart({ values: e.trend, labels: e.trendLabels, highlight: e.trend.length - 1,
          label: c.t('expenses.trend'), caption: c.t('expenses.trendCap', { avg: c.money(e.dailyAvg) }) })) }) +
      UI.section({ title: c.t('expenses.categories'), body: UI.card(UI.donut({
        label: c.t('expenses.categories'),
        centre: c.money(e.spent), centreSub: c.t('common.total'),
        slices: e.categories.map(function (x) {
          return { label: x.label, value: x.amount, color: x.color, display: c.money(x.amount) };
        })
      })) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('expenses.search'), target: 'expenses', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'cat', label: c.t('expenses.category'), items: [
        { value: 'all', label: c.t('common.all'), on: cat === 'all' }
      ].concat(D.EXPENSE_CATEGORIES.map(function (x) {
        return { value: x.id, label: x.label, icon: x.icon, on: cat === x.id };
      })) }], 'expenses') }) +
      UI.section({ body: UI.sortBar({ tool: 'expenses', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'date', label: c.t('common.date') },
          { value: 'amount', label: c.t('common.amount') },
          { value: 'cat', label: c.t('expenses.category') }
        ], 'date', 'desc') }) }) +
      UI.section({ title: c.t('expenses.transactions'), body: tx.length
        ? UI.rows(tx.map(function (x) {
            return UI.richRow({
              icon: x.icon, iconTone: x.income ? 'accent' : null,
              title: x.title, sub: x.catLabel,
              meta: [x.when, x.method],
              value: (x.income ? '+' : '−') + c.money(Math.abs(x.amount)),
              cls: x.income ? 'is-income' : ''
            });
          }))
        : UI.emptyState({ icon: 'i-wallet', title: c.t('expenses.noMatch'),
            text: c.t('expenses.noMatchText'),
            action: { label: c.t('common.all'), act: 'toolstate:expenses:cat:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('expenses.budgets'), body: UI.card(e.budgets.map(function (b) {
        return UI.meterRow({ label: b.label, value: c.money(b.spent) + ' / ' + c.money(b.limit),
          pct: b.spent / b.limit, tone: b.spent > b.limit ? 'warn' : null });
      }).join('')) }) +
      UI.section({ title: c.t('expenses.recurring'), body: UI.rows(e.recurring.map(function (r) {
        return UI.compactRow({ icon: 'i-refresh', label: r.label, sub: r.when, value: c.money(r.amount) });
      })) }) +
      UI.section({ title: c.t('expenses.insights'), body: UI.rows(e.insights.map(function (i) {
        return UI.richRow({ icon: i.icon, iconTone: 'accent', title: i.title, sub: i.text });
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('expenses.add'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('expenses.adding') },
        { label: c.t('common.export'), icon: 'i-download', act: 'export:expenses' }]) });
  }
};
