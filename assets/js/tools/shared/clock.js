/* ============================================================
   Lume — the running-clock screen

   The stopwatch, the countdown timer and the focus session are
   one instrument with three faces. Sharing the screen is what
   keeps the controls, the lap/history treatment and the
   accessible announcements identical across all three.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export function clockScreen(c, o) {
  return '<div class="clockface">' +
    '<p class="clockface__time" data-clock-display>' + o.display + '</p>' +
    (o.sub ? '<p class="clockface__sub">' + UI.esc(o.sub) + '</p>' : '') +
    '<div class="clockface__acts">' +
      UI.button({ label: o.primary, tone: 'accent', icon: 'i-play', act: o.primaryAct }) +
      UI.button({ label: c.t('common.reset'), icon: 'i-refresh', act: o.resetAct }) +
    '</div>' +
  '</div>';
}
