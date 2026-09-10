/* ============================================================
   Lume — the router

   Three separate code paths used to activate a screen: the tab
   bar, the destinations that are not tabs (Explore, the
   notification centre, Account, Auth) and the tool host. Each
   one repeated the same six steps, and each one had its own
   idea of what the tab bar should look like afterwards. This
   owns all three.

   What the router knows:

     · which destination is current, which is the one piece of
       navigation state the rest of the app reads;
     · which destinations are tabs right now — the tab set is
       personalised, so this is a question, not a constant;
     · how to hand a screen its lifecycle moments as it comes
       and goes.

   What the router does not know: anything about what a screen
   contains. It activates by id and lets the screen render
   itself.
   ============================================================ */
import { $, $$ } from './dom.js';

/* Destinations that are legitimately reachable while no tab is selected.
   Anything else that is not currently a tab has lost its place and is sent
   home when the tab set changes underneath it. */
const NON_TAB_DESTINATIONS = ['explore', 'tool', 'notifications', 'account', 'auth'];

export function createRouter(deps) {
  const lifecycle = deps.lifecycle;
  const tabOrder = deps.tabOrder;
  const renderTabBar = deps.renderTabBar;
  const onActivate = deps.onActivate || function () {};

  let current = 'home';

  function screenEl(name) { return $('#screen-' + name); }

  function isTab(name) { return tabOrder().indexOf(name) !== -1; }

  /* The pill sits under the selected tab, and has no home when the current
     destination is not a tab. */
  function movePill(tab) {
    const pill = $('#tabPill');
    if (!pill) return;
    if (!tab) { pill.style.opacity = '0'; return; }
    pill.style.opacity = '';
    pill.style.width = tab.offsetWidth + 'px';
    pill.style.transform = 'translateX(' + tab.offsetLeft + 'px)';
  }

  /* Every presentation of the navigation is selected at once — bottom bar,
     rail and sidebar are the same destination set at three widths, and a
     user who resizes must not find the other one still pointing at where
     they used to be. The pill belongs to the bottom bar alone, so it is
     read from there rather than from whichever .tab matched last. */
  function syncTabs(name) {
    let active = null;
    $$('.tab, .navtab').forEach(function (tab) {
      const on = tab.dataset.tab === name;
      tab.classList.toggle('is-active', on);
      tab.setAttribute('aria-selected', on ? 'true' : 'false');
      if (on) active = tab;
    });
    movePill(barTab());
    return active;
  }

  /* The selected destination in the bottom bar specifically. */
  function barTab() {
    const bar = $('#tabbar');
    return bar ? $('.tab.is-active', bar) : null;
  }

  /* The single activation path. Everything that shows a screen comes
     through here, so the leave/enter pairing cannot be skipped by one
     caller and honoured by another. */
  function activate(name, opts) {
    const options = opts || {};
    const el = screenEl(name);
    if (!el) return false;

    const previous = current;
    if (previous !== name) lifecycle.leave(previous);

    current = name;

    $$('.screen').forEach(function (screen) { screen.classList.remove('is-active'); });
    el.classList.add('is-active');
    el.scrollTop = 0;

    const active = syncTabs(name);

    /* Explore is reachable for Pakistan users even though it is not a tab,
       and needs a way back when it is opened that way. */
    const back = $('#exploreBack');
    if (back) back.hidden = !!active || name !== 'explore';

    lifecycle.render(name, options.route);
    lifecycle.enter(name, options.route);
    onActivate(name, previous, options);
    return true;
  }

  return {
    current: function () { return current; },

    /* Used where the app needs to remember a tab to come back to, and the
       current destination may be a tool or an overlay screen. */
    currentTab: function (fallback) {
      return isTab(current) ? current : (fallback || 'home');
    },

    isTab: isTab,
    /* Called after a resize, when the pill's arithmetic has changed but the
       destination has not. */
    movePill: function (tab) { movePill(tab === undefined ? barTab() : tab); },

    go: function (name, opts) { return activate(name, opts); },

    /* Re-draw the tab bar after something that changes the tab set —
       a country change, a language change. A destination that is no longer
       a tab, and is not one of the standing non-tab destinations, has lost
       its place and goes home. */
    refreshTabs: function () {
      renderTabBar();
      if (!isTab(current) && NON_TAB_DESTINATIONS.indexOf(current) === -1) current = 'home';
      activate(current, { quiet: true });
    },

    /* Set the current destination without touching the DOM. Used only where
       another system has already activated a screen and the router is being
       told after the fact; it still pairs leave with enter. */
    adopt: function (name) {
      if (current === name) return;
      lifecycle.leave(current);
      current = name;
      lifecycle.enter(name);
    }
  };
}
