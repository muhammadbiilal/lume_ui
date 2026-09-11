# Component matrix

Every shared Lume component, where it comes from, the states it has to carry,
and its conversion status. Status: `not started` · `built` · `measured` ·
`signed off`. A component is `measured` when its rendered bounds, typography
and spacing have been compared against the web component at the viewports in
[VISUAL_VERIFICATION.md](VISUAL_VERIFICATION.md), and `signed off` when its
states and goldens are complete.

**Renaming a Material widget does not make it Lume-compliant.** Its rendered
output has to match. Every row below is held to that.

Source counts: **60** builders in `ui/components.js`, **22** in `ui/crud.js`,
**5** picker/sheet builders in `ui/pickers.js` and `ui/sheets.js`,
**1,088** unique CSS class selectors across 19 stylesheets.

---

## 1. States vocabulary

Referenced by the `States` column below rather than repeated.

| Code | State |
|---|---|
| `d` | default |
| `p` | pressed |
| `h` | hover (pointer devices) |
| `f` | focus — 2 px accent outline, 2 px offset |
| `s` | selected |
| `x` | disabled |
| `l` | loading / busy |
| `e` | error / invalid |
| `o` | offline |
| `v` | private / sensitive |
| `u` | unavailable |
| `r` | RTL mirror |

Every component additionally carries: dark theme, 200 % text scale, text
wrapping with an explicit `maxLines` and overflow, and semantics.

---

## 2. Shell and scaffolding

| Component | Web source | Spec | States | Status |
|---|---|---|---|---|
| App shell | `.app`, `base.css` | Flex column compact; grid `nav + screens` under a status strip at medium/expanded | `r` | not started |
| Stage / device frame | `.stage`, `base.css` | **Not reproduced** — browser presentation only, see KNOWN_DIFFERENCES | — | n/a |
| Status strip | `.statusbar` | Compact: replaced by the OS bar. Medium/expanded: `card` bg, 1 px bottom border, 12 px block padding, wordmark, clock at `order: 2` | `r` | not started |
| Page scaffold | `.screen`, `screens/shared.css` | Scroll container, 20/24/32 px gutters, 40 px bottom padding at medium+ | `r` | not started |
| Content measure | `.sect` / `.section` caps, `responsive.css` | `min(contentMax + pad*2)` centred; `.is-wide` → `contentWide` | — | not started |
| Decorative mesh | `.app__mesh` | Radial-gradient layers at `--mesh-opacity` (.55 light / .35 dark) | — | not started |

## 3. Navigation

| Component | Web source | Spec | States | Status |
|---|---|---|---|---|
| Bottom bar | `.tabbar`, `.tab`, components.css | Compact only, ≤ 5 destinations, `--t-tab` label, `--shadow-nav` | `d s f r` | not started |
| Selection pill | `.tabbar__pill`, `#tabPill` | Animates `width` and `translateX` to the selected tab; opacity 0 when the destination is not a tab | `d s` | not started |
| Navigation rail | `.navtab` at `data-bp=medium` | 84 px, column, gap 5, padding 10 4, `--t-tab` centred label, 20 px glyph | `d s h f r` | not started |
| Sidebar | `.navtab` at `data-bp=expanded` | 244 px, row, gap 12, padding 10 12, radius 12, `--t-cardtitle`, ls −.02em, min-height 44 | `d s h f r` | not started |
| Sidebar wordmark | `.navside__brand` | `--t-display`, ls −.035em, padding 4 12 20; expanded only | — | not started |
| Tab/destination active | `.navtab.is-active` | bg `tintAccent`, fg `accent700`, glyph `accent` | `s` | not started |
| App bar | `.appbar`, `screens/shared.css` | Greeting, date, city, notification entry, avatar | `d r` | not started |
| Page head | `.page-head` | Title + optional subtitle, back affordance | `d r` | not started |
| Tool header | `toolHeader()`, `.toolbar` | Back, title, contextual action | `d x r` | not started |
| Circular back | `.onb__nav` | 34 × 34, `card` bg, 1 px `border`, `shadow-xs`, 17 px glyph; disabled → opacity 0, `scale(.8)` | `d p x r` | not started |
| Context bar | `contextBar()`, `.ctx` | Location / freshness strip under the header | `d r` | not started |

## 4. Actions

