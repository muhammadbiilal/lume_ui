/* ============================================================
   Lume — tasbih

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'tasbih',

  /* ---------------------------------------------------------
     24.15 Tasbih — focused interaction, deliberately low density
     --------------------------------------------------------- */
  build: function (c) {
    var s = c.tasbih();
    var dh = D.DHIKR[s.dhikrIndex];
    return '<div class="tasbih">' +
      '<div class="tasbih__pick">' +
        D.DHIKR.map(function (d, i) {
          return '<button class="tasbih__opt' + (i === s.dhikrIndex ? ' is-on' : '') + '" data-dhikr="' + i + '">' +
            UI.esc(d.tl) + '</button>';
        }).join('') +
      '</div>' +
      '<p class="tasbih__ar arabic">' + UI.esc(dh.ar) + '</p>' +
      '<p class="tasbih__tr">' + UI.esc(dh.tr) + '</p>' +
      '<button class="tasbih__counter pressable" data-tasbih-count aria-label="' + UI.esc(c.t('tasbih.count')) + '">' +
        '<svg class="tasbih__ring" viewBox="0 0 200 200" aria-hidden="true">' +
          '<circle cx="100" cy="100" r="88" class="tasbih__ringbg" fill="none" stroke-width="8"/>' +
          '<circle cx="100" cy="100" r="88" class="tasbih__ringfg" fill="none" stroke-width="8"' +
            ' stroke-dasharray="' + (2 * Math.PI * 88).toFixed(1) + '"' +
            ' stroke-dashoffset="' + ((1 - s.count / dh.target) * 2 * Math.PI * 88).toFixed(1) + '"' +
            ' data-tasbih-ring/>' +
        '</svg>' +
        '<span class="tasbih__num" data-tasbih-num>' + s.count + '</span>' +
        '<span class="tasbih__target" data-tasbih-target>' + c.t('tasbih.of', { n: dh.target }) + '</span>' +
      '</button>' +
      '<div class="tasbih__acts">' +
        UI.button({ label: c.t('tasbih.reset'), icon: 'i-refresh', act: 'tasbihreset' }) +
        UI.button({ label: c.t('tasbih.sets', { n: s.sets }), icon: 'i-beads' }) +
      '</div>' +
    '</div>' +
    UI.section({ title: c.t('tasbih.history'), body: UI.rows(s.history.map(function (h) {
      return UI.compactRow({ icon: 'i-beads', label: h.dhikr, sub: h.when, value: String(h.count) });
    })) });
  }
};
