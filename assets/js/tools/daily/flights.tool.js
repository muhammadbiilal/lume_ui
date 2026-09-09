/* ============================================================
   Lume — flights

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'flights',

  /* ---------------------------------------------------------
     §43 Flights — live board + map, very high density
     --------------------------------------------------------- */
  build: function (c) {
    var sel = c.state('flight') || D.FLIGHTS[0].no;
    var fl = D.FLIGHTS.filter(function (f) { return f.no === sel; })[0] || D.FLIGHTS[0];
    var view = c.filter('view', 'arrivals');
    var query = (c.state('q') || '').trim().toLowerCase();
    var enRoute = D.FLIGHTS.filter(function (f) { return f.statusKey === 'flights.st.enroute'; }).length;

    /* Arrivals are the flights landing at the user's city; departures leave
       from it; tracked is what they asked to follow. The board actually
       changes what it lists (§112). */
    var home = (c.profile.city || '').slice(0, 3).toUpperCase();
    var board = D.FLIGHTS.filter(function (f) {
      if (view === 'departures') return f.fromCode !== f.toCode && f.progress < 1;
      if (view === 'tracked') return (c.profile.favourites || []).indexOf('flights') !== -1 || f.tone2 === 'live';
      return true;
    }).filter(function (f) {
      if (!query) return true;
      return (f.no + ' ' + f.airline + ' ' + f.from + ' ' + f.to + ' ' + f.fromCode + ' ' + f.toCode)
        .toLowerCase().indexOf(query) !== -1;
    });

    return UI.section({ body: UI.searchBar({
        placeholder: c.t('flights.search'), target: 'flights', value: c.state('q') || '' }) }) +
      UI.section({ body: UI.segmented({ id: 'flightview', label: c.t('flights.board'), items: [
        { value: 'arrivals', label: c.t('flights.arrivals'), on: view === 'arrivals', act: 'toolstate:flights:view:arrivals' },
        { value: 'departures', label: c.t('flights.departures'), on: view === 'departures', act: 'toolstate:flights:view:departures' },
        { value: 'tracked', label: c.t('flights.tracked'), on: view === 'tracked', act: 'toolstate:flights:view:tracked' }
      ] }) }) +
      UI.section({ body: UI.metrics([
        { value: String(D.FLIGHTS.length), label: c.t('flights.total') },
        { value: String(enRoute), label: c.t('flights.enRoute') },
        { value: String(D.FLIGHTS.filter(function (f) { return f.delay > 0; }).length), label: c.t('flights.delayed') }
      ], 3) }) +
      UI.section({ body: UI.map({
        tall: true, label: c.t('flights.map'), caption: fl.fromCode + ' → ' + fl.toCode,
        route: 'M10 78 C 34 50, 58 30, 90 16',
        markers: [
          { x: 10, y: 78, icon: 'i-pin', label: fl.from },
          { x: 10 + 80 * fl.progress, y: 78 - 62 * fl.progress, icon: 'i-plane', label: fl.no, active: true },
          { x: 90, y: 16, icon: 'i-pin', label: fl.to }
        ]
      }) }) +
      UI.section({ title: c.t('flights.live'), body: board.length ? UI.rows(board.map(function (f) {
        return UI.richRow({
          logo: f.logo, logoTone: 'var(--tone-' + f.tone + ')',
          title: f.no,
          sub: f.airline + ' · ' + f.craft,
          meta: [f.fromCode + ' → ' + f.toCode, c.t('flights.gate') + ' ' + f.gate,
                 f.delay ? '+' + f.delay + 'm' : c.t('flights.onTime')],
          badge: { label: c.t(f.statusKey), tone: f.tone2 },
          value: f.arr,
          valueSub: f.delay ? c.t('flights.eta') + ' ' + f.eta : c.t('flights.scheduled'),
          act: 'toolstate:flights:flight:' + f.no,
          cls: f.no === sel ? 'is-selected' : ''
        });
      })) : UI.emptyState({ icon: 'i-plane', title: c.t('flights.noMatch'),
        text: c.t('flights.noMatchText'),
        action: { label: c.t('flights.arrivals'), act: 'toolstate:flights:view:arrivals', icon: 'i-refresh' } }) }) +
      UI.section({ title: fl.no + ' · ' + fl.airline, body: UI.card(
        UI.journey({
          fromCode: fl.fromCode, from: fl.from, fromTime: fl.actual,
          toCode: fl.toCode, to: fl.to, toTime: fl.eta,
          duration: c.t('flights.remaining', { d: c.L.distance(Math.round(fl.dist * (1 - fl.progress))) }),
          progress: fl.progress, icon: 'i-plane'
        })) }) +
      UI.section({ title: c.t('flights.aircraft'), body: UI.table({
        label: c.t('flights.aircraft'),
        cols: [{ label: c.t('common.field') }, { label: c.t('common.value'), align: 'right' }],
        rows: [
          { cells: [c.t('flights.type'), UI.esc(fl.craft)] },
          { cells: [c.t('flights.registration'), UI.esc(fl.reg)] },
          { cells: [c.t('flights.altitude'), c.num(fl.alt) + ' ' + c.t('unit.ft')] },
          { cells: [c.t('flights.speed'), c.L.speed(fl.speed)] },
          { cells: [c.t('flights.distance'), c.L.distance(fl.dist)] },
          { cells: [c.t('flights.terminal'), UI.esc(fl.term) + ' · ' + c.t('flights.gate') + ' ' + UI.esc(fl.gate)] }
        ]
      }) }) +
      UI.section({ title: c.t('flights.timeline'), body: UI.timeline([
        { time: fl.dep, title: c.t('flights.scheduledDep'), sub: fl.from, state: 'done' },
        { time: fl.actual, title: c.t('flights.actualDep'), sub: fl.delay ? c.t('flights.lateBy', { n: fl.delay }) : c.t('flights.onTime'), state: 'done' },
        { time: '—', title: c.t('flights.cruise'), sub: c.num(fl.alt) + ' ' + c.t('unit.ft') + ' · ' + c.L.speed(fl.speed), state: fl.progress < 1 ? 'now' : 'done' },
        { time: fl.eta, title: c.t('flights.estArrival'), sub: fl.to, state: fl.progress >= 1 ? 'done' : '' }
      ]) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('flights.track'), tone: 'accent', icon: 'i-bell', act: 'toast:' + c.t('flights.tracking', { no: fl.no }) },
        { label: c.t('common.share'), icon: 'i-share', act: 'share:flights' }]) });
  }
};
