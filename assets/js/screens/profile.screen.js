/* ============================================================
   Lume — Profile screen

   The entry point for identity, preferences, privacy and
   support. Its composition stays the same whether the user is a
   guest, signed in, or holding a session that has expired —
   what changes is which rows exist and what they say.

   The screen renders from state rather than being edited in
   place, so it cannot drift into claiming an account that is
   not there. Nothing here invents a name, an email or a
   statistic to fill a gap.
   ============================================================ */
import { defineScreen } from './screen-base.js';
import { $ } from '../core/dom.js';

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
    },

    render: function (root) {
      const host = $('#profileBody', root);
      if (!host) return;
      host.innerHTML = ctx.accountUI.renderProfile();
      ctx.applyStrings(host);
    }
  });
}
