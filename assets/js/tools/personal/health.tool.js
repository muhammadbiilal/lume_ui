/* ============================================================
   Lume — health

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'health',

  /* ---------------------------------------------------------
     §69 Health records — personal health record manager
     --------------------------------------------------------- */
  build: function (c) {
    var h = c.health();
    var kind = c.filter('kind', 'all');
    var records = h.records.filter(function (r) { return kind === 'all' || r.kind === kind; });

    return UI.section({ flush: true, body: '<div class="people">' +
        h.people.map(function (p) {
          return '<button class="person' + (p.id === h.selected ? ' is-on' : '') + '" data-act="toolstate:health:person:' + p.id + '">' +
            '<span class="person__avatar">' + UI.esc(p.initials) + '</span>' +
            '<span class="person__name">' + UI.esc(p.name) + '</span>' +
          '</button>';
        }).join('') + '</div>' }) +
      UI.section({ body: UI.summaryCard({
        tone: 'lock',
        kicker: h.person.name,
        value: h.upcoming + ' <small>' + UI.esc(c.t('health.upcoming')) + '</small>',
        caption: h.nextLabel,
        stats: [
          { value: h.person.blood, label: c.t('health.blood') },
          { value: String(h.person.age), label: c.t('health.age') },
          { value: c.money(h.spend), label: c.t('health.spendYear') }
        ]
      }) }) +
      UI.section({ body: UI.filterBar([{ id: 'kind', label: c.t('health.recordType'), items: [
        { value: 'all', label: c.t('common.all'), on: kind === 'all' }
      ].concat(h.kinds.map(function (k) {
        return { value: k.id, label: k.label, count: k.n, on: kind === k.id };
      })) }], 'health') }) +
      UI.section({ title: c.t('health.timeline'), body: records.length
        ? UI.timeline(records.map(function (r) {
        return { time: r.date, title: r.title, sub: r.who,
          meta: r.flag ? UI.statusBadge({ label: r.flag, tone: 'warn' }) : r.kind,
          value: r.cost ? c.money(r.cost) : '', state: r.state === 'upcoming' ? 'now' : 'done' };
          }))
        : UI.emptyState({ icon: 'i-pulse', title: c.t('health.noRecords'),
            text: c.t('health.noRecordsText'),
            action: { label: c.t('health.addRecord'), act: 'toast:' + c.t('health.adding'), icon: 'i-plus' } }) }) +
      UI.section({ title: c.t('health.vitals'), body: UI.card(
        UI.lineChart({ values: h.vitals, labels: [c.t('range.6m'), c.t('range.3m'), c.t('common.now')],
          label: c.t('health.weight'), caption: c.t('health.weightCap') })) }) +
      UI.section({ title: c.t('health.related'), body: UI.rows([
        UI.compactRow({ icon: 'i-syringe', label: c.t('f.vaccines'), value: c.t('health.doses', { n: h.vaccineDue }), act: 'tool:vaccines' }),
        UI.compactRow({ icon: 'i-pill', label: c.t('f.meds'), value: c.t('health.activeMeds', { n: 2 }), act: 'tool:meds' }),
        UI.compactRow({ icon: 'i-folder', label: c.t('f.documents'), value: c.t('common.locked'), act: 'tool:documents' })
      ]) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('health.addRecord'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('health.adding') },
        { label: c.t('health.exportSummary'), icon: 'i-download', act: 'export:health' }]) });
  }
};