| Component | Web source | Spec | States | Status |
|---|---|---|---|---|
| Primary button | `.btn` | h 46, pad 0 20, radius 12, 14 px w700, ls −.022em, gap 7; bg `text` / fg `bg` | `d p f x l` | not started |
| Accent button | `.btn--accent` | bg `accent`, fg `#fff` (dark `#06231F`), shadow `0 6px 18px -8px accent@80%` | `d p f x l` | not started |
| Secondary/ghost | `.btn--ghost` | bg `tintNeutral`, fg `text` | `d p f x` | not started |
| Tertiary / link | `.onb__link`, `.picker__clear` | 13 px w700, `text-2`, `:active` opacity .5 | `d p f x` | not started |
| Destructive | `.cact--danger` | `roseInk` ink, danger surface; carries white at AA | `d p f x l` | not started |
| Block button | `.btn--block` | `width: 100%` | — | not started |
| Icon button | `.iconbtn`, `.bar__act` | ≥ 44 px target, 20 px glyph, `aria-label` required | `d p f x r` | not started |
| FAB | `fab()`, `.fab` | Floating; `bottom: 28` at medium+; absolute at ≥ 600 | `d p f r` | not started |
| Button row | `buttonRow()` | Horizontal group with consistent gap | `r` | not started |
| Detail actions | `detailActions()`, `.cacts` | Grid gap 10, margin-top 20; edit = `tintAccent`/`accent700` | `d p x` | not started |

## 5. Inputs

| Component | Web source | Spec | States | Status |
|---|---|---|---|---|
| Text field | `.cfield__box` | min-h 48, pad 0 14, gap 8, radius 12, `card` bg, 1 px `border-2` | `d f e x r` | not started |
| — focus | `:focus-within` | border `accent`, ring `0 0 0 3px tintAccent` | `f` | not started |
| — invalid | `.is-invalid` | border `roseInk`, ring `rose@22%`, **plus a message below** | `e` | not started |
| Field label | `.cfield__label` | `--t-label`; optional marker `--t-metasm` `text-3` | `r` | not started |
| Helper / error | `.cfield__hint` / `.cfield__err` | `--t-metasm`; error pairs an icon with the text | `d e` | not started |
| Text area | `.cfield__box textarea` | min-h 76, line-height 1.55, vertical resize only | `d f e x` | not started |
| Search field | `.search` | h 44, pad 0 14, gap 9, radius 12, `card`, 1 px `border`, `shadow-xs`, `text-3` | `d f x r` | not started |
| Small search | `.search--sm` | Picker variant | `d f r` | not started |
| Select | `.cfield__select` | Appearance stripped, 15 px chevron, `text-3` | `d f x r` | not started |
| Date / time control | `field({type:'date'})` | Native control in web; native pickers in Flutter | `d f x` | not started |
| Switch | `.switch`, `.switch__knob` | Knob translate over `--dur`; used by the faith toggle | `d s f x r` | not started |
| Checkbox | `.cfield__checkbox`, `.rrec__check` | 17 px glyph; exposes `role="checkbox"`; ≥ 44 px row | `d s f x` | not started |
| Radio | `optlist()` rows | Single-select list with a tick | `d s f x` | not started |
| Stepper | `stepper()` | Decrement / value / increment | `d p x r` | not started |
| Selection chip | `.pick` | Interest chip with icon + label, `aria-pressed`; `.is-muted` when the max is reached | `d s x` | not started |
| Filter chip | `.cchip`, `filterChips()` | Carries a tabular count `.cchip__n` at opacity .7 | `d s` | not started |
| Segmented control | `segmented()` | Mutually exclusive inline options | `d s f r` | not started |
| Tabs | `tabs()` | In-screen tab strip | `d s f r` | not started |
| Sort bar | `sortBar()` | Sort key + direction | `d s r` | not started |
| Filter bar | `filterBar()` | Chip group over a scroll rail | `d s r` | not started |
| Choice pills | `.onb-choice button` | h 34, pad 0 13, radius full, 12 px w600; active = `text` bg, `bg` ink | `d s` | not started |

## 6. Surfaces and rows

