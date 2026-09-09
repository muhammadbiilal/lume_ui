/* ============================================================
   Lume — emergency

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';

export default {
  id: 'emergency',

  /* ---------------------------------------------------------
     §46 Emergency — action interface. Low density on purpose:
     the actions must be unmissable.
     --------------------------------------------------------- */
  build: function (c) {
    var list = D.emergencyFor(c.profile.country);
    var primary = list[0];
    return UI.section({ flush: true, body: UI.contextBar([
        { icon: 'i-pin', label: c.profile.city + ', ' + c.L.countryName(c.profile.country) }]) }) +
      UI.section({ body:
        '<a class="sos pressable" href="tel:' + UI.esc(primary.num) + '">' +
          '<span class="sos__icon">' + UI.ico('i-shield') + '</span>' +
          '<span class="sos__body"><b>' + UI.esc(primary.n) + '</b>' +
          '<i>' + UI.esc(c.t(primary.kindKey)) + '</i></span>' +
          '<span class="sos__num">' + UI.esc(primary.num) + '</span>' +
        '</a>' }) +
      UI.section({ title: c.t('emergency.services'), body: '<div class="calls">' +
        list.slice(1).map(function (e) {
          return '<a class="call pressable" href="tel:' + UI.esc(e.num) + '">' +
            '<span class="call__icon">' + UI.ico(e.icon) + '</span>' +
            '<span class="call__name">' + UI.esc(e.n) + '</span>' +
            '<span class="call__num">' + UI.esc(e.num) + '</span>' +
            '<span class="call__kind">' + UI.esc(c.t(e.kindKey)) + '</span>' +
          '</a>';
        }).join('') + '</div>' }) +
      UI.section({ title: c.t('emergency.yourInfo'), body: UI.rows([
        UI.compactRow({ icon: 'i-pulse', label: c.t('emergency.medical'), value: c.t('emergency.setUp'), act: 'tool:health' }),
        UI.compactRow({ icon: 'i-folder', label: c.t('emergency.documents'), value: c.t('common.locked'), act: 'tool:documents' }),
        UI.compactRow({ icon: 'i-pin', label: c.t('emergency.shareLocation'), value: c.profile.city, act: 'toast:' + c.t('emergency.locationShared') })
      ]) }) +
      UI.section({ body: UI.noteCard({ tone: 'info', icon: 'i-info',
        title: c.t('emergency.note.title'), text: c.t('emergency.note.text') }) });
  }
};
