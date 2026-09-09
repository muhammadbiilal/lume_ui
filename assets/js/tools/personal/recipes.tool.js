/* ============================================================
   Lume — recipes

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'recipes',

  /* ---------------------------------------------------------
     §63 Recipes — visual library + reader
     --------------------------------------------------------- */
  build: function (c) {
    var cuisine = c.state('cuisine') || 'all';
    var query = (c.state('q') || '').trim().toLowerCase();
    var list = (cuisine === 'all' ? D.RECIPES : D.RECIPES.filter(function (r) { return r.cuisine === cuisine; }))
      .filter(function (r) {
        return !query || (r.name + ' ' + r.cuisine + ' ' + r.tags.join(' ')).toLowerCase().indexOf(query) !== -1;
      });
    var cuisines = ['all'].concat(D.RECIPES.map(function (r) { return r.cuisine; })
      .filter(function (v, i, a) { return a.indexOf(v) === i; }));

    return UI.section({ body: UI.searchBar({ placeholder: c.t('recipes.search'), target: 'recipes', value: c.state('q') || '' }) }) +
      UI.section({ flush: true, body: '<div class="chips chips--scroll">' +
        cuisines.map(function (x) {
          return '<button class="chip' + (x === cuisine ? ' is-on' : '') + '" data-act="toolstate:recipes:cuisine:' + UI.esc(x) + '">' +
            UI.esc(x === 'all' ? c.t('common.all') : x) + '</button>';
        }).join('') + '</div>' }) +
      UI.section({ title: c.t('recipes.favourites'), flush: true, body: UI.hscroll(
        D.RECIPES.filter(function (r) { return r.fav; }).map(function (r) {
          return UI.imageCard({
            tone: r.tone, seed: r.name.length, glyph: r.glyph,
            kicker: r.cuisine, title: r.name,
            meta: (r.prep + r.cook) + ' ' + c.t('unit.min') + ' · ' + c.t('recipes.serves', { n: r.serves }),
            act: 'toast:' + r.name
          });
        })) }) +
      UI.section({ title: c.t('recipes.all'), body: list.length ? UI.rows(list.map(function (r) {
        return UI.richRow({
          thumb: UI.art({ tone: r.tone, seed: r.name.length, glyph: r.glyph }),
          title: r.name, sub: r.cuisine,
          meta: [c.t('recipes.prepCook', { prep: r.prep, cook: r.cook }),
                 c.t('recipes.serves', { n: r.serves }),
                 c.num(r.kcal) + ' ' + c.t('unit.kcal'),
                 c.t('recipes.stepsN', { n: r.steps }),
                 r.ingredients + ' ' + c.t('recipes.ingredients'),
                 r.tags.join(' · ')],
          badge: r.fav ? { label: c.t('common.saved'), tone: 'ok' } : null,
          act: 'toast:' + r.name, chevron: true
        });
      })) : UI.emptyState({ icon: 'i-utensils', title: c.t('recipes.noMatch'),
        text: c.t('recipes.noMatchText') }) }) +
      UI.section({ title: c.t('recipes.related'), body: UI.rows([
        UI.compactRow({ icon: 'i-calendar', label: c.t('f.mealplan'), act: 'tool:mealplan' }),
        UI.compactRow({ icon: 'i-cart', label: c.t('f.shopping'), act: 'tool:shopping' })
      ]) });
  }
};
