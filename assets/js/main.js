/* ============================================================
   Lume — module entry point

   The one script index.html loads. Everything else reaches the
   page because something here, or something it imports, asked
   for it by name. Nothing depends on <script> order any more.

   Import order still matters for the two side-effect groups
   below, and that is deliberate rather than incidental:

     · the string packs merge into the shared dictionaries, so
       they must run before anything reads a translation;
     · the tool builders register themselves into the tool
       registry, so they must run before the shell opens a tool.

   ES modules evaluate depth-first in written order, so listing
   them above the shell is the ordering guarantee.
   ============================================================ */

/* Strings first — the packs merge into LUME_I18N.DICTS. */
import './i18n-tools.js';
import './i18n-account.js';

/* Then the tool builders, which register into the tool registry. */
import './tools-faith.js';
import './tools-money.js';
import './tools-life.js';
import './tools-personal.js';

/* Then the shell, which reads both. */
import { account, accountUI } from './app.js';

import { LUME } from './catalogue.js';
import { LUME_GEO } from './geo.js';
import { LUME_I18N } from './i18n.js';
import { LUME_LOCALE } from './locale.js';
import { LUME_SPEC } from './toolspec.js';
import { LUME_TOOLS } from './tools.js';
import { LUME_CTX } from './toolctx.js';
import { LUME_NOTIFY } from './notify.js';
import { createLifecycle } from './core/lifecycle.js';

/* ------------------------------------------------------------
   The inspection surface

   One namespace, published on purpose, so the test harness and a
   developer console can reach pieces the modules otherwise wire
   to each other privately. Nothing in the application reads it:
   modules find each other by import, and this object is written
   to, never from. It replaces the flat window.LUME_* globals,
   which existed only so classic scripts could find one another
   and are gone with the script tags that needed them.

   Every import above has finished evaluating by the time this
   statement runs, so `account` and `accountUI` — which app.js
   fills in while it boots — are already the live instances.
   ------------------------------------------------------------ */
window.Lume = {
  catalogue: LUME,
  geo: LUME_GEO,
  i18n: LUME_I18N,
  spec: LUME_SPEC,
  tools: LUME_TOOLS,
  localeFactory: LUME_LOCALE,
  ctxFactory: LUME_CTX,
  notifyFactory: LUME_NOTIFY,
  createLifecycle: createLifecycle,
  account: account,
  accountUI: accountUI
};
