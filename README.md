# Lume

A global daily-life super-app: everyday utilities, planning, money, local
services, travel, personal records and an optional, deeply integrated
Islamic experience — personalised by country, city, language, locale,
units, currency, time zone and interests, and by nothing the user did not
choose.

It is a high-fidelity browser prototype. The interactions are real and the
data is realistic demonstration data; there is no backend yet.

## Running it

ES modules are fetched rather than read, so the app no longer opens from
`file://` — a browser refuses a module script on that origin.

```bash
npm install     # jsdom, for the tests; nothing is needed at runtime
npm run serve   # http://localhost:8080
npm test        # the full suite
```

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

jsdom has no module loader, so `tests/modules.js` resolves the import graph
itself and hands jsdom one ordinary script. It refuses a cycle rather than
emitting a bundle that half-works, and `architecture.js` walks the same
graph over a real HTTP server so a specifier that resolves only in the test
cannot pass.

## Not yet production

No backend, no real authentication, no live data providers, no cloud sync,
no push service. The account engine simulates identity in browser storage
and is explicitly not production security.
