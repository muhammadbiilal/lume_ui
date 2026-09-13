# Cross-cutting surfaces: the inventory

Every non-tool application surface that exists in the running Lume
implementation after F5C, traced from callers, builders, state and handlers
rather than from the earlier documents' names. Conversion evidence; the
product documentation is in `../`.

Method: `grep` for the trigger attribute or action string, then read the
builder and its CSS. Where a document and the source disagree, the source is
recorded.

---

## 1. The two kinds of surface

The reference has exactly two mechanisms for a surface that is not a
destination.

**A sheet** mounts into the overlay outlet, not the screen outlet
(`ui/sheets-markup.js`, `ui/sheets.js`). It sits over whichever screen is
showing, survives that screen changing, and belongs to no destination. There
are **nine**.

**A nested screen** is a real screen with its own id, entered through the
router. The notification centre is the only cross-cutting one.

Plus two surfaces that are neither: the notification **banner**, which is a
transient overlay the shell paints into `#notifBanner`, and the **toast**.

---

## 2. Global search — a sheet, not a screen

| | |
|---|---|
| **trigger** | `data-sheet="search"` |
| **active callers** | Home's app bar (`home.screen.js:486`), Explore's page head (`explore.screen.js:199`), and the `quransearch` catalogue entry, whose `act` is `sheet:search` (`catalogue.js:120`) |
| **builder** | markup `ui/sheets-markup.js:35-65`; behaviour `services/search.js` |
| **fill on open** | `shell.js:471` — `resetSearch()`, then focus `#globalSearch` after **320 ms** |
| **selectors** | `.sheet.sheet--tall#sheet-search`, `.sheet__head`, `.search`, `.sheet__body`, `#searchIdle`, `.chips.chips--wrap#searchSuggest`, `.list.list--flat#searchRecent`, `#searchResults`, `.empty#searchEmpty`, and per hit `.list-row.pressable` with `.list-row__icon/__body/__title/__sub/__end` |
| **dismissal** | scrim click, `Escape`, `[data-close]`, swipe down > 90 px; a hit closes it after **60 ms** (`services/search.js`, bottom) |
| **focus** | opener stored and restored on close; the screen behind gets `aria-hidden` while it is up, unless the visibility system had already hidden it |

### What it searches

`searchIndex()` = **`visibleFeatures()`** mapped to rows, plus a seven-entry
`EXTRA_INDEX` filtered by faith and country.

| index source | rows | gating |
|---|---|---|
| catalogue features | every visible feature | `ELIGIBLE.visibleFeatures()` — the same selector Home and the hub ask |
| `extra.darkMode` | 1 | none; `act: 'theme'` |
| `extra.personalise` | 1 | none; `act: 'sheet:personalise'` |
| three surahs | 3 | `faith: 1` |
| Karachi Cantt | 1 | `loc: 'PK'` |
| Masjid-e-Tooba | 1 | `faith: 1`; `act: 'toast:…'` |

**There is no grouping.** One flat `.list--flat`, ranked by score, capped at
**14**. No section heads, no "Tools"/"Settings" separation on screen — `sub`
is the category name per row.

### Matching

Query lowercased and trimmed, split on whitespace. Every word must appear in
`hay` or the item scores −99 and is dropped. Per word: **6** if at position 0,
**4** if found after a space, **2** otherwise. Sorted descending, sliced to 14.
**No debounce** — `input` runs it synchronously. **No highlighting.**

### States

| state | what renders |
|---|---|
| empty query | `#searchIdle` shown, results hidden, `#searchEmpty` loses `is-shown` |
| results | flat list of up to 14 |
| no results | `#searchEmpty` gains `is-shown`, results emptied |
| loading | **none** — the index is synchronous |
| error / offline / no-permission | **none exist** |

Idle shows two blocks: **suggestion chips** (`petrol, trains, bills` for PK;
`qibla, surah rahman` when faith is on; then `currency, calculator, weather`,
sliced to 6) and **recents** — the profile's recents mapped through
`feature`, filtered by `visible`, sliced to 4, falling back to
`calculator, weather, calendar` when empty.

### Flutter status

`/…/search` is routed to `LumeFixtureScreen`. **The reference has no search
route** — it is a sheet over the current destination. Recorded as decision
**Q10** below.

---

## 3. The notification centre — a screen

| | |
|---|---|
| **trigger** | `data-act="tab:notifications"` |
| **active callers** | Home's app bar (`home.screen.js:489`); Flutter also routes `/notifications` as a deep link |
| **builder** | `screens/notifications.screen.js` |
| **engine** | `services/notify-engine.js` (681 lines) — decides what is true |
| **presenter** | `services/notifications.js` — badge, banner, preferences |
| **selectors** | `.screen--tool#screen-notifications`, `#notifHeader`, `#notifBody`, `.nlist`, `.nrow` (`.is-unread`, `.is-actioned`, `.is-expired`), `.nrow__main/__icon/__body/__titleline/__title/__text/__meta/__dot/__acts/__act/__dismiss` |

### Composition, in order

1. `UI.toolHeader` — title, subtitle (`n.unreadCount` or `n.allRead`), back, and up to two actions: **Mark all read** (only when unread > 0) and **Settings** (`sheet:notifprefs`)
2. `UI.tabs` — **All / Unread / Important**, each with a count; important = `priorityRank >= 2`
3. `UI.filterBar` — category chips, **only for categories that have something in them**, prefixed by All
4. Quiet-hours note card, when `inQuietHours()`
5. `.nlist` of `.nrow`, or an empty state
6. A trailing `compactRow` to notification settings, showing push on/off

