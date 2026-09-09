/* ============================================================
   Lume - Profile screen

   Identity, account state, preferences, privacy and support.

   Owns its own markup and nobody else's. The composition and
   the DOM order here are the ones the design specification
   fixes, so they are moved rather than rewritten.
   ============================================================ */
import { defineScreen } from './screen-base.js';

export function createProfileScreen(ctx) {
  return defineScreen({
    id: 'profile',
    template: function () {
      return `
  <section class="screen" id="screen-profile" role="tabpanel" aria-label="Profile">
    <div class="page-head">
      <div class="page-head__bar">
        <div>
          <h1 class="page-head__title" data-i18n="profile.title">Profile</h1>
          <p class="page-head__sub" data-i18n="profile.sub">Preferences and your saved things</p>
        </div>
        <button class="iconbtn pressable" data-act="acct:prefs" data-i18n-aria="acct.prefsTitle" aria-label="Preferences">
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-settings"/></svg>
        </button>
      </div>
    </div>
    <div id="profileBody"></div>
  </section>
`;
    }
  });
}
