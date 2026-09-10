/* ============================================================
   Lume — the screen lifecycle

   Every top-level screen has the same five moments, and the
   controller here is what guarantees they happen in order and
   exactly once:

     mount(container, route)  build DOM, bind listeners
     render(route)            redraw from current state
     onEnter(route)           the screen is now visible
     onLeave()                the screen is no longer visible
     unmount()                release everything mount() took

   The guarantees this enforces, rather than trusts:

     · mount() runs once. Mounting an already-mounted screen is
       ignored, so a second registration cannot double up its
       event listeners.
     · onEnter() only follows a mount, and only when the screen
       was not already entered. onLeave() only follows an
       onEnter. A screen therefore never leaves twice, and never
       leaves without having entered.
     · unmount() implies onLeave() first, so a screen releasing
       its DOM always gets the chance to stop its timers.
     · Every hook is optional. A screen that has nothing to stop
       does not have to say so.

   Screens are handed an AbortController signal at mount. Any
   listener bound with it disappears on unmount without the
   screen having to remember it, which is the whole reason the
   old document-level handlers could not be cleaned up.
   ============================================================ */

export function createLifecycle(options) {
  const onError = (options && options.onError) || function () {};
  const screens = new Map();

  function record(screen) {
    return {
      screen: screen,
      mounted: false,
      entered: false,
      container: null,
      controller: null
    };
  }

  /* A hook that throws must not take the navigation down with it: the user
     asked to go somewhere, and a screen failing to stop a timer is not a
     reason to strand them on the screen they were leaving. */
  function call(entry, hook /* , ...args */) {
    const fn = entry.screen[hook];
    if (typeof fn !== 'function') return;
    const args = Array.prototype.slice.call(arguments, 2);
    try {
      fn.apply(entry.screen, args);
    } catch (e) {
      onError(entry.screen.id, hook, e);
    }
  }

  return {
    register: function (screen) {
      if (!screen || !screen.id) throw new Error('a screen must declare an id');
      if (screens.has(screen.id)) throw new Error('screen already registered: ' + screen.id);
      screens.set(screen.id, record(screen));
      return screen;
    },

    has: function (id) { return screens.has(id); },

    get: function (id) {
      const entry = screens.get(id);
      return entry ? entry.screen : null;
    },

    ids: function () { return Array.from(screens.keys()); },

    isMounted: function (id) {
      const entry = screens.get(id);
      return !!(entry && entry.mounted);
    },

    mount: function (id, container, route) {
      const entry = screens.get(id);
      if (!entry || entry.mounted) return false;
      entry.container = container;
      entry.controller = new AbortController();
      entry.mounted = true;
      entry.screen.signal = entry.controller.signal;
      call(entry, 'mount', container, route);
      return true;
    },

    render: function (id, route) {
      const entry = screens.get(id);
      if (!entry || !entry.mounted) return false;
      call(entry, 'render', route);
      return true;
    },

    enter: function (id, route) {
      const entry = screens.get(id);
      if (!entry || !entry.mounted || entry.entered) return false;
      entry.entered = true;
      call(entry, 'onEnter', route);
      return true;
    },

    leave: function (id) {
      const entry = screens.get(id);
      if (!entry || !entry.entered) return false;
      entry.entered = false;
      call(entry, 'onLeave');
      return true;
    },

    unmount: function (id) {
      const entry = screens.get(id);
      if (!entry || !entry.mounted) return false;
      if (entry.entered) {
        entry.entered = false;
        call(entry, 'onLeave');
      }
      call(entry, 'unmount');
      if (entry.controller) entry.controller.abort();
      entry.controller = null;
      entry.container = null;
      entry.mounted = false;
      entry.screen.signal = null;
      return true;
    }
  };
}
