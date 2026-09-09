# Lume — Screen-Based File Architecture and Refactoring Plan

## 1. Objective

Refactor the current Lume prototype so each screen owns a separate implementation file while preserving the existing appearance, behaviour, localization, personalization, accessibility and passing test suite.

This is a structural refactor, not a redesign. Pixel-level styling, user-visible text, navigation behaviour, tool calculations, eligibility rules and stored-data keys must remain unchanged unless a separate requirement explicitly changes them.

## 2. Current architectural reality

The project is not literally one source file, but two important areas are too concentrated:

- `index.html` contains the full application shell and most static screen markup.
- `assets/js/app.js` coordinates routing, screen rendering, onboarding, sheets, tool interaction, notifications, account UI and many event handlers.

Tool implementations are already divided into broad domain files, but each domain file still contains many individual tool screens. For true screen ownership, those tools should also become one module per tool.

Existing useful boundaries that should be retained:

- `catalogue.js`: feature catalogue and availability metadata.
- `toolspec.js`: tool composition/capability contracts.
- `tooldata.js`: demonstration and regional datasets.
- `toolkit.js`: shared HTML/component builders.
- `toolctx.js`: tool context creation.
- `geo.js`, `locale.js`, `i18n*.js`: location and localization.
- `notify.js`: notification engine.
- `account.js`: prototype account engine.
- CSS token and component files.

## 3. Critical technical decision

Plain HTML cannot natively include separate HTML partials. Splitting `index.html` into files therefore requires one of these approaches:

### Recommended: ES module screen components

Each screen is a JavaScript module that owns its template, DOM references, render logic, event binding and cleanup. `index.html` retains only the shell and root mount points.

Advantages:

- Works with a simple static server.
- No framework migration is required.
- Clear lifecycle prevents duplicate listeners and timers.
- Individual screens can be tested directly.
- Supports lazy loading later.

Trade-off: the project moves from classic global scripts to ES modules, so tests and local serving must support modules.

### Alternative: build-time HTML partials

Maintain one `.html` partial per screen and assemble them into `index.html` during a build.

Advantages: screen markup remains HTML.

Trade-off: requires a build tool and does not solve `app.js` concentration by itself.

### Not recommended: runtime `fetch()` of HTML partials

This creates loading order, offline, file-protocol, focus, event binding and testing complications. It also turns local markup into artificial network requests.

This plan uses the recommended ES module approach.

## 4. Target folder structure

```text
tes/
├── index.html
├── package.json
├── assets/
│   ├── css/
│   │   ├── tokens.css
│   │   ├── base.css
│   │   ├── components.css
│   │   ├── screens/
│   │   │   ├── home.css
│   │   │   ├── tools.css
│   │   │   ├── today.css
│   │   │   ├── explore.css
│   │   │   ├── profile.css
│   │   │   ├── account.css
│   │   │   ├── auth.css
│   │   │   └── notifications.css
│   │   └── tools/
│   │       ├── shared.css
│   │       ├── markets.css
│   │       └── ...only when a tool needs unique styles
│   └── js/
│       ├── main.js
│       ├── core/
│       │   ├── app-store.js
│       │   ├── router.js
│       │   ├── navigation-stack.js
│       │   ├── event-bus.js
│       │   ├── storage.js
│       │   ├── eligibility.js
│       │   └── lifecycle.js
│       ├── data/
│       │   ├── catalogue.js
│       │   ├── tool-specs.js
│       │   ├── tool-data.js
│       │   ├── geo.js
│       │   └── solar.js
│       ├── services/
│       │   ├── account-service.js
│       │   ├── notification-service.js
│       │   ├── locale-service.js
│       │   ├── share-service.js
│       │   └── timer-service.js
│       ├── i18n/
│       │   ├── core.js
│       │   ├── tools.js
│       │   └── account.js
│       ├── ui/
│       │   ├── components.js
│       │   ├── icons.js
│       │   ├── sheets.js
│       │   ├── dialogs.js
│       │   └── states.js
│       ├── screens/
│       │   ├── home.screen.js
│       │   ├── tools.screen.js
│       │   ├── trains.screen.js
│       │   ├── today.screen.js
│       │   ├── explore.screen.js
│       │   ├── profile.screen.js
│       │   ├── account.screen.js
│       │   ├── auth.screen.js
│       │   ├── notifications.screen.js
│       │   └── tool-host.screen.js
│       └── tools/
│           ├── registry.js
│           ├── everyday/
│           │   ├── calculator.tool.js
│           │   ├── converter.tool.js
│           │   └── ...
│           ├── planning/
│           │   ├── calendar.tool.js
│           │   └── ...
│           ├── islamic/
│           │   ├── prayer.tool.js
│           │   ├── quran.tool.js
│           │   └── ...
│           ├── money/
│           │   ├── markets.tool.js
│           │   ├── tax.tool.js
│           │   └── ...
│           ├── daily/
│           │   ├── weather.tool.js
│           │   ├── emergency.tool.js
│           │   └── ...
│           └── personal/
│               ├── expenses.tool.js
│               ├── health.tool.js
│               └── ...
└── tests/
    ├── screens/
    ├── tools/
    ├── integration/
    └── existing regression files
```

