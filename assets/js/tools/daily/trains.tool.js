/* ============================================================
   Lume — trains

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'trains',

  /* ---------------------------------------------------------
     §42 Trains — live tracking, very high density
     --------------------------------------------------------- */
  build: function (c) {
    var sel = c.state('train') || D.TRAINS[0].no;
    var train = D.TRAINS.filter(function (t) { return t.no === sel; })[0] || D.TRAINS[0];
    var ccy = c.L.country().currency;
    var onTime = D.TRAINS.filter(function (t) { return !t.delay; }).length;
    var status = c.filter('status', 'all');
    var shown = D.TRAINS.filter(function (t) {
      return status === 'all' || (status === 'ontime' ? !t.delay : !!t.delay);
    });

    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: c.profile.city, act: 'sheet:personalise' },
        { label: c.t('trains.operator') }]) }) +
      UI.section({ body: UI.card(UI.formGrid([
        UI.field({ label: c.t('trains.from'), name: 'tr_from', value: train.from }),
        UI.field({ label: c.t('trains.to'), name: 'tr_to', value: train.to })
      ]) + UI.buttonRow([{ label: c.t('trains.find'), tone: 'accent', icon: 'i-search', block: true,
        act: 'toast:' + c.t('trains.searching') }])) }) +
      UI.section({ body: UI.metrics([
        { value: String(D.TRAINS.length), label: c.t('trains.running') },
        { value: String(onTime), label: c.t('trains.onTime') },
        { value: String(D.TRAINS.length - onTime), label: c.t('trains.delayed') }
      ], 3) }) +
      UI.section({ body: UI.filterBar([{ id: 'status', label: c.t('common.status'), items: [
        { value: 'all', label: c.t('common.all'), on: status === 'all' },
        { value: 'ontime', label: c.t('trains.onTime'), on: status === 'ontime' },
        { value: 'late', label: c.t('trains.delayed'), on: status === 'late' }
      ] }], 'trains') }) +
      UI.section({ title: c.t('trains.departures'), body: shown.length ? UI.rows(shown.map(function (t) {
        return UI.richRow({
          logo: t.no.replace(/[A-Z]+/, ''), logoTone: t.delay ? 'var(--tone-amber)' : 'var(--tint-accent)',
          title: t.name,
          sub: t.from + ' → ' + t.to,
          meta: [t.dep + ' – ' + t.arr, t.dur, c.t('trains.platform') + ' ' + t.platform],
          badge: { label: c.t(t.statusKey, { n: t.delay }), tone: t.tone === 'ok' ? 'ok' : 'late' },
          value: c.moneyRaw(t.fare, ccy, 0),
          valueSub: c.t('trains.from2'),
          act: 'toolstate:trains:train:' + t.no,
          cls: t.no === sel ? 'is-selected' : ''
        });
      })) : UI.emptyState({ icon: 'i-train', title: c.t('trains.noMatch'), text: c.t('trains.noMatchText'),
        action: { label: c.t('common.all'), act: 'toolstate:trains:status:all', icon: 'i-refresh' } }) }) +
      UI.section({ title: c.t('trains.selected', { name: train.name }), body: UI.card(
        UI.journey({
          fromCode: train.fromCode, from: train.from, fromTime: train.dep,
          toCode: train.toCode, to: train.to, toTime: train.arr,
          duration: train.dur, progress: train.progress, icon: 'i-train'
        }) +
        UI.metrics([
          { value: c.L.speed(train.speed), label: c.t('trains.speed') },
          { value: train.next, label: c.t('trains.nextStop') },
          { value: train.delay ? '+' + train.delay + 'm' : c.t('trains.onTime'), label: c.t('trains.delay') }
        ], 3)) }) +
      UI.section({ body: UI.map({
        label: c.t('trains.route'), caption: train.from + ' → ' + train.to,
        route: 'M8 84 C 30 70, 40 44, 62 30 S 88 14, 94 8',
        markers: [
          { x: 8, y: 84, icon: 'i-pin', label: train.from },
          { x: 8 + (94 - 8) * train.progress, y: 84 - (84 - 8) * train.progress, icon: 'i-train', label: train.name, active: true },
          { x: 94, y: 8, icon: 'i-pin', label: train.to }
        ]
      }) }) +
      UI.section({ title: c.t('trains.stops'), body: UI.timeline(D.TRAIN_STOPS.map(function (s) {
        return { time: s.sched, title: s.st,
          sub: s.act !== '—' ? c.t('trains.actual', { time: s.act }) : c.t('trains.scheduled'),
          meta: c.L.distance(s.km), state: s.state === 'done' ? 'done' : s.state === 'now' ? 'now' : '' };
      })) }) +
      UI.section({ title: c.t('trains.fares'), body: UI.table({
        label: c.t('trains.fares'),
        cols: [{ label: c.t('trains.class') }, { label: c.t('trains.fare'), align: 'right' },
               { label: c.t('trains.seats'), align: 'right' }],
        rows: train.classes.map(function (cl, i) {
          return { cells: [UI.esc(cl), c.moneyRaw(train.fare * (i ? 0.72 : 1), ccy, 0), String(48 - i * 17)] };
        })
      }) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('trains.remind'), tone: 'accent', icon: 'i-bell', act: 'toast:' + c.t('trains.reminded', { name: train.name }) },
        { label: c.t('common.share'), icon: 'i-share', act: 'share:trains' }]) });
  }
};
