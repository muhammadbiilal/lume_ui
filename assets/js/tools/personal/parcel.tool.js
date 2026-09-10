/* ============================================================
   Lume — parcel

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'parcel',

  /* ---------------------------------------------------------
     §59 Parcel tracker — tracking timeline
     --------------------------------------------------------- */
  build: function (c) {
    var sel = c.state('parcel') || D.PARCELS[0].ref;
    var p = D.PARCELS.filter(function (x) { return x.ref === sel; })[0] || D.PARCELS[0];
    return UI.section({ body: UI.card(UI.formGrid([
        UI.field({ label: c.t('parcel.tracking'), name: 'pc_ref', placeholder: c.t('parcel.placeholder'), wide: true })
      ]) + UI.buttonRow([{ label: c.t('parcel.track'), tone: 'accent', icon: 'i-search', block: true,
        act: 'toast:' + c.t('parcel.tracking2') }])) }) +
      UI.section({ title: c.t('parcel.active'), body: UI.rows(D.PARCELS.map(function (x) {
        return UI.richRow({
          logo: x.logo, logoTone: 'var(--tone-' + x.tone + ')',
          title: x.item, sub: x.carrier + ' · ' + x.ref,
          meta: [x.place, x.eta],
          badge: { label: x.status, tone: x.state },
          act: 'toolstate:parcel:parcel:' + x.ref,
          cls: x.ref === sel ? 'is-selected' : ''
        });
      })) }) +
      UI.section({ title: p.item, body: UI.card(
        UI.metrics([
          { icon: 'i-package', value: p.carrier, label: c.t('parcel.carrier') },
          { icon: 'i-pin', value: p.place, label: c.t('parcel.location') },
          { icon: 'i-clock', value: p.eta, label: c.t('parcel.eta') }
        ], 3) +
        UI.progressBar({ value: p.progress, label: p.item })) }) +
      UI.section({ title: c.t('parcel.events'), body: UI.timeline(p.events.map(function (e) {
        return { time: e[2], title: e[0], sub: e[1], state: e[3] === 'done' ? 'done' : e[3] === 'now' ? 'now' : '' };
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('parcel.notify'), tone: 'accent', icon: 'i-bell', act: 'toast:' + c.t('parcel.notifying') },
        { label: c.t('common.share'), icon: 'i-share', act: 'share:parcel' }]) });
  }
};
