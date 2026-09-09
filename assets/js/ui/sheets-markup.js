/* ============================================================
   Lume - the overlay set

   Every sheet the shell can raise, in one place. They are not
   screens: they are temporary surfaces that sit over whichever
   screen is showing, so they mount into the overlay outlet
   rather than the screen outlet and none of them belongs to a
   destination.

   Markup only. What each sheet does when it opens lives with
   the system that opens it.
   ============================================================ */

export function sheetsTemplate() {
  return `

  <!-- Global search -->
  <aside class="sheet sheet--tall" id="sheet-search" role="dialog" aria-modal="true" aria-label="Search">
    <span class="sheet__grab"></span>
    <div class="sheet__head">
      <div style="flex:1;min-width:0">
        <label class="search">
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-search"/></svg>
          <input type="search" id="globalSearch" data-i18n-ph="search.placeholder" placeholder="Search anything — tools, rates, places" aria-label="Search everything">
        </label>
      </div>
      
    </div>
    <div class="sheet__body">
      <div id="searchIdle">
        <p class="group-label" style="padding:0;margin:4px 0 9px" data-i18n="search.try">Try searching for</p>
        <div class="chips chips--wrap" id="searchSuggest"></div>
        <p class="group-label" style="padding:0;margin:20px 0 9px" data-i18n="search.jumpBack">Jump back in</p>
        <div class="list list--flat" id="searchRecent"></div>
      </div>
      <div id="searchResults" hidden></div>
      <div class="empty" id="searchEmpty">
        <svg width="88" height="66" viewBox="0 0 88 66" fill="none" aria-hidden="true">
          <circle cx="44" cy="30" r="22" stroke="var(--border-2)" stroke-width="2" stroke-dasharray="5 7"/>
          <path d="m58 44 12 12" stroke="var(--border-2)" stroke-width="2.4" stroke-linecap="round"/>
          <circle cx="20" cy="14" r="3" fill="var(--accent)" opacity=".4"/>
        </svg>
        <p class="empty__title">Nothing found</p>
        <p class="empty__text">Try another word, or turn on more interests in Personalisation.</p>
      </div>
    </div>
  </aside>

  <!-- Personalisation -->
  <aside class="sheet sheet--tall" id="sheet-personalise" role="dialog" aria-modal="true" aria-label="Personalisation">
    <span class="sheet__grab"></span>
    <div class="sheet__head">
      <div>
        <h2 class="sheet__title" data-i18n="pers.title">Personalisation</h2>
        <p class="sheet__sub" data-i18n="pers.sub">Change any of this whenever you like</p>
      </div>
      <button class="closebtn pressable" data-close data-i18n-aria="a.close" aria-label="Close"><svg class="ico" viewBox="0 0 24 24"><use href="#i-x"/></svg></button>
    </div>
    <div class="sheet__body">

      <p class="group-label" style="padding:0;margin:2px 0 9px" data-i18n="pers.whereYouAre">Where you are</p>
      <!-- §124.17 — say what changing this changes, at the point of change.
           The warning used to live only on the Region settings screen, while
           the editor that actually moves the user is here. -->
      <div class="notecard notecard--warn" style="margin-bottom:12px">
        <svg class="ico" viewBox="0 0 24 24"><use href="#i-alert"/></svg>
        <div><b data-i18n="acct.regionTitle">Region &amp; currency</b>
        <p data-i18n="acct.regionWarn">Changing your region may update your currency, markets, holidays, emergency numbers and local services.</p></div>
      </div>
      <div class="list list--flat">
        <button class="list-row pressable" id="setCountryRow">
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-globe"/></svg></span>
          <span class="list-row__body">
            <span class="list-row__title" data-i18n="pers.country">Country</span>
            <span class="list-row__sub" data-i18n="pers.countrySub">Unlocks local services — nothing else</span>
          </span>
          <span class="list-row__end"><span class="list-row__value" id="setCountryValue">Pakistan</span></span>
        </button>
        <div class="list-row" id="setRegionRow" hidden>
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-pin"/></svg></span>
          <span class="list-row__body">
            <span class="list-row__title" data-i18n="pers.region">Region</span>
          </span>
          <span class="list-row__end"><span class="list-row__value" id="setRegionValue"></span></span>
        </div>
        <div class="list-row">
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-pin"/></svg></span>
          <span class="list-row__body">
            <span class="list-row__title" data-i18n="pers.city">City</span>
            <span class="list-row__sub" data-i18n="pers.citySub">Used for weather, local information and nearby places</span>
          </span>
          <span class="list-row__end"><span class="list-row__value" id="setCityValue">Islamabad</span></span>
        </div>
      </div>
      <div class="locpicker locpicker--inset" id="setLocation"></div>

      <p class="group-label" style="padding:0;margin:22px 0 9px" data-i18n="pers.formatting">Language &amp; formatting</p>
      <div class="list list--flat">
        <button class="list-row pressable" id="setLangRow">
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-globe"/></svg></span>
          <span class="list-row__body">
            <span class="list-row__title" data-i18n="pers.appLanguage">App language</span>
          </span>
          <span class="list-row__end"><span class="list-row__value" id="setLangValue">English</span><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span>
        </button>
        <button class="list-row pressable" id="setUnitsRow">
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-ruler"/></svg></span>
          <span class="list-row__body">
            <span class="list-row__title" data-i18n="pers.units">Units</span>
          </span>
          <span class="list-row__end"><span class="list-row__value" id="setUnitsValue">Automatic</span><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span>
        </button>
        <button class="list-row pressable" id="setCurrencyRow">
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-currency"/></svg></span>
          <span class="list-row__body">
            <span class="list-row__title" data-i18n="pers.currency">Currency</span>
          </span>
          <span class="list-row__end"><span class="list-row__value" id="setCurrencyValue">Automatic</span><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span>
        </button>
        <button class="list-row pressable" id="setClockRow">
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-clock"/></svg></span>
          <span class="list-row__body">
            <span class="list-row__title" data-i18n="pers.timeFormat">Time</span>
          </span>
          <span class="list-row__end"><span class="list-row__value" id="setClockValue">Automatic</span><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span>
        </button>
      </div>

      <p class="group-label" style="padding:0;margin:22px 0 9px" data-i18n="pers.content">Content</p>
      <div class="list list--flat">
        <button class="list-row pressable" id="setIslamicRow">
          <span class="list-row__icon" id="setIslamicIcon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-moon-star"/></svg></span>
          <span class="list-row__body">
            <span class="list-row__title" data-i18n="pers.islamic">Islamic features</span>
            <span class="list-row__sub" data-i18n="pers.islamicSub">Prayer times, Qur’an, duas, zakat and Ramadan</span>
          </span>
          <span class="switch" id="setIslamicSwitch"><span class="switch__knob"></span></span>
        </button>
        <button class="list-row pressable" data-pref="news">
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-news"/></svg></span>
          <span class="list-row__body"><span class="list-row__title" data-i18n="pers.news">News</span><span class="list-row__sub" data-i18n="pers.newsSub">Headlines on Explore and Today</span></span>
          <span class="switch is-on"><span class="switch__knob"></span></span>
        </button>
        <button class="list-row pressable" data-pref="cricket">
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-cricket"/></svg></span>
          <span class="list-row__body"><span class="list-row__title" data-i18n="pers.sport">Sport</span><span class="list-row__sub" data-i18n="pers.sportSub">Live cricket scores</span></span>
          <span class="switch is-on"><span class="switch__knob"></span></span>
        </button>
        <button class="list-row pressable" data-pref="finance">
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-trending"/></svg></span>
          <span class="list-row__body"><span class="list-row__title" data-i18n="pers.finance">Financial information</span><span class="list-row__sub" data-i18n="pers.financeSub">Rates, gold and markets</span></span>
          <span class="switch is-on"><span class="switch__knob"></span></span>
        </button>
        <button class="list-row pressable" data-pref="recos">
          <span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-sparkles"/></svg></span>
          <span class="list-row__body"><span class="list-row__title" data-i18n="pers.recos">Recommendations</span><span class="list-row__sub">Suggest tools based on how you use Lume</span></span>
          <span class="switch is-on"><span class="switch__knob"></span></span>
        </button>
      </div>

      <p class="group-label" style="padding:0;margin:22px 0 4px" data-i18n="pers.interests">Your interests</p>
      <p class="meta" style="margin-bottom:12px">Pick at least 5. They decide what fills your home screen.</p>
      <div class="picker__bar">
        <span class="picker__count" id="setPickCount">0 selected</span>
        <button class="picker__clear pressable" id="setPickClear">Clear</button>
      </div>
      <div id="setPicker"></div>

      <p class="meta" style="margin:16px 0 0" data-i18n="pers.dataSafe">Changing any of this only changes what you see. Your notes, tasks and records stay exactly where they are.</p>

      <div class="sheet-actions">
        <button class="btn btn--accent btn--block pressable" id="setPickSave" data-i18n="pers.savePrefs">Save preferences</button>
      </div>
    </div>
  </aside>

  <!-- Share card -->
  <aside class="sheet sheet--tall" id="sheet-share" role="dialog" aria-modal="true" aria-label="Share card">
    <span class="sheet__grab"></span>
    <div class="sheet__head">
      <div>
        <h2 class="sheet__title" data-i18n="share.title">Share</h2>
        <p class="sheet__sub" data-i18n="share.cardReady">Your card is ready</p>
      </div>
      <button class="closebtn pressable" data-close data-i18n-aria="a.close" aria-label="Close"><svg class="ico" viewBox="0 0 24 24"><use href="#i-x"/></svg></button>
    </div>
    <div class="sheet__body">
      <div class="sharecard" id="shareStage">
        <canvas id="shareCanvas" width="1080" height="1350" role="img" aria-label="Share card preview"></canvas>
      </div>
      <div class="sharecard__actions">
        <button class="btn btn--ghost pressable" id="shareSave">
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-download"/></svg> <span data-i18n="a.saveImage">Save image</span>
        </button>
        <button class="btn btn--accent pressable" id="shareSend">
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-share"/></svg> <span data-i18n="a.share">Share</span>
        </button>
      </div>
    </div>
  </aside>

  <!-- Notifications -->
  <!-- Notification settings (§100.9) -->
  <aside class="sheet sheet--tall" id="sheet-notifprefs" role="dialog" aria-modal="true" aria-label="Notification settings">
    <span class="sheet__grab"></span>
    <div class="sheet__head">
      <div>
        <h2 class="sheet__title" data-i18n="n.settings">Notifications</h2>
        <p class="sheet__sub" data-i18n="n.settingsSub">What Lume may tell you, and when</p>
      </div>
      <button class="closebtn pressable" data-close data-i18n-aria="a.close" aria-label="Close"><svg class="ico" viewBox="0 0 24 24"><use href="#i-x"/></svg></button>
    </div>
    <div class="sheet__body" id="notifPrefsBody"></div>
  </aside>

  <!-- Push permission, asked in context (§100.11) -->
  <!-- Confirmation for anything that cannot be undone (§124.21, §124.22) -->
  <aside class="sheet" id="sheet-confirm" role="dialog" aria-modal="true" aria-labelledby="confirmTitle">
    <span class="sheet__grab"></span>
    <div class="sheet__body">
      <div class="confirm">
        <h2 class="confirm__title" id="confirmTitle"></h2>
        <p class="confirm__text" id="confirmText"></p>
        <div class="confirm__acts">
          <button class="btn btn--danger btn--block pressable" id="confirmGo"></button>
          <button class="btn btn--ghost btn--block pressable" data-close id="confirmCancel"></button>
        </div>
      </div>
    </div>
  </aside>

  <!-- §126.40 — the legal line's link, as a sheet rather than a screen.
       Navigating away from step two of a sign-up would take the password
       the user has just typed with it; a sheet keeps the form underneath
       exactly as it was. -->
  <aside class="sheet" id="sheet-authlegal" role="dialog" aria-modal="true" aria-labelledby="authLegalTitle">
    <span class="sheet__grab"></span>
    <div class="sheet__body">
      <div class="confirm">
        <h2 class="confirm__title" id="authLegalTitle" data-i18n="auth.legalTitle">How Lume handles your data</h2>
        <p class="confirm__text" data-i18n="auth.legalBody">Your account, your settings and everything you create in Lume are stored on this device. Lume does not sell your information and does not share it with anyone.</p>
        <p class="confirm__text" data-i18n="auth.legalWhere">The full detail lives under Privacy in your profile, and you can delete your account and everything in it at any time.</p>
        <div class="confirm__acts">
          <button class="btn btn--ghost btn--block pressable" data-close data-i18n="a.close">Close</button>
        </div>
      </div>
    </div>
  </aside>

  <aside class="sheet" id="sheet-notifpush" role="dialog" aria-modal="true" aria-label="Enable notifications">
    <span class="sheet__grab"></span>
    <div class="sheet__body">
      <div class="pushask">
        <span class="pushask__art"><svg class="ico" viewBox="0 0 24 24"><use href="#i-bell-ring"/></svg></span>
        <h2 class="pushask__title" data-i18n="n.ask.title">Stay informed</h2>
        <p class="pushask__text" data-i18n="n.ask.text">Useful alerts for the things you already follow — and nothing else.</p>
        <ul class="pushask__list" id="pushAskList"></ul>
        <div class="btnrow">
          <button class="btn btn--accent btn--block" data-act="pushallow"><span data-i18n="n.ask.enable">Enable notifications</span></button>
        </div>
        <button class="pushask__later" data-close data-i18n="n.ask.later">Not now</button>
      </div>
    </div>
  </aside>

  <!-- Change market (§26.11) -->
  <aside class="sheet" id="sheet-market" role="dialog" aria-modal="true" aria-label="Change market">
    <span class="sheet__grab"></span>
    <div class="sheet__head">
      <div>
        <h2 class="sheet__title" data-i18n="markets.change">Change market</h2>
        <p class="sheet__sub" data-i18n="markets.changeSub">Local exchanges and the world board</p>
      </div>
    </div>
    <div class="sheet__body"><div class="list" id="marketList"></div></div>
  </aside>
`;
}
