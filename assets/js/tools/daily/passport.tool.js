/* ============================================================
   Lume — passport

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'passport',

  build: function (c) {
    var specs = c.passportSpecs();
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-globe', label: c.L.countryName(c.profile.country), act: 'sheet:personalise' }]) }) +
      UI.section({ body: UI.card(
        '<div class="photoguide">' +
          '<span class="photoguide__frame"><i class="photoguide__head"></i></span>' +
          '<div class="photoguide__specs">' + specs.map(function (s) {
            return '<span class="photoguide__spec"><b>' + UI.esc(s.value) + '</b><i>' + UI.esc(s.label) + '</i></span>';
          }).join('') + '</div>' +
        '</div>' +
        UI.buttonRow([
          { label: c.t('passport.capture'), tone: 'accent', icon: 'i-image', act: 'toast:' + c.t('passport.capturing') },
          { label: c.t('passport.import'), icon: 'i-download', act: 'toast:' + c.t('passport.importing') }
        ])) }) +
      UI.section({ title: c.t('passport.requirements'), body: UI.rows([
        UI.compactRow({ icon: 'i-check', label: c.t('passport.req.background') }),
        UI.compactRow({ icon: 'i-check', label: c.t('passport.req.expression') }),
        UI.compactRow({ icon: 'i-check', label: c.t('passport.req.glasses') }),
        UI.compactRow({ icon: 'i-check', label: c.t('passport.req.recent') })
      ]) }) +
      UI.section({ title: c.t('passport.sizes'), body: UI.table({
        label: c.t('passport.sizes'),
        cols: [{ label: c.t('passport.document') }, { label: c.t('passport.size'), align: 'right' },
               { label: c.t('passport.dpi'), align: 'right' }],
        rows: [
          { cells: [c.t('passport.passport'), '35 × 45 mm', '600'] },
          { cells: [c.t('passport.visaUS'), '2 × 2 in', '600'] },
          { cells: [c.t('passport.idCard'), '35 × 45 mm', '600'] }
        ]
      }) });
  }
};
