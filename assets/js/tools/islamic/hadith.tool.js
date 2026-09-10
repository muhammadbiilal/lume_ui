/* ============================================================
   Lume — hadith

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'hadith',

  /* ---------------------------------------------------------
     24.11 Hadith — library + reader
     --------------------------------------------------------- */
  build: function (c) {
    var h = D.HADITH[c.dayIndex(D.HADITH.length)];
    var coll = c.filter('collection', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();
    var shown = D.HADITH.filter(function (x) {
      if (coll !== 'all' && x.collection !== coll) return false;
      if (query && (x.text + ' ' + x.narrator + ' ' + x.src).toLowerCase().indexOf(query) === -1) return false;
      return true;
    });
    return UI.section({ body: UI.card(
        '<p class="reader__ref">' + UI.esc(h.src) + ' · ' + UI.esc(h.ref) + '</p>' +
        '<p class="reader__body">' + UI.esc(h.text) + '</p>' +
        '<div class="metaline">' +
          '<span>' + UI.esc(c.t('hadith.narrator')) + ': ' + UI.esc(h.narrator) + '</span>' +
          UI.statusBadge({ label: h.grade, tone: h.grade === 'Sahih' ? 'ok' : 'info' }) +
        '</div>' +
        '<div class="reader__acts">' +
          UI.button({ label: c.t('common.share'), icon: 'i-share', tone: 'accent', act: 'share:hadith' }) +
          UI.button({ label: c.t('common.save'), icon: 'i-bookmark', act: 'bookmark:hadith' }) +
        '</div>', { tone: 'reader' }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('hadith.search'), target: 'hadith', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([{ id: 'collection', label: c.t('hadith.collection'), items: [
        { value: 'all', label: c.t('common.all'), on: coll === 'all' },
        { value: 'Bukhari', label: 'Bukhari', count: 7563, on: coll === 'Bukhari' },
        { value: 'Muslim', label: 'Muslim', count: 5362, on: coll === 'Muslim' },
        { value: 'Tabarani', label: 'Tabarani', count: 3956, on: coll === 'Tabarani' }
      ] }], 'hadith') }) +
      UI.section({ title: c.t('hadith.browse'), body: shown.length ? UI.rows(shown.map(function (x) {
        return UI.richRow({
          icon: 'i-quote',
          title: x.text.length > 58 ? x.text.slice(0, 58) + '…' : x.text,
          sub: x.src + ' · ' + x.ref,
          meta: [x.narrator, x.grade],
          badge: { label: x.grade, tone: x.grade === 'Sahih' ? 'ok' : 'info' },
          act: 'toast:' + x.src + ' ' + x.ref, chevron: true
        });
      })) : UI.emptyState({ icon: 'i-quote', title: c.t('hadith.noMatch'), text: c.t('hadith.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:hadith:collection:all', icon: 'i-refresh' } }) });
  }
};
