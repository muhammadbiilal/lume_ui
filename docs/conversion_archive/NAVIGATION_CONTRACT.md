# Navigation: the shell, the routes and the four contracts

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** This document describes the browser prototype that Lume is
> being converted *from*, and is removed or relabelled as historical at Phase F9.
> The authoritative documents for the Flutter application are `claude.md`, `README.md`
> and the rewritten `LUME_*` specifications.

Written at Phase F3. It records what the shell, the router, the tool host and the
master-detail layout promise, where each promise comes from in the reference, and
where the native version deliberately differs.

The single organising idea is the reference's own:

> Both bars are drawn from the same `tabOrder()`, carry the same `data-tab` and
> the same class, so the router selects a destination once rather than keeping
> three navigations in step by hand.
> — `assets/js/shell.js`

Everything below is that sentence, typed.

---

## 1. The destination contract

**One definition.** [`lib/core/navigation/lume_destination.dart`](../../lib/core/navigation/lume_destination.dart)
is the only place a destination's id, route, icon, branch index, badge or
semantic label is written. The bottom bar, the rail and the sidebar all render
the list it returns. They cannot disagree, because there is nothing for them to
disagree about.

**Never more than five** (Design System §6, brief §46). Asserted in
`LumeDestinations.build` and tested for every country.

**The visible set is personalised; the branch set is not.**

| | source | changes with country |
|---|---|---|
| `LumeDestinations.orderFor(country)` | `shell.js` `tabOrder()` | yes |
| `LumeDestinations.all` | this conversion | no |

```
PK          Home · Tools · Trains · Today · Profile
everywhere  Home · Tools · Today · Explore · Profile
```

Explore stays reachable in Pakistan and Trains stays reachable elsewhere — they
move out of the bar, not out of the product. `eligibility` decides whether a
feature exists; `orderFor` decides whether it is a *tab*, and the two are
different questions.

**Labels come from the caller.** `LumeDestinations.build` takes a
`String Function(LumeDestinationId)`, so this layer holds no user-facing text and
cannot be the reason a language is incomplete.

**Badges.** A count reaches the screen reader as part of the label
(`"Today, 3 new"`); a dot reaches it without inventing a number
(`"Profile, new"`); a count of zero is not a badge at all.

---

## 2. Branch-index mapping

Six branches serve five tabs. The branch index is **fixed for the life of the
app**; the visible position is not.

| Destination | Branch index | Route | PK tab | Global tab |
|---|---|---|---|---|
| Home | 0 | `/home` | 1st | 1st |
| Tools | 1 | `/tools` | 2nd | 2nd |
| Trains | 2 | `/trains` | 3rd | — |
| Today | 3 | `/today` | 4th | 3rd |
| Explore | 4 | `/explore` | — | 4th |
| Profile | 5 | `/profile` | 5th | 5th |

This is what lets a Pakistani user move to the UK, lose Trains from the bar and
gain Explore, and still find Today's stack, its scroll and its half-filled form
exactly where they left them. Building the branches from `orderFor` instead
would renumber them, and every branch after the change would be showing another
branch's history.

`LumeDestinations.branchIndexOf` is the only translation between the two, and a
test asserts that no destination's branch index moves when the country does.

---

## 3. The route map

Paths are declared in [`lib/core/routing/lume_routes.dart`](../../lib/core/routing/lume_routes.dart)
and assembled in [`app_router.dart`](../../lib/core/routing/app_router.dart).

### Branch roots

```
/home  /tools  /trains  /today  /explore  /profile
```

### Nested destinations — mounted on every branch

These are the reference's non-tab destinations. Each is defined once and mounted
on all six branches, so the notification centre opened from Today is the same
screen as the one opened from Home and only its stack differs.

```
<branch>/notifications
<branch>/search
<branch>/account
<branch>/unavailable
<branch>/tool/:toolId
<branch>/tool/:toolId/records
<branch>/tool/:toolId/records/new
<branch>/tool/:toolId/records/:recordId
<branch>/tool/:toolId/records/:recordId/edit
```

The record routes are **siblings, not a nest**: `records/:recordId` is the
collection opened on a record, not a page stacked on top of it. Stacking them
would put two near-identical lists in the back stack and make Back walk through
both. The fixed segments (`new`, `edit`) are declared before `:recordId`, so
`new` is never read as a record id.

