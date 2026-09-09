/* ============================================================
   Lume — mediasaver

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'mediasaver',

  /* ---------------------------------------------------------
     §54 Media saver · §55 WhatsApp status
     --------------------------------------------------------- */
  build: function (c) {
    var items = c.savedMedia();
    return UI.section({ body: UI.card(UI.formGrid([
        UI.field({ label: c.t('media.link'), name: 'ms_link', placeholder: 'https://…', wide: true })
      ]) + UI.buttonRow([{ label: c.t('media.fetch'), tone: 'accent', icon: 'i-download', block: true,
        act: 'toast:' + c.t('media.fetching') }])) }) +
      UI.section({ body: UI.metrics([
        { value: String(items.length), label: c.t('media.saved') },
        { value: '182 ' + c.t('unit.mb'), label: c.t('media.storage') },
        { value: c.t('common.today'), label: c.t('media.lastSave') }
      ], 3) }) +
      UI.section({ title: c.t('media.library'), body: items.length
        ? '<div class="mgrid">' + items.map(function (m) {
            return '<button class="mtile pressable" data-act="toast:' + UI.esc(m.title) + '">' +
              UI.art({ tone: m.tone, seed: m.title.length, glyph: m.glyph }) +
              '<span class="mtile__label">' + UI.esc(m.title) + '</span>' +
              '<span class="mtile__meta">' + UI.esc(m.size) + '</span></button>';
          }).join('') + '</div>'
        : UI.emptyState({ icon: 'i-download', title: c.t('media.empty.title'), text: c.t('media.empty.text') }) });
  }
};
