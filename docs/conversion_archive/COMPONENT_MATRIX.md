# Component matrix

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** It maps Flutter widgets back to the browser prototype they
> were measured against, and is removed or relabelled historical at Phase F9.
> The Dart doc comments carry the same contracts and outlive it.

Every shared Lume component, its source, its Flutter widget, and how it was
verified.

**Completeness source:** the 60 builders in `assets/js/ui/components.js` and the
22 in `assets/js/ui/crud.js`. Nothing is omitted for being used by one screen.

**Verification:** each component is measured against a **real rendered
specimen**, not read out of a stylesheet. The
[fixture](tool/fixture/index.html) renders the production builders under the
production CSS; [`measure_components.mjs`](tool/measure_components.mjs) reads
`getComputedStyle` from the live page; the JSON lands in
[`measurements/`](measurements/); and
`test/core/widgets/component_parity_test.dart` asserts the Flutter widget
against it. A declaration in a file is a claim — the cascade, specificity,
inheritance, `color-mix`, custom properties and state classes all get a vote
before it becomes a pixel.

## Totals

| | |
|---|---:|
| Measured specimens | **162** |
| Measurement cells (width × theme × direction) | **5** |
| Flutter widget and type classes | **79** in 14 files |
| Parity tests (against measured values) | 48 |
| Behaviour, state and semantics tests | 46 |
| Responsive / RTL / text-scale sweeps | 20 |
| Component goldens | 29 |
| **Total Flutter tests** | **405** |

Status values: `done` — implemented, measured against the specimen, tested and
golden-covered. `deferred` — with the reason, in §3.

---

## 1. The matrix

Columns: the Lume builder → its CSS → the Flutter widget → the states it
carries → responsive → RTL → accessibility → tests → goldens.

State codes: `d` default · `p` pressed · `h` hover · `f` focus · `s` selected ·
`x` disabled · `l` loading/busy · `e` error · `o` offline · `v` private ·
`q` queued. Dark mode, 200 % text and both directions are carried by **every**
row and are not repeated.

### Navigation and chrome

| Lume builder | CSS | Flutter | States | Responsive | RTL | A11y | Tests | Golden | Status |
|---|---|---|---|---|---|---|---|---|---|
| `toolHeader` | `.toolbar` | `LumeToolbar` | d | gutters follow width class | logical insets | `header: true` on the title | parity + responsive | `chrome_*` | done |
| — (onboarding) | `.onb__nav` | `LumeBackButton` | d p x | — | chevron mirrors | button + label, disabled is inert | parity + behaviour | `chrome_*` | done |
| `contextBar` | `.ctxbar` | `LumeContextBar` / `LumeContextItem` | d p | wraps | logical | pressable items named | responsive | `chrome_*` | done |
| `sectionHead` | `.sect__head` | `LumeSectionHeader` | d p | — | link chevron mirrors | link is a named button | responsive | `chrome_*` | done |
| `section` | `.sect` | `LumeSection` | d | page gutters per class | logical padding | — | responsive | — | done |
| — (onboarding) | `.onb__seg` | `LumeSegmentedProgress` | d | fills width | fills from start edge | announces "step n of m" | behaviour | — | done |
| `iconbtn` | `.iconbtn` | `LumeIconButton` | d p f x | — | — | **label required**; badge is decorative | parity + behaviour | `actions_*` | done |
| `textbtn` | `.textbtn` | `LumeTextButton` | d p f x | — | logical | named | responsive | `actions_*` | done |

### Actions

| Lume builder | CSS | Flutter | States | Responsive | RTL | A11y | Tests | Golden | Status |
|---|---|---|---|---|---|---|---|---|---|
| `button` | `.btn`, `--accent`, `--ghost`, `--block`, `--sm` | `LumeButton` (4 tones) | d p f x l | `block` fills | logical icon order | button + enabled; busy is a live region | parity + behaviour | `actions_*` | done |
| `submitBar` busy | `.btn.is-busy` | `LumeButton(busy:)` | l | — | — | announces; **refuses the second tap** | behaviour | `actions_*` | done |
| `buttonRow` | `.btnrow` | `LumeButtonRow` | — | equal share or wrap | logical | — | responsive | `actions_*` | done |
| `fab` | `.fab` | `LumeFab` | d p f | — | — | named | parity | `actions_*` | done |
| `detailActions` | `.cacts`, `.cact--edit`, `--danger` | `LumeDetailActions`, `LumeDetailAction` | d p f x | full width | logical | named buttons | parity + behaviour | `crud_*` | done |
| toast Undo | `.toast__act` | `LumeToast(actionLabel:)` | d p | — | logical | in the live region | behaviour | `states_*` | done |

