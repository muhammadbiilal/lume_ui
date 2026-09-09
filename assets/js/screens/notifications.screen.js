/* ============================================================
   Lume - Notifications screen

   The notification centre and its settings.

   Owns its own markup and nobody else's. The composition and
   the DOM order here are the ones the design specification
   fixes, so they are moved rather than rewritten.
   ============================================================ */
import { defineScreen } from './screen-base.js';

export function createNotificationsScreen() {
  return defineScreen({
    id: 'notifications',
    template: function () {
      return `
  <section class="screen screen--tool" id="screen-notifications" role="tabpanel" aria-label="Notifications">
    <div id="notifHeader"></div>
    <div id="notifBody"></div>
  </section>
`;
    }
  });
}
