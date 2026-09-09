/* ============================================================
   Lume — mosques

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'mosques',

  /* ---------------------------------------------------------
     24.3 Nearby Mosques — map + list
     --------------------------------------------------------- */
  build: function (c) {
    var list = c.nearbyMosques();
    var radius = c.filter('radius', '3');
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = list.filter(function (m) {
      if (m.km > Number(radius)) return false;
      if (query && m.name.toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    return UI.section({ flush: true, body: UI.contextBar([{ icon: 'i-pin', label: c.profile.city, act: 'sheet:personalise' }]) }) +
      UI.section({ body: UI.map({
        label: c.t('mosques.map'),
        caption: c.profile.city,
        markers: list.map(function (m, i) {
          return { x: m.x, y: m.y, icon: 'i-mosque', label: m.name, active: i === 0 };
        })
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('mosques.search'), target: 'mosques', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'radius', label: c.t('mosques.radius'), items: [
        { value: '1', label: c.L.distance(1), on: radius === '1' },
        { value: '3', label: c.L.distance(3), on: radius === '3' },
        { value: '5', label: c.L.distance(5), on: radius === '5' }
      ] }], 'mosques') }) +
      UI.section({ title: c.t('mosques.nearby'), body: shown.length ? UI.rows(shown.map(function (m) {
        return UI.richRow({
          icon: 'i-mosque', iconTone: 'accent',
          title: m.name,
          sub: m.address,
          meta: [c.L.distance(m.km), m.walk + ' ' + c.t('unit.walk'), m.facilities.join(' · ')],
          value: c.time(m.next.h, m.next.m),
          valueSub: c.t('prayer.' + m.next.key),
          act: 'toast:' + m.name + ' · ' + c.L.distance(m.km),
          chevron: true
        });
      })) : UI.emptyState({ icon: 'i-mosque', title: c.t('mosques.noneNear'),
        text: c.t('mosques.noneNearText'),
        action: { label: c.L.distance(5), act: 'toolstate:mosques:radius:5', icon: 'i-navigation' } }) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('mosques.directions'), tone: 'accent', icon: 'i-navigation', act: 'toast:' + c.t('mosques.opening') },
        { label: c.t('mosques.addyours'), icon: 'i-plus', act: 'toast:' + c.t('mosques.suggest') }
      ]) });
  }
};
