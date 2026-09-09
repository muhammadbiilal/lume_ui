/* ============================================================
   Lume - Tool host screen

   The shared frame every one of the 85 tool screens is
   composed into.

   Owns its own markup and nobody else's. The composition and
   the DOM order here are the ones the design specification
   fixes, so they are moved rather than rewritten.
   ============================================================ */
import { defineScreen } from './screen-base.js';

export function createToolHostScreen() {
  return defineScreen({
    id: 'tool',
    template: function () {
      return `
  <section class="screen screen--tool" id="screen-tool" role="tabpanel" aria-label="Tool">
    <div id="toolHeader"></div>
    <div id="toolBody"></div>
  </section>
`;
    }
  });
}
