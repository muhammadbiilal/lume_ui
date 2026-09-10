/* ============================================================
   Lume — taraweeh

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'taraweeh',

  /* ---------------------------------------------------------
     24.7 Taraweeh — schedule + location
     --------------------------------------------------------- */
  build: function (c) {
    var list = c.nearbyMosques();
    var rakaat = c.filter('rakaat', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = list.filter(function (m) {
      if (rakaat !== 'all' && String(m.rakaat) !== rakaat) return false;
      if (query && m.name.toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: c.profile.city, act: 'sheet:personalise' },
        { label: c.t('taraweeh.season') }]) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('taraweeh.search'), target: 'taraweeh', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'rakaat', label: c.t('taraweeh.rakaat'), items: [
        { value: 'all', label: c.t('common.all'), on: rakaat === 'all' },
        { value: '8', label: '8 ' + c.t('taraweeh.rakaatShort'), on: rakaat === '8' },
        { value: '20', label: '20 ' + c.t('taraweeh.rakaatShort'), on: rakaat === '20' }
      ] }], 'taraweeh') }) +
      UI.section({ body: UI.map({
        label: c.t('taraweeh.map'), caption: c.profile.city,
        markers: shown.map(function (m, i) {
          return { x: m.x, y: m.y, icon: 'i-mosque', label: m.name, active: i === 0 };
        })
      }) }) +
      UI.section({ title: c.t('taraweeh.nearby'), body: shown.length ? UI.rows(shown.map(function (m) {
        return UI.richRow({
          icon: 'i-mosque', iconTone: 'accent',
          title: m.name, sub: m.address,
          meta: [c.L.distance(m.km), m.rakaat + ' ' + c.t('taraweeh.rakaatShort'), m.reciter],
          value: c.time(m.taraweeh.h, m.taraweeh.m), valueSub: c.t('taraweeh.starts'),
          act: 'toast:' + m.name, chevron: true
        });
      })) : UI.emptyState({ icon: 'i-mosque', title: c.t('taraweeh.noMatch'),
        text: c.t('taraweeh.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:taraweeh:rakaat:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('taraweeh.selected'), body: UI.card(
        UI.metrics([
          { icon: 'i-clock', value: c.time(shown[0] ? shown[0].taraweeh.h : 20, shown[0] ? shown[0].taraweeh.m : 45),
            label: c.t('taraweeh.starts') },
          { icon: 'i-route', value: c.L.distance(shown[0] ? shown[0].km : 0), label: c.t('qibla.distance') },
          { icon: 'i-beads', value: String(shown[0] ? shown[0].rakaat : 20), label: c.t('taraweeh.rakaat') }
        ], 3)) }) +
      UI.section({ body: UI.noteCard({ icon: 'i-bell', tone: 'info',
        title: c.t('taraweeh.remind.title'), text: c.t('taraweeh.remind.text') }) });
  }
};
