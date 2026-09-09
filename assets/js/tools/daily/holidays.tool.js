/* ============================================================
   Lume — holidays

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'holidays',

  build: function (c) {
    var list = D.holidaysFor(c.profile.country);
    var kind = c.filter('kind', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();
    var kinds = list.map(function (h) { return h.kind; })
      .filter(function (v, i, a) { return a.indexOf(v) === i; });
    var shown = list.filter(function (h) {
      if (kind !== 'all' && h.kind !== kind) return false;
      if (query && h.name.toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' }]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('holidays.next'),
        value: list[0].name,
        caption: list[0].date + ' · ' + list[0].kind,
        stats: [{ value: String(list.length), label: c.t('holidays.thisYear') }]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('holidays.search'), target: 'holidays', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'kind', label: c.t('holidays.kind'), items: [
        { value: 'all', label: c.t('common.all'), on: kind === 'all' }
      ].concat(kinds.map(function (k) { return { value: k, label: k, on: kind === k }; })) }], 'holidays') }) +
      UI.section({ body: c.monthGrid() }) +
      UI.section({ title: c.t('holidays.calendar'), body: shown.length
        ? UI.rows(shown.map(function (h) {
            return UI.richRow({ icon: 'i-calendar', iconTone: 'accent', title: h.name, sub: h.kind, value: h.date });
          }))
        : UI.emptyState({ icon: 'i-calendar', title: c.t('holidays.noMatch'), text: c.t('holidays.noMatchText'),
            action: { label: c.t('common.all'), act: 'toolstate:holidays:kind:all', icon: 'i-refresh' } }) }) +
      (c.profile.islamic ? UI.section({ title: c.t('holidays.islamic'), body: UI.rows(D.ISLAMIC_EVENTS.map(function (e) {
        return UI.compactRow({ icon: 'i-moon-star', label: e.name, sub: e.hijri, value: e.greg });
      })) }) : '');
  }
};
