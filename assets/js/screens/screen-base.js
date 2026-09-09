/* ============================================================
   Lume — the shape every screen has

   A screen module declares four things: its id, the markup for
   its own root element, and optionally what to do when it is
   built, shown, hidden and released. This wraps that into the
   lifecycle object the controller drives, so no screen has to
   repeat the bookkeeping.

   The rule the wrapper enforces is ownership. A screen is given
   the outlet, creates exactly one root inside it, and is handed
   that root back on every later call. It never receives the
   outlet again, so it cannot reach a sibling screen by walking
   up — the boundary is structural rather than a convention.

   Listeners bound with `signal` disappear when the screen is
   unmounted, without the screen keeping a list.
   ============================================================ */

export function defineScreen(config) {
  if (!config.id) throw new Error('a screen must declare an id');
  if (typeof config.template !== 'function') {
    throw new Error('screen ' + config.id + ' must declare a template');
  }

  let root = null;

  return {
    id: config.id,

    /* Set by the lifecycle controller at mount; aborted at unmount. */
    signal: null,

    get root() { return root; },

    mount: function (outlet) {
      const holder = document.createElement('div');
      holder.innerHTML = config.template();
      root = holder.firstElementChild;
      if (!root) throw new Error('screen ' + config.id + ' rendered no root element');
      if (root.id !== 'screen-' + config.id) {
        throw new Error('screen ' + config.id + ' must root itself at #screen-' + config.id);
      }
      outlet.appendChild(root);
      if (config.bind) config.bind(root, this.signal);
    },

    render: function (route) {
      if (root && config.render) config.render(root, route);
    },

    onEnter: function (route) {
      if (root && config.onEnter) config.onEnter(root, route);
    },

    onLeave: function () {
      if (root && config.onLeave) config.onLeave(root);
    },

    unmount: function () {
      if (root && config.unmount) config.unmount(root);
      if (root && root.parentNode) root.parentNode.removeChild(root);
      root = null;
    }
  };
}
