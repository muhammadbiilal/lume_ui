/* ============================================================
   Lume — play

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'play',

  build: function (c) {
    return UI.section({ title: c.t('play.games'), body: '<div class="tiles tiles--play">' +
        D.GAMES.map(function (g) {
          return '<button class="tile pressable" data-act="toast:' + UI.esc(g.name) + '">' +
            '<span class="tile__glyph">' + UI.esc(g.glyph) + '</span>' +
            '<span class="tile__label">' + UI.esc(g.name) + '</span>' +
            '<span class="tile__meta">' + UI.esc(g.kind) + ' · ' + UI.esc(g.best) + '</span></button>';
        }).join('') + '</div>' }) +
      UI.section({ title: c.t('play.recent'), body: UI.rows(D.GAMES.slice(0, 3).map(function (g) {
        return UI.compactRow({ icon: 'i-play', label: g.name, sub: g.kind,
          value: c.t('play.plays', { n: g.plays }) });
      })) });
  }
};
