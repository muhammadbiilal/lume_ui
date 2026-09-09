/* ============================================================
   Lume — quransearch

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'quransearch',

  /* ---------------------------------------------------------
     24.10 Search the Qur'an — search explorer
     --------------------------------------------------------- */
  build: function (c) {
    var results = c.quranSearch(c.state('q') || '');
    return UI.section({ body: UI.searchBar({
        placeholder: c.t('quransearch.placeholder'), target: 'quransearch', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([
        { id: 'scope', label: c.t('quransearch.scope'), items: [
          { value: 'all', label: c.t('common.all'), on: true },
          { value: 'ar', label: c.t('quransearch.arabic') },
          { value: 'tr', label: c.t('quransearch.translation') }
        ] },
        { id: 'place', label: c.t('quransearch.revealed'), items: [
          { value: 'meccan', label: c.t('quran.meccan') },
          { value: 'medinan', label: c.t('quran.medinan') }
        ] }
      ]) }) +
      (results.length
        ? UI.section({ title: c.t('quransearch.results', { n: results.length }), body: UI.rows(results.map(function (r) {
            return UI.richRow({
              logo: r.s + ':' + r.a, logoTone: 'var(--tint-accent)',
              title: r.surah, sub: r.tr,
              meta: [c.t('quran.ayah') + ' ' + r.a, r.place || ''],
              act: 'tool:quran', chevron: true
            });
          })) })
        : UI.section({ body: UI.emptyState({
            icon: 'i-search', title: c.t('quransearch.empty.title'), text: c.t('quransearch.empty.text') }) })) +
      UI.section({ title: c.t('quransearch.suggested'), body: '<div class="chips">' +
        ['rahman', 'sabr', 'light', 'mercy', 'ar-rahman', 'yaseen'].map(function (s) {
          return '<button class="chip" data-act="toolsearch:quransearch:' + s + '">' + UI.esc(s) + '</button>';
        }).join('') + '</div>' });
  }
};
