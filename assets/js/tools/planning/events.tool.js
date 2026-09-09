/* ============================================================
   Lume — events

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'events',

  build: function (c) {
    var e0 = c.events();
    var query = (c.state('q') || '').trim().toLowerCase();
    var e = e0.filter(function (x) {
      return !query || (x.title + ' ' + x.where).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ body: UI.searchBar({ placeholder: c.t('events.search'), target: 'events', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('events.upcoming'), body: e.length ? UI.rows(e.map(function (x) {
        return UI.richRow({ icon: 'i-calendar', iconTone: 'accent', title: x.title, sub: x.where,
          meta: [x.when, x.people], act: 'toast:' + x.title, chevron: true });
      })) : UI.emptyState({ icon: 'i-calendar', title: c.t('events.noMatch'), text: c.t('events.noMatchText') }) });
  }
};
