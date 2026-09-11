# Web → Flutter mapping

Every Lume web concept and the Flutter construct that reproduces it. This is
the translation table the conversion works from; where a number appears here it
came out of the stylesheet or the module, not out of a description of it.

Conventions used throughout:

- **CSS px are logical pixels.** The web prototype and Flutter use the same
  number for the same size. No scaling factor is applied anywhere.
- **A token is never inlined at a call site.** If `tokens.css` names a value,
  the Flutter side reaches for the token, not the literal.
- **Dark is authored, not derived.** Every dark value is the one written in
  `[data-theme="dark"]`, never computed from the light value.

---

## 1. The top-level correspondence

| Lume web concept | Flutter equivalent |
|---|---|
| CSS custom property in `tokens.css` | Field on a `ThemeExtension` — `LumeColors`, `LumeType`, `LumeSpace`, `LumeMotion` |
| CSS class | A named widget, or a style method on a token class — never a loose `Container` |
| `display:flex` row/column | `Row` / `Column`, `Flexible`, `Expanded`, `Spacer` |
| `flex-wrap: wrap` | `Wrap` |
| `display:grid` fixed columns | `GridView` with `SliverGridDelegateWithFixedCrossAxisCount`, or `LayoutGrid`-style custom layout |
| `display:grid` with `gap` | `Column`/`Row` with `spacing:`, or `Wrap(spacing:, runSpacing:)` |
| `grid-template-areas` shell | `Row` of rail + `Expanded(content)` under a status strip `Column` |
| `@media` / `data-bp` | `LumeBreakpointScope` → `context.widthClass` |
| DOM route (`router.go('home')`) | `GoRouter` route with a `StatefulShellRoute` for the tab set |
| `data-act="tool:calculator"` | A typed callback on the view model, not a string |
| `data-i18n` key | ARB key, read through `AppLocalizations` |
| `localStorage` profile | Fixture/reference state object, provider-shaped |
| Record schema | Fixture model + declarative form definition |
| `.is-loading` / skeleton markup | `LumeSkeleton` widget |
| `.panes` master-detail CSS | `LumeMasterDetail` adaptive widget |
| `:focus-visible` / `:hover` / `[disabled]` | `WidgetStateProperty` / `WidgetStatesController` |
| `.is-rtl` selectors | `Directionality` + logical `EdgeInsetsDirectional` |
| `overflow: hidden` + `text-overflow` | `maxLines` + `TextOverflow.ellipsis` |
| `text-wrap: balance` / `pretty` | Nearest Flutter behaviour is plain wrapping — recorded as a permitted difference |

---

## 2. Design tokens

### 2.1 Colour — `LumeColors extends ThemeExtension<LumeColors>`

Read as `Theme.of(context).extension<LumeColors>()!`, exposed through a
`context.lume` extension getter.

