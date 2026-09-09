/* ============================================================
   Lume — ayah

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'ayah',

  /* ---------------------------------------------------------
     24.8 Ayah of the Day — reader card
     --------------------------------------------------------- */
  build: function (c) {
    var a = c.ayahOfDay();
    return UI.section({ body: UI.card(
      '<p class="reader__ref">' + UI.esc(a.surah) + ' · ' + a.s + ':' + a.a + '</p>' +
      '<p class="arabic arabic--lg">' + UI.esc(a.ar) + '</p>' +
      '<p class="reader__tl">' + UI.esc(a.tl) + '</p>' +
      '<p class="reader__tr">' + UI.esc(a.tr) + '</p>' +
      '<div class="reader__acts">' +
        UI.button({ label: c.t('common.share'), icon: 'i-share', tone: 'accent', act: 'share:ayah' }) +
        UI.button({ label: c.t('common.save'), icon: 'i-bookmark', act: 'bookmark:ayah' }) +
        UI.button({ label: c.t('reader.listen'), icon: 'i-play', act: 'toast:' + c.t('reader.playing') }) +
      '</div>', { tone: 'reader' }) }) +
      UI.section({ title: c.t('ayah.tafsir'), body: UI.card(
        '<p class="kard__lead">' + UI.esc(a.tafsir) + '</p>', { tone: 'quiet' }) }) +
      UI.section({ title: c.t('ayah.more'), body: UI.rows(D.AYAT.map(function (x) {
        return UI.richRow({ icon: 'i-book', title: x.surah + ' ' + x.s + ':' + x.a,
          sub: x.tr.slice(0, 62) + '…', act: 'tool:quran', chevron: true });
      })) });
  }
};