### Inputs and selection

| Lume builder | CSS | Flutter | States | Responsive | RTL | A11y | Tests | Golden | Status |
|---|---|---|---|---|---|---|---|---|---|
| `field` | `.field`, `.field__box` (42, r8, `card-2`) | `LumeToolField` | d f x | `wide` spans | logical affixes | label + hint | parity + responsive | `inputs_*` | done |
| `formField` | `.cfield`, `.cfield__box` (48, r12, `card`) | `LumeFormField` | d f e x | `wide` spans; pair collapses | logical | `textField`, error in `value` | parity + behaviour | `inputs_*` | done |
| `searchBar` | `.search` | `LumeSearchField` | d f x | — | logical glyph | `textField` + label | parity + responsive | `inputs_*` | done |
| `formField` textarea | `.cfield__box textarea` | `LumeFormField(multiline)` | d f e x | min 76 | logical | — | behaviour | `inputs_*` | done |
| `formField` money/date | input `type`/`inputmode` | `LumeFieldKind` | — | — | numerals isolated | right keyboard per kind | behaviour | `inputs_*` | done |
| `selectField` | `.field__box--select` | `LumeFormField(kind: select)` **deferred** | — | — | — | — | — | — | deferred §3 |
| `formField` check | `.cfield--check` | `LumeCheckbox` | d s f x | — | logical | `checked` | behaviour | `selection_*` | done |
| account `optlist` | `.srow` option rows | `LumeRadioRow` | d s p | — | logical | `inMutuallyExclusiveGroup` + `checked` | responsive | — | done |
| `switch` | `.switch` | `LumeSwitch` | d s f x | — | knob follows direction | `toggled` | behaviour | `selection_*` | done |
| `stepper` | `.stepper` | `LumeStepper` | d p x | — | logical order | group + per-button names | parity + behaviour | `selection_*` | done |
| `chip` | `.fchip`, `.is-on` | `LumeFilterChip` | d s p f x | wraps | logical | `toggled` | parity + behaviour | `selection_*` | done |
| `filterChips` | `.cchip`, `.is-on` | `LumeRecordChip` | d s p | wraps | logical | `toggled` + count spoken | parity | `selection_*` | done |
| `filterBar` | `.filterbar` | `LumeFilterBar` | — | scrolls | scrolls from start | — | responsive | — | done |
| `segmented` | `.segmented`, `.seg.is-on` | `LumeSegmented` | d s p | — | logical order | exactly one `selected` | parity + behaviour | `selection_*` | done |
| `tabs` | `.ttabs`, `.ttab.is-on` | `LumeTabs` | d s p | scrolls | scrolls from start | `selected` + count | responsive | `selection_*` | done |
| `sortBar` | `.sortbar`, `.sortopt.is-on` | `LumeSortBar` | d s p | scrolls | direction glyph | speaks its direction | parity + behaviour | `selection_*` | done |

### Content and data display