Do not create a separate CSS file mechanically for every tool. Shared styles should stay shared; unique CSS belongs with the screen that uniquely needs it. One-file-per-screen ownership applies primarily to behaviour and composition, not duplicated style rules.

## 5. Screen module contract

Every top-level screen should expose the same lifecycle:

```js
export function createHomeScreen(deps) {
  let root = null;
  let abortController = null;

  return {
    id: 'home',

    mount(container, route) {
      root = container;
      abortController = new AbortController();
      root.innerHTML = template();
      bindEvents(abortController.signal);
      this.render(route);
    },

    render(route) {
      // Read current app state and update this screen only.
    },

    onEnter(route) {
      // Restore focus/scroll or start visible-only work.
    },

    onLeave() {
      // Stop timers, observers and screen-specific work.
    },

    unmount() {
      abortController?.abort();
      root?.replaceChildren();
      root = null;
    }
  };
}
```

Required guarantees:

- A screen owns only DOM inside its provided container.
- Event listeners are scoped with an `AbortController` or explicitly removed.
- Timers, animation frames, observers and subscriptions stop on leave/unmount.
- A screen does not directly activate another screen; it requests navigation through the router.
- A screen reads shared state through injected services/store, not unrelated DOM nodes.
- Rendering the same state twice is safe.
- Mounting twice does not duplicate event handlers.

## 6. Tool module contract

Each of the 85 tools should become a separate module registered by ID.

```js
export default {
  id: 'calculator',

  build(ctx) {
    return {
      header: ctx.ui.toolHeader({
        title: ctx.featureName,
        sub: ctx.t('archetype.calculator')
      }),
      body: buildCalculatorBody(ctx),
      density: ctx.spec.density,
      archetype: ctx.spec.archetype
    };
  },

  bind(root, ctx) {
    // Optional interactive bindings.
    // Return cleanup function.
    return () => {};
  }
};
```

The registry imports modules and validates that:

- Every catalogue feature has exactly one tool module.
- Every tool module ID exists in the catalogue.
- No duplicate IDs exist.
- Required composition sections follow `toolspec.js`.
- Tool capabilities match the controls actually rendered.

## 7. Shared state contract

Create one application store as the source of truth for shell-level state.

Suggested state shape:

```js
{
  route: { screen: 'home', params: {}, stack: [] },
  profile: {
    name: '', country: 'PK', region: '', city: 'Islamabad',
    language: 'en', faithEnabled: false, interests: [],
    units: 'auto', currency: 'auto', timezone: 'auto', theme: 'system'
  },
  account: { status: 'guest', user: null },
  notifications: { unread: 0, filter: 'all' },
  connectivity: { online: true },
  ui: { sheet: null, dialog: null, toast: null }
}
```

Rules:

- Preserve existing local-storage keys during the first refactor.
- State changes use named actions or service methods.
- Screens subscribe only to slices they need.
- Derived values such as eligible features are selectors, not stored duplicates.
- Sensitive records are not copied into general UI state.

## 8. Router contract

Recommended route model:

```text
/
/home
/tools
/today
/explore
/profile
/trains
/notifications
/account/:section
/auth/:flow
/tool/:toolId
/tool/:toolId/:detailId
```

The router must:

- Validate tool eligibility before rendering.
- Preserve the current return target for nested screens.
- Maintain in-tool detail history separately from primary navigation.
- Clear invalid nested state when changing tabs.
- Restore focus after Back.
- Support direct links without exposing hidden tools.
- Produce an explanatory unavailable screen when a deep link is refused.

## 9. Screen ownership map

| New module | Owns | Must not own |
| --- | --- | --- |
| `home.screen.js` | Home composition and home-only interactions | Catalogue rules, account storage, notification generation |
| `tools.screen.js` | Search, category filters, recents and tool opening | Individual tool implementations |
| `trains.screen.js` | Dedicated trains destination, if retained | General tool routing |
| `today.screen.js` | Progress, agenda and task interactions | Global time formatting logic |
| `explore.screen.js` | Weather/discovery/news composition | Regional datasets or eligibility rules |
| `profile.screen.js` | Guest/authed/expired profile composition | Password/session algorithms |
| `account.screen.js` | Account settings host and section navigation | Account persistence engine |
| `auth.screen.js` | Authentication flow presentation and validation feedback | Credential storage/security implementation |
| `notifications.screen.js` | Notification centre and settings presentation | Notification generation engine |
| `tool-host.screen.js` | Shared tool header, mounting and cleanup | Tool-specific composition |

