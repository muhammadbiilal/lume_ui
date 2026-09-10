/* ============================================================
   Lume — the width class

   The Design System defines three width classes rather than a
   pile of media queries: compact below 600, medium 600-839,
   expanded 840 and above. CSS could answer that for itself, but
   two other things cannot:

     · JavaScript has to know whether a detail pane exists before
       it decides what "open this record" means — a push on a
       phone, a selection on a tablet;
     · the navigation is one model with three presentations, and
       whoever renders it needs to know which one is showing.

   So the class is resolved once, here, stamped on <html> as
   data-bp, and published as a subscription. Nothing else in the
   app calls matchMedia and no screen counts pixels.

   It measures the shell, not the viewport. Those are not the
   same number: the shell sits inside the stage's padding and is
   capped at 1366, so an 880 px window holds an 832 px shell —
   medium, not expanded. Measuring the window would put a
   master-detail layout into a pane too narrow to hold it. A
   ResizeObserver on the shell is therefore the primary source,
   and the viewport media query is the fallback for environments
   that have no observer.
   ============================================================ */

export const BREAKPOINTS = { medium: 600, expanded: 840 };

export function classFor(width) {
  if (width >= BREAKPOINTS.expanded) return 'expanded';
  if (width >= BREAKPOINTS.medium) return 'medium';
  return 'compact';
}

export function createBreakpoint(deps) {
  const options = deps || {};
  const root = options.root || document.documentElement;
  const shell = options.shell || null;
  const listeners = [];
  let current = 'compact';

  /* jsdom, a print context and an old browser may have neither of these.
     Compact is the honest answer when nothing can be measured, and a shell
     that threw here would take the whole app down with it. */
  const hasObserver = typeof ResizeObserver !== 'undefined';
  const media = typeof window !== 'undefined' && window.matchMedia
    ? {
        medium: window.matchMedia('(min-width: ' + BREAKPOINTS.medium + 'px)'),
        expanded: window.matchMedia('(min-width: ' + BREAKPOINTS.expanded + 'px)')
      }
    : null;

  function measure() {
    /* offsetWidth is 0 while the shell is display:none or not yet laid
       out — a measurement, not a width, so fall through rather than
       reporting a spurious compact. */
    if (shell && shell.offsetWidth) return classFor(shell.offsetWidth);
    if (media) {
      if (media.expanded.matches) return 'expanded';
      if (media.medium.matches) return 'medium';
    }
    return 'compact';
  }

  function apply(next) {
    if (next === current) return;
    const previous = current;
    current = next;
    root.dataset.bp = next;
    listeners.forEach(function (fn) {
      try { fn(next, previous); } catch (err) {
        if (window.console) console.error('breakpoint listener failed', err);
      }
    });
  }

  function refresh() { apply(measure()); }

  if (shell && hasObserver) {
    new ResizeObserver(refresh).observe(shell);
  } else if (media) {
    ['medium', 'expanded'].forEach(function (k) {
      const m = media[k];
      /* addListener is the deprecated spelling, and the only one Safari
         understood until 14. One branch keeps it working there. */
      if (m.addEventListener) m.addEventListener('change', refresh);
      else if (m.addListener) m.addListener(refresh);
    });
  }

  /* Stamped before anything renders, so the first paint is already in the
     right layout rather than reflowing into it. */
  current = measure();
  root.dataset.bp = current;

  return {
    current: function () { return current; },
    is: function (name) { return current === name; },

    /* "Is there a second pane?" is the only question most callers have,
       and asking it this way keeps the pixel count in one file. */
    hasDetailPane: function () { return current === 'expanded'; },
    isCompact: function () { return current === 'compact'; },

    refresh: refresh,

    subscribe: function (fn) {
      listeners.push(fn);
      return function () {
        const at = listeners.indexOf(fn);
        if (at !== -1) listeners.splice(at, 1);
      };
    }
  };
}
