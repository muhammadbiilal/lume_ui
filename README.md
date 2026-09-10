# Lume

A global daily-life super-app: everyday utilities, planning, money, local
services, travel, personal records and an optional, deeply integrated
Islamic experience — personalised by country, city, language, locale,
units, currency, time zone and interests, and by nothing the user did not
choose.

It is a high-fidelity browser prototype. The interactions are real and the
data is realistic demonstration data; there is no backend yet.

## Running it

```bash
npm install     # jsdom, for the tests and the build; nothing is needed at runtime
npm run serve   # http://localhost:8080
npm test        # the full suite
```

The app is ES modules, so a browser refuses to load it from `file://` and
opening `index.html` directly gives a blank page. Serve it instead.

If you want a page you can just double-click:

```bash
npm run build   # then open build/index.html
```

That bundles the module graph into one classic script and writes a page
that loads it, referencing the real stylesheets in place so there is no
second copy to fall out of date. The build opens its own output in jsdom
and checks the shell, the screens, the tab bar and a rendered Home before
reporting success — it will tell you if it produced something broken.
Rebuild after changing any JavaScript; CSS edits show up on reload.

## How it is put together

```text
index.html            the shell: metadata, icon sprite, status bar,
                      one screen outlet, one overlay outlet, the tab
                      bar, the live regions and one module entry

assets/js/
  main.js             the entry point — the only script index.html loads
  shell.js            the composition root: builds the store, the router,
                      the services, mounts the screens, owns the action
                      vocabulary
  core/               router, lifecycle, profile store, eligibility,
                      storage, the shell context and four DOM helpers
  data/…              catalogue, tool specs, demonstration data, geography
  services/           account forms, notifications, prayer times, search,
                      share cards, appearance
  ui/                 sheets, pickers, the component builders
  screens/            one module per destination, each owning its markup,
                      its rendering and its own cleanup
  tools/              one module per tool, under its category, plus a
                      registry that checks itself against the catalogue

assets/css/
  tokens, base, components        global
  screens/…                       one sheet per screen
  tools/shared.css, markets.css   the tool component library, and the one
                                  tool with enough of its own language to
                                  earn a sheet
  rtl.css                         direction, last so it can correct
```

Two rules hold the structure together, and `tests/architecture.js`
enforces both:

**Visibility is asked in one place.** Whether a feature exists for this
user is decided by `core/eligibility.js` and nowhere else, so Home, Tools,
Today, Explore, search, the tab bar, notifications, recents, related tools
and deep links cannot disagree. Faith and country are separate rules: one
is the Islamic experience being switched on, the other is which markets a
feature has launched in.

**A screen owns its own root and nothing else.** Each screen builds one
element into the outlet and is handed that element back on every later
call, so it cannot reach a sibling. Listeners are bound with an abort
signal and timers stop when the screen leaves.

## Tests

```bash
npm test
```

Eight suites, all of which boot the real `index.html`:

| Suite | What it holds |
| --- | --- |
| `architecture.js` | the module graph, the registry, the lifecycle, screen isolation, repeat navigation, the first run, the cascade |
| `verify.js` | every tool builds in five personalisation states, with no leaks and no untranslated keys |
| `interact.js` | navigation, gating and regional configuration |
| `controls.js` | filters, sorting, search, accessibility roles, localisation |
| `regress.js` | one assertion per defect found by an adversarial read |
| `notify.js` | the notification engine, centre, privacy rules and permission flow |
| `account.js` | onboarding, identity, settings and the account lifecycle |
| `auth.js` | the authentication flows and their layout contract |

jsdom has no module loader, so `scripts/bundler.js` resolves the import
graph itself and hands jsdom one ordinary script — the same bundler
`npm run build` uses. It refuses a cycle rather than
emitting a bundle that half-works, and `architecture.js` walks the same
graph over a real HTTP server so a specifier that resolves only in the test
cannot pass.

## Not yet production

No backend, no real authentication, no live data providers, no cloud sync,
no push service. The account engine simulates identity in browser storage
and is explicitly not production security.
