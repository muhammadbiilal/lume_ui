/* ============================================================
   Lume — documents

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'documents',

  /* ---------------------------------------------------------
     §67 Documents — secure records manager, very high density
     --------------------------------------------------------- */
  build: function (c) {
    var d = c.documents();
    var cat = c.filter('cat', 'all');
    var query = (c.state('q') || '').trim().toLowerCase();

    function keep(x) {
      if (cat !== 'all' && x.cat !== cat) return false;
      if (query && (x.name + ' ' + x.cat + ' ' + x.holder).toLowerCase().indexOf(query) === -1) return false;
      return true;
    }
    var groups = d.groups.map(function (g) {
      return { label: g.label, items: c.sortBy(g.items.filter(keep), {
        expiry: function (x) { return x.days === null ? 1e9 : x.days; },
        cat: function (x) { return x.cat; },
        updated: function (x) { return x.files; }
      }, 'expiry', 'asc') };
    }).filter(function (g) { return g.items.length; });

    return UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: c.t('docs.vault'),
        value: String(d.list.length),
        caption: d.expiring ? c.t('docs.expiringSoon', { n: d.expiring }) : c.t('docs.allValid'),
        aside: '<span class="lockmark">' + UI.ico('i-lock') + '</span>',
        stats: [
          { value: String(d.expired), label: c.t('docs.expired') },
          { value: String(d.expiring), label: c.t('docs.expiring') },
          { value: String(d.files), label: c.t('docs.files') }
        ]
      }) }) +
      (d.expiring ? UI.section({ body: UI.noteCard({ tone: 'warn', icon: 'i-alert',
        title: c.t('docs.renew.title', { n: d.expiring }), text: c.t('docs.renew.text') }) }) : '') +
      UI.section({ body: UI.filterBar([{ id: 'cat', label: c.t('docs.category'), items: [
        { value: 'all', label: c.t('common.all'), on: cat === 'all', count: d.list.length }
      ].concat(d.categories.map(function (x) {
        return { value: x.id, label: x.label, count: x.n, on: cat === x.id };
      })) }], 'documents') }) +
      UI.section({ body: UI.sortBar({ tool: 'documents', label: c.t('common.sort'),
        items: c.sortItems([
          { value: 'expiry', label: c.t('docs.expiry') },
          { value: 'cat', label: c.t('docs.category') },
          { value: 'updated', label: c.t('docs.updated') }
        ], 'expiry', 'asc') }) }) +
      (groups.length ? '' : UI.section({ body: UI.emptyState({ icon: 'i-folder',
        title: c.t('docs.noMatch'), text: c.t('docs.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:documents:cat:all', icon: 'i-refresh' } }) })) +
      groups.map(function (grp) {
        return UI.section({ title: grp.label, body: UI.rows(grp.items.map(function (x) {
          return UI.richRow({
            icon: x.icon, iconTone: x.tone,
            title: x.name, sub: x.num,
            meta: [x.holder, c.t('docs.filesN', { n: x.files })],
            badge: x.badge,
            value: x.expires,
            valueSub: x.days === null ? '' : c.t('common.inDays', { n: x.days }),
            act: 'toast:' + c.t('docs.unlockToView'), chevron: true
          });
        })) });
      }).join('') +
      UI.section({ body: UI.buttonRow([
        { label: c.t('docs.add'), tone: 'accent', icon: 'i-plus', act: 'tool:docscan' },
        { label: c.t('common.export'), icon: 'i-download', act: 'export:documents' }]) });
  }
};