| Lume builder | CSS | Flutter | States | Responsive | RTL | A11y | Tests | Golden | Status |
|---|---|---|---|---|---|---|---|---|---|
| `card` | `.kard` | `LumeCard` | d p | — | — | optional label when pressable | parity | — | done |
| `noteCard` | `.notecard` | `LumeNoteCard` (4 tones) | d | — | logical | — | responsive | `status_*` | done |
| `rows` | `.rows` | `LumeRows` | — | — | hairline indent is logical | — | responsive | `rows_*` | done |
| `richRow` | `.rrow` + parts | `LumeRichRow` | d p h | — | lead/value swap | link role + composed label | parity + responsive | `rows_*` | done |
| `compactRow` | `.crow` | `LumeCompactRow` | d p h | — | lead/value swap | link role | parity | `rows_*` | done |
| `recordRow` | `.rrec`, `.is-selected`, `.is-done` | `LumeRecordRow` | d p h s q | — | disc/value swap | `selected`; checkbox `checked` | parity + behaviour | `rows_*` | done |
| `recordRows` | `.rrecs` | `LumeRecordList` | — | — | — | — | responsive | `rows_*` | done |
| `expandRow` | `.xrow` | `LumeExpandRow` | d s | — | caret rotates | `expanded`; **body absent when closed** | behaviour | — | done |
| `summaryCard` | `.summary` | `LumeSummaryCard` | d | stats share width | logical | numerals isolated | parity | `values_*` | done |
| `metric` | `.metric` | `LumeMetric` | d p | — | logical | composed label | parity | `values_*` | done |
| `metrics` | `.metrics` | `LumeMetrics` | — | 2–3 cols; **4 above 1180** | logical | — | responsive | `values_*` | done |
| `recordHero` | `.chero` | `LumeRecordHero` | d | — | logical | numerals isolated | parity | `values_*` | done |
| `factCard` | `.cfacts`, `.cfact--block` | `LumeFactCard` / `LumeFact` | d | block wraps | value to end edge | — | parity | `crud_*` | done |
| `table` | `.dtable`, `.tablewrap` | `LumeTable` / `LumeColumn` | d p | scrolls horizontally | numerics isolated | **named scroll region** | behaviour | `chrome_*` | done |
| `imageCard` | `.imgcard` | `LumeImageCard` | d p | fixed item width in a strip | logical | title is the label | responsive | — | done |
| `art` | `.art` | `_ArtPainter` (deterministic) | — | — | — | decorative | responsive | — | done |
| `hscroll` | `.hstrip` | `LumeHorizontalStrip` | — | scrolls | scrolls from start | — | responsive | — | done |
| `relatedTools` | `.related` | `LumeRelatedTools` / `LumeRelatedTool` | d p | wraps | logical | named buttons | responsive | — | done |
| `timeline` | `.tline` | `LumeTimeline` / `LumeTimelineEntry` | d s | — | rail follows direction | — | responsive | `progress_*` | done |
| `journey` | `.journey` | `LumeJourney` / `LumeJourneyStep` | d s | shares width | fills from start | announces the reached step | behaviour | `progress_*` | done |
| `progressBar` | `.pbar` | `LumeProgressBar` | d | fills | fills from start | announces its value; clamps | parity + behaviour | `progress_*` | done |
| `meterRow` | `.meter` | `LumeMeterRow` | d | — | logical | value spoken | responsive | `progress_*` | done |
| `progressRing` | `.pring` | `LumeProgressRing` | d | — | — | announces its value | responsive | `progress_*` | done |

### States and feedback

| Lume builder | CSS | Flutter | States | Responsive | RTL | A11y | Tests | Golden | Status |
|---|---|---|---|---|---|---|---|---|---|
| `statusBadge` | `.badge` ×6 tones | `LumeBadge` | d | — | — | label; **glyph per tone** | parity + behaviour | `status_*` | done |
| `deltaTag` | `.delta` | `LumeDelta` | d | — | — | speaks "up"/"down" | parity + behaviour | `status_*` | done |
| `freshness` | `.fresh` ×4 | `LumeFreshness` | d l o | — | — | label; **shape differs too** | parity + behaviour | `status_*` | done |
| `sourceLine` | `.srcline` | `LumeSourceLine` | d o | wraps | logical | — | responsive | `status_*` | done |
| `skeleton` | `.sk--*` | `LumeSkeleton` (5 kinds) | l | — | shimmer follows direction | "Loading" live region | parity + behaviour | `states_*` | done |
| `loadingRows` | `.csks`, `.csk` | `LumeSkeleton(record)` | l | — | — | — | parity | `states_*` | done |
| `emptyState` | `.state--empty` | `LumeToolState` | d | — | logical | — | parity | — | done |
| `errorState` | `.state--error` | `LumeToolState.error` | e | — | logical | live region | parity | — | done |
| `emptyCollection` | `.cstate` | `LumeCollectionState(empty)` | d | — | logical | **one primary CTA** | parity + behaviour | `states_*` | done |
| `noMatches` | `.cstate--quiet` | `LumeCollectionState(noResults)` | d | — | logical | distinct from empty | behaviour | — | done |
| `loadError` | `.cstate--error` | `LumeCollectionState(error)` | e | — | logical | live; **Retry first** | behaviour | — | done |
| `noSelection` | `.cstate--pane` | `LumeCollectionState(pane)` | d | expanded only | logical | — | responsive | `crud_*` | done |
| `saveError` | `.cnotice--error` | `LumeNotice(error)` | e | — | logical | live region | parity + behaviour | `states_*` | done |
| `conflictNotice` | `.cnotice--warn` | `LumeNotice(warning)` | e | actions wrap | logical | live; Review **and** Reload | behaviour | `states_*` | done |
| `offlineNotice` / `offlineBanner` | `.cnotice--offline`, `.obanner` | `LumeNotice(offline)`, `LumeOfflineBanner` | o | — | logical | status role | parity | `states_*` | done |
| `.cnotice__act` | `.cnotice__act` | `LumeNoticeAction` | d p f x | wraps | logical | named; **44 px target** (see D6) | parity + responsive | `states_*` | done |
| `.private-card` | `.private-card` | `LumePrivateState` | v | — | logical | reveal is a named action | behaviour | — | done |
| `.toast` | `.toast` | `LumeToast` / `showLumeToast` | d l e | centred, above nav | logical | **live region + announcement** | behaviour | `states_*` | done |
| `.sheet` | `.sheet` + responsive | `LumeSheet` / `showLumeSheet` | d p | **compact: bottom sheet · else: centred dialog** | logical | header semantics; named close | behaviour | — | done |
| confirmation | delete sheet | `LumeDeleteConfirmation` | d x | — | logical | header; verb-labelled action | behaviour | — | done |

