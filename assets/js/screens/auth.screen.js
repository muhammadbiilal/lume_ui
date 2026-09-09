/* ============================================================
   Lume - Authentication screen

   The identity flows, which are a flow rather than a tool.

   Owns its own markup and nobody else's. The composition and
   the DOM order here are the ones the design specification
   fixes, so they are moved rather than rewritten.
   ============================================================ */
import { defineScreen } from './screen-base.js';

export function createAuthScreen() {
  return defineScreen({
    id: 'auth',
    template: function () {
      return `
  <section class="screen screen--auth" id="screen-auth" role="region" aria-label="Sign in">
    <div id="authBody"></div>
  </section>
`;
    }
  });
}
