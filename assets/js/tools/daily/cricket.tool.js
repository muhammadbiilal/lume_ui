/* ============================================================
   Lume — cricket

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'cricket',

  /* ---------------------------------------------------------
     §45 Cricket — live sports dashboard
     --------------------------------------------------------- */
  build: function (c) {
    var k = D.CRICKET, m = k.live;
    var tab = c.state('tab') || 'live';
    return UI.section({ body: UI.card(
        '<div class="mscore">' +
          '<div class="mscore__side"><b>' + UI.esc(m.t1) + '</b><span>' + UI.esc(m.t1full) + '</span></div>' +
          '<div class="mscore__mid">' +
            '<p class="mscore__runs">' + UI.esc(m.s1) + '</p>' +
            '<p class="mscore__overs">' + UI.esc(m.o1) + ' ' + UI.esc(c.t('cricket.overs')) + '</p>' +
            UI.freshness({ quality: 'live', label: c.t('cricket.live') }) +
          '</div>' +
          '<div class="mscore__side score__side--away"><b>' + UI.esc(m.t2) + '</b><span>' + UI.esc(m.t2full) + '</span>' +
            (m.s2 && m.s2 !== '—' ? '<i class="mscore__second">' + UI.esc(m.s2) + ' (' + UI.esc(m.o2) + ')</i>' : '') + '</div>' +
        '</div>' +
        '<p class="mscore__status">' + UI.esc(c.t(m.statusKey, { team: m.t1full })) + '</p>' +
        UI.metrics([
          { value: c.num(m.rr, { minimumFractionDigits: 2, maximumFractionDigits: 2 }), label: c.t('cricket.runRate') },
          { value: m.format, label: c.t('cricket.format') },
          { value: m.venue.split(',')[0], label: c.t('cricket.venue') }
        ], 3), { tone: 'sport' }) }) +
      UI.section({ flush: true, body: UI.tabs({ id: 'cricket', items: [
        { value: 'live', label: c.t('cricket.live'), on: tab === 'live', act: 'toolstate:cricket:tab:live' },
        { value: 'fixtures', label: c.t('cricket.fixtures'), on: tab === 'fixtures', act: 'toolstate:cricket:tab:fixtures' },
        { value: 'standings', label: c.t('cricket.standings'), on: tab === 'standings', act: 'toolstate:cricket:tab:standings' }
      ] }) }) +
      (tab === 'fixtures'
        ? UI.section({ title: c.t('cricket.upcoming'), body: UI.rows(k.fixtures.map(function (f) {
            return UI.richRow({ icon: 'i-cricket', title: f.t1 + ' v ' + f.t2, sub: f.venue,
              meta: [f.format], value: f.when.split(' · ')[0], valueSub: f.when.split(' · ')[1] });
          })) })
        : tab === 'standings'
        ? UI.section({ title: c.t('cricket.table'), body: UI.table({
            label: c.t('cricket.table'),
            cols: [{ label: c.t('cricket.team') }, { label: c.t('cricket.played'), align: 'right' },
                   { label: c.t('cricket.won'), align: 'right' }, { label: c.t('cricket.lost'), align: 'right' },
                   { label: c.t('cricket.points'), align: 'right' }, { label: c.t('cricket.nrr'), align: 'right' }],
            rows: k.standings.map(function (s) {
              return { cells: [UI.esc(s.team), c.num(s.p), c.num(s.w), c.num(s.l),
                               '<b>' + c.num(s.pts) + '</b>', UI.esc(s.nrr)] };
            })
          }) })
        : UI.section({ title: c.t('cricket.batting'), body: UI.table({
            label: c.t('cricket.batting'),
            cols: [{ label: c.t('cricket.batter') }, { label: c.t('cricket.runs'), align: 'right' },
                   { label: c.t('cricket.balls'), align: 'right' }, { label: c.t('cricket.fours'), align: 'right' },
                   { label: c.t('cricket.sixes'), align: 'right' }, { label: c.t('cricket.strikeRate'), align: 'right' }],
            rows: m.batters.map(function (b) {
              return { cells: ['<b>' + UI.esc(b.n) + '</b>' + (b.out ? '' : ' <i class="cellsub">' + UI.esc(c.t('cricket.notOut')) + '</i>'),
                               c.num(b.r), c.num(b.b), c.num(b.f), c.num(b.s), c.num(b.sr, { maximumFractionDigits: 1 })] };
            })
          }) }) +
          UI.section({ title: c.t('cricket.bowling'), body: UI.table({
            label: c.t('cricket.bowling'),
            cols: [{ label: c.t('cricket.bowler') }, { label: c.t('cricket.overs2'), align: 'right' },
                   { label: c.t('cricket.maidens'), align: 'right' }, { label: c.t('cricket.runs'), align: 'right' },
                   { label: c.t('cricket.wickets'), align: 'right' }, { label: c.t('cricket.economy'), align: 'right' }],
            rows: m.bowlers.map(function (b) {
              return { cells: ['<b>' + UI.esc(b.n) + '</b>', c.num(b.o), c.num(b.m), c.num(b.r),
                               '<b>' + c.num(b.w) + '</b>', c.num(b.ec, { maximumFractionDigits: 2 })] };
            })
          }) }));
  }
};
