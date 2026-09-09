/* ============================================================
   Lume — quran

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'quran',

  /* ---------------------------------------------------------
     24.9 Al-Qur'an — reader + library
     --------------------------------------------------------- */
  build: function (c) {
    var p = c.quranProgress();
    var view = c.filter('quranview', 'surah');
    var query = (c.state('q') || '').trim().toLowerCase();
    var surahs = D.SURAHS.filter(function (s) {
      return !query || (s.name + ' ' + s.meaning + ' ' + s.n).toLowerCase().indexOf(query) !== -1;
    });
    var juzList = [];
    for (var j = 1; j <= 30; j++) {
      juzList.push({ n: j, start: D.SURAHS[(j - 1) % D.SURAHS.length].name, pages: 20 });
    }
    var bookmarks = [
      { surah: 'Al-Kahf', ayah: 42, when: c.t('common.yesterday') },
      { surah: 'Ar-Rahman', ayah: 13, when: '4 Sep' }
    ];
    return UI.section({ body: UI.card(
        '<div class="continue">' +
          '<div class="continue__body">' +
            '<p class="continue__kicker">' + UI.esc(c.t('quran.continue')) + '</p>' +
            '<p class="continue__title">' + UI.esc(p.surah) + ' · ' + UI.esc(c.t('quran.ayah')) + ' ' + p.ayah + '</p>' +
            '<p class="continue__meta">' + UI.esc(c.t('quran.juz')) + ' ' + p.juz + ' · ' +
              UI.esc(c.t('quran.lastread', { when: p.lastRead })) + '</p>' +
          '</div>' +
          UI.progressRing({ value: p.pct, centre: Math.round(p.pct * 100) + '%', label: c.t('quran.progress') }) +
        '</div>' +
        UI.progressBar({ value: p.pct, label: c.t('quran.progress') }) +
        UI.buttonRow([{ label: c.t('quran.resume'), tone: 'accent', icon: 'i-play', act: 'toast:' + p.surah + ' ' + p.ayah }])) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('quran.search'), target: 'quran', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.segmented({ id: 'quranview', label: c.t('quran.browse'), tool: 'quran', items: [
        { value: 'surah', label: c.t('quran.surah'), on: view === 'surah' },
        { value: 'juz', label: c.t('quran.juz'), on: view === 'juz' },
        { value: 'bookmarks', label: c.t('quran.bookmarks'), on: view === 'bookmarks' }
      ] }) }) +
      (view === 'juz'
        ? UI.section({ title: c.t('quran.juzList'), body: UI.rows(juzList.map(function (j) {
            return UI.richRow({
              logo: String(j.n), logoTone: 'var(--tint-neutral)',
              title: c.t('quran.juz') + ' ' + j.n, sub: j.start,
              meta: [c.t('quran.pages', { n: j.pages })],
              value: j.n <= p.juz ? UI.statusBadge({ label: c.t('common.done'), tone: 'ok' }) : '',
              act: 'toast:' + c.t('quran.juz') + ' ' + j.n, chevron: true
            });
          })) })
        : view === 'bookmarks'
        ? UI.section({ title: c.t('quran.bookmarks'), body: bookmarks.length
            ? UI.rows(bookmarks.map(function (b) {
                return UI.richRow({ icon: 'i-bookmark', iconTone: 'accent', title: b.surah,
                  sub: c.t('quran.ayah') + ' ' + b.ayah, meta: [b.when], act: 'toast:' + b.surah, chevron: true });
              }))
            : UI.emptyState({ icon: 'i-bookmark', title: c.t('quran.noBookmarks'),
                text: c.t('quran.noBookmarksText') }) })
        : UI.section({ title: c.t('quran.surahs'), body: surahs.length ? UI.rows(surahs.map(function (s) {
            return UI.richRow({
              logo: String(s.n), logoTone: 'var(--tint-accent)',
              title: s.name, sub: s.meaning,
              meta: [s.ayat + ' ' + c.t('quran.ayat'), c.t('quran.' + s.place.toLowerCase())],
              value: '<span class="arabic">' + UI.esc(s.ar) + '</span>',
              act: 'toast:' + s.name, chevron: true
            });
          })) : UI.emptyState({ icon: 'i-search', title: c.t('quran.noMatch'), text: c.t('quran.noMatchText') }) })) +
      UI.section({ title: c.t('quran.reader'), body: UI.card(
        UI.rows([
          UI.compactRow({ icon: 'i-globe', label: c.t('quran.translation'), value: c.t('quran.translation.value'), act: 'toast:' + c.t('quran.translation.change') }),
          UI.compactRow({ icon: 'i-play', label: c.t('quran.reciter'), value: 'Mishary Alafasy', act: 'toast:' + c.t('quran.reciter.change') }),
          UI.compactRow({ icon: 'i-ruler', label: c.t('quran.textsize'), value: c.t('common.medium') }),
          UI.compactRow({ icon: 'i-eye', label: c.t('quran.transliteration'), value: c.t('common.on') })
        ], { flat: true }), { pad: false }) });
  }
};
