/* ============================================================
   Lume — names99

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'names99',

  /* ---------------------------------------------------------
     24.13 99 Names — learning grid + detail
     --------------------------------------------------------- */
  build: function (c) {
    var learned = 12;
    var query = (c.state('q') || '').trim().toLowerCase();
    var names = D.NAMES99.filter(function (n) {
      return !query || (n.tl + ' ' + n.meaning).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('names.title'),
        value: learned + ' <small>/ 99</small>',
        caption: c.t('names.learned'),
        aside: UI.progressRing({ value: learned / 99, centre: Math.round(learned / 99 * 100) + '%', label: c.t('names.progress') })
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('names.search'), target: 'names99', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('names.all'), body: names.length ? '<div class="ngrid">' +
        names.map(function (n) {
          return '<button class="ncard pressable" data-act="toast:' + UI.esc(n.tl + ' — ' + n.meaning) + '">' +
            '<span class="ncard__n">' + n.n + '</span>' +
            '<span class="ncard__ar arabic">' + UI.esc(n.ar) + '</span>' +
            '<span class="ncard__tl">' + UI.esc(n.tl) + '</span>' +
            '<span class="ncard__meaning">' + UI.esc(n.meaning) + '</span>' +
          '</button>';
        }).join('') + '</div>'
        : UI.emptyState({ icon: 'i-search', title: c.t('names.noMatch'), text: c.t('names.noMatchText') }) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('names.practise'), tone: 'accent', icon: 'i-play', act: 'toast:' + c.t('names.practising') },
        { label: c.t('common.share'), icon: 'i-share', act: 'share:names99' }]) });
  }
};
