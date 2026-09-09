/* ============================================================
   Lume — bills

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'bills',

  /* ---------------------------------------------------------
     §32 Bills — financial dashboard
     --------------------------------------------------------- */
  build: function (c) {
    var b = c.bills();
    var state = c.filter('state', 'all');
    var shownBills = b.list.filter(function (x) {
      return state === 'all' || x.state === state || (state === 'due' && x.state === 'upcoming');
    });
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('bills.dueThisMonth'),
        value: c.money(b.totalDue),
        caption: b.overdueCount
          ? c.t('bills.overdueCount', { n: b.overdueCount })
          : c.t('bills.allOnTrack'),
        aside: UI.progressRing({ value: b.paidRatio, centre: b.paidCount + '/' + b.list.length, label: c.t('bills.paid') }),
        stats: [
          { value: c.money(b.overdue), label: c.t('bills.overdue') },
          { value: c.money(b.upcoming), label: c.t('bills.upcoming') },
          { value: c.money(b.paid), label: c.t('bills.paidAmount') }
        ]
      }) }) +
      (b.overdueCount ? UI.section({ body: UI.noteCard({ tone: 'warn', icon: 'i-alert',
        title: c.t('bills.overdue.title', { n: b.overdueCount }),
        text: c.t('bills.overdue.text') }) }) : '') +
      UI.section({ body: UI.filterBar([{ id: 'state', label: c.t('common.status'), items: [
        { value: 'all', label: c.t('common.all'), on: state === 'all', count: b.list.length },
        { value: 'overdue', label: c.t('bills.overdue'), on: state === 'overdue', count: b.overdueCount },
        { value: 'due', label: c.t('bills.due'), on: state === 'due', count: b.dueCount },
        { value: 'paid', label: c.t('bills.paidState'), on: state === 'paid', count: b.paidCount }
      ] }], 'bills') }) +
      UI.section({ title: c.t('bills.all'), body: shownBills.length ? UI.rows(shownBills.map(function (x) {
        return UI.richRow({
          icon: x.icon, iconTone: x.state === 'overdue' ? 'warn' : null,
          title: x.name, sub: x.provider,
          meta: [c.t('bills.ref') + ' ' + x.ref, x.dueLabel],
          badge: x.badge,
          value: c.money(x.amount),
          act: x.state === 'paid' ? 'toast:' + x.name + ' — ' + c.t('bills.paidState')
                                  : 'toast:' + c.t('bills.opening', { name: x.provider })
        });
      })) : UI.emptyState({ icon: 'i-receipt', title: c.t('bills.noMatch'), text: c.t('bills.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:bills:state:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('bills.trend'), body: UI.card(
        UI.barChart({ values: b.trend, labels: b.trendLabels, highlight: b.trend.length - 1,
          label: c.t('bills.trend'), caption: c.t('bills.trendCap') })) }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(b.history.map(function (h) {
        return UI.compactRow({ icon: 'i-check-circle', label: h.name, sub: h.when, value: c.money(h.amount) });
      })) });
  }
};
