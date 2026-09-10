/* ============================================================
   Lume — docscan

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { scannerScreen } from '../shared/scanner.js';

export default {
  id: 'docscan',

  build: function (c) {
    return scannerScreen(c, {
      hint: c.t('docscan.hint'), cta: c.t('docscan.capture'), icon: 'i-scan', acting: c.t('docscan.capturing'),
      stepsTitle: c.t('docscan.workflow'),
      steps: [
        { time: '1', title: c.t('docscan.step.edges'), state: 'now' },
        { time: '2', title: c.t('docscan.step.crop') },
        { time: '3', title: c.t('docscan.step.enhance') },
        { time: '4', title: c.t('docscan.step.export') }
      ],
      history: [
        { icon: 'i-folder', title: c.t('docscan.recent1'), sub: '3 ' + c.t('docscan.pages'), when: c.t('common.today') },
        { icon: 'i-folder', title: c.t('docscan.recent2'), sub: '1 ' + c.t('docscan.page'), when: '4 Sep' }
      ]
    });
  }
};
