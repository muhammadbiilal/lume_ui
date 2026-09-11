# Authentication inventory

**TEMPORARY CONVERSION MATERIAL.** Read out of the running Lume prototype at
Phase F4C and deleted with it at F9. The product-facing description of what
Flutter does is `docs/LUME_AUTH.md`; this file records what was *found*.

Sources, in the order the phase brief ranks them:

| Layer | File |
|---|---|
| rendered screens | `docs/conversion_archive/shots/auth/*.web.png`, 16 states |
| measured bounds | `docs/conversion_archive/measurements/auth_*.json`, 16 cells |
| flow / screen JS | `assets/js/screens/auth.screen.js` (259 lines) |
| submission JS | `assets/js/services/account-forms.js` (657) |
| engine JS | `assets/js/services/account.js` (736) |
| templates | `assets/js/ui/account-ui.js` §126 region (lines 976–1398) |
| screen CSS | `assets/css/auth.css` (832) |
| shared CSS | `assets/css/account.css` (fields, rules, meter, form messages) |
| router / startup | `assets/js/core/router.js`, `assets/js/shell.js` (boot, line 988) |
| strings | `assets/js/i18n/account.js` (501) |
| responsive / RTL | `assets/css/auth.css` §16–§18, `assets/css/rtl.css` |
| web tests | `tests/auth.js` (609), `tests/account.js` (1237) |

---

## 1. The eleven states

`AUI.AUTH` has ten entries; `signup` renders two different screens, so there
are **eleven** compositions. Every one is assembled from one shell in one
order — top → brand → visual → hero → steps → notice → form → grow → actions →
alt → foot → legal. A screen that needs less leaves a slot empty; none of them
reorders the slots.

| # | `data-auth` | Screen | Kind | Brand | Visual | Back | Dismissible |
|---|---|---|---|---|---|---|---|
| 1 | `signin` | Welcome back | form | yes | — | yes | when modal |
| 2 | `signup` (step 1) | Create your Lume account | progressive form | yes | — | yes | when modal |
| 3 | `signup` (step 2) | Choose a password | progressive form | yes | — | to step 1 | when modal |
| 4 | `forgot` | Forgot password? | form | yes | seal `i-key` calm | yes | when modal |
| 5 | `sent` | Check your email | status | **no** | seal `i-mail` calm | yes | when modal |
| 6 | `reset` | Create a new password | form | yes | seal `i-shield` calm | yes | when modal |
| 7 | `updated` | Password updated | status | no | seal `i-check` | **no** | when modal |
| 8 | `created` | You're all set | status | no | seal `i-check` | **no** | **never** |
| 9 | `expired` | Your session has expired | status | no | seal `i-clock` warn | **no** | **never** |
| 10 | `trouble` | That link didn't work | status | no | seal `i-alert` warn | yes | when modal |
| 11 | `verify` | Check your inbox | status + form | no | seal `i-mail` calm | yes | when modal |

`status` adds `.auth--status`, which centres the hero and drops the title's
360-point cap. A form screen is ranged, "because a label ranged to the centre
of the field it names is harder to read, not calmer".

---

## 2. Per-state detail

### 1 · `signin` — Welcome back

| | |
|---|---|
| **Entry** | `auth:signin`; the "Sign in" row on Profile; a protected account route (modal, with `then`); the `expired` screen; the onboarding welcome step; `trouble` and `sent` footers; `updated`'s action |
| **Fields** | `email` (type email, inputmode email, autocomplete `email`, placeholder `you@example.com`), `password` (autocomplete `current-password`, reveal) |
| **Actions** | primary `acctsubmit:signin` "Sign in"; inline `auth:forgot` "Forgot password?"; foot link `auth:signup`; secondary "Continue as a guest" **only when modal** |
| **Validation** | on blur: email shape only. On submit: email required → `emailRequired`, email shape → `emailInvalid`, password required → `passwordRequired` |
| **Loading** | 420 ms, button keeps its 342 × 54 box, label → "Signing you in…", spinner replaces the arrow, `pointer-events: none` |
| **Errors** | form-level `credentials` (one message for unknown account *and* wrong password), `locked`, `storage` |
| **Success** | `authSucceeded` → toast "Welcome back, {name}" / "Welcome to Lume"; go to the held account route, else the pending action, else the return tab |
| **Back** | pops the auth stack (sign-up ↔ sign-in are siblings, not levels); at the bottom of the stack, leaves the flow |
| **Deep link** | `opts.then` holds an action across the flow and runs it on success |
| **Session** | starts a 30-day session, adopts the guest's name and photo one way only |
| **Onboarding** | none. Signing in never marks onboarding complete |
| **Guest** | "Continue as a guest" dismisses without ending anything |

