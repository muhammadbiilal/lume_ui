/* ============================================================
   Lume — the profile store

   One object holds every personalisation dimension, and each
   dimension is independent of the others. Religion is not read
   from country, language is not read from country, and units
   and currency follow the country only until the user says
   otherwise.

   Screens do not keep their own copies. They read through
   get(), change through patch()/save(), and re-render when
   subscribe() tells them something moved.
   ============================================================ */
import { store } from './storage.js';

const KEY = 'lume-profile';
const ONBOARDED_KEY = 'lume-onboarded';

/* The shape a first-run profile has. Every field here is a separate
   personalisation dimension; none of them is derived from another. */
function defaults() {
  return {
    /* Identity starts empty. A name appears here only because the user
       typed one, in onboarding or in Edit profile; the greeting and the
       avatar have designed shapes for its absence. */
    displayName: '',
    photo: '',

    /* Location: country → region (where a country uses one) → city. */
    country: 'PK',
    region: 'Islamabad Capital Territory',
    city: 'Islamabad',

    /* The faith dimension, entirely separate from country. Off until the
       user asks for it in onboarding or Personalisation — never assumed,
       and never inferred from the country above. */
    islamic: false,

    /* Formatting. 'auto' follows the country; anything else is the user
       overriding it, which they are always allowed to do. Language is
       deliberately NOT derived from country. */
    lang: 'en',
    units: 'auto',
    currency: 'auto',
    clock: 'auto',
    method: 'MWL',

    interests: [],
    prefs: { news: true, cricket: true, finance: true, recos: true },
    recents: [],
    favourites: [],
    market: null,
    recentCountries: []
  };
}

export function createProfileStore(catalogue) {
  const profile = defaults();
  const listeners = [];

  /* Picking anything in the faith group is what turns Islamic content on.
     We never ask "are you Muslim?" anywhere in the product. */
  function syncFaithFromInterests() {
    const any = profile.interests.some(function (id) {
      return catalogue.FAITH_INTERESTS.indexOf(id) !== -1;
    });
    if (any) profile.islamic = true;
  }

  function load() {
    const raw = store.get(KEY);
    if (raw) {
      try {
        const saved = JSON.parse(raw);
        for (const k in saved) {
          if (Object.prototype.hasOwnProperty.call(saved, k)) profile[k] = saved[k];
        }
      } catch (e) { /* a corrupt record is a first run, not a crash */ }
    }
    /* An older build shipped a placeholder name and initials in the profile
       record itself. They were never entered by anyone, so they are dropped
       rather than migrated. */
    delete profile.name;
    delete profile.initials;
    if (!profile.interests || !profile.interests.length) {
      /* Onboarded but nothing stored (skipped, or an older build): fall back
         to the general defaults. Islamic content is never switched on for
         someone who did not ask for it. */
      profile.interests = store.get(ONBOARDED_KEY) ? catalogue.DEFAULT_INTERESTS.slice() : [];
    }
    syncFaithFromInterests();
    return profile;
  }

  function save() {
    return store.set(KEY, JSON.stringify(profile));
  }

  function notify() {
    listeners.forEach(function (fn) { fn(profile); });
  }

  return {
    /* The live object. It is handed out rather than copied because the
       locale engine, the account engine and the tool context all hold a
       getter onto it and must see the same profile the screens see. */
    get: function () { return profile; },

    load: load,
    save: save,
    syncFaithFromInterests: syncFaithFromInterests,

    has: function (interest) { return profile.interests.indexOf(interest) !== -1; },

    /* Change and persist in one step, then tell whoever is listening. */
    patch: function (changes) {
      for (const k in changes) {
        if (Object.prototype.hasOwnProperty.call(changes, k)) profile[k] = changes[k];
      }
      save();
      notify();
    },

    /* For callers that mutated the live object directly — onboarding and
       the pickers do, because they edit drafts in place. */
    commit: function () { save(); notify(); },

    subscribe: function (fn) {
      listeners.push(fn);
      return function () {
        const at = listeners.indexOf(fn);
        if (at !== -1) listeners.splice(at, 1);
      };
    }
  };
}
