# Lume authentication and startup

Eleven screens and one decision. The screens are what somebody sees when they
sign in, sign up, lose a password or come back to a session that has run out.
The decision is the single place that says which screen comes next.

This is the maintenance document for the Flutter application. It describes what
the flow *is*, not what it was converted from.

---

## 1. The eleven screens

| Route | Screen | Kind | Brand | Visual | Back | Cross |
|---|---|---|---|---|---|---|
| `/auth/signin` | Welcome back | form | yes | — | yes | when it interrupted something |
| `/auth/signup` · step 1 | Create your Lume account | progressive | yes | — | yes | as above |
| `/auth/signup` · step 2 | Choose a password | progressive | yes | — | to step 1 | as above |
| `/auth/forgot` | Forgot password? | form | yes | key, calm | yes | as above |
| `/auth/sent` | Check your email | status | no | mail, calm | yes | as above |
| `/auth/reset` | Create a new password | form | yes | shield, calm | yes | as above |
| `/auth/updated` | Password updated | status | no | check | **no** | as above |
| `/auth/created` | You're all set | status | no | check | **no** | **never** |
| `/auth/expired` | Your session has expired | status | no | clock, warn | **no** | **never** |
| `/auth/trouble` | That link didn't work | status | no | alert, warn | yes | as above |
| `/auth/verify` | Check your inbox | status + form | no | mail, calm | yes | as above |

`/auth` on its own resolves to `/auth/signin`. Every screen is a real location,
so a link to one is a link.

**One shell, one order.** Header → brand → visual → heading → steps → notice →
form → slack → action → alternates → footer → legal. A screen that needs less
leaves a slot empty; none of them reorders the slots or draws its own header.

**A status screen reports; a form screen asks.** A status screen centres its
copy around a focal point and pushes its action to the bottom. A form screen is
ranged, because a label centred over the field it names is harder to read, not
calmer.

---

## 2. The startup decision

```
                      ┌─────────────────────────┐
        launch  ─────▶│  /splash                │
                      │  read the profile       │
                      │  run one-shot migrations│
                      │  restore the session    │
                      └───────────┬─────────────┘
                                  │ ready
                                  ▼
                        ┌───────────────────┐
                        │ LumeRouteGate     │
                        └─────────┬─────────┘
        ┌─────────────┬───────────┼────────────┬──────────────┐
        ▼             ▼           ▼            ▼              ▼
  onboarding    /auth/expired  /auth/signin  held link   the start route
   required      session ran    a protected   resumed     everything else
                    out          surface
```

### Priority

The conditions are not independent, so the order is stated rather than left to
fall out of the code.

| # | Condition | Destination |
|---|---|---|
| 1 | the launch has not answered yet | `/splash` |
| 2 | onboarding is required | `/onboarding` |
| 3 | the session has expired | `/auth/expired` |
| 4 | a protected location, and no account | `/auth/signin`, holding the location |
| 5 | sitting on the splash with nothing left to wait for | the held location, else `/` |

Onboarding outranks the session because it is the product's first question, and
because a brand-new install has no session to have an opinion about. An expired
session outranks a protected route because being told your session ended is
more use than being asked to sign in for no stated reason.

**One decision system.** No screen performs its own redirect. A screen that did
would be racing this one, and two systems that both navigate produce loops
nobody can read. `startup_gate_test.dart` proves every destination the gate
names is a fixed point — redirecting twice always stops.

### What it guarantees

* **Home never flashes** before the session is known, and **Sign In never
  flashes** in front of somebody who is signed in. While the launch is
  deciding, the splash is the only correct thing to draw; anything else is a
  guess, and a guess that turns out wrong is a flash of the wrong screen.
* **A deep link is never lost.** A location the gate redirects away from is
  held and resumed on success. It survives authentication and onboarding both.
  Walking away does *not* resume it: somebody who chose to stay a guest is not
  asking to be sent back to the screen that sent them there.
* **Session restoration runs once**, however many times `boot()` is called.
  The flow hands its status upward rather than asking the repository again.
* **Authentication never marks onboarding complete.** Having an account is not
  having answered the first questions.

---

## 3. The five session states

| State | What it means | What the product does |
|---|---|---|
| **guest** | nobody is signed in, and nobody was | everything works except the account's own surfaces |
| **signed in** | a live session | everything works |
| **restored** | a session found at launch and still live | indistinguishable from signed in, by design |
| **expired** | a session past its month, or revoked elsewhere | `/auth/expired`, once, with the address shown back masked |
| **signed out** | a session ended deliberately | back to guest; **the device keeps what the device made** |