### 2–3 · `signup` — two steps

| | |
|---|---|
| **Entry** | `auth:signin` foot link; `auth:signup` |
| **Step 1 fields** | `name` (optional, maxlength 40, autocomplete `name`, hint "So Lume knows what to call you."), `email` |
| **Step 2 fields** | `password` (autocomplete `new-password`, reveal) + meter + rules, `confirm` (reveal) |
| **Actions** | step 1 `acctsubmit:signupstep` "Continue"; step 2 `acctsubmit:signup` "Create account", busy "Creating your account…" |
| **Validation** | step 1 runs the *same* engine check the whole form will run (`identityErrors`), so step 1 can never accept what step 2 would reject: `emailRequired`, `emailInvalid`, `emailTaken`. Step 2: `passwordRequired`, `passwordWeak`, `confirmRequired`, `confirmMismatch`. `confirm` also checks on blur |
| **Indicator** | `.authsteps` 150 × 4, two segments, **plus** "Step 2 of 2" spelled out in the header — never the only signal |
| **Success** | step 1 → step 2, `nav: 'fwd'`; step 2 → account exists, notification state reset, `created` opened with `fresh: true` so nothing behind it is returnable |
| **Back** | step 2 → step 1 via `acctdo:signupback`; the system back and Escape do the same rather than throwing step 1 away |
| **Legal** | step 2 only, below the action; the link opens a **sheet**, not a screen, so the typed password is not lost |
| **Session** | signing up starts a session immediately |

### 4 · `forgot`

Field `email`. Action `acctsubmit:forgot` "Send reset link". Foot link back to
sign in. Errors `emailRequired`, `emailInvalid`. Success → `sent`.

### 5 · `sent` — the neutral confirmation

Deliberately **identical whether or not the address exists**. The typed address
is not echoed. `grow: true` pushes the action to the bottom. The action exists
only when a token is held (`auth:reset`, "Open the reset link") — which in the
prototype is always, because `requestReset` returns a token of the same shape
either way. Foot: "Back to sign in", plus a quiet line explaining the build has
no mail server.

### 6 · `reset`

Fields `password` + meter + rules, `confirm`. Action "Update password".
Failures split: `passwordRequired` / `passwordWeak` / `confirmMismatch` are
field errors on this screen; `linkInvalid` / `linkExpired` are **not the
user's to fix by retyping**, so they leave for `trouble` with `fresh: true`.
Success invalidates every session for that account, ends the live session if it
belonged to that address, and opens `updated`.

### 7 · `updated`

Status. No back. One action: "Sign in".

### 8 · `created`

Status, **not dismissible and no back** — the account already exists by the
time it renders. Text is named when a name was given. One action,
`acctdo:authdone` "Enter Lume".

### 9 · `expired`

Status, not dismissible, no back. Text plus the **masked** account address on
its own bold line. Primary "Sign in again"; foot link "Continue as a guest",
which calls `ACCT.signOut()` — choosing to stay a guest ends the dead session
rather than letting it interrupt again next launch.

### 10 · `trouble`

Status. Two texts: the generic one, or the expired-link one, chosen by which
failure arrived. Primary "Request a new link" → `forgot`. Foot "Back to sign
in".

### 11 · `verify`

Status **with a form**. Text plus the masked pending address. Field `code`
(inputmode numeric, maxlength 6, autocomplete `one-time-code`). Action "Verify
email". Foot carries three rows: the quiet "Didn't receive it?", then either a
live countdown (`You can ask again in {s}s`, a real `setInterval`, `role=
"status"`) or the "Send it again" action once 45 s have passed, then "Cancel".
Errors `codeWrong`, `nothingPending`, and `emailTaken` when the address was
claimed between request and verification.