### Canonical entries

A push notification or an external link has no branch of its own, so the bare
forms redirect onto one:

| Link | Resolves to | Why |
|---|---|---|
| `/notifications` | `/home/notifications` | `notifReturnTab` starts at `home` |
| `/search` | `/home/search` | same |
| `/account` | `/profile/account` | where a user would have opened it |

### Outside the shell

```
/auth          authentication — a flow, not a tool (§124)
/onboarding    the first-run flow, which covers the shell
```

Neither has navigation. §124: authentication "never enters the tool router, the
catalogue or search."

### Development only

`/profile/gallery` and `/profile/navigation-gallery` reach the token, component
and navigation galleries. They are not product surfaces and nothing links to
them.

### Anything else

`errorBuilder` renders a named state with a way home. There is no silent
fallback to `/home`: a link that did not resolve should say so.

---

## 4. Breakpoint behaviour

| Class | Shell width | Navigation | Content |
|---|---|---|---|
| compact | < 600 | bottom bar, floating, inset 12 | one pane |
| medium | 600–839 | 84 px labelled rail + status strip | one pane, centred |
| expanded | ≥ 840 | 244 px sidebar + status strip | master-detail |

Plus one rule the reference does not have: **a shell under 480 logical pixels
tall is compact whatever its width** (D1). A landscape phone is a phone.

**What is measured.** `breakpoint.js` observes `.app` — the whole shell
*including* its navigation, not the content area and not the window. `LumeShell`
applies the width cap first and `LumeBreakpointScope` measures inside it, so the
class Flutter resolves and the class the reference draws are the same number.

**The caps.** `.app { max-width: 1366px }`, and `560px` below 600. Both are
kept. They never argue: the 560 cap is gated on a *window* under 600, where the
shell is compact anyway.

Boundaries under test: 359/360, 599/600, 839/840, 1179/1180, 479/480 tall, and
852 × 393.

---

## 5. Back-navigation rules

One rule, stated four ways.

| Where you are | Back goes to | Why |
|---|---|---|
| A branch root | out of the app | nothing above it |
| A nested destination | that branch's root | it was pushed onto that branch |
| A tool opened from Home | `/home` | the stack remembers, so nothing has to |
| A tool opened from Today | `/today` | the same screen, a different stack |
| A record shown over its list (compact) | the list | the record is over the list, not after it |
| A record in a detail pane (expanded) | — | the list never left |
| A tool opened from a related card | the previous tool's caller | related tools **replace**, so the chain cannot grow a stack |

The reference gets the second and third rows from a remembered variable:

> The centre is a destination rather than a tab, so it remembers where the user
> was and its back control returns them there.
> — `assets/js/shell.js`

A branch stack gets the same result without remembering anything, and it also
survives the case a single variable cannot: the centre opened from two different
tabs, twice, with a rotation in between.

**The compact record case is the one exception to "Back is a pop."** At compact
the detail replaces the list inside one route, so the first Back clears the
selection and the second leaves the collection. A `BackButtonListener` takes the
first press. At expanded there is nothing to clear and Back is left alone.

---

## 6. Selection rules

`router.js` syncs the selection against `data-tab`. A destination that has no
`data-tab` selects nothing and the pill hides:

```js
function syncTabs(name) {
  $$('.tab, .navtab').forEach(function (tab) {
    const on = tab.dataset.tab === name;  …
  });
  movePill(barTab());   // null when nothing matched → opacity 0
}
```

So `LumeRoutes.destinationAt(location)` answers "is this location a branch
root?", and `selectedIndex` is `-1` when it is not. **A tool sitting on the Tools
branch selects nothing**, even though `navigationShell.currentIndex` says Tools.
Reading the branch index instead would light a tab the reference leaves dark.

The same applies to Explore in Pakistan: reachable, not a tab, so no selection.

---

## 7. The tool-host contract

[`lume_tool_frame.dart`](../../lib/core/navigation/lume_tool_frame.dart). One
frame, all 85 tools.

**What the host owns:** the back control, title, subtitle, actions, freshness
marker, provenance line, privacy notice, related rail, and the four states.
**What a tool supplies:** its own composition, and nothing else.

