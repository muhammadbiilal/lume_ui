/* ============================================================
   Lume - Account screen

   The host for the nested account and settings screens.

   Owns its own markup and nobody else's. The composition and
   the DOM order here are the ones the design specification
   fixes, so they are moved rather than rewritten.
   ============================================================ */
import { defineScreen } from './screen-base.js';

export function createAccountScreen(ctx) {
  return defineScreen({
    id: 'account',
    template: function () {
      return `
  <section class="screen screen--tool" id="screen-account" role="region" aria-label="Account">
    <div id="accountHeader"></div>
    <div id="accountBody"></div>
  </section>
`;
    }
  });
}
