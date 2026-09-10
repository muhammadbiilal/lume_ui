/* ============================================================
   Lume — qr

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { scannerScreen } from '../shared/scanner.js';

export default {
  id: 'qr',

  build: function (c) {
    return scannerScreen(c, {
      hint: c.t('qr.hint'), cta: c.t('qr.scan'), icon: 'i-qr', acting: c.t('qr.scanning'),
      stepsTitle: c.t('qr.detects'),
      steps: [
        { time: '1', title: c.t('qr.step.point'), state: 'now' },
        { time: '2', title: c.t('qr.step.detect') },
        { time: '3', title: c.t('qr.step.act') }
      ],
      history: [
        { icon: 'i-globe', title: 'lume.app/tools', sub: c.t('qr.kind.link'), when: c.t('common.today') },
        { icon: 'i-wifi', title: 'Home-WiFi', sub: c.t('qr.kind.wifi'), when: c.t('common.yesterday') }
      ]
    });
  }
};