`expired` is a real state, not a flavour of signed out: the account is known,
the address can be shown back, and the way out is to sign in again rather than
to start from nothing. Expiry **fails closed** — a timestamp that cannot be
proved to be in the future is expired, and a revoked device row is expired
however far off its stated expiry is.

**Guest is not a lesser signed-in state.** Only the account's own surfaces are
gated. A row a guest can see has to lead somewhere.

---

## 4. What each screen collects, and what it does with it

| Screen | Fields | On success |
|---|---|---|
| sign in | email, password | the held destination, else the start route |
| sign up 1 | name (optional, 40), email | step 2 |
| sign up 2 | password + meter + rules, confirm | the account exists → `/auth/created` |
| forgot | email | `/auth/sent` — **the same screen whether or not the address has an account** |
| reset | password + meter + rules, confirm | every session for that account ends → `/auth/updated` |
| verify | six-digit code | the address moves, the session stays |

**Validation timing.** Nothing is judged on first render. A field is checked
when it is *left*, and only the two checks that can be made in isolation happen
there: whether an address is an address, and whether a confirmation matches.
Everything else waits for the submission, which is the first moment the form is
a whole. Editing a field drops the verdict on it — a tick that survived the
edit that invalidated it would be a lie.

**The password rules are one array read twice.** What the checklist draws is
what a submission enforces. The strength meter is advice on top and can never
read better than "Fair" while a rule is unmet: a password scoring "Good" beside
two unticked rows and then being refused is a screen arguing with itself.

---

## 5. Errors

Two kinds, and the split is a design rule rather than a convenience.

**A field complaint** belongs to a field and is fixed by retyping it: the
address is not an address, the passwords do not match, the code is wrong. It
appears under the field, with a glyph as well as a colour, in a line that is
*always* in the layout — so an error appearing never moves the button being
reached for.

**A failure** belongs to the attempt and is not fixed by retyping: wrong
credentials, a locked account, no network, a full disk. It appears as one
tinted message at the top of the form, and it is announced.

Two failures get a **screen** rather than a line: a recovery link that is
invalid or expired. Nothing the user retypes will make a spent link work, so
they get `/auth/trouble` and a way out instead of a red line above a form that
will refuse them again.

**One message for "no such account" and "wrong password."** The difference
between them is exactly what an attacker is asking for.

---

## 6. Sensitive data

* A password is an argument, never state that outlives its use. What has been
  typed is wiped on success, on dismissal, when the screen is disposed and when
  the flow moves to another route — so a half-typed sign-up cannot leak into a
  sign-in.
* Nothing interpolates a typed value into a message. The messages are fixed
  strings; the only interpolations in the whole flow are a display name, a step
  number and a countdown.
* No password, digest, code or token is on any model the presentation layer
  sees. `LumeAccount` carries nothing that would be a problem in a log.
* A repository that throws is caught and turned into a designed failure. The
  thrown object is never rendered: it could name an address, an endpoint or
  worse.
* Password fields are secure entry, and turn off the keyboard's suggestion
  strip and learning dictionary, so nothing typed there reaches the dictionary.
* Autofill is asked for by name: `username`/`email` and `password` on sign in,
  `newPassword` on both password screens, `oneTimeCode` on verification. There
  is no clipboard handling and nothing is copied automatically.
* A revealed password stays revealed through a failed submission — which is
  exactly when somebody most wants to read what they typed — and is still
  secure entry when hidden.
* An outcome is not a step. Nothing goes back into `created` or `updated`, so a
  spent recovery code is never one press away.
* **No backend is reached.** The only repository in this application is a
  deterministic double. No `.env`, no Supabase, no Firebase, no endpoint.

---

## 7. Accessibility

* One host, eleven screens: each announces its own title, so a screen reader is
  never told "Sign in" over the expiry screen.
* Every field's message line is announced when it becomes an error, and the
  form-level message is a live region.
* The reveal control says which way it is going — "Show password" or "Hide
  password" — and carries its pressed state.
* The resend countdown is a live region. The number is only honest if it moves,
  so it does.
* The progressive indicator carries no semantics; the count is spelled out
  beside it, because a bar of segments is never the only way to know where you
  are.
* Every control clears 44 points, including the ones drawn smaller.
* Colour never carries a state alone: a valid field gets a tick, an invalid one
  a glyph, a met rule a filled mark.
