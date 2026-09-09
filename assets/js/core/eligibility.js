/* ============================================================
   Lume — visibility, in one place

   Whether a feature exists for this user is decided here and
   nowhere else. Home, Tools, Today, Explore, search, the tab
   bar, notifications, recents, related tools and deep links all
   ask the same visible(), so a feature cannot be hidden from
   one surface and reachable from another.

   Two separate rules, deliberately not mixed:

     faith     — the feature belongs to the Islamic experience,
                 and appears only when that is switched on.
     countries — the markets a feature has launched in. This is
                 availability, not localisation: a global
                 feature whose content adapts stays visible
                 everywhere, and only a feature that genuinely
                 has no meaning elsewhere carries the list.
   ============================================================ */

export function createEligibility(deps) {
  const catalogue = deps.catalogue;
  const getProfile = deps.profile;
  const t = deps.t;

  /* Content the user has switched off in preferences. These are the only
     per-feature switches, and they live on the live profile even while an
     onboarding draft is being previewed against a different country —
     the draft is choosing a location, not re-answering these. */
  const PREF_GATED = {
    cricket: 'cricket',
    news: 'news',
    markets: 'finance',
    goldrates: 'finance'
  };

  function visibleIn(f, ctx) {
    if (f.faith && !ctx.islamic) return false;
    if (f.countries && f.countries.indexOf(ctx.country) === -1) return false;
    const pref = PREF_GATED[f.id];
    if (pref && !getProfile().prefs[pref]) return false;
    return true;
  }

  function visible(f) { return visibleIn(f, getProfile()); }

  function feature(id) {
    const all = catalogue.FEATURES;
    for (let i = 0; i < all.length; i++) if (all[i].id === id) return all[i];
    return null;
  }

  return {
    visibleIn: visibleIn,
    visible: visible,
    visibleFeatures: function () { return catalogue.FEATURES.filter(visible); },
    feature: feature,

    /* Feature names come from the catalogue in English; a dictionary entry
       overrides it where a translation exists. */
    name: function (f) {
      const key = 'f.' + f.id;
      const s = t(key);
      return s === key ? f.n : s;
    },

    /* Every feature opens its own tool screen. The catalogue's `act` is kept
       as the quick-glance surface (a sheet) but the tool screen is the tool:
       that is what makes each one its own information architecture rather
       than a toast. */
    actFor: function (f) { return 'tool:' + f.id; }
  };
}