---

## 3. The measured composition — 390 × 844, light, English

Every number below is `getBoundingClientRect`, read from the running screen.
The prototype draws a 28-point simulated status bar, so `.auth` begins at 28.

| Element | Rule | measured |
|---|---|---|
| `.auth__top` | `min-height: 48`, `padding-top: max(16, safe-top)` | y 28, h 60 with a nav, **48 without** |
| `.auth__nav` | 44 × 44, `margin-inline-start: -10` | x 14, 44 × 44 |
| `.auth__nav--close` | `margin-inline: 0 -10px` | x 332 |
| `.auth__step-of` | caption, end of the header | x 301.36, h 18.13 |
| `.auth__brand` | `margin-top: 24` | y 112, h 34 |
| `.auth__mark` | 34 × 34, radius 11, glyph 19 | 34 × 34 |
| `.auth__word` | 17px/800/−.035em | w 43.3, h 22 |
| `.auth__visual` | `margin-top: 24`, seal auto height | y 100 (no nav) / 112, h 128 |
| `.authseal` | 128 × 128, disc 68 | centred, disc y +30 |
| `.auth__hero` | `margin-top: 24` | y 170 |
| `.auth__title` | `720 clamp(31, 8.6vw, 38)/1.1`, `text-wrap: balance`, max 360 | h 36.89 at 390 |
| `.auth__text` | `500 15.5/1.5`, max 34ch, `margin-top: 10` | y 216.89, h 23.25 per line |
| `.auth__note` | caption, `margin-top: 12` | h 18.13 |
| `.authsteps` | `margin-top: 16`, 150 × 4, gap 6 | y 256.14, seg w 72 |
| `.formok` (notice) | outside the form, inline `margin-top: 18` | h 46.13 |
| `.formerr` | **inside** the form, first child | h 46.13 |
| `.auth__form` | `margin-top: 24`, column, gap 12 | y 264.14 |
| `.field` | gap 8 | h 101.89 |
| `.field__label` | `650 13/1.3`, **not** uppercase | h 16.89 |
| `.field__box` | `min-height: 52`, radius 14, padding 0 16 | h 52 |
| `.field__msg` | `min-height: 17` — always present | h 17 |
| `.pwtoggle` | 34 × 34, `margin-inline-end: -8` | x 323 |
| `.pwmeter` | `margin-top: 2`, gap 10, 4 segments of 4 | h 13 |
| `.pwrules` | `margin-top: 2`, padding 12 14, gap 5 | h 121 |
| `.auth__inline` | `align-self: flex-end`, `margin-top: -4`, min 44 | y 487.92, w 128.73 |
| `.auth__actions` | `margin-top: 24` | y 555.92 |
| `.btn--auth` | 100% × 54, radius 15, `700 15.5/1`, arrow 17 | 342 × 54 |
| `.btn--authsec` | 100% × 50, radius 14, 14.5px | h 50 |
| `.auth__foot` | `margin-top: 16`, column, gap 8 | y 625.92 |
| `.auth__link` | `min-height: 46`, `550 14/1.35` | h 46 |
| `.auth__link--quiet` | caption, `min-height: 0`, padding 8 0 | h 34.13 |
| `.auth__legal` | `margin-top: 24`, 12px, centred | h 38.78 |
| `.auth__panel` | max-width 420, padding 0 24, bottom `24 + safe + kb` | w 390 → content 342 |

Derived and confirmed: 24 + 60 + 24 = 112 (brand), +34 +24 = 170 (hero),
+70.14 +24 = 264.14 (form). Field internals 16.89 + 8 + 52 + 8 + 17 = 101.89.

---

## 4. Breakpoints

| Width | What changes |
|---|---|
| ≤ 359 | `--auth-pad: 20`, title 28px, visual 96, seal 108 |
| 360 – 1179 | the phone composition; the panel is 420 wide at most and centred |
| ≥ 1180 (`app--wide`) | the panel becomes a **card**: 460 wide, padding 48, radius 28, a border and `--auth-elevation-card`; the region centres vertically; `.auth__grow` is dropped; the title steps up to `--auth-type-display` |
| ≥ 1380 (`app--wide`) | two regions: a 48% decorative aside (gradient, art, one line of brand message, `aria-hidden`) and a 52% task region. The ambient layer is dropped because the aside carries it |

