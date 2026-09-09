/* ============================================================
   Lume — duas

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'duas',

  /* ---------------------------------------------------------
     24.12 Daily Duas — category library
     --------------------------------------------------------- */
  build: function (c) {
    var featured = D.DUAS[c.dayIndex(D.DUAS.length)];
    var cat = c.filter('cat', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();
    var catLabel = (D.DUA_CATEGORIES.filter(function (x) { return x.id === cat; })[0] || {}).label || '';
    var shown = D.DUAS.filter(function (d) {
      if (cat !== 'all' && d.cat !== cat) return false;
      if (query && (d.title + ' ' + d.tr).toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    return UI.section({ body: UI.card(
        '<p class="reader__ref">' + UI.esc(c.t('duas.today')) + ' · ' + UI.esc(featured.title) + '</p>' +
        '<p class="arabic arabic--lg">' + UI.esc(featured.ar) + '</p>' +
        '<p class="reader__tr">' + UI.esc(featured.tr) + '</p>' +
        '<p class="reader__src">' + UI.esc(featured.src) + '</p>' +
        '<div class="reader__acts">' +
          UI.button({ label: c.t('common.share'), icon: 'i-share', tone: 'accent', act: 'share:dua' }) +
          UI.button({ label: c.t('reader.listen'), icon: 'i-play', act: 'toast:' + c.t('reader.playing') }) +
        '</div>', { tone: 'reader' }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('duas.search'), target: 'duas', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('duas.categories'), body: '<div class="tiles">' +
        D.DUA_CATEGORIES.map(function (x) {
          var count = D.DUAS.filter(function (d) { return d.cat === x.id; }).length;
          return '<button class="tile pressable' + (cat === x.id ? ' is-on' : '') +
            '" data-act="toolstate:duas:cat:' + x.id + '" aria-pressed="' + (cat === x.id ? 'true' : 'false') + '">' +
            '<span class="tile__icon">' + UI.ico(x.icon) + '</span>' +
            '<span class="tile__label">' + UI.esc(x.label) + '</span>' +
            '<span class="tile__meta">' + count + ' ' + UI.esc(c.t('duas.count')) + '</span>' +
          '</button>';
        }).join('') + '</div>' }) +
      UI.section({ title: cat === 'all' ? c.t('duas.all') : c.t('duas.inCategory', { name: catLabel }),
        link: cat === 'all' ? null : { label: c.t('common.all'), act: 'toolstate:duas:cat:all' },
        body: shown.length ? UI.rows(shown.map(function (d) {
          return UI.richRow({
            icon: 'i-heart', iconTone: 'accent',
            title: d.title, sub: d.tr,
            meta: [d.src],
            value: '<span class="arabic">' + UI.esc(d.ar.slice(0, 16)) + '</span>',
            act: 'share:duas', chevron: true
          });
        })) : UI.emptyState({ icon: 'i-heart', title: c.t('duas.noMatch'), text: c.t('duas.noMatchText'),
          action: { label: c.t('common.all'), act: 'toolstate:duas:cat:all', icon: 'i-refresh' } }) });
  }
};
