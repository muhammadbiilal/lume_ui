/* ============================================================
   Lume — shopping

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'shopping',

  /* ---------------------------------------------------------
     §60 Shopping list · §61 Birthdays
     --------------------------------------------------------- */
  build: function (c) {
    var s = c.shopping();
    var query = (c.state('q') || '').trim().toLowerCase();
    var shopGroups = s.groups.map(function (g) {
      return { label: g.label, items: g.items.filter(function (i) {
        return !query || i.label.toLowerCase().indexOf(query) !== -1;
      }) };
    }).filter(function (g) { return g.items.length; });

    return UI.section({ body: UI.summaryCard({
        kicker: c.t('shopping.list'),
        value: s.remaining + ' <small>/ ' + s.items.length + '</small>',
        caption: c.t('shopping.estimated', { amount: c.money(s.estimate) }),
        aside: UI.progressRing({ value: s.checked / s.items.length,
          centre: s.checked + '/' + s.items.length, label: c.t('shopping.progress') })
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('shopping.add'), target: 'shopping', value: c.state('q') || '' }) }) +
      shopGroups.map(function (g) {
        return UI.section({ title: g.label, body: UI.rows(g.items.map(function (x) {
          return '<button class="taskrow pressable' + (x.done ? ' is-done' : '') + '" data-shop="' + UI.esc(x.id) + '"' +
            ' role="checkbox" aria-checked="' + (x.done ? 'true' : 'false') + '">' +
            '<span class="taskrow__box">' + UI.ico('i-check') + '</span>' +
            '<span class="taskrow__body"><span class="taskrow__label">' + UI.esc(x.label) + '</span>' +
              '<span class="taskrow__meta">' + UI.esc(x.qty) + '</span></span>' +
            '<span class="taskrow__value">' + c.money(x.price) + '</span></button>';
        })) });
      }).join('') +
      UI.section({ body: UI.buttonRow([
        { label: c.t('shopping.share'), icon: 'i-share', act: 'toast:' + c.t('shopping.sharing') },
        { label: c.t('shopping.clear'), icon: 'i-refresh', act: 'toast:' + c.t('shopping.cleared') }]) });
  }
};
