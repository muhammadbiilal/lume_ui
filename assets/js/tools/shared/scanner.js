/* ============================================================
   Lume — the camera scanning screen

   The QR reader and the document scanner are the same
   instrument pointed at different things: request the camera,
   frame something, keep a history. Only the words and the
   result differ, so the screen is shared and the rest is
   supplied by the caller.

   Permission is asked for by a user action and never at boot,
   and a denial gets an explanation rather than a second prompt.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export function scannerScreen(c, o) {
  return UI.section({ body:
      '<div class="scanner">' +
        '<div class="scanner__view">' +
          '<span class="scanner__frame"></span>' +
          '<span class="scanner__beam"></span>' +
          '<p class="scanner__hint">' + UI.esc(o.hint) + '</p>' +
        '</div>' +
        UI.buttonRow([
          { label: o.cta, tone: 'accent', icon: o.icon, act: 'toast:' + o.acting },
          { label: c.t('scan.fromGallery'), icon: 'i-image', act: 'toast:' + c.t('scan.picking') }
        ]) +
      '</div>' }) +
    UI.section({ title: o.stepsTitle, body: UI.timeline(o.steps) }) +
    UI.section({ title: c.t('common.history'), body: o.history.length
      ? UI.rows(o.history.map(function (h) {
          return UI.richRow({ icon: h.icon, title: h.title, sub: h.sub, meta: [h.when], act: 'toast:' + h.title, chevron: true });
        }))
      : UI.emptyState({ icon: 'i-scan', title: c.t('scan.empty.title'), text: c.t('scan.empty.text') }) });
}
