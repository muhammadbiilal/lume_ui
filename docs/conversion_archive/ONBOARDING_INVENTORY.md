# The nine onboarding steps, as the running source defines them

> **Temporary conversion evidence. Not part of the final Flutter maintenance
> specification.** This document describes the browser prototype that Lume is
> being converted *from*, and is removed or relabelled as historical at Phase F9.
> The authoritative documents for the Flutter application are `claude.md`, `README.md`
> and the rewritten `LUME_*` specifications.

Read out of `screens/onboarding.screen.js` (the template and the handlers),
`ui/pickers.js`, `core/app-store.js`, `data/geo.js`, `data/catalogue.js`,
`css/onboarding.css` and `css/screens/shared.css`. Nothing here is taken from a
title or from a Dayroz model.

Step indices are the `data-step` attributes the prototype itself carries.

---

## 1. The inventory

### Step 0 — Welcome

| | |
|---|---|
| Identifier | `data-step="0"` |
| Builder | `onboardingTemplate()`, static |
| Purpose | What the product is, and a way past it for a returning user |
| Controls | `.onb__art` illustration · `.onb__brand` mark + wordmark + tagline · title · text · **Get started** (`[data-onb-next]`) · **Already have an account? Sign in** (`#onbSignIn`) |
| Continue | Always enabled |
| Skip | Header Skip active |
| Persists | Nothing. Sign-in commits `DEFAULT_INTERESTS` first when none are stored, then finishes and opens auth |
| Depends on | — |
| Responsive | `.onb__art` is `flex: 1 1 auto; min-height: 200px`, SVG capped at 292 |
| RTL | Brand row and footer mirror; the arrow mirrors |
| Flutter | Built at F4B |

### Step 1 — Plan

| | |
|---|---|
| Identifier | `data-step="1"` |
| Purpose | The first of two value slides |
| Controls | illustration · kicker `onb.planKicker` · title `onb.planTitle` · text · Continue |
| Continue | Always enabled |
| Skip | Header Skip active |
| Persists | Nothing |
| Flutter | Built at F4B |

### Step 2 — Tools

| | |
|---|---|
| Identifier | `data-step="2"` |
| Purpose | The second value slide; quotes the catalogue's size |
| Controls | illustration · kicker `onb.toolsKicker` · **title with a live count** — `<span id="onbToolCount">` is written with `C.FEATURES.length` in `onbStart()` · text · Continue |
| Continue | Always enabled |
| Persists | Nothing |
| Depends on | the catalogue's length |
| Flutter | Built at F4B |

### Step 3 — Where are you based?

| | |
|---|---|
| Identifier | `data-step="3"`, `.onb-step--list` |
| Builder | `PICKERS.makeLocationPicker($('#onbCountry'), …, { stage: 'country' })` |
| Controls | lead · search · Recent / Popular / All countries · Continue (sticky) |
| Continue | Always enabled — a country is always selected |
| Persists | Into `onbDraft` only. Written to the profile at **step 4's** Continue |
| Flutter | **complete (F4A)** — integrated unchanged |

### Step 4 — Which city are you in?

| | |
|---|---|
| Identifier | `data-step="4"`, `.onb-step--list` |
| Builder | `PICKERS.makeLocationPicker($('#onbCity'), …, { stage: 'city' })` |
| Purpose | City, and the region it belongs to |
| Controls | **kicker is the country's localised name** (`#onbCityCountry`) · title `onb.cityTitle` · text · search (`pers.searchCities`) · **"Use my current location"** action row · region groups *or* a flat city list · Continue (sticky) |
| Composition rule | A country with `REGIONS` and **no query** renders one `.locgroup` per region; otherwise a flat `.loclist` of every city, each carrying its region as meta |
| No results | `.locempty` with `search.nothing` |
| Continue | Always enabled |
| Persists | **Here**: `country`, `region`, `city` are written to the profile and `forgetPrayerTimes()` is called, *before* step 5, so the interest picker can drop interests that lead nowhere in this country |
| Depends on | Step 3. Choosing a country resets `city` to `citiesOf(country)[0]` and `region` accordingly |
| Note | The onboarding instance passes `stage: 'city'`, so the `.locback` button that the personalisation sheet shows is **absent** here |
| Flutter | Built at F4B |

### Step 5 — What are you here for?

| | |
|---|---|
| Identifier | `data-step="5"` |
| Builder | `PICKERS.makeInterestPicker(…)` with a context of `{ country: draft.country, islamic: true }` |
| Continue | `#onbPickNext`, disabled until five are chosen |
| Persists | On Continue: `onbCommit(interests, faith)` writes `interests`, `islamic`, `country`, `region`, `city`, then `forgetPrayerTimes`, `syncFaithFromInterests`, `save`, `renderAll` |
| Flutter | **complete (F4A)** — integrated unchanged |

### Step 6 — Set it up once

| | |
|---|---|
| Identifier | `data-step="6"` |
| Purpose | Two permissions, and the prayer calculation method for Muslim users |
| Controls | small illustration · title `onb.setupTitle` · text `onb.setupText` · two `.onb-row` toggles, **both on by default** · a `data-faith="islamic"` block holding "Prayer calculation method" and a five-option `.onb-choice` · **Looks good** · note `onb.onDevice` |
| State-dependent copy | Both row subtitles change with `profile.islamic`: location becomes "For prayer times, Qibla, weather and nearby places"; notifications become "A quiet nudge 5 minutes before each adhan" |
| Faith gate | `applyVisibility()` hides the method block when `islamic` is false |
| Continue | Always enabled |
| **Persists** | **Nothing.** The toggle handler flips classes and the method handler moves `is-active`; neither writes to the profile. See §3 |
| Depends on | Step 5's faith outcome |
| Flutter | Built at F4B |

