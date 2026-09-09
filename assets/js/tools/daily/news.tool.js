/* ============================================================
   Lume — news

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'news',

  /* ---------------------------------------------------------
     §44 News — editorial feed. Images earn their place here.
     --------------------------------------------------------- */
  build: function (c) {
    var cat = c.state('cat') || 'Top';
    var all = D.newsFor(c.profile.country);
    var query = (c.state('q') || '').trim().toLowerCase();
    var list = (cat === 'Top' ? all : all.filter(function (n) { return n.cat === cat; }))
      .filter(function (n) {
        return !query || (n.title + ' ' + n.src + ' ' + n.cat).toLowerCase().indexOf(query) !== -1;
      });
    var lead = list[0] || null;
    var rest = list.slice(1);

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: c.t('news.edition') }]) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('news.search'), target: 'news', value: c.state('q') || '' }) }) +
      UI.section({ flush: true, body: '<div class="chips chips--scroll">' +
        D.NEWS_CATEGORIES.map(function (x) {
          return '<button class="chip' + (x === cat ? ' is-on' : '') + '" data-act="toolstate:news:cat:' + UI.esc(x) + '">' +
            UI.esc(x) + '</button>';
        }).join('') + '</div>' }) +
      (lead ? UI.section({ title: c.t('news.top'), body:
        '<button class="lead pressable" data-act="toast:' + UI.esc(lead.title) + '">' +
          UI.art({ tone: lead.tone, seed: lead.title.length, cls: 'lead__art' }) +
          '<span class="lead__body">' +
            '<span class="lead__cat">' + UI.esc(lead.cat) + '</span>' +
            '<span class="lead__title">' + UI.esc(lead.title) + '</span>' +
            '<span class="lead__meta">' + UI.esc(lead.src) + ' · ' + UI.esc(lead.ago) + ' · ' +
              UI.esc(c.t('news.readTime', { n: lead.mins })) + '</span>' +
          '</span>' +
        '</button>' }) : '') +
      UI.section({ title: c.t('news.latest'), body: rest.length ? UI.rows(rest.map(function (n) {
        return UI.richRow({
          thumb: UI.art({ tone: n.tone, seed: n.title.length + n.mins }),
          title: n.title,
          sub: n.src,
          meta: [n.cat, n.ago, c.t('news.readTime', { n: n.mins })],
          act: 'toast:' + n.title, chevron: true
        });
      })) : UI.emptyState({ icon: 'i-news', title: c.t('news.empty.title'), text: c.t('news.empty.text') }) }) +
      UI.section({ title: c.t('news.saved'), body: UI.rows([
        UI.compactRow({ icon: 'i-bookmark', label: c.t('news.savedCount', { n: 4 }), act: 'toast:' + c.t('news.savedOpen') }),
        UI.compactRow({ icon: 'i-sliders', label: c.t('news.sources'), value: c.t('news.sourcesValue', { n: 8 }), act: 'toast:' + c.t('news.sourcesEdit') })
      ]) });
  }
};
