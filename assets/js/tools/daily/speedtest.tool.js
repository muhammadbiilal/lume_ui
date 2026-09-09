/* ============================================================
   Lume — speedtest

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'speedtest',

  /* ---------------------------------------------------------
     §56 Speed test — live instrument
     --------------------------------------------------------- */
  build: function (c) {
    var s = c.speedTest();
    return UI.section({ body: UI.card(
        '<div class="gauge" data-gauge>' +
          '<svg viewBox="0 0 200 120" aria-hidden="true">' +
            '<path class="gauge__track" d="M20 108 A 80 80 0 0 1 180 108"/>' +
            '<path class="gauge__fill" d="M20 108 A 80 80 0 0 1 180 108" style="--p:' + s.pct.toFixed(3) + '"/>' +
          '</svg>' +
          '<div class="gauge__mid"><b data-speed-value>' + s.down.toFixed(1) + '</b><i>Mbps</i></div>' +
        '</div>' +
        UI.buttonRow([{ label: c.t('speed.start'), tone: 'accent', icon: 'i-play', block: true, act: 'speedtest' }])) }) +
      UI.section({ body: UI.metrics([
        { icon: 'i-download', value: c.num(s.down, { maximumFractionDigits: 1 }), label: c.t('speed.download') },
        { icon: 'i-arrow-ur', value: c.num(s.up, { maximumFractionDigits: 1 }), label: c.t('speed.upload') },
        { icon: 'i-timer', value: c.num(s.ping) + ' ' + c.t('unit.ms'), label: c.t('speed.ping') }
      ], 3) }) +
      UI.section({ title: c.t('speed.connection'), body: UI.rows([
        UI.compactRow({ icon: 'i-wifi', label: c.t('speed.type'), value: s.type }),
        UI.compactRow({ icon: 'i-signal', label: c.t('speed.server'), value: s.server }),
        UI.compactRow({ icon: 'i-globe', label: c.t('speed.isp'), value: s.isp })
      ]) }) +
      UI.section({ title: c.t('common.history'), body: UI.rows(s.history.map(function (h) {
        return UI.richRow({ icon: 'i-wifi', title: h.when, sub: h.type,
          meta: [c.t('speed.ping') + ' ' + c.num(h.ping) + ' ' + c.t('unit.ms')],
          spark: UI.sparkline(h.series, { tone: 'up' }),
          value: c.num(h.down, { maximumFractionDigits: 1 }), valueSub: c.t('unit.mbps') });
      })) });
  }
};