| CSS token | Dart field | Light | Dark |
|---|---|---|---|
| `--accent-50` | `accent50` | `#E9F7F4` | `#0C2B27` |
| `--accent-100` | `accent100` | `#CFEDE7` | `#103B35` |
| `--accent-200` | `accent200` | `#A5DED4` | `#17564D` |
| `--accent-400` | `accent400` | `#34B39D` | `#2FC0A9` |
| `--accent` | `accent` | `#10998A` | `#35CBB2` |
| `--accent-600` | `accent600` | `#0B7F73` | `#58D8C2` |
| `--accent-700` | `accent700` | `#086357` | `#8AE7D7` |
| `--accent-ink` | `accentInk` | `#07564C` | `#B6F2E7` |
| (`.btn--accent` colour) | `onAccent` | `#FFFFFF` | `#06231F` |
| `--violet` | `violet` | `#6E62E5` | `#9A90FF` |
| `--indigo` | `indigo` | `#3D4BC7` | `#7E8AF0` |
| `--amber` | `amber` | `#E0913A` | `#EDB268` |
| `--on-amber` | `onAmber` | `#2A1A06` | `#2A1A06` |
| `--amber-ink` | `amberInk` | `#8A5410` | `#F0C48A` |
| `--rose` | `rose` | `#DE6B7A` | `#F0919C` |
| `--on-rose` | `onRose` | `#FFFFFF` | `#2A0E12` |
| `--rose-ink` | `roseInk` | `#A3323F` | `#F0A3AD` |
| `--sky` | `sky` | `#3E9BD4` | `#6EBAE8` |
| `--bg` | `bg` | `#F6F6F4` | `#0A0A0B` |
| `--bg-sunk` | `bgSunk` | `#EFEFEC` | `#060607` |
| `--card` | `card` | `#FFFFFF` | `#141416` |
| `--card-2` | `card2` | `#FAFAF9` | `#191A1C` |
| `--card-hover` | `cardHover` | `#F4F4F2` | `#1E1F22` |
| `--text` | `text` | `#101113` | `#F3F3F4` |
| `--text-2` | `text2` | `#56585F` | `#A2A4AB` |
| `--text-3` | `text3` | `#8B8D95` | `#74767D` |
| `--border` | `border` | `rgba(16,17,19,.07)` | `rgba(255,255,255,.075)` |
| `--border-2` | `border2` | `rgba(16,17,19,.12)` | `rgba(255,255,255,.14)` |
| `--overlay` | `overlay` | `rgba(16,17,19,.38)` | `rgba(0,0,0,.6)` |
| `--tint-accent` | `tintAccent` | `#E7F4F1` | `#10312C` |
| `--tint-neutral` | `tintNeutral` | `#F1F1EE` | `#1C1D20` |
| `--sticker-opacity` | `stickerOpacity` | `1.0` | `0.72` |
| `--mesh-opacity` | `meshOpacity` | `0.55` | `0.35` |

Three pairs must stay two fields, never one — this is a real accessibility
contract, stated in `tokens.css` and asserted by `tests/design.js`:

- **rose** carries white at 3.24:1 and reads on `card` at 3.24:1 → `onRose` ≠ `roseInk`.
- **amber** carries white at 2.1:1 → `onAmber` ≠ `amberInk`.
- **accent** as a surface takes white ink in light and a deep ink in dark → `onAccent` flips.

`color-mix(in srgb, X p%, transparent)` → `X.withValues(alpha: p/100)`.
`color-mix(in srgb, X p%, Y)` → `Color.lerp(Y, X, p/100)`.

### 2.2 Gradients — `LumeGradients`

Eleven named two-stop colourways, each re-authored for dark rather than dimmed,
plus the ink that sits on them (`--on-grad`, `--on-grad-dim`).

| Colourway | Light a → b | Dark a → b |
|---|---|---|
| `accent` | `#0B7F73` → `#23A894` | `#06463F` → `#0E6F63` |
| `prayer` | `#0B4F63` → `#10998A` | `#072F3C` → `#0A6156` |
| `night` | `#1F2352` → `#4B3E8E` | `#14163A` → `#2E2760` |
| `gold` | `#5E4110` → `#8A6420` | `#3B2909` → `#5E4415` |
| `sky` | `#1F5680` → `#3E86BB` | `#133753` → `#24567A` |
| `flame` | `#8A3A16` → `#B36A22` | `#57240D` → `#7A4716` |
| `lock` | `#2E3440` → `#55606F` | `#1D222B` → `#364049` |
| `sport` | `#14513A` → `#2E8F63` | `#0C3325` → `#1B5C40` |
| `warn` | `#7A3A14` → `#A8672C` | `#4E250D` → `#6F441D` |
| `sos` | `#8E1B2E` → `#B83D48` | `#5C111E` → `#7C2831` |
| `scan` | `#1A1D22` → `#2B3038` | `#101216` → `#1B1F25` |
| on-grad | `#FFFFFF` / `rgba(255,255,255,.82)` | `#F4F6F5` / `rgba(244,246,245,.80)` |