## 10. Migration sequence

### Phase 0 — Freeze behaviour

1. Run and record the current test results.
2. Record the 85 catalogue IDs and 85 registered tool IDs.
3. Record existing local-storage keys.
4. Create a screen DOM/composition snapshot map.
5. Do not rename selectors until migration is complete.

Exit condition: baseline tests pass and inventories match.

### Phase 1 — Introduce module entry point

1. Add `assets/js/main.js` with `type="module"`.
2. Wrap global modules with temporary adapters rather than rewriting everything.
3. Create dependency injection for catalogue, locale, UI, data, account and notification services.
4. Keep the old script entry available behind a temporary development flag if necessary.

Exit condition: application boots identically through the module entry point.

### Phase 2 — Extract router and lifecycle

1. Move screen activation and Back-stack rules out of `app.js`.
2. Add a lifecycle controller.
3. Centralize screen registration.
4. Add tests for mount, enter, leave, unmount, Back and tab switching.

Exit condition: navigation tests pass with no duplicate listeners or surviving timers.

### Phase 3 — Extract top-level screens one at a time

Recommended order:

1. Tools.
2. Today.
3. Explore.
4. Home.
5. Notifications.
6. Profile.
7. Account.
8. Authentication.
9. Trains.
10. Tool host.

For each screen:

1. Move only its markup into its module template.
2. Move screen-specific rendering functions.
3. Move screen-specific event handlers.
4. Inject shared services.
5. Delete migrated code from `app.js` immediately after tests pass.
6. Run the complete test suite before starting the next screen.

Exit condition: `index.html` contains only the shell, shared overlays, mount roots and entry script.

### Phase 4 — Extract individual tools

Move tools from the four grouped implementation files into category folders, one tool per file. Start with simple calculators and focused interactions, then move complex tools such as Markets, Qur'an, account-like managers and regional dashboards.

For each tool:

1. Copy the existing registered function without redesigning it.
2. Convert implicit globals into injected context.
3. Register the new module.
4. Remove the old registration.
5. Run composition, localization and interaction tests.

Exit condition: all 85 catalogue items resolve to exactly one module and no grouped tool implementation file remains.

### Phase 5 — Split CSS by ownership

1. Keep tokens, resets and reusable components global.
2. Move clearly screen-specific selectors to screen CSS files.
3. Move truly unique complex-tool styles to tool CSS files.
4. Avoid copying shared declarations into multiple files.
5. Validate CSS loading order and RTL/dark-mode overrides.

Exit condition: global CSS contains only tokens, base layout and reusable components.

### Phase 6 — Remove compatibility layer

1. Remove obsolete `window.LUME_*` globals.
2. Remove the legacy `app.js` and grouped `tools-*.js` files.
3. Remove temporary adapters and flags.
4. Update documentation and test imports.
5. Run the full suite in a clean install.

Exit condition: no feature depends on execution order of classic global scripts.

## 11. Event-handling rules

The current application relies heavily on document-level delegated listeners. During extraction:

- Keep one intentional global dispatcher only for truly global actions.
- Prefer screen-root delegation for screen actions.
- Use declarative `data-action` values with a documented action registry.
- Do not let two screens handle the same event.
- Abort listeners on unmount.
- Stop countdowns when their screen leaves.
- Do not query inactive screen DOM to obtain state.

## 12. HTML shell after refactoring

The final `index.html` should contain only:

- Document metadata and font/style links.
- SVG icon sprite, or a separate imported sprite solution.
- Application root.
- Global status/safe-area shell if required.
- One screen outlet.
- One overlay outlet for sheets/dialogs.
- Toast and banner live regions.
- The ES module entry script.

Example:

```html
<body>
  <div id="app" class="app">
    <header id="status-root"></header>
    <main id="screen-outlet"></main>
    <nav id="tabbar-root"></nav>
    <div id="overlay-root"></div>
    <div id="toast-root" role="status" aria-live="polite"></div>
  </div>
  <script type="module" src="assets/js/main.js"></script>
</body>
```

## 13. Testing plan

### Keep unchanged

- Existing verification, interaction, control, regression, notification, account and authentication suites.

### Add

- One lifecycle test per top-level screen.
- Screen isolation tests proving it does not query another screen's DOM.
- Duplicate-listener tests after repeated navigation.
- Timer/observer cleanup tests.
- Router direct-link and Back-stack tests.
- Registry completeness test for 85 tool modules.
- Import-cycle detection.
- Module-level tests for complex calculations.
- A clean-install production boot test through a local HTTP server.