* **One approved exception.** The data link inside the legal sentence is an
  inline run of text and cannot be 44 points tall without breaking the
  paragraph it sits in. It is announced as a link, and the same page is
  reachable at full size from Profile → Privacy.
* Reduced motion stops the ambient drift, hides the specks, stops the panel's
  entrance and leaves the seal in its finished state. The state changes that
  carry meaning stay.

---

## 8. Localisation

English, Urdu and Arabic, with exact key parity enforced by test. 104 strings.

* Addresses and verification codes are wrapped in directional isolates, so a
  domain does not jump to the other end of an Arabic line and a six-digit code
  does not read backwards.
* The back chevron mirrors, because it means "back". The dismissal does not,
  because a cross is not a direction. The button's arrow mirrors with the
  reading order.
* The countdown is a plural, with Arabic's own categories rather than English's
  two.
* "Lume" is a proper noun and is not translated.

---

## 9. Adapting to the surface

| Width | Composition |
|---|---|
| ≤ 359 | tighter gutters, a smaller heading and a smaller seal |
| 360 – 1179 | one column, capped at 420 and centred |
| ≥ 1180 | the panel becomes a **card**: 460 wide, padded, bordered, lifted. The heading steps up to the display size, and the slack that pushes a status action to the bottom is dropped — a card is as tall as its contents |
| ≥ 1380 | **two regions**: a decorative aside carrying one line of brand message, and the task beside it. The aside holds no field and no control, so nothing is lost when it disappears |

The panel's bottom rises above the software keyboard, so the field being typed
into and the button that submits it are never underneath it. At 200 per cent
text every screen scrolls; nothing is clipped and nothing overlaps.

---

## 10. Deliberate differences from the design source

Recorded in full in `docs/conversion_archive/KNOWN_DIFFERENCES.md`.

| # | Difference | Why |
|---|---|---|
| D18 | The flow covers the shell; the navigation bar is not drawn over it | In the source the floating bar covers the footer — measured, the whole of one line and part of another — and walks straight out of two screens that declare nothing dismisses them |
| D19 | A tall screen scrolls rather than compressing its header | The source's header is a flex item that shrinks from 60 to 48 when the page overflows, sliding the back control 6 up and everything else 12. The header's height should not depend on the length of the page below it |
| D20 | The legal line's inline link has no padded box | An inline `<button>` grows the line box it sits in; a text span does not. The paragraph is two points shorter and the link is in the same place |
| D21 | The seal arrives by fading and scaling rather than by drawing its stroke | The source animates `stroke-dashoffset` on a referenced glyph, which is a technique rather than a requirement |

---

## 11. Evidence

* `test/features/auth/auth_domain_test.dart` — the rules: what an address is,
  what a password is, what a refusal may reveal, what a session is when it has
  run out.
* `test/features/auth/auth_flow_test.dart` — every screen, every validation
  rule, submission exactly once, the loading and error states, the reveal,
  autofill, the resend window, sensitive-state clearing, and every surface,
  theme, language and text size.
* `test/features/auth/auth_bounds_test.dart` — **467 element positions**, each
  within a logical pixel of the design source.
* `test/features/startup/startup_gate_test.dart` — the decision table, the
  priority order, deep-link retention, and a proof that no rule loops.
* `test/features/startup/startup_navigation_test.dart` — the same decisions
  driven through the real router.
* `test/goldens/auth_golden_test.dart` — eleven screens at nine surfaces, plus
  the thirteen states that only appear under a condition.

---

## 12. What is left for the adapter

The repository contract is `LumeAuthRepository`. Dayroz implements it; this
application ships only `LumeFakeAuthRepository`, which is deterministic, holds
its accounts for the life of the process and reaches nothing.

An implementation has four obligations beyond the signatures:

1. Map its own errors onto `LumeAuthFailure` and `LumeAuthIssue` **inside the
   repository**. A widget must never see a provider's error code, and swapping
   the provider must not change what a screen says.
2. Return `LumeAuthFailure.credentials` for an unknown account and a wrong
   password alike.
3. Make a recovery request neutral, including the shape of what it returns.
4. Fail closed on restore.

`auth_domain_test.dart` is the suite it has to satisfy.

**The first-run gate is live but unreachable in this build.** Rule 2 of the
priority table is implemented, tested, and gated on
`LumeProfileRepository.isDurable` — which is `false` for every implementation
here. With a store that forgets, a completed onboarding is forgotten too, and
forcing the flow would put it in front of the same person on every launch. The
gate says so rather than pretending to work; a durable profile repository turns
it on with no other change.