Gradients are reserved for hero surfaces, featured content and decoration. A
`LinearGradient` reproduces `linear-gradient(150deg, a, b)` with matching
`begin`/`end` alignments; radial mesh backgrounds map to
`RadialGradient` layers in a `DecoratedBox` stack at `meshOpacity`.

### 2.3 Typography — `LumeType`

`--font: "Plus Jakarta Sans"` for Latin and numerals. `Noto Naskh Arabic` for
Arabic-script reading content. Money, timers, rates and aligned statistics use
tabular numerals (`FontFeature.tabularFigures()`), which is what the `.num`
class does in the web.

CSS `font: <weight> <size>/<line-height> <family>` maps to
`TextStyle(fontWeight:, fontSize:, height: lineHeight / fontSize)`.

| CSS token | Dart role | Size / line | Weight | `height` | Usage |
|---|---|---|---|---|---|
| `--t-display` | `display` | 28 / 32 | w800 | 1.1429 | Key value, onboarding title |
| `--t-title` | `title` | 20 / 26 | w700 | 1.30 | Screen title |
| `--t-section` | `section` | 17 / 22 | w700 | 1.2941 | Section hierarchy |
| `--t-cardtitle` | `cardTitle` | 15 / 20 | w700 | 1.3333 | Record or card name |
| `--t-body` | `body` | 14 / 22 | w400 | 1.5714 | Descriptions and values |
| `--t-bodystrong` | `bodyStrong` | 14 / 22 | w500 | 1.5714 | Emphasised body |
| `--t-label` | `label` | 12 / 16 | w700 | 1.3333 | Fields and actions |
| `--t-meta` | `meta` | 12 / 16 | w600 | 1.3333 | Dates and statuses |
| `--t-metasm` | `metaSmall` | 11 / 16 | w500 | 1.4545 | Small metadata |
| `--t-tab` | `tab` | 10 / 14 | w700 | 1.40 | Bottom bar and rail labels only |

Letter-spacing is not in the token; it is applied per role at the call site in
CSS and becomes part of the Dart role:

| Where | `letter-spacing` | Dart |
|---|---|---|
| `.btn` | `-.022em` | `letterSpacing: -0.022 * 14` |
| `.navtab` | `-.02em` | `letterSpacing: -0.02 * 15` |
| `.onb__title` | `-.04em` | `letterSpacing: -0.04 * 28` |
| `.onb__kicker`, `.statusbar__brand` | `.1em` + uppercase | `letterSpacing: 0.1 * 11`, via `LumeType.overline` |
| `.onb__wordmark` | `-.04em` | `letterSpacing: -0.04 * 20` |

Three rules carried over:

- **Never write a bare line height.** Arabic, Urdu and Devanagari fall back per
  glyph to a system face while keeping the height they were handed, and 1.2–1.3
  clips harakat, Nastaliq descenders and matras. Use a script-aware helper
  (`LumeType.lineHeight(context, base)`), which is what `rtl.css` does with
  `[lang="ur"] body { line-height: 1.6 }` and `[lang="ur"] .onb__title { line-height: 1.45 }`.
- **Never `toUpperCase()`.** Dart's is locale-independent: Turkish `i` becomes
  `I` not `İ`, and it is a wasted allocation in caseless scripts. An overline
  helper does it correctly or not at all.
- **`[lang="ur"] .tab__label` drops to 10 px** and `letter-spacing` goes to `0`
  for `.appbar__greet`, `.page-head__title` and `.onb__title` in ur/ar. These
  are script overrides on the role, not per-screen hacks.

### 2.4 Space, shape, elevation, motion — `LumeSpace`, `LumeRadius`, `LumeShadow`, `LumeMotion`

