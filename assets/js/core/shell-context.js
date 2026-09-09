/* ============================================================
   Lume — what a screen is allowed to know

   Screens are built before the shell has finished assembling
   itself: their markup has to exist before anything looks for a
   node inside one. So they are handed this object at
   construction and it is filled in as the shell comes up.

   That ordering is safe because of one rule, and the rule is
   worth stating plainly: a screen may read this object during
   render, onEnter, onLeave and event handling, and never during
   mount. mount() builds markup and nothing else, so it cannot
   observe a half-built shell.

   createShellContext() exists so the set of things a screen can
   reach is written down in one place rather than being whatever
   app.js happened to have in scope. Adding a capability here is
   a deliberate act; reaching around it is not possible, because
   a screen has no other reference to the shell.
   ============================================================ */

/* Everything a screen may use, and nothing else. The shell fills each of
   these in as it builds them; a screen reading one before then is reading
   during mount, which is the one thing the contract forbids. */
const SLOTS = [
  /* formatting and language */
  't', 'L', 'applyStrings',
  /* data and metadata */
  'catalogue', 'data', 'spec', 'ui', 'tools', 'toolCtx',
  /* personalisation */
  'profile', 'eligible', 'hasInterest',
  /* navigation and shell surfaces */
  'router', 'openTool', 'sheetOpen', 'sheetClose', 'toast', 'runAct',
  /* shared behaviour screens need but do not own */
  'animateBars', 'prayer', 'notify', 'account'
];

export function createShellContext() {
  const filled = {};
  let ready = false;

  const api = {
    /* Fill in a group of capabilities. Anything not declared above is
       rejected, so a screen cannot quietly grow a private channel into the
       shell by having something new assigned onto the context. */
    provide: function (values) {
      for (const key in values) {
        if (!Object.prototype.hasOwnProperty.call(values, key)) continue;
        if (SLOTS.indexOf(key) === -1) {
          throw new Error('shell context has no slot named "' + key + '"');
        }
        filled[key] = values[key];
      }
      const missing = SLOTS.filter(function (slot) { return !(slot in filled); });
      if (missing.length) {
        throw new Error('shell context left unfilled: ' + missing.join(', '));
      }
      ready = true;
      return proxy;
    }
  };

  /* Reading a capability before the shell has provided it means the read
     happened during mount, and the message says so rather than leaving a
     bare "undefined is not a function" at the call site. A screen that
     wants to act at mount time should bind a handler, not call the shell:
     the handler runs later, when the shell is up. */
  const proxy = new Proxy(api, {
    get: function (target, key) {
      if (key in target) return target[key];
      if (typeof key !== 'string') return undefined;
      if (key in filled) return filled[key];
      if (SLOTS.indexOf(key) !== -1) {
        throw new Error(
          ready
            ? 'shell context slot "' + key + '" was never provided'
            : 'shell context read during mount: "' + key + '". A screen may ' +
              'read the shell from render onward, not while building markup.'
        );
      }
      return undefined;
    },

    has: function (target, key) {
      return key in target || key in filled || SLOTS.indexOf(key) !== -1;
    }
  });

  return proxy;
}
