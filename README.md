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
                      the record store, the width class, storage, the
                      shell context and four DOM helpers
  data/…              catalogue, tool specs, record schemas,
                      demonstration data, geography
  services/           account forms, notifications, prayer times, search,
                      share cards, appearance
  ui/                 sheets, pickers, the component builders and the
                      record vocabulary
  screens/            one module per destination, each owning its markup,
                      its rendering and its own cleanup
  tools/              one module per tool, under its category, plus a
                      registry that checks itself against the catalogue
                      and the CRUD engine every record tool runs on

assets/css/
  tokens, base, components        global
  crud.css                        record lists, details, forms and states
  responsive.css                  the three width classes
  screens/…                       one sheet per screen
  tools/shared.css, markets.css   the tool component library, and the one
                                  tool with enough of its own language to
                                  earn a sheet
  rtl.css                         direction, last so it can correct
```

Four rules hold the structure together. `tests/architecture.js` enforces
the first two; `tests/design.js` and `tests/crud.js` enforce the others.

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

**The width is decided in one place.** `core/breakpoint.js` measures the
shell — not the window, which is a different number once the shell is
inside the stage's padding and capped at 1366 — and stamps `data-bp` on
`<html>`. `responsive.css` switches on that attribute and nothing else
counts pixels a second time. The three classes are the Design System's:
compact below 600 with a bottom bar, medium 600–839 with a labelled
navigation rail, expanded 840–1366 with a persistent sidebar and
master-detail. The navigation is one destination set drawn twice, so the
router selects a destination rather than keeping three bars in step.

**A record flow is written once.** Twelve tools keep records — tasks,
reminders, notes, expenses, medication, documents, health records, habits,
water, shopping, events and birthdays — and none of them writes a list, a
form or a delete confirmation. `data/record-schemas.js` says what each
record *is*; `tools/crud-engine.js` builds every view from that, owns the
validation lifecycle and the dirty guard, and `core/records.js` holds the
records. The states the CRUD guide asks for are real rather than mocked: a
collection hydrates on a genuinely deferred read, `navigator.onLine` drives
offline, device storage genuinely refuses writes where it is blocked, a
corrupt store is a genuine load error, and every record carries a version
so a form opened against one cannot silently overwrite another.

Deleting says which kind of deletion it is. Most families offer Undo and
mean it; documents and health records — the two whose consideration in the
guide is secure deletion and consent — say the action cannot be undone and
then do not arm an Undo they could not honour.

## Tests

```bash
npm test
```

Ten suites, all of which boot the real `index.html`:

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
| `design.js` | the Design System's handoff contract: the palette, the type scale, spacing, motion, the three width classes and a golden pass at each |
| `crud.js` | the CRUD guide's own checklist, driven: every state, the validation lifecycle, conflict, undo, the dirty guard and master-detail |

jsdom has no module loader, so `scripts/bundler.js` resolves the import
graph itself and hands jsdom one ordinary script — the same bundler
`npm run build` uses. It refuses a cycle rather than
emitting a bundle that half-works, and `architecture.js` walks the same
graph over a real HTTP server so a specifier that resolves only in the test
cannot pass.

## Being converted to Flutter

**Everything above describes a temporary conversion input.** Lume is being
re-authored as a native Flutter mobile and tablet application, and this
repository becomes that Flutter project. The HTML, CSS, JavaScript, Node
scripts and the ten JavaScript suites are kept only while they are needed to
determine and verify what the Flutter interface must be. They are removed in a
dedicated cleanup commit once Flutter parity is proven and protected by
Flutter's own tests, after which this README is rewritten to describe the
Flutter project.

While the conversion runs, this prototype is the design and stays authoritative:
where it and a document disagree, the rendered interface wins. No new product
behaviour is built here.

The working record lives in `docs/conversion_archive/`, every file of which is
marked temporary and none of which is product documentation. Start with
`F0_FINAL_ARCHITECTURE.md` for the target structure, the retention plan and the
removal manifest, and `TEMPORARY_WEB_REFERENCE_NOTES.md` for what each web file
is still needed for and until when.

## Not yet production

No backend, no real authentication, no live data providers, no cloud sync,
no push service. The account engine simulates identity in browser storage
and is explicitly not production security.