| CSS token | Dart | Value | Note |
|---|---|---|---|
| `--pad` | `LumeSpace.page` | 20 (compact) / 24 (medium) / 32 (expanded) | Changes with width class |
| `--gap-card` | `LumeSpace.gapCard` | 16 | Between cards |
| `--gap-section` | `LumeSpace.gapSection` | 24 | Between sections |
| `--pad-card` | `LumeSpace.padCard` | 16 | Inside a card |
| `--pad-row` | `LumeSpace.padRow` | `EdgeInsets.symmetric(vertical: 12, horizontal: 16)` | One value for nine row types |
| `--r-xs` | `LumeRadius.xs` | 8 | Small controls |
| `--r-icon` | `LumeRadius.icon` | 12 | Every icon container |
| `--r-sm` | `LumeRadius.sm` | 12 | Compact cards, controls |
| `--r-md` | `LumeRadius.md` | 16 | Standard cards |
| `--r-lg` | `LumeRadius.lg` | 20 | Prominent surfaces |
| `--r-xl` | `LumeRadius.xl` | 26 | Sheets and hero surfaces |
| `--r-full` | `LumeRadius.full` | `StadiumBorder` | |
| `--tap` | `LumeSpace.tap` | 44 | Minimum touch target |
| `--nav-rail` | `LumeSpace.navRail` | 84 | Medium rail width |
| `--nav-side` | `LumeSpace.navSide` | 244 | Expanded sidebar width |
| `--content-max` | `LumeSpace.contentMax` | 760 | Reading and form cap |
| `--content-wide` | `LumeSpace.contentWide` | 1180 | Master-detail, multi-column |
| `--list-pane` | `LumeSpace.listPane` | 380 | Expanded list pane (clamped 320–380) |

Elevation — CSS box-shadows become `List<BoxShadow>`; a two-layer CSS shadow is
two `BoxShadow`s in order. Negative `spread` maps to `spreadRadius`, and CSS
blur radius is **twice** Flutter's `blurRadius`, so every blur is halved.

| CSS token | Light | Dark |
|---|---|---|
| `--shadow-xs` | `0 1px 2px rgba(16,24,40,.05)` | `0 1px 2px rgba(0,0,0,.5)` |
| `--shadow-sm` | `0 1px 2px /.04` + `0 2px 6px -2px /.06` | `0 1px 2px /.4` + `0 2px 6px -2px /.5` |
| `--shadow-md` | `0 2px 4px -2px /.05` + `0 8px 20px -6px /.10` | `/.4` + `/.55` |
| `--shadow-lg` | `0 8px 16px -8px /.10` + `0 24px 48px -16px /.20` | `/.5` + `/.7` |
| `--shadow-nav` | `0 -1px 0 border` + `0 -8px 32px -12px /.16` | `/.8` |

Motion — durations and curves are tokens, and `tests/design.js` asserts all
three durations by name.

| CSS token | Dart | Value |
|---|---|---|
| `--dur-fast` | `LumeMotion.fast` | 160 ms — press feedback |
| `--dur` | `LumeMotion.standard` | 260 ms — standard transition |
| `--dur-slow` | `LumeMotion.slow` | 420 ms — screen transition |
| `--ease` | `LumeMotion.ease` | `Cubic(.22, .61, .36, 1)` |
| `--ease-out` | `LumeMotion.easeOut` | `Cubic(.16, 1, .3, 1)` |
| `--ease-spring` | `LumeMotion.spring` | `Cubic(.34, 1.4, .64, 1)` |

`@media (prefers-reduced-motion: reduce)` → `MediaQuery.disableAnimationsOf(context)`.
Every indefinite animation (skeleton shimmer, live-marker pulse, `.onb__float`)
must stop when it is true — both because the design says so and because
`pumpAndSettle` hangs forever otherwise.

---

## 3. Layout and responsiveness

### 3.1 The width class

`core/breakpoint.js` resolves the class once, from the **shell**, and stamps it
on `<html>` as `data-bp`. Flutter does the same with a `LayoutBuilder` at the
shell, published through an `InheritedWidget`.

