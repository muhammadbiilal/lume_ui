/* ============================================================
   Lume — prizebonds

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'prizebonds',

  /* ---------------------------------------------------------
     §31 Prize Bonds — search + results
     --------------------------------------------------------- */
  build: function (c) {
    var list = D.PRIZE_BONDS[c.profile.country];
    if (!list) return UI.section({ body: UI.emptyState({
      icon: 'i-ticket', title: c.t('bonds.unavailable.title'), text: c.t('bonds.unavailable.text') }) });
    var ccy = c.L.country().currency;

    var next = list.slice().sort(function (a, b) { return a.denom - b.denom; })[0];
    var pool = list.reduce(function (a, b) { return a + b.first + b.second * 3 + b.third * b.winners; }, 0);
    var saved = c.state('saved') || [];

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' },
        { label: c.t('bonds.scheme') }
      ]) }) +
      UI.section({ body: UI.summaryCard({
        kicker: c.t('bonds.nextDraw'),
        value: next.date,
        caption: c.t('bonds.nextDrawSub', { denom: c.moneyRaw(next.denom, ccy, 0), draw: next.draw }),
        stats: [
          { value: c.moneyRaw(pool, ccy, 0), label: c.t('bonds.prizePool') },
          { value: c.num(list.reduce(function (a, b) { return a + b.winners; }, 0)), label: c.t('bonds.totalWinners') },
          { value: String(list.length), label: c.t('bonds.denominations') }
        ]
      }) }) +
      UI.section({ body: UI.card(
        '<p class="kard__lead">' + UI.esc(c.t('bonds.checkLead')) + '</p>' +
        UI.formGrid([
          UI.selectField({ label: c.t('bonds.denomination'), name: 'pb_denom', value: '750',
            options: list.map(function (b) { return { value: String(b.denom), label: c.moneyRaw(b.denom, ccy, 0) }; }) }),
          UI.field({ label: c.t('bonds.number'), name: 'pb_num', placeholder: '000000', inputmode: 'numeric' })
        ]) +
        UI.buttonRow([{ label: c.t('bonds.check'), tone: 'accent', icon: 'i-search', block: true,
          act: 'toast:' + c.t('bonds.noWin') }])) }) +
      UI.section({ title: c.t('bonds.draws'), body: UI.rows(list.map(function (b) {
        return UI.richRow({
          logo: String(b.denom), logoTone: 'var(--tint-accent)',
          title: c.moneyRaw(b.denom, ccy, 0) + ' ' + c.t('bonds.bond'),
          sub: b.draw,
          meta: [b.date, c.t('bonds.winners', { n: c.num(b.winners) })],
          value: c.moneyRaw(b.first, ccy, 0),
          valueSub: c.t('bonds.firstPrize'),
          act: 'toast:' + b.draw + ' · ' + b.date, chevron: true
        });
      })) }) +
      UI.section({ title: c.t('bonds.prizeTiers'), body: UI.table({
        label: c.t('bonds.prizeTiers'),
        cols: [{ label: c.t('bonds.bond') }, { label: c.t('bonds.first'), align: 'right' },
               { label: c.t('bonds.second'), align: 'right' }, { label: c.t('bonds.third'), align: 'right' }],
        rows: list.map(function (b) {
          return { cells: [c.moneyRaw(b.denom, ccy, 0), c.moneyRaw(b.first, ccy, 0),
                           c.moneyRaw(b.second, ccy, 0), c.moneyRaw(b.third, ccy, 0)] };
        })
      }) }) +
      UI.section({ title: c.t('bonds.prizeShape'), body: UI.card(
        UI.barChart({
          values: list.map(function (b) { return b.first; }),
          labels: list.map(function (b) { return c.moneyRaw(b.denom, ccy, 0); }),
          label: c.t('bonds.prizeShape'), caption: c.t('bonds.prizeShapeCap') })) }) +
      UI.section({ title: c.t('bonds.yourNumbers'), body: saved.length
        ? UI.rows(saved.map(function (n) {
            return UI.compactRow({ icon: 'i-ticket', label: n, value: c.t('bonds.notDrawn') });
          }))
        : UI.emptyState({ icon: 'i-ticket', title: c.t('bonds.noneSaved'),
            text: c.t('bonds.noneSavedText') }) });
  }
};
