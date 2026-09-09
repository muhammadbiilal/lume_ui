/* ============================================================
   Lume — vehicle

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';
import { LUME_DATA as D } from '../../tooldata.js';

export default {
  id: 'vehicle',

  /* ---------------------------------------------------------
     §53 Vehicle & fines — vehicle manager
     --------------------------------------------------------- */
  build: function (c) {
    var cfg = c.vehicleCosts();
    var ccy = cfg.ccy;
    var query = (c.state('q') || '').trim().toLowerCase();
    var vehicles = D.VEHICLES.filter(function (v) {
      return !query || (v.plate + ' ' + v.make).toLowerCase().indexOf(query) !== -1;
    });
    var fines = D.VEHICLES.reduce(function (a, v) { return a + v.fines; }, 0);
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('vehicle.fleet'),
        value: String(D.VEHICLES.length),
        caption: fines ? c.t('vehicle.openFines', { n: fines }) : c.t('vehicle.noFines'),
        stats: [
          { value: c.money(D.VEHICLES.reduce(function (a, v) { return a + v.fineAmount; }, 0)),
            label: c.t('vehicle.outstanding') },
          { value: D.VEHICLES[0].token, label: c.t('vehicle.nextToken') },
          { value: c.L.distance(D.VEHICLES[0].odo), label: c.t('vehicle.odometer') }
        ]
      }) }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('vehicle.search'), target: 'vehicle', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('vehicle.yours'), body: UI.rows(vehicles.map(function (v) {
        return UI.richRow({
          logo: v.plate.slice(0, 3), logoTone: 'var(--tone-' + v.tone + ')',
          title: v.plate, sub: v.make + ' · ' + v.year,
          meta: [c.t('vehicle.token') + ' ' + v.token, c.t('vehicle.insurance') + ' ' + v.insurance],
          badge: v.fines ? { label: c.t('vehicle.fines', { n: v.fines }), tone: 'warn' }
                         : { label: c.t('vehicle.clear'), tone: 'ok' },
          value: c.L.distance(v.odo), valueSub: '',
          act: 'toast:' + v.plate, chevron: true
        });
      })) }) +
      UI.section({ title: c.t('vehicle.check'), body: UI.card(UI.formGrid([
        UI.field({ label: c.t('vehicle.registration'), name: 'veh_reg', placeholder: 'ABC-123', wide: true })
      ]) + UI.buttonRow([{ label: c.t('vehicle.lookup'), tone: 'accent', icon: 'i-search', block: true,
        act: 'toast:' + c.t('vehicle.lookingUp') }])) }) +
      UI.section({ title: c.t('vehicle.reminders'), body: UI.timeline(
        D.VEHICLES.map(function (v, i) {
          return { time: v.token, title: c.t('vehicle.tokenTax'), sub: v.plate,
            meta: c.t('common.inDays', { n: v.tokenDays }),
            state: v.tokenDays < 30 ? 'now' : '',
            value: c.money(i === 0 ? cfg.tokenCar : cfg.tokenBike) };
        }).concat(D.VEHICLES.filter(function (v) { return v.insurance !== '—'; }).map(function (v) {
          return { time: v.insurance, title: c.t('vehicle.insuranceRenewal'), sub: v.plate,
            value: c.money(cfg.insurance) };
        }))) });
  }
};