| Component | Web source | Spec | States | Status |
|---|---|---|---|---|
| Card | `.card` | `card` bg, 1 px `border`, radius 20, `shadow-sm`, clipped | `d p l` | not started |
| Section | `section()`, `sectionHead()` | Heading + optional link; 24 px section gap | `r` | not started |
| Summary card | `summaryCard()`, `.sum` | Lead value + supporting lines | `d l` | not started |
| Stat card | `.stat-card` | Value, label, optional delta | `d` | not started |
| Metric grid | `metrics()`, `.metrics` | `--cols` 2–3; 4 at ≥ 1180 | `d r` | not started |
| Delta tag | `deltaTag()` | Direction by **glyph and text**, never colour alone | `d` | not started |
| Compact row | `compactRow()`, `.crow` | `--pad-row` 12 16 | `d p h s r` | not started |
| Rich row | `richRow()`, `.list-row` | Icon, body, trailing value, chevron | `d p h s u r` | not started |
| Expandable row | `expandRow()` | Collapsed / expanded | `d s` | not started |
| Record row | `recordRow()`, `.rrec` | min-h 44, pad 13 14, gap 12, radius 16, `card`, 1 px `border`, `shadow-xs` | `d p h s o r` | not started |
| — selected | `.rrec.is-selected` | bg `tintAccent`, border `accent@45%` — persists, not a flash | `s` | not started |
| — done | `.rrec.is-done` | Title line-through + `text-3`; disc opacity .55 | `s` | not started |
| — queued | `.rrec__queued` | Offline write pending | `o` | not started |
| Note card | `noteCard()` | Title, excerpt, modified date | `d p` | not started |
| Image card | `imageCard()` | Media + caption | `d l` | not started |
| Horizontal scroll | `hscroll()`, `.hcards` | Snapping rail | `d r` | not started |
| Table | `table()` | Header + aligned tabular rows | `d r` | not started |
| Record hero | `recordHero()`, `.chero` | Kicker, value, title, caption on a gradient | `d r` | not started |
| Fact card | `factCard()`, `.cfacts` | Label/value pairs; `.cfact--block` for long values | `d v r` | not started |
| Tone ramp | `tools/shared.css` §tone | Per-category logo, avatar and art tinting | — | not started |

## 7. Data display

| Component | Web source | Spec | States | Status |
|---|---|---|---|---|
| Sparkline | `sparkline()` | Inline SVG path | `d` | not started |
| Line chart | `lineChart()` | Axis, path, points | `d l o` | not started |
| Bar chart | `barChart()` | Animated bars | `d l` | not started |
| Donut | `donut()` | Segments + centre value | `d l` | not started |
| Progress ring | `progressRing()` | Stroke-dash progress | `d l` | not started |
| Progress bar | `progressBar()` | Track + fill | `d l` | not started |
| Meter row | `meterRow()` | Label + inline meter | `d` | not started |
| Heatmap | `heatmap()` | Calendar grid | `d` | not started |
| Timeline | `timeline()`, `.tl` | Chronological entries; `.tl-time` `text-align: start` in RTL | `d r` | not started |
| Journey | `journey()` | Stepped progress presentation | `d s` | not started |
| Map | `map()` | Static map surface with pins | `d l o u` | not started |
| Generated art | `art()` | Deterministic decorative SVG | — | not started |