### Step 7 — What should we call you?

| | |
|---|---|
| Identifier | `data-step="7"` |
| Purpose | An optional display name |
| Controls | illustration · kicker · title · text · `.field--wide` text input (`maxlength="40"`, `autocomplete="given-name"`) · **Continue** (`#onbNameNext`) · **Skip for now** (`#onbNameSkip`) · note |
| Prefill | `account.displayName()` — the account's name for a signed-in user, the device's for a guest |
| Continue | Always enabled. Commits **only when the trimmed value differs** from the current name, then advances |
| Skip | Its own Skip advances **without writing** — §124.4: skipping is not a deletion |
| Persists | `commitName` trims to 40 and writes to the account when authed, otherwise to `profile.displayName`; then saves and re-renders Home and Profile |
| Swipe | Left-swipe advance is **disabled** on this step (and on step 5) |
| Flutter | Built at F4B |

### Step 8 — You're all set

| | |
|---|---|
| Identifier | `data-step="8"` |
| Purpose | Completion |
| Controls | animated seal · kicker `onb.allSet` · **title varies**: `onb.readyNamed{name}` when a name is known, else `onb.readyTitle` · **text varies**: `onb.readyFaith{prayer}` when `islamic`, else `onb.readyGeneral` · **Enter Lume** (`#onbFinish`) · note `onb.revisit` |
| Continue | Always enabled |
| Skip | **Header Skip is disabled on the last step** |
| Persists | `onbFinish` sets `lume-onboarded` = `'1'` and dismisses over 380 ms |
| Depends on | the name from step 7 and the faith outcome from step 5 |
| Flutter | Built at F4B |

---

## 2. The state machine

| Transition | Source |
|---|---|
| Entry | `?tour=1` forces it; otherwise shown when `lume-onboarded` is unset |
| Replay | `#replayTour` in Profile calls `onbStart()` |
| Start | `onbStart` re-seeds `onbDraft` from the profile, sets the picker from the profile, shows step 0 |
| Forward | `[data-onb-next]` on 0, 1, 2, 3, 4, 6; step 5 and step 7 have their own |
| Back | header Back, `onbShow(step - 1, true)` — adds `is-back` for the reverse rise |
| Back disabled | step 0 |
| Skip disabled | step 8 |
| Header Skip | if no interests stored: commit `DEFAULT_INTERESTS` with `islamic: false` and finish with one message; otherwise finish with another |
| Swipe | left advances except on steps 5 and 7; right always goes back; ignored under 56 px or when vertical dominates |
| Clamp | `onbShow` clamps to 0…8 |
| Finish | `lume-onboarded` = `'1'`, `.is-leaving`, hidden after 380 ms |

---

## 3. Findings

**F1 — step 6 persists nothing.** Both permission toggles and the prayer-method
chooser are visual only: the handlers add and remove classes. Nothing reaches
`profile.method`, and no permission is requested. A **prototype gap**, not dead
source — the step is reachable and its controls respond. The Flutter build
persists the method (the profile already has a `method` field, defaulted to
`MWL`) and treats the two permission rows as **intent**, recorded in the draft,
because a real permission has to be requested by the platform at the moment it
is needed rather than promised on a slide.

**F2 — `onb.readyTitle` is defined twice.** `core.js` says "You're ready";
`account.js` says "You're all set". `account.js` is merged later, so the
rendered value is **"You're all set"**, which is also the markup's fallback.
`core.js`'s copy is dead for this key. Stale duplicate; the rendered value wins.

**F3 — the method list is hard-coded in the markup.** Five options — University
of Karachi, Muslim World League, ISNA, Umm al-Qura, Egyptian — appear as literal
`<button>`s with no ids and no `data-i18n`, while `profile.method` defaults to
`'MWL'`. The first is marked `is-active` regardless of what `profile.method`
holds, so the rendered selection and the stored value disagree on a first run.
A **prototype defect**; the Flutter build marks the stored method.

**F4 — `.onb__skip` and `.onb__nav` are under the touch floor.** Resolved in
F4A: the targets overhang. Recorded here because every remaining step inherits
the same chrome.

**F5 — step 2's count is `C.FEATURES.length`, not the visible count.** It quotes
the whole catalogue (85), not what this user can see. Faithful, and worth
knowing before someone "fixes" it to an eligibility-filtered number.

---

## 4. Persistence

| Key / field | Written by | Lifecycle |
|---|---|---|
| `lume-onboarded` | `onbFinish`, and the header Skip through it | Set once; its presence suppresses the flow on next launch |
| `lume-profile.country` / `.region` / `.city` | step 4's Continue, and again by `onbCommit` | Overwritten on every completed run |
| `lume-profile.interests` | `onbCommit`; header Skip writes `DEFAULT_INTERESTS` when empty | |
| `lume-profile.islamic` | `onbCommit` from the picker's switch, then `syncFaithFromInterests` | Never inferred from country or language |
| `lume-profile.displayName` | `commitName`, only when changed | Guest only; an authed user's name lives on the account |
| `lume-profile.method` | **never, in the prototype** | See F1 |

`load()` carries one migration already: a profile with no interests that has
been onboarded falls back to `DEFAULT_INTERESTS`, and `syncFaithFromInterests`
turns `islamic` on when any faith interest is present — **never off**, so an
explicit preference is not overwritten.

---

## 5. What F4B builds

Seven steps — 0, 1, 2, 4, 6, 7, 8 — the nine-step machine, the persistence
contract above, and the migration rules the phase adds on top of it. Country and
interests are integrated unchanged from F4A, and their goldens must not move.
