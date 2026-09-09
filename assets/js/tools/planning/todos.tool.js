/* ============================================================
   Lume — todos

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'todos',

  /* ---------------------------------------------------------
     §57.1 To-dos · §58 Notes · reminders · events
     --------------------------------------------------------- */
  build: function (c) {
    var t = c.todos();
    var when = c.filter('when', 'today');
    var prio = c.filter('priority', 'any');
    var query = (c.state('q') || '').trim().toLowerCase();

    var pool = when === 'today' ? t.today : t.today.concat(t.upcoming);
    var visible = pool.filter(function (x) {
      if (prio !== 'any' && (x.priority || 'normal') !== prio) return false;
      if (query && (x.label + ' ' + x.list).toLowerCase().indexOf(query) === -1) return false;
      return true;
    });

    return UI.section({ body: UI.summaryCard({
        kicker: c.t('todos.today'),
        value: t.doneToday + ' <small>/ ' + t.today.length + '</small>',
        caption: t.overdue ? c.t('todos.overdueN', { n: t.overdue }) : c.t('todos.onTrack'),
        aside: UI.progressRing({ value: t.today.length ? t.doneToday / t.today.length : 0,
          centre: Math.round((t.today.length ? t.doneToday / t.today.length : 0) * 100) + '%', label: c.t('todos.today') }),
        stats: [
          { value: String(t.overdue), label: c.t('common.overdue') },
          { value: String(t.upcoming.length), label: c.t('todos.upcoming') },
          { value: String(t.done7), label: c.t('todos.done7') }
        ]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('todos.search'), target: 'todos', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.filterBar([
        { id: 'when', label: c.t('todos.when'), items: [
          { value: 'today', label: c.t('common.today'), on: when === 'today' },
          { value: 'week', label: c.t('common.week'), on: when === 'week' },
          { value: 'all', label: c.t('common.all'), on: when === 'all' } ] },
        { id: 'priority', label: c.t('todos.priority'), items: [
          { value: 'any', label: c.t('common.all'), on: prio === 'any' },
          { value: 'high', label: c.t('todos.high'), on: prio === 'high' },
          { value: 'normal', label: c.t('todos.normal'), on: prio === 'normal' } ] }
      ], 'todos') }) +
      UI.section({ title: c.t('todos.today'), body: visible.length
        ? UI.rows(visible.map(function (x) {
        return '<button class="taskrow pressable' + (x.done ? ' is-done' : '') + '" data-task="' + UI.esc(x.id) + '"' +
          ' role="checkbox" aria-checked="' + (x.done ? 'true' : 'false') + '">' +
          '<span class="taskrow__box">' + UI.ico('i-check') + '</span>' +
          '<span class="taskrow__body"><span class="taskrow__label">' + UI.esc(x.label) + '</span>' +
            '<span class="taskrow__meta">' + UI.esc(x.list) + (x.due ? ' · ' + UI.esc(x.due) : '') + '</span></span>' +
          (x.priority === 'high' ? UI.statusBadge({ label: c.t('todos.high'), tone: 'warn' }) : '') +
        '</button>';
          }))
        : UI.emptyState({ icon: 'i-check-circle', title: c.t('todos.clear'), text: c.t('todos.clearText') }) }) +
      UI.section({ title: c.t('todos.upcoming'), body: UI.rows(t.upcoming.map(function (x) {
        return UI.compactRow({ icon: 'i-check-square', label: x.label, sub: x.list, value: x.due });
      })) }) +
      UI.section({ title: c.t('todos.lists'), body: UI.rows(t.lists.map(function (l) {
        return UI.compactRow({ icon: l.icon, label: l.label, value: l.open + ' ' + c.t('todos.open') });
      })) }) +
      UI.fab({ icon: 'i-plus', label: c.t('todos.add'), act: 'toast:' + c.t('todos.adding') });
  }
};