All twelve are bespoke SVG in the web with their own visual language. They are
reproduced with `CustomPainter`, **not** with a charting package — see
[DAYROZ_ARCHITECTURE_MAPPING.md §3](DAYROZ_ARCHITECTURE_MAPPING.md#3-dependency-plan).

## 8. Status and feedback

| Component | Web source | Spec | States | Status |
|---|---|---|---|---|
| Badge | `statusBadge()` | Text + shape, never colour alone | `d` | not started |
| Freshness label | `freshness()` | Live marker pulses; **must stop under reduced motion** | `d l o` | not started |
| Source line | `sourceLine()` | Provenance + timestamp | `d o` | not started |
| Skeleton | `skeleton()`, `.skel` | Shaped like the final content; shimmer **must stop under reduced motion** | `l` | not started |
| Loading rows | `loadingRows()` | Record-row-shaped skeletons | `l` | not started |
| Empty state | `emptyState()`, `emptyCollection()` | Reason, next step, exactly one primary CTA. Never a blank card | `d` | not started |
| No results | `noMatches()` | Distinct from empty | `d` | not started |
| Error state | `errorState()`, `loadError()` | Explanation, "saved data is still safe", **Try again first** | `e` | not started |
| Offline banner | `offlineBanner()`, `offlineNotice()` | Cached records + offline label; never passes for current | `o` | not started |
| Save error | `saveError()` | Preserved input + explanation + Retry | `e` | not started |
| Conflict notice | `conflictNotice()` | Newer version explained; **Review or Reload**, never a silent overwrite | `e` | not started |
| Private state | `.private-card` | Sensitive detail hidden by default | `v` | not started |
| Unavailable state | eligibility | Feature not available here | `u` | not started |
| Toast | `.toast` | High-contrast pill above the navigation; `bottom: 28` at medium+ | `d l` | not started |
| Undo action | `.toast__act` | Armed only where deletion is recoverable | `d p` | not started |
| Notification banner | `.nbanner` | Compact: top. Medium/expanded: trailing corner card, `min(400px, 100% − nav − 48px)` | `d r` | not started |

## 9. Overlays

| Component | Web source | Spec | States | Status |
|---|---|---|---|---|
| Bottom sheet | `.sheet`, `ui/sheets.js` | Top radius 26, safe-area padding. At ≥ 600: centred `min(520px, 100% − 48px)`, `bottom: 24`, full radius | `d p r` | not started |
| Scrim | `.scrim` | `--overlay` | `d` | not started |
| Confirmation dialog | delete confirmation sheet | Names the record, states the consequence, verb-labelled destructive action — never "OK" | `d x l` | not started |
| Interest picker | `makePicker()` | Six groups, individual chips, live count, Clear, min 5 / max 10, separate faith switch | `d s x` | not started |
| Location picker | `makeLocationPicker()` | Search + Recent / Popular / All over 194 countries; city stage with regions and "Use my current location" | `d s r` | not started |
| Option picker | `optlist()` | Single-select list used by 21 account routes | `d s f` | not started |

## 10. Forms and CRUD scaffolding

| Component | Web source | Spec | States | Status |
|---|---|---|---|---|
| Form card | `formCard()`, `.cformcard` | Capped at `contentMax` even inside a wide composition | `d r` | not started |
| Form section | `formGrid()`, `.cform` | Grid gap 18 | `r` | not started |
| Two-column pair | `.fgrid--pair` | Expanded only, `1fr 1fr`, gap 16 20; `.field--wide` spans both; collapses in split-screen | `r` | not started |
| Submit bar | `submitBar()` | Progress in the action; duplicate submission prevented | `d l x` | not started |
| Inline validation | `.cfield__err` | Directly below its field; icon **and** text | `e` | not started |
| List count | `listCount()`, `.crud__count` | Says the state rather than counting to zero when empty | `d o e` | not started |
| Bulk action | `.cbulk` | Full-width; confirmed bulk clear | `d x` | not started |
| Record id | `recordId()`, `.crud__id` | Provenance line | `d` | not started |
| Panes | `panes()`, `.panes` | `minmax(320, 380)` + `minmax(0, 1fr)`, gap 20, detail sticky | `r` | not started |
| No selection | `noSelection()` | Detail pane invites a selection | `d` | not started |
| Master-detail scaffold | `responsive.css` §master-detail | Selection at expanded does not push; list keeps scroll, filters, position | `s r` | not started |
| Related tools | `relatedTools()` | From the spec's `rel` list, eligibility-filtered | `d r` | not started |

## 11. Icons and illustration

| Item | Web source | Spec | Status |
|---|---|---|---|
| Icon set | `index.html` sprite | **112 symbols**, 24 px box, **1.75 px rounded stroke**, sizes 16 / 20 / 24 | not started |
| Directional glyphs | `rtl.css` | Exactly seven selectors flip in RTL. Clocks, play buttons and media controls never do | not started |
| Onboarding art | inline SVG in `onboarding.screen.js` | Floating stickers, 8 s / 6.4 s / 9.2 s cycles with negative delays | not started |
| Success seal | `.onb__seal` | Ring draw 1 s, tick draw 0.5 s @ 0.8 s, three pops @ 1.0 / 1.1 / 1.2 s | not started |
| Auth seal | `.authseal` | 108 px below 360 px width | not started |

---

## 12. Completion rule

A component is signed off when all of the following hold.

1. Rendered bounds, typography, spacing, radius, border and shadow match the
   web component, measured — not eyeballed.
2. Every state in its `States` column is implemented and has a golden.
3. Light and dark both pass.
4. LTR and RTL both pass, and only genuinely directional elements mirrored.
5. 200 % text scale does not clip, and `maxLines`/overflow are explicit.
6. Touch targets are ≥ 44 px.
7. Semantics are present: labels on icon-only controls, selected/toggled/checked
   states exposed, validation outcomes announced.
8. Any indefinite animation stops under reduced motion.
9. Any remaining difference is in
   [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md) with approval.
