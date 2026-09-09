/* ============================================================
   Lume — committee

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'committee',

  /* ---------------------------------------------------------
     §38 Committee — group finance manager
     --------------------------------------------------------- */
  build: function (c) {
    var k = c.committee();
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('committee.pool'),
        value: c.money(k.pool),
        caption: c.t('committee.cycle', { a: k.month, b: k.months }),
        aside: UI.progressRing({ value: k.month / k.months, centre: k.month + '/' + k.months, label: c.t('committee.cycleShort') }),
        stats: [
          { value: c.money(k.contribution), label: c.t('committee.contribution') },
          { value: String(k.members.length), label: c.t('committee.members') },
          { value: c.t('committee.monthN', { n: k.yourTurn }), label: c.t('committee.yourTurn') }
        ]
      }) }) +
      UI.section({ title: c.t('committee.thisMonth'), body: UI.rows(k.members.map(function (m) {
        return UI.richRow({
          logo: m.initials, logoTone: 'var(--tone-' + m.tone + ')',
          title: m.name, sub: m.paid ? c.t('committee.paidOn', { date: m.when }) : c.t('committee.pending'),
          meta: [c.t('committee.turnMonth', { n: m.turn })],
          badge: m.paid ? { label: c.t('common.paid'), tone: 'ok' } : { label: c.t('common.pending'), tone: 'warn' },
          value: c.money(k.contribution)
        });
      })) }) +
      UI.section({ title: c.t('committee.payoutOrder'), body: UI.timeline(k.order.map(function (o) {
        return { time: o.month, title: o.name, sub: o.you ? c.t('committee.you') : '', value: c.money(k.pool), state: o.state };
      })) }) +
      UI.section({ title: c.t('committee.collection'), body: UI.card(
        UI.barChart({ values: k.collected, labels: k.collectedLabels, highlight: k.month - 1,
          label: c.t('committee.collection'), caption: c.t('committee.collectionCap') })) }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(k.history.map(function (h) {
        return UI.compactRow({ icon: 'i-users', label: h.name, sub: h.when, value: c.money(h.amount) });
      })) });
  }
};