| | Web | Flutter |
|---|---|---|
| Source of measurement | `ResizeObserver` on `.app`, `matchMedia` fallback | `LayoutBuilder` constraints, `MediaQuery.sizeOf` fallback |
| Publication | `data-bp` attribute + subscription | `LumeBreakpoint` inherited widget |
| Read | CSS `:root[data-bp="…"]`, JS `breakpoint.is()` | `context.widthClass` |
| "Is there a second pane?" | `breakpoint.hasDetailPane()` | `context.hasDetailPane` |

| Class | Width | Navigation | Page padding |
|---|---|---|---|
| compact | < 600 | bottom bar | 20 |
| medium | 600–839 | 84 px labelled rail | 24 |
| expanded | ≥ 840 | 244 px sidebar | 32 |

**Compact-height override — a native addition.** The web prototype's classes
are width-only; it never met a phone held sideways. A landscape iPhone is
852 × 393 or 926 × 428, which crosses the expanded boundary on width alone and
would be handed a 244 px sidebar and a two-pane layout on a surface 393 px tall.
Below **480 logical pixels of height** the shell is compact whatever its width.
480 is Material's own compact-height boundary and it separates the two
populations cleanly — no tablet loses its rail in either orientation, and no
phone gains one. Recorded in [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md).

The **content measure** keeps the width-only class. Navigation and panes are
about room; the reading cap is about line length, and a 900 px line of body text
is too long whatever the height. So the shell publishes both a
height-aware `widthClass` and a width-only `measureClass`.

### 3.2 Sub-breakpoints that are not the width class

The stylesheets carry four narrower rules beyond `data-bp`. They are real and
must be reproduced, but they are **layout details of a component**, not a fourth
width class, so they become named constants on the component rather than new
entries in the breakpoint enum.

| CSS | Where | Flutter |
|---|---|---|
| `@media (max-width: 359px)` | `.appbar__greet` 20 px, `.cat-grid` → 2 columns, `.pavatar` 66 px, `.srow__value` 40vw, `.auth__title` 28 px, `.auth__visual` 96 px, `.authseal` 108 px | `LumeBreakpoints.narrow = 360`, checked by the owning widget |
| `@media (min-width: 600px)` | `.fab { position: absolute }` | Already implied by the medium class |
| `@media (min-width: 1180px)` on `.app--wide` | `.metrics --cols: 4`, `.tiles` → 5 columns, `.phead` max 620, auth panel becomes a 460 px card | `LumeBreakpoints.wide = 1180` |
| `@media (min-width: 1380px)` on `.app--wide` | Auth grows a 48 % illustrated aside | `LumeBreakpoints.ultrawide = 1380` |
| `@media (840px–1100px)` + `[data-split="1"]` | Two-column form collapses to one | Form collapses on its own measured width |

### 3.3 The stage and the device frame

`base.css` puts the shell inside a `.stage`: below 600 px the app is capped at
560 px and centred; at 600 px and above the stage gains 24 px of padding, a
radial-gradient ground, and the app becomes a rounded, bordered, shadowed
surface `min(100dvh - 48px, 980px)` tall.

**This is browser presentation, not application layout.** It exists so a
prototype on a desktop monitor reads as a device on a desk. In Flutter the app
*is* the device, so the stage, the frame, the 560 px cap and the 980 px height
clamp are all dropped. The layout *inside* the frame is the real layout and is
reproduced exactly. Recorded in [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md).

The simulated `.statusbar` (brand mark, `9:41` clock, signal/wifi/battery
glyphs) is the same kind of artifact at compact width and is replaced by the
real system status bar and `SafeArea`. At medium and expanded it is *not* an
artifact — it is the top of the application, carries the wordmark, and is kept.

### 3.4 Master-detail

| | Web | Flutter |
|---|---|---|
| Structure | `.panes` grid, `minmax(320px, 380px)` + `minmax(0, 1fr)`, 20 px gap | `Row` of a `SizedBox(width: clamp)` list and an `Expanded` detail |
| Below expanded | `.panes__detail[data-when="expanded"]` hidden | Detail is a pushed route |
| At expanded | `.panes__list[data-when="compact"]` hidden | Both panes live |
| Detail behaviour | `position: sticky; top: 0` | Detail pane does not scroll with the list |
| List state | never re-mounted, keeps scroll and filters | `PageStorageKey` on the list; selection is view-model state |

