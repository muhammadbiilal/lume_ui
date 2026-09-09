/* ============================================================
   Lume — subs

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'subs',

  /* ---------------------------------------------------------
     §78 Subscriptions — recurring expense manager
     --------------------------------------------------------- */
  build: function (c) {
    var s = c.subscriptions();
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = c.sortBy(s.list.filter(function (x) {
      return !query || (x.name + ' ' + x.cat).toLowerCase().indexOf(query) !== -1;
    }), {
      renews: function (x) { return x.days; },
      price: function (x) { return x.price; },
      name: function (x) { return x.name; }
    }, 'renews', 'asc');

    return UI.section({ body: UI.summaryCard({
        kicker: c.t('subs.monthly'),
        value: c.money(s.monthly),
        caption: c.t('subs.yearly', { amount: c.money(s.yearly) }),
        stats: [
          { value: String(s.list.length), label: c.t('subs.active') },
          { value: s.next.name, label: c.t('subs.nextRenewal') },
          { value: c.t('common.inDays', { n: s.next.days }), label: c.t('subs.renewsIn') }
        ]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('subs.search'), target: 'subs', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.sortBar({ tool: 'subs', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'renews', label: c.t('subs.renewal') },
          { value: 'price', label: c.t('common.amount') },
          { value: 'name', label: c.t('common.name') }
        ], 'renews', 'asc') }) }) +
      UI.section({ title: c.t('subs.all'), body: UI.rows(shown.map(function (x) {
        return UI.richRow({
          logo: x.logo, logoTone: 'var(--tone-' + x.tone + ')',
          title: x.name, sub: x.cat,
          meta: [x.cycle, c.t('subs.renews', { date: x.renews })],
          badge: x.days <= 7 ? { label: c.t('common.inDays', { n: x.days }), tone: 'warn' } : null,
          value: c.money(x.price), valueSub: c.t('common.perMonth'),
          act: 'toast:' + x.name, chevron: true
        });
      })) }) +
      UI.section({ title: c.t('subs.byCategory'), body: UI.card(UI.donut({
        label: c.t('subs.byCategory'), centre: c.money(s.monthly), centreSub: c.t('common.perMonth'),
        slices: s.byCategory
      })) }) +
      UI.section({ title: c.t('subs.timeline'), body: UI.timeline(s.list.slice(0, 4).map(function (x) {
        return { time: x.renews, title: x.name, sub: x.cat, value: c.money(x.price), state: x.days <= 7 ? 'now' : '' };
      })) });
  }
};