`.auth__aside` is `display: none` at every width below 1380, and is
`aria-hidden` at every width — it never carries a field or a control, so
nothing is lost when it disappears.

There is **no compact-height rule.** §16 and §17 key on width only.

---

## 5. RTL

| Rule | Where |
|---|---|
| the back chevron mirrors | `.is-rtl .auth__nav--back svg { transform: scaleX(-1) }` |
| the dismissal never mirrors | there is no rule for `--close` |
| the button arrow mirrors, pressed state included | `.is-rtl .btn--auth .btn__arrow` |
| glows, specks, sparks and the seal use `inset-inline-*` | throughout |
| `.auth__link b` uses `margin-inline-start` | §10 |

---

## 6. Accessibility as found

* Every field's message line carries `id="fm-<name>"` and the input
  `aria-describedby`; an error adds `aria-invalid="true"` and `role="alert"`.
* On failure, focus is moved to the **first** invalid field.
* `.pwtoggle` carries `aria-pressed` and a label that swaps between "Show
  password" and "Hide password".
* The resend countdown is `role="status"`.
* `#screen-auth` takes its `aria-label` from the rendered title, so one host
  announces eleven different screens correctly.
* `.authsteps` is `aria-hidden`; the count is spelled out in the header.
* Focus is `2px solid` accent at `2px` offset on every control, never removed.
* Reduced motion stops the ambient drift, the specks, the panel entrance and
  the invalid shake, and leaves the seal in its finished state.
* Valid fields get a tick as well as a border, so the state is not colour
  alone.

---

## 7. Startup and session, as found

| | |
|---|---|
| **Session** | `lume-session` — email, token, issued, expires (**30 days**), device |
| **Device** | `lume-device` — per browser, not per sign-in |
| **States** | `guest` (no session), `authed`, `expired` (past expiry **or** the device's row was revoked) |
| **Fail closed** | a corrupt or absent `expires` reads as expired, never as valid for ever |
| **Revocation** | signing a device out elsewhere, or changing the password, removes its row; that device becomes `expired` |
| **Boot** | one line, `shell.js:988` — `if (ACCT.isExpired() && store.get('lume-onboarded')) openAuth('expired')` |
| **Protected routes** | `ACCT.requiresAccount(route)` → `openAuth('signin', { modal: true, then: 'acct:' + route })`; the held route *and its stack* are resumed after success |
| **Sign-out** | ends the session, removes the device row, drops `accountEmail`, releases notification state. **The device keeps what the device made** — signing out is not a wipe |

---

## 8. What is wrong in the reference

### D18 — the floating navigation bar is drawn over the flow

`.onb` is `position: absolute; inset: 0; z-index: 65` and covers the shell.
`.screen--auth` is an ordinary screen, and `padding-bottom: 0` removes the
clearance every other screen keeps for the floating bar. Measured on `sent` at
390 × 844:

| | y | height | bottom |
|---|---|---|---|
| `#tabbar` | 770 | 62 | 832 |
| `.auth__foot` | 731.88 | 88.13 | 820.01 |
| `.auth__link` "Back to sign in" | 731.88 | 46 | 777.88 |
| `.auth__link--quiet` | 785.88 | 34.13 | 820.01 |

The last 7.88 points of "Back to sign in" and the **whole** of the quiet line
are underneath the bar. The bar is also live, so `created` and `expired` —
both declared `dismissible: false, back: false` — can be walked straight out
of by tapping Home. Three screens declare that nothing dismisses them and the
navigation dismisses them anyway.

### The notification engine fires during the flow

The `sent` capture caught a delay alert drawn over the header, covering the
back control. Authentication is not isolated from the shell's timers.

---

## 9. Web tests read

`tests/auth.js` (609) and `tests/account.js` (1237) were read for behaviour
the markup does not state: neutrality of `sent`, the single `credentials`
message, expiry failing closed, revocation, the held-route resume, and the
one-way adoption of a guest's name. Nothing in them describes a composition,
so nothing in them overrides a measurement.
