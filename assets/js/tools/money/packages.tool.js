/* ============================================================
   Lume — packages

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'packages',

  /* ---------------------------------------------------------
     §33 Mobile packages — comparison explorer
     --------------------------------------------------------- */
  build: function (c) {
    var list = D.MOBILE_PACKAGES[c.profile.country];
    if (!list) return UI.section({ body: UI.emptyState({
      icon: 'i-signal', title: c.t('packages.unavailable.title'), text: c.t('packages.unavailable.text') }) });
    var ccy = c.L.country().currency;

    var op = c.filter('op', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = list.filter(function (p) {
      if (op !== 'all' && p.op !== op) return false;
      if (query && (p.op + ' ' + p.name).toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    shown = c.sortBy(shown, {
      price: function (p) { return p.price; },
      data: function (p) { return parseFloat(p.data); },
      valid: function (p) { return parseInt(p.valid, 10); }
    }, 'price', 'asc');

    return UI.section({ body: UI.searchBar({ placeholder: c.t('packages.search'), target: 'packages', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([
        { id: 'op', label: c.t('packages.operator'), items: [{ value: 'all', label: c.t('common.all'), on: op === 'all' }]
          .concat(list.map(function (p) { return { value: p.op, label: p.op, on: op === p.op }; })) }
      ], 'packages') }) +
      UI.section({ body: UI.sortBar({ tool: 'packages', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'price', label: c.t('packages.price') },
          { value: 'data', label: c.t('packages.data') },
          { value: 'valid', label: c.t('packages.validity') }
        ], 'price', 'asc') }) }) +
      (shown.length ? UI.section({ title: c.t('packages.compare'), body: UI.table({
        label: c.t('packages.compare'),
        cols: [{ label: c.t('packages.package') }, { label: c.t('packages.data'), align: 'right' },
               { label: c.t('packages.mins'), align: 'right' }, { label: c.t('packages.price'), align: 'right' }],
        rows: shown.map(function (p) {
          return { act: 'toast:' + p.op + ' ' + p.name,
            cells: ['<b>' + UI.esc(p.op) + '</b><i class="cellsub">' + UI.esc(p.name) + '</i>',
                    UI.esc(p.data), UI.esc(p.mins), c.moneyRaw(p.price, ccy, 0)] };
        })
      }) }) : UI.section({ body: UI.emptyState({ icon: 'i-signal',
        title: c.t('packages.noMatch'), text: c.t('packages.noMatchText') }) })) +
      UI.section({ title: c.t('packages.detail'), body: UI.rows(shown.map(function (p) {
        return UI.expandRow({
          head: '<span class="xrow__title">' + UI.esc(p.op) + ' · ' + UI.esc(p.name) + '</span>' +
                '<span class="xrow__value">' + c.moneyRaw(p.price, ccy, 0) + '</span>',
          body: UI.rows([
            UI.compactRow({ label: c.t('packages.data'), value: p.data }),
            UI.compactRow({ label: c.t('packages.mins'), value: p.mins }),
            UI.compactRow({ label: c.t('packages.sms'), value: p.sms }),
            UI.compactRow({ label: c.t('packages.validity'), value: p.valid })
          ], { flat: true })
        });
      })) });
  }
};
