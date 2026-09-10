/* ============================================================
   Lume — wastatus

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'wastatus',

  build: function (c) {
    return UI.section({ body: UI.noteCard({ tone: 'info', icon: 'i-message',
        title: c.t('wastatus.android.title'), text: c.t('wastatus.android.text') }) }) +
      UI.section({ title: c.t('wastatus.detected'), body: UI.emptyState({
        icon: 'i-message', title: c.t('wastatus.empty.title'), text: c.t('wastatus.empty.text'),
        action: { label: c.t('wastatus.grant'), act: 'toast:' + c.t('wastatus.granting'), icon: 'i-folder' } }) });
  }
};
