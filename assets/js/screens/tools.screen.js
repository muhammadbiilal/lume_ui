/* ============================================================
   Lume - Tools screen

   The searchable catalogue of every eligible utility.

   Owns its own markup and nobody else's. The composition and
   the DOM order here are the ones the design specification
   fixes, so they are moved rather than rewritten.
   ============================================================ */
import { defineScreen } from './screen-base.js';

export function createToolsScreen() {
  return defineScreen({
    id: 'tools',
    template: function () {
      return `
  <section class="screen" id="screen-tools" role="tabpanel" aria-label="Tools">

    <div class="page-head">
      <div class="page-head__bar">
        <div>
          <h1 class="page-head__title" data-i18n="tools.title">Tools</h1>
          <p class="page-head__sub" id="toolSub">79 utilities, neatly sorted</p>
        </div>
        <button class="iconbtn pressable" data-sheet="personalise" aria-label="Personalise">
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-sliders"/></svg>
        </button>
      </div>
    </div>

    <div class="section" style="margin-top:16px">
      <label class="search">
        <svg class="ico" viewBox="0 0 24 24"><use href="#i-search"/></svg>
        <input type="search" id="toolSearch" placeholder="Search tools — try “petrol”" aria-label="Search tools">
      </label>
    </div>

    <div class="section" style="margin-top:14px">
      <div class="chips" id="toolChips"></div>
    </div>

    <!-- Recently used — can only ever show what this user is allowed to see -->
    <div class="section" id="toolRecent" hidden>
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="tools.recent">Recently used</h2>
          <p class="section__sub" data-i18n="tools.recentSub">Straight back to where you were</p>
        </div>
      </div>
      <div class="hscroll" id="toolRecentList"></div>
    </div>

    <div id="toolCats"></div>

    <div class="empty" id="toolEmpty">
      <svg width="88" height="66" viewBox="0 0 88 66" fill="none" aria-hidden="true">
        <circle cx="44" cy="30" r="22" stroke="var(--border-2)" stroke-width="2" stroke-dasharray="5 7"/>
        <path d="m58 44 12 12" stroke="var(--border-2)" stroke-width="2.4" stroke-linecap="round"/>
        <circle cx="20" cy="14" r="3" fill="var(--accent)" opacity=".4"/>
        <circle cx="72" cy="18" r="4" fill="var(--accent)" opacity=".25"/>
      </svg>
      <p class="empty__title">No tools match</p>
      <p class="empty__text">Try a different word — or browse a category above.</p>
    </div>

  </section>
`;
    }
  });
}