Selecting a record at expanded width must not push a route, and the list must
keep its scroll position, its filters and its search. `tests/crud.js` asserts
both.

### 3.5 Content measure

Every `.sect` / `.section` / `.row-gap` is capped at
`--content-max + --pad * 2` and centred at medium and expanded. `.is-wide`
raises the cap to `--content-wide + --pad * 2`, and a screen showing two panes
raises every section under it to the wide cap. Forms stay at `--content-max`
even inside a wide composition.

Flutter: one `LumeMeasure` widget that applies
`ConstrainedBox(maxWidth: cap) + Center`, taking the cap from `measureClass` and
an `isWide` flag. Individual screens do not compute this.

---

## 4. Navigation and routing

One destination set, three presentations, one selection. The router selects a
destination; it does not keep three bars in step.

| Web | Flutter |
|---|---|
| `createRouter` + `activate(name)` | `GoRouter` with `StatefulShellRoute.indexedStack` |
| `tabOrder()` — personalised, 5 max | A provider returning the ordered destination list |
| `.tab` bottom bar + `#tabPill` | `LumeBottomBar` with an animated selection pill |
| `.navtab` rail (medium) | `LumeNavRail`, stacked icon over `--t-tab` label |
| `.navtab` sidebar (expanded) | `LumeNavSidebar`, row with `--t-cardtitle` label + wordmark |
| `lifecycle.mount/render/enter/leave/unmount` | `StatefulWidget` lifecycle + `AutomaticKeepAliveClientMixin` inside the shell's `IndexedStack` |
| `AbortController` signal | `dispose()` cancelling controllers, timers and subscriptions |
| `NON_TAB_DESTINATIONS` | Routes outside the shell branch set |
| `router.refreshTabs()` after a country change | Re-reading the destination provider; a destination that is no longer a tab goes home |
| `#exploreBack` | A back affordance shown when Explore is reached as a non-tab |

| Country | Destinations |
|---|---|
| Pakistan | Home · Tools · Trains · Today · Profile |
| Everywhere else | Home · Tools · Today · Explore · Profile |

Screen state must survive a destination change and a width-class change.
`IndexedStack` inside the shell branch gives that for free; a `PageStorageKey`
on every scrollable gives scroll restoration.

---

## 5. Visibility and gating

`core/eligibility.js` is the only place that decides whether a feature exists
for this user, and Home, Tools, Today, Explore, search, the tab bar,
notifications, recents, related tools and deep links all ask the same function.
The Flutter side keeps that shape exactly: one `LumeEligibility` service, one
`visible(feature)`, and no `if (islamic)` anywhere in a widget.

| Rule | Web | Flutter |
|---|---|---|
| Faith | `f.faith && !ctx.islamic` → hidden | same predicate, same one place |
| Country | `f.countries && !contains(ctx.country)` → hidden | same |
| Preference | `cricket`, `news`, `markets`, `goldrates` read live profile prefs | same |

Defence in depth: hiding the entry point is not enough. The route itself, the
search index, deep links, sheets, notifications, recommendations, quick tools,
the hero and recents must all refuse a hidden feature. In Flutter that is a
router `redirect` on the tool route plus the same predicate at every list.

---

## 6. Components

Full inventory and status in [COMPONENT_MATRIX.md](COMPONENT_MATRIX.md). The
measurements below are the ones the conversion is held to.

