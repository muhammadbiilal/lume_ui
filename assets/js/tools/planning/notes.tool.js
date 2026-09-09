/* ============================================================
   Lume — notes

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'notes',

  build: function (c) {
    var n = c.notes();
    var query = (c.state('q') || '').trim().toLowerCase();
    var notesShown = n.all.filter(function (x) {
      return !query || (x.title + ' ' + x.excerpt + ' ' + x.folder).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ body: UI.searchBar({ placeholder: c.t('notes.search'), target: 'notes', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.metrics([
        { value: String(n.all.length), label: c.t('notes.total') },
        { value: String(n.pinned.length), label: c.t('notes.pinned') },
        { value: String(n.folders.length), label: c.t('notes.folders') }
      ], 3) }) +
      (n.pinned.length ? UI.section({ title: c.t('notes.pinned'), flush: true, body:
        UI.hscroll(n.pinned.map(function (x) {
          return '<button class="notecardx pressable" data-act="toast:' + UI.esc(x.title) + '">' +
            '<span class="notecardx__title">' + UI.esc(x.title) + '</span>' +
            '<span class="notecardx__body">' + UI.esc(x.excerpt) + '</span>' +
            '<span class="notecardx__meta">' + UI.esc(x.when) + '</span></button>';
        })) }) : '') +
      UI.section({ title: c.t('notes.folders'), body: UI.rows(n.folders.map(function (f) {
        return UI.compactRow({ icon: 'i-folder', label: f.label, value: String(f.n) });
      })) }) +
      UI.section({ title: c.t('notes.recent'), body: notesShown.length ? UI.rows(notesShown.map(function (x) {
        return UI.richRow({ icon: 'i-note', title: x.title, sub: x.excerpt,
          meta: [x.folder, x.when], act: 'toast:' + x.title, chevron: true });
      })) : UI.emptyState({ icon: 'i-note', title: c.t('notes.noMatch'), text: c.t('notes.noMatchText') }) }) +
      UI.fab({ icon: 'i-plus', label: c.t('notes.new'), act: 'toast:' + c.t('notes.creating') });
  }
};