### CRUD presentation

| Lume builder | CSS | Flutter | States | Responsive | RTL | A11y | Tests | Golden | Status |
|---|---|---|---|---|---|---|---|---|---|
| `listCount` | `.crud__count` | `LumeListCount` | d o e | — | — | live region | parity | — | done |
| `recordId` | `.crud__id` | `LumeRecordId` | d | — | — | — | responsive | — | done |
| `formGrid` | `.cform`, `.fgrid--pair` | `LumeFormSection` | — | **two columns at expanded, one otherwise or at large text** | logical | — | responsive | `crud_*` | done |
| `formCard` | `.cformcard` | `LumeFormCard` | — | capped at the reading measure | logical | — | responsive | `crud_*` | done |
| `submitBar` | `.csubmit` | `LumeSubmitBar` | d l x | block | logical | — | behaviour | `crud_*` | done |
| `panes` | `.panes` | `LumeMasterDetail` | — | **two panes at expanded only; never on a landscape phone** | panes follow direction | — | behaviour | `crud_*` | done |
| `.pressable` | `.pressable:active` | `LumePressable` | d p f x s | 44 px floor | — | button/link, selected, enabled | every component test | — | done |

---

## 2. What the measurement caught that reading would not

Seven findings, each one a thing a transcription gets wrong.

| # | Finding | Why a stylesheet read misses it |
|---|---|---|
| 1 | `.btn--sm` is still **46 px tall** | The padding shrinks but `min-height` wins. A small button is narrower, not shorter |
| 2 | `.kard` is **20 px** radius, not 16 | It takes `--r-lg`; `--r-md` is the *record row's* radius |
| 3 | **Two field systems**: `.field__box` 42/r8/`card-2` and `.cfield__box` 48/r12/`card` | They look like one component with a density flag until they are measured side by side |
| 4 | `.seg.is-on` casts a **shadow** | It is a raised thumb on a track, not a tinted cell — invisible in the declaration, obvious in the computed style |
| 5 | `.summary__value` is **34 px** and `.chero__value` **32 px** | Neither is in the type scale; both are per-surface display sizes |
| 6 | `.notecard` sits on **`card-2`**, not `card` | One token apart, and the difference is the whole reason it reads as an aside |
| 7 | `.sk--metric` is **76**, not 84 | The metric card is 84; its skeleton is not the same height |

## 3. Deferred, with the reason

| Component | Reason | When |
|---|---|---|
| **Select / picker field** (`.field__box--select`, `.cfield__select`) | The reference's select opens the platform's own control. Lume's real selection surface is the **picker sheet** — the country, city, language and interest pickers — which is a screen-level composition, not a component. Building a `LumeSelectField` now would either wrap Material's dropdown (wrong look) or pre-empt the picker's design. | F4, with the onboarding pickers it belongs to |
| **Charts** — `sparkline`, `lineChart`, `barChart`, `donut`, `heatmap` | These are not general components: each answers one tool's question, and their contracts come from the data the tool has. Building them without their callers would be guessing at the API. `LumeProgressBar`, `LumeProgressRing` and `LumeMeterRow` — the four that *are* general — are done. | F6, per archetype batch |
| **Map surface** (`map()`) | Needs a tile source and a location permission story, neither of which exists in a fixture-driven reference. | F6, location-tool batch |
| **Date and time pickers** | The reference uses the browser's native controls. Flutter's platform pickers are the right equivalent and need no Lume wrapper beyond the field that launches them, which is done. | F7, with the record forms that use them |

Nothing is deferred for being used by only one screen.

## 4. Completion rule

A component is done when all of these hold, and all of them are enforced by a
test rather than a review:

1. Its rendered geometry, typography, spacing, radius, border and shadow match
   the **measured** specimen.
2. Every state in its `States` column is implemented.
3. Light and dark both pass — against the dark measurement, not a derivation.
4. LTR and RTL both pass, and only genuinely directional elements mirror.
5. 200 % text does not overflow, at 390 and at 359.
6. Touch targets clear 44 px.
7. Semantics are present: labels on icon-only controls, selected/toggled/checked
   exposed, validation and status announced.
8. Indefinite animation stops under reduced motion.
9. Any remaining difference is in
   [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md) with approval.
