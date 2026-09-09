/* ============================================================
   Lume — ledger

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'ledger',

  /* ---------------------------------------------------------
     §36 Lending ledger — personal financial manager
     --------------------------------------------------------- */
  build: function (c) {
    var g = c.ledger();
    var dir = c.filter('dir', 'all');
    var people = g.people.filter(function (p) {
      if (dir === 'lent') return p.amount > 0;
      if (dir === 'borrowed') return p.amount < 0;
      if (dir === 'overdue') return !!p.overdue;
      return true;
    });
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('ledger.net'),
        value: c.money(g.net),
        caption: g.net >= 0 ? c.t('ledger.owedToYou') : c.t('ledger.youOwe'),
        stats: [
          { value: c.money(g.lent), label: c.t('ledger.lent') },
          { value: c.money(g.borrowed), label: c.t('ledger.borrowed') },
          { value: String(g.people.length), label: c.t('ledger.people') }
        ]
      }) }) +
      UI.section({ body: UI.filterBar([{ id: 'dir', label: c.t('ledger.direction'), items: [
        { value: 'all', label: c.t('common.all'), on: dir === 'all' },
        { value: 'lent', label: c.t('ledger.lent'), on: dir === 'lent' },
        { value: 'borrowed', label: c.t('ledger.borrowed'), on: dir === 'borrowed' },
        { value: 'overdue', label: c.t('common.overdue'), on: dir === 'overdue' }
      ] }], 'ledger') }) +
      UI.section({ title: c.t('ledger.people'), body: people.length ? UI.rows(people.map(function (p) {
        return UI.richRow({
          logo: p.initials, logoTone: 'var(--tone-' + p.tone + ')',
          title: p.name, sub: p.note,
          meta: [p.since, p.due ? c.t('ledger.due', { date: p.due }) : ''],
          badge: p.overdue ? { label: c.t('common.overdue'), tone: 'warn' } : null,
          value: c.money(Math.abs(p.amount)),
          valueSub: p.amount >= 0 ? c.t('ledger.owesYou') : c.t('ledger.youOweShort'),
          act: 'toast:' + p.name, chevron: true
        });
      })) : UI.emptyState({ icon: 'i-users', title: c.t('ledger.noMatch'), text: c.t('ledger.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:ledger:dir:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('common.recent'), body: UI.rows(g.entries.map(function (e) {
        return UI.compactRow({ icon: e.amount >= 0 ? 'i-arrow-r' : 'i-arrow-r', label: e.who, sub: e.when,
          value: (e.amount >= 0 ? '+' : '−') + c.money(Math.abs(e.amount)) });
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('ledger.add'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('ledger.adding') },
        { label: c.t('ledger.remind'), icon: 'i-bell', act: 'toast:' + c.t('ledger.reminded') }]) });
  }
};