### Required matrix

At minimum, test:

- Muslim + Pakistan + English.
- Non-Muslim + Pakistan + English.
- Muslim + UK + Urdu/RTL.
- Non-Muslim + US + English.
- Muslim + Saudi Arabia + Arabic/RTL.
- Light, dark and system theme.
- Online and offline states.
- Guest, authenticated and expired account states.
- Keyboard-only and reduced-motion use.

## 14. Risks and controls

| Risk | Control |
| --- | --- |
| Screen split changes visual composition | Preserve DOM order and selectors first; improve later in separate changes |
| Duplicate document listeners | Use screen-root delegation and lifecycle cleanup |
| Circular imports | Enforce dependency direction: screens → services/UI/data; never core → screens |
| Tool availability leaks | Keep eligibility in one selector and test all entry points |
| Local storage becomes incompatible | Preserve keys and stored shapes during structural migration |
| Authentication behaviour changes | Treat account engine as an injected service; do not rewrite it during UI extraction |
| Tests fail under ES modules | Update harness loading deliberately before deleting the legacy entry |
| Too many tiny CSS files | Split only by real ownership; retain shared component styles |
| Big-bang refactor becomes unreviewable | Migrate one screen/tool at a time and keep every commit passing |

## 15. Acceptance criteria

The refactor is complete when:

- `index.html` is a small application shell rather than a screen warehouse.
- Every top-level screen has exactly one owner module.
- Every one of the 85 tools has exactly one owner module.
- Routing, lifecycle and state are separate from screen presentation.
- No screen depends on another screen's DOM.
- No duplicate listeners, timers or observers survive navigation.
- Existing user-visible design and behaviour remain unchanged.
- Faith, country and sensitive-content rules work through every entry point.
- English, Urdu, Arabic, LTR, RTL, dark mode and responsive layouts remain correct.
- All existing and new tests pass from a clean install.
- The app runs through a local HTTP server and is ready for later backend/API integration.

## 16. Ready-to-use refactoring prompt

```text
Act as a senior frontend architect. Refactor the attached Lume project from a large index.html/app.js architecture into a screen-based ES module architecture without redesigning it.

Non-negotiable requirements:

1. First inspect the complete project, its existing specifications and tests. Run the baseline test suite before editing.
2. Preserve all visible layouts, DOM composition order, CSS appearance, translations, accessibility semantics, calculations, personalization rules, local-storage keys and navigation behaviour.
3. Keep index.html as a minimal shell with a screen outlet, overlay outlet, global live regions, tab-bar root and one module entry point.
4. Create one module for each top-level screen: Home, Tools, Trains, Today, Explore, Profile, Account, Authentication, Notifications and Tool Host.
5. Give every screen the same lifecycle contract: mount(container, route), render(state), onEnter(route), onLeave(), and unmount(). All listeners, timers, observers and subscriptions must be cleaned up.
6. Move the 85 tool implementations into one module per tool under category folders. Build a registry that rejects missing, unknown or duplicate tool IDs and validates catalogue/spec compatibility.
7. Keep shared concerns separate: router, navigation stack, store, storage, eligibility, localization, regional data, account engine, notification engine, UI components, sheets/dialogs and sharing.
8. A screen may touch only its own root. It must request navigation through the router and read shared state through injected services/selectors.
9. Keep faith eligibility and country availability centralized. Hidden tools must not leak through Home, Tools, search, recents, notifications, related tools or deep links.
10. Do not use runtime fetch calls for HTML partials. Use ES module screen templates/components. Do not introduce React/Vue/Angular unless explicitly requested.
11. Migrate incrementally: entry point, router/lifecycle, top-level screens, individual tools, CSS ownership, then legacy removal. After every screen or tool batch, run the full suite.
12. Keep semantic tokens and shared component CSS global. Split only genuinely screen-specific or tool-specific CSS; do not duplicate shared styles.
13. Add tests for lifecycle cleanup, repeat navigation, direct links, Back behaviour, screen isolation, registry completeness and module cycles.
14. Do not delete legacy code until its replacement passes all relevant tests. Do not leave compatibility globals in the final architecture.

Before changing code, output:
- Current architecture map.
- Exact target file tree.
- Dependency-direction rules.
- Migration checklist.
- Risk register.
- Baseline test result.

Then implement one phase at a time. At the end, provide changed-file inventory, test results, remaining production gaps and exact run commands.
```

## 17. Recommended implementation command sequence

```bash
npm ci
npm test
# Start the refactor in small commits.
npm test
# Serve through HTTP after ES modules are introduced.
npx http-server .
```

Do not open the final module build directly with `file://`; ES module and browser security behaviour is more reliable through a local HTTP server.