**The gate is not the entry point.** §64. `eligible: false` renders the
unavailable state and **never builds the body** — so a gated tool's widgets do
not exist, and nothing in them can run, request or announce itself. The gate is
checked before the status, so a caller that says "ineligible but ready" still
gets nothing. A tool id nobody knows is refused the same way a gated one is: a
deep link is not a second entry point with weaker rules.

**The four states.**

| Status | Shows |
|---|---|
| `ready` | freshness · body · provenance · privacy · related |
| `loading` | skeletons shaped like the content, never a spinner |
| `error` | a named failure and a retry |
| `unavailable` | where, not what broke |

A state shows no provenance, privacy or related rail. A tool that could not load
has nothing to attribute, and a source line under an error attributes a number
that is not there.

**Teardown is Flutter's.** The reference releases countdowns, sub-views and the
tool stack by hand in `onLeave`, because a hidden browser screen is still
mounted. Here a tool that leaves is disposed. `onLeave` remains for what
genuinely outlives the widget — a recents note — and not for cleanup.

**Layout.** The frame applies `LumeMeasure`, so the content is capped and
centred at medium and expanded and full-bleed at compact; `wide: true` opts a
two-pane or wide-table tool into the wider cap.

---

## 8. The master-detail contract

[`lume_master_detail.dart`](../../lib/core/navigation/lume_master_detail.dart).

**Selecting does not push a route.** The CRUD guide's rule, kept: the list is
never rebuilt, so it keeps its scroll, its filters and its sort.

**The list never leaves the tree.** At compact the detail replaces it visually,
but it stays behind it, offstage — so returning from a record returns to the
same scroll offset and the same filter chips, with no screen saving or restoring
anything.

**Rotation is a re-layout.** The two layouts put the list and the detail at
different depths — a row at expanded, a stack at compact — so both are carried
by `GlobalKey`s. A phone turned sideways mid-record keeps the record, the
scroll and the half-typed field.

**The URL carries a selection in, not out.** A deep link to a record lands as
the shell's opening selection; selecting afterwards does not rewrite the
location. The alternative — a route per selection — is exactly the rebuild the
CRUD guide says not to do, and the reference has no locations at all, so nothing
is lost. A *new* deep link does move the selection; a rebuild with the same one
does not, or the screen could never be navigated away from its own opening
record.

**The detail pane is never blank.** `emptyDetail` is required, and
`.cstate--pane` is what it is for.

---

## 9. What the shell hands a screen

A screen never counts the navigation's height for itself. The outlet consumes
the top and side insets and republishes the bottom one:

| Class | `MediaQuery.padding.bottom` inside the outlet | From |
|---|---|---|
| compact, bar showing | 118 | `.screen { padding-bottom: 118px }` |
| compact, no bar | 40 | `:root[data-bp] .screen` |
| medium / expanded | 40 | same |

Plus `viewInsets.bottom` when the keyboard is up, so a form can lift its last
field above it.

---

## 10. Native differences introduced at F3

Each is also recorded in
[KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md).

| # | Difference |
|---|---|
| D8 | Nested destinations ride a branch stack instead of a remembered `notifReturnTab` |
| D9 | The floating bar hides while the keyboard is up |
| D10 | A master-detail selection is not written into the location |
| D11 | The tablet status strip drops the simulated signal, wifi and battery glyphs |

The stage, the device frame and the compact status bar were already covered by
P1, P5 and their consequences.

---

## 11. Where the promises are tested

| Promise | Test |
|---|---|
| One definition, ≤ 5, stable branch indices | `test/core/navigation/destination_test.dart` |
| Bar, rail and sidebar match the measurements | `test/core/navigation/navigation_parity_test.dart` |
| The three presentations, every boundary, the keyboard, the overlay host | `test/core/navigation/shell_test.dart` |
| The four tool-host states and the gate | `test/core/navigation/tool_frame_test.dart` |
| Selection, scroll, filters, rotation, deep links | `test/core/navigation/master_detail_test.dart` |
| Every route resolves; stacks, Back, selection, country switching | `test/core/routing/router_test.dart` |
| The shell at 390×844, 700×900, 1100×900, 852×393, dark, Urdu | `test/goldens/navigation_golden_test.dart` |
| The same ten cells compared value by value against the rendered prototype | `test/core/navigation/navigation_report_test.dart` → [NAVIGATION_PARITY.md](NAVIGATION_PARITY.md) |
