/* ============================================================
   Lume — Appearance

   Three states, not two: an explicit light, an explicit dark,
   and following the system — which is the absence of a stored
   choice rather than a third stored value.

   "Follow the system" has to actually follow it. Sampling the
   preference once at startup and freezing was the bug this
   exists to prevent, so the media query is watched for as long
   as the app is open and an explicit choice always wins.
   ============================================================ */
import { store } from '../core/storage.js';

export function createTheme(options) {
  const onChange = (options && options.onChange) || function () {};
  const root = document.documentElement;
  function setTheme(theme, remember) {
    root.dataset.theme = theme;
    if (remember) store.set('lume-theme', theme);
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', theme === 'dark' ? '#0A0A0B' : '#F6F6F4');
  }

  function setThemeMode(mode) {
    if (mode === 'system') {
      store.set('lume-theme', '');
      var dark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
      setTheme(dark ? 'dark' : 'light', false);
      return;
    }
    setTheme(mode, true);
  }

  /* "Follow the system" has to actually follow it, rather than sampling the
     preference once at startup and freezing. */
  (function watchSystemTheme() {
    if (!window.matchMedia) return;
    var mq = window.matchMedia('(prefers-color-scheme: dark)');
    var onChange = function () {
      if (store.get('lume-theme')) return;     /* an explicit choice wins */
      setTheme(mq.matches ? 'dark' : 'light', false);
      onChange();
    };
    if (mq.addEventListener) mq.addEventListener('change', onChange);
    else if (mq.addListener) mq.addListener(onChange);
  })();

  /* The theme is applied before first paint by a small inline script in
     index.html, so this only has to keep it in step from here on. */
  return {
    set: setTheme,
    setMode: setThemeMode,
    current: function () { return root.dataset.theme; }
  };
}