| Component | Web spec | Flutter |
|---|---|---|
| Primary button `.btn` | h 46, pad 0 20, radius 12, 14 px w700, ls −.022em, gap 7, bg `text`/fg `bg` | `LumeButton` — `height: 46`, `LumeRadius.sm` |
| `.btn--accent` | bg `accent`, fg `#fff` (dark: `#06231F`), shadow `0 6px 18px -8px accent@80%` | `LumeButton.accent` |
| `.btn--ghost` | bg `tintNeutral`, fg `text` | `LumeButton.ghost` |
| `.btn--block` | `width: 100%` | `LumeButton(block: true)` |
| Search `.search` | h 44, pad 0 14, radius 12, gap 9, bg `card`, 1 px `border`, `shadow-xs`, fg `text-3` | `LumeSearchField` |
| Card `.card` | bg `card`, 1 px `border`, radius 20 (`--r-lg`), `shadow-sm`, clipped | `LumeCard` |
| Record row `.rrec` | min-h 44, pad 13 14, gap 12, radius 16, bg `card`, 1 px `border`, `shadow-xs` | `LumeRecordRow` |
| `.rrec:hover` | bg `card-hover` | `WidgetState.hovered` |
| `.rrec.is-selected` | bg `tintAccent`, border `accent@45%` | `WidgetState.selected` |
| `.rrec.is-done` | title line-through + `text-3`, disc opacity .55 | `done` flag on the row |
| Form field `.cfield__box` | min-h 48, pad 0 14, gap 8, radius 12, bg `card`, 1 px `border-2` | `LumeField` |
| field focus | border `accent` + ring `0 0 0 3px tintAccent` | focused state |
| field invalid | border `roseInk` + ring `rose@22%` **and a message below** | invalid state — colour never alone |
| Field label `.cfield__label` | `--t-label`; optional marker `--t-metasm` `text-3` | |
| Textarea | `min-height: 76`, line-height 1.55, vertical resize only | `maxLines` + `minLines` |
| Focus ring (global) | `outline: 2px solid accent; offset 2px; radius 6` | `FocusRing` decoration, same numbers |
| Icons | 24 px box, **1.75 px rounded stroke**, sizes 16/20/24 | One stroke-consistent icon set |
| Bottom sheet | top radius 26, safe-area padding; at ≥600 a centred `min(520px, 100% − 48px)` surface, 24 px from the bottom | `LumeSheet` |
| Toast | high-contrast pill above navigation, carries Undo | `LumeToast` |
| FAB | `bottom: 28` at medium/expanded | `LumeFab` |
| Onboarding progress `.onb__seg` | flex segments, h 3, gap 5, radius full, fill animates width over `--dur-slow` `--ease-out` | `LumeSegmentedProgress` |
| Onboarding back `.onb__nav` | 34 × 34 circle, `card` bg, 1 px `border`, `shadow-xs`, 17 px glyph; disabled → opacity 0, `scale(.8)`, non-interactive | `LumeCircleBack` |

---

## 7. States

Every state in the CRUD guide is reachable for real in the web prototype — none
is mocked — and the Flutter reference reproduces each as a deterministic fixture.

| State | Web origin | Flutter fixture |
|---|---|---|
| loading | genuinely deferred read in `core/records.js` | `RecordsState.loading` |
| ready / populated | store returns items | `RecordsState.ready` |
| empty | store returns zero items | `RecordsState.empty` |
| offline | `navigator.onLine` | `RecordsState.offline` — cached records + offline label |
| load error | corrupt store | `RecordsState.error` — Try again first |
| save failure | device storage refuses the write | input preserved, explanation, Retry |
| conflict | every record carries a version | Review or Reload, never a silent overwrite |
| no results | filter/search matches nothing | distinct from empty |
| disabled / unavailable | eligibility | |
| sensitive / private | `sens` flag in the catalogue | detail hidden by default |

CRUD views are `list`, `detail`, `new`, `edit`, plus delete as a confirmation
sheet. Twelve record families share one engine; none writes its own form.

Validation lifecycle, asserted by `tests/crud.js`: do not judge an untouched
field; validate independently judgeable rules on blur; validate everything on
submit, focus the first error and keep every value typed; prevent duplicate
submission while a save is in flight; warn before leaving a dirty form.

