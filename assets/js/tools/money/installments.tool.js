/* ============================================================
   Lume — installments

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'installments',

  /* ---------------------------------------------------------
     §37 Installments — financial manager
     --------------------------------------------------------- */
  build: function (c) {
    var i = c.installments();
    var state = c.filter('state', 'active');
    var plans = c.sortBy(i.plans.filter(function (p) {
      var done = p.paidCount >= p.total;
      return state === 'all' || (state === 'active' ? !done : done);
    }), {
      next: function (p) { return p.total - p.paidCount; },
      amount: function (p) { return p.monthly; },
      progress: function (p) { return p.paidCount / p.total; }
    }, 'next', 'asc');

    return UI.section({ body: UI.summaryCard({
        kicker: c.t('inst.monthlyTotal'),
        value: c.money(i.monthly),
        caption: c.t('inst.activePlans', { n: i.plans.length }),
        stats: [
          { value: c.money(i.remaining), label: c.t('inst.remaining') },
          { value: c.money(i.paid), label: c.t('inst.paid') },
          { value: i.nextDate, label: c.t('inst.nextPayment') }
        ]
      }) }) +
      UI.section({ body: UI.filterBar([{ id: 'state', label: c.t('common.status'), items: [
        { value: 'active', label: c.t('inst.stActive'), on: state === 'active',
          count: i.plans.filter(function (p) { return p.paidCount < p.total; }).length },
        { value: 'done', label: c.t('inst.stDone'), on: state === 'done',
          count: i.plans.filter(function (p) { return p.paidCount >= p.total; }).length },
        { value: 'all', label: c.t('common.all'), on: state === 'all', count: i.plans.length }
      ] }], 'installments') }) +
      UI.section({ body: UI.sortBar({ tool: 'installments', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'next', label: c.t('inst.remainingShort') },
          { value: 'amount', label: c.t('common.amount') },
          { value: 'progress', label: c.t('inst.progress') }
        ], 'next', 'asc') }) }) +
      UI.section({ title: c.t('inst.plans'), body: plans.length ? UI.rows(plans.map(function (p) {
        return UI.richRow({
          logo: p.logo, logoTone: 'var(--tone-' + p.tone + ')',
          title: p.item, sub: p.merchant,
          meta: [c.t('inst.instalment', { a: p.paidCount, b: p.total }), c.t('inst.next') + ' ' + p.next],
          value: c.money(p.monthly),
          valueSub: c.t('common.perMonth')
        }) + '<div class="rowmeter">' + UI.progressBar({ value: p.paidCount / p.total, label: p.item }) + '</div>';
      })) : UI.emptyState({ icon: 'i-calendar', title: c.t('inst.noneHere'),
        text: c.t('inst.noneHereText'),
        action: { label: c.t('common.all'), act: 'toolstate:installments:state:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('inst.schedule'), body: UI.timeline(i.schedule.map(function (s) {
        return { time: s.date, title: s.item, sub: s.merchant, value: c.money(s.amount), state: s.state };
      })) }) +
      UI.section({ title: c.t('inst.payoff'), body: UI.card(
        UI.barChart({
          values: i.months, labels: i.monthLabels, highlight: 0,
          label: c.t('inst.payoff'), caption: c.t('inst.payoffCap', { amount: c.money(i.monthly) }) })) }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(i.history.map(function (h) {
        return UI.compactRow({ icon: 'i-check-circle', label: h.item, sub: h.when, value: c.money(h.amount) });
      })) });
  }
};