### The row

Icon tinted by category (`.nrow__icon--faith|markets|finance|travel|weather|documents|…`), title, optional priority badge (**critical** → `late` tone, **high** → `warn`), body, and a meta line: relative time · category (omitted when grouped) · `actioned` · `expired`. Unread adds `.is-unread` and a `.nrow__dot`. Actions row carries the notification's own action and a dismiss ✕ — rendered only when there is an action or the row is not grouped.

### Time

`n.now` under 1 min; `n.minsAgo` under 60; `n.hoursAgo` under 1440; else
`n.daysAgo`. Computed from `agoMins`, which the engine derives.

### States

| state | source |
|---|---|
| skeleton | `onEnter`, **first visit only**, `UI.skeleton('row', 4)` for **90 ms** |
| error | `NOTIFY.list` throwing → `UI.errorState` with a retry that re-applies the filter |
| empty (unread filter) | `n.empty.caughtUp` with `i-check-circle` |
| empty (other) | `n.empty.title` with `i-bell` |
| quiet hours | note card above the list |

### Gating

The engine drops any notification whose feature is not visible — faith or
country — and withholds a sensitive tool's detail when previews are off
(`allowed(src)`, `bodyFor(src, made)`). Priority outranks recency.

### Flutter status

`/…/notifications` is routed to `LumeFixtureScreen`. The **badge** exists
(`LumeHeaderButton` with a count). The preference screen exists (F5C,
`account/notifications`) and is a **different surface**.

---

## 4. The nine sheets

| id | trigger | callers | Flutter status |
|---|---|---|---|
| `sheet-search` | `data-sheet="search"` | Home bar, Explore head, `quransearch` | **absent** |
| `sheet-personalise` | `sheet:personalise` | 23 call sites | **built** — `personalise_sheet.dart` (F5C) |
| `sheet-market` | `sheet:market` | 3 | tool-phase (Markets) |
| `sheet-notifprefs` | `sheet:notifprefs` | 2 | the account route covers the same content (F5C); the sheet form is F5D |
| `sheet-authlegal` | `sheet:authlegal` | 1 | **built** — auth flow (F4) |
| `sheet-recdelete` | `sheetOpen('recdelete')` | 3 | **built** — `LumeDeleteConfirmation` |
| `sheet-notifpush` | `sheetOpen('notifpush')` | 2 | **absent** |
| `sheet-share` | `sheetOpen('share')` | 1 | tool-phase (share cards) |
| `sheet-confirm` | `sheetOpen('confirm')` | 1 | **built** — `showLumeDialog` / `LumeDeleteConfirmation` |

Shared sheet behaviour (`ui/sheets.js`), which Flutter's `showLumeSheet`
already reproduces: scrim, `Escape`, `[data-close]`, swipe-to-dismiss over
90 px, `aria-hidden` on the screen behind unless already hidden, focus into
the dialog after 60 ms, focus restored to the opener on close.

---

## 5. Transient feedback

| surface | trigger | builder | Flutter |
|---|---|---|---|
| toast | `toast(msg)` and `act: 'toast:…'` | shell | **built** — `LumeToast` |
| notification banner | `notifyTick()` when the surface is `banner` and the centre is not showing | `services/notifications.js:56` | **absent** |
| offline banner | `UI.offlineBanner` | `ui/components.js` | **built** — `LumeOfflineBanner` |
| retry / conflict notice | `UI.errorState`, `rec.conflict*` keys | `ui/components.js`, `ui/crud.js` | **built** — `LumeNotice`, `LumeToolState` |

The **banner** auto-hides after 6000 ms, vibrates 12 ms when haptics are on,
and is suppressed while the notification centre is the current screen.

---

## 6. Verdict per surface

| surface | phase |
|---|---|
| Global search sheet | **F5D** |
| Notification centre screen | **F5D** |
| Notification banner | **F5D** |
| `sheet-notifpush` | **F5D** |
| `sheet-notifprefs` as a sheet | **F5D** |
| `sheet-market` | tool phase — Markets owns it |
| `sheet-share` | tool phase — share cards |
| Tools-hub inline search (`#toolSearch`) | **already built**, and a different surface from global search |
| Personalise, authlegal, recdelete, confirm, toast, offline banner, notices | **already built** |

---

## 7. Decisions this inventory raises

### Q10 — global search is a sheet; Flutter routed it as a screen

The reference opens `#sheet-search` over the current destination. Flutter's
router already declares `/<branch>/search`, asserted by `router_test.dart`,
currently rendering a placeholder screen.

**Proposed:** keep the route as an addressable deep link, and have it present
the **sheet** over the branch root rather than a screen of its own — so the
rendered result matches the reference and the existing route contract and its
tests survive. Recorded rather than settled.

### Q11 — the reference's search has no loading, error or offline state

Its index is synchronous and local. The brief asks for those states. Building
them would mean inventing a screen the reference never shows.

**Proposed:** the repository contract carries them, so Dayroz can supply a
remote index without a redesign; the fixture resolves synchronously and those
states are unreachable in this build, which is what the reference does. Any
state that cannot be reached is not drawn.