Deletion says which kind it is. Most families offer Undo and honour it;
`documents` and `health` say the action cannot be undone and then do not arm an
Undo they could not keep.

---

## 8. Localisation and RTL

| Web | Flutter |
|---|---|
| `data-i18n` attribute + `applyStrings()` | ARB keys through `AppLocalizations` |
| `LUME_I18N.DICTS` (en/ur/ar) | `app_en.arb`, `app_ur.arb`, `app_ar.arb` |
| Missing key falls back to English | gen_l10n's template fallback — same behaviour |
| `LANGS[].dir` | `AppLocalizations.supportedLocales` + `Directionality` |
| `.is-rtl` class on the shell | `Directionality.of(context)` |
| `margin-inline`, `padding-inline`, `border-inline-end`, `inset-inline-start` | `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional` |
| `text-align: start` | `TextAlign.start` |
| `.is-rtl … svg { transform: scaleX(-1) }` on forward chevrons | `Transform.flip` **only** on the same directional glyphs |
| `.num`, `.locrow__code`, `.trainno` → `direction: ltr; unicode-bidi: isolate` | `Directionality(TextDirection.ltr)` around the numeral run |
| `unicode-bidi: plaintext` on mixed status values | `TextDirection` from first strong character |
| `[lang="ur"] body { line-height: 1.6 }` | script-aware line height |

**What must not mirror:** clocks, play buttons, media controls, numbers,
charts with a time axis, and any chevron whose meaning is "later in time"
rather than "forward in reading order". `rtl.css` names exactly seven selectors
that flip; nothing else does.

**Coverage today:** en 2,587 keys; ur 730 (25.2 %); ar 726 (25.0 %). The
Flutter ARB files carry the same coverage and the same English fallback — the
conversion does not invent translations.

---

## 9. Accessibility

| Web | Flutter |
|---|---|
| `aria-selected` on tabs | `Semantics(selected:)` |
| `aria-pressed` on interest chips and the faith toggle | `Semantics(toggled:)` |
| `role="tablist"` on both navigations | `Semantics` container with `namesRoute` |
| `aria-live="polite"` toast and banner | `SemanticsService.announce` |
| `.sr-only` | `Semantics(label:, child: SizedBox.shrink())` or `ExcludeSemantics` |
| Icon-only control with `aria-label` | `IconButton(tooltip:)` + `Semantics(label:)` |
| `:focus-visible` 2 px accent outline, 2 px offset | same numbers, `Focus` + decoration |
| 44 px minimum target | `ConstrainedBox(minHeight: 44, minWidth: 44)` |
| 200 % dynamic type | `MediaQuery.textScalerOf`, tested at 2.0 |
| Checkbox row exposes `role="checkbox"` | `Semantics(checked:)` |

Contrast is WCAG AA — 4.5:1 body, 3:1 large text and UI boundaries — and the
three ink/surface token pairs in §2.1 exist to keep it. An invalid field is a
boundary *and* a message; a status is never colour alone.

---

## 10. Assets

| Web | Flutter |
|---|---|
| Google Fonts CDN link for Plus Jakarta Sans (400–800) and Noto Naskh Arabic (400/600/700) | **Locally bundled** `.ttf` + OFL licence in `assets/fonts/` — no network font fetch |
| 112-symbol inline SVG sprite (`#i-…`) | One bundled SVG icon set keyed by the same names, 1.75 px stroke preserved |
| Inline decorative SVG in screen templates (onboarding art, seals, stickers) | Hand-authored Flutter SVG assets or `CustomPainter`, same geometry |
| `color-mix` and `var()` inside SVG fills | Colour resolved from `LumeColors` at build time |

The web prototype fetches fonts over the network; the Flutter reference must
not. All five Plus Jakarta Sans weights (400, 500, 600, 700, 800) must have a
real file, or Flutter synthesises a faux bold that is visibly not Plus Jakarta.
