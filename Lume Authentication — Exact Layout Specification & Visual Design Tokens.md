# LUME AUTHENTICATION — EXACT LAYOUT SPECIFICATION & VISUAL DESIGN TOKENS

This section extends the existing Lume Master Product, UX, UI Composition & Visual Design Specification.

Authentication must have its own explicit layout system within the Lume Design System.

The implementation must not invent authentication layouts.

The following specifications define:

- exact screen composition
- content hierarchy
- spacing
- component dimensions
- responsive behavior
- typography
- colors
- surfaces
- borders
- shadows
- radii
- motion
- states
- interaction behavior
- accessibility
- visual tokens

The authentication experience must feel premium, modern, calm and highly polished.

==================================================
1. AUTHENTICATION VISUAL DIRECTION
==================================================

Authentication is a premium Lume entry experience.

Visual characteristics:

- editorial-quality typography
- generous whitespace
- soft atmospheric background
- restrained gradients
- large but controlled visual hierarchy
- rounded modern surfaces
- subtle depth
- refined micro-interactions
- smooth transitions
- strong focus states
- high-quality loading/success states

Avoid:

- generic centered login form
- excessive cards
- excessive borders
- excessive shadows
- oversized illustrations
- giant decorative gradients
- template-style authentication pages
- dense forms
- unnecessary fields

The visual hierarchy must always be:

BRAND
↓
PURPOSE
↓
INPUT
↓
PRIMARY ACTION
↓
SECONDARY ACTION
↓
SUPPORTING INFORMATION

==================================================
2. AUTHENTICATION CANVAS
==================================================

## Mobile

Authentication uses the entire safe-area-aware viewport.

Canvas:

100% viewport width
100% viewport height

Safe areas must be respected.

Recommended horizontal content padding:

24px

Maximum mobile form width:

420px

On larger phones, center the content horizontally.

Primary form content should never touch the screen edges.

---

## Tablet

Use a centered authentication composition.

Recommended:

Horizontal padding:
40–64px

Maximum content width:
480px

Optional ambient visual region may occupy the remaining space.

---

## Desktop

Use a premium two-region composition.

Recommended structure:

```text
┌──────────────────────────────────────────────────────────┐
│                                                          │
│   LUME VISUAL REGION        │       AUTH REGION          │
│                             │                            │
│                             │       Lume logo            │
│                             │                            │
│    Ambient animation        │       Heading              │
│    / illustration           │       Supporting text      │
│                             │                            │
│    Brand message            │       Form                 │
│                             │                            │
│                             │       Primary CTA          │
│                             │                            │
│                             │       Secondary actions    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

Visual region:

45–55% viewport width

Authentication region:

45–55% viewport width

The form itself remains constrained.

Maximum auth form width:

420px

Do not stretch form fields across the entire right half.

==================================================
3. MOBILE AUTHENTICATION LAYOUT
==================================================

Mobile is the primary authentication composition.

Exact vertical hierarchy:

```text
SAFE AREA
↓
Top navigation
↓
Lume logo
↓
Optional ambient visual
↓
Heading
↓
Supporting text
↓
Form
↓
Primary CTA
↓
Recovery / alternate actions
↓
Legal/supporting copy
↓
Bottom safe area
```

Recommended vertical composition:

Top safe area:
16–24px

Header:
48px

Gap after header:
24–32px

Brand/logo:
32–40px visual height

Gap:
24–32px

Optional visual:
72–140px

Gap:
24–32px

Heading:
36–48px depending on screen

Gap:
8–12px

Supporting text:
16px

Gap:
24–32px

Form fields:
48–56px each

Gap between fields:
12px

Gap before primary CTA:
20–24px

Primary CTA:
52–56px

Gap:
16px

Secondary actions:
44–48px minimum touch target

Bottom content:
16–24px

These values are targets rather than absolute pixel locking when device dimensions require adaptation.

==================================================
4. MOBILE HEADER
==================================================

Authentication header:

```text
←                         Lume
```

or:

```text
←

                 Lume logo
```

depending on the flow.

Back button:

40–44px touch target

Visual icon:

20–22px

Do not use an X as the default authentication navigation control.

Use:

← Back

for normal authentication navigation.

X is reserved for temporary dismissible authentication surfaces.

==================================================
5. LOGO
==================================================

Lume logo must use the official Lume brand asset.

Recommended logo visual height:

28–36px

Do not recreate the logo with text.

Logo should have enough surrounding whitespace to remain premium.

Do not place the logo inside a heavy card.

==================================================
6. AUTHENTICATION HERO
==================================================

Primary heading:

32–40px mobile

40–48px desktop

Font weight:

700–750

Line height:

1.05–1.15

Maximum heading width:

360px

Supporting text:

15–17px

Line height:

1.4–1.55

Color:

secondary text token

Example:

Welcome back

Continue your Lume journey.

Do not use overly long marketing copy.

==================================================
7. SIGN-IN EXACT COMPOSITION
==================================================

Sign-in screen:

```text
┌───────────────────────────────────────┐
│                                       │
│  ←                                    │
│                                       │
│             LUME                      │
│                                       │
│                                       │
│  Welcome back                         │
│  Continue your Lume journey.         │
│                                       │
│  Email                                │
│  ┌─────────────────────────────────┐  │
│  │ email@example.com               │  │
│  └─────────────────────────────────┘  │
│                                       │
│  Password                             │
│  ┌─────────────────────────────────┐  │
│  │ •••••••••••••••••           ◉  │  │
│  └─────────────────────────────────┘  │
│                                       │
│                    Forgot password?   │
│                                       │
│  ┌─────────────────────────────────┐  │
│  │          Sign in →              │  │
│  └─────────────────────────────────┘  │
│                                       │
│              ── or ──                 │
│                                       │
│  ┌─────────────────────────────────┐  │
│  │     Continue with Google        │  │
│  └─────────────────────────────────┘  │
│                                       │
│  ┌─────────────────────────────────┐  │
│  │      Continue with Apple       │  │
│  └─────────────────────────────────┘  │
│                                       │
│       New to Lume? Create account    │
│                                       │
└───────────────────────────────────────┘
```

Order is intentional.

Do not move social authentication above the primary email/password action unless explicitly specified by product requirements.

==================================================
8. SIGN-UP EXACT COMPOSITION
==================================================

Sign-up screen:

```text
←

Create your Lume account

Set up your account and make Lume yours.

Name
[____________________________]

Email
[____________________________]

Password
[____________________________] ◉

Password strength
━━━━━━━━━━━━━━━━

✓ 8+ characters
✓ Uppercase
✓ Number

[ Create account → ]

Already have an account?
Sign in
```

If signup requires additional fields, use progressive steps rather than creating an excessively tall form.

==================================================
9. PROGRESSIVE SIGNUP

For multi-step signup:

```text
Create your account

● ━━━━━ ○ ━━━━━ ○

Step 1
Your details

[Continue]
```

Progress indicator:

Height:
4px

Maximum width:
120–160px

Use animated progression.

Never make the progress indicator visually dominant.

==================================================
10. FORGOT PASSWORD LAYOUT
==================================================

```text
←

Forgot password?

Enter your email and we'll send
instructions to reset your password.

Email
[____________________________]

[ Send reset link → ]

Remember your password?
Sign in
```

The recovery illustration/visual may appear between the heading and form.

On small screens it must remain compact.

==================================================
11. RESET PASSWORD LAYOUT
==================================================

```text
←

Create a new password

Choose a strong password for your
Lume account.

New password
[____________________________] ◉

Password strength
━━━━━━━━━━━━━━━━

Confirm password
[____________________________] ◉

[ Update password → ]
```

Validation should appear immediately below the relevant field.

==================================================
12. EMAIL VERIFICATION LAYOUT
==================================================

```text
←

              ✉

Check your inbox

We sent a verification link to

m•••••@example.com

[ Open email ]

Didn't receive it?

Resend email

Resend available in 42s
```

Use a dedicated verification illustration/icon.

The verification state should animate after successful verification.

==================================================
13. SUCCESS SCREEN
==================================================

Success screens should use a visual focal point.

Example:

```text
                 ✦
              ┌─────┐
              │  ✓  │
              └─────┘

              All set

       Your Lume account is ready.

          [ Enter Lume → ]
```

Success visual:

96–144px visual region

Do not use giant celebration graphics.

Animation:

- ring expands subtly
- checkmark draws
- small ambient particles appear
- content fades into final state

Total animation:

approximately 500–800ms

The user must not be blocked from pressing the CTA while the animation runs.

==================================================
14. INPUT SPECIFICATION
==================================================

Standard input:

Height:
52px

Minimum touch target:
48px

Horizontal padding:
16px

Radius:
14px

Border:
1px

Label:

13–14px

Input text:

16px

Supporting/error text:

12–13px

Vertical gap:

8px label → input

12px input → next field

Inputs should have a comfortable visual density without appearing oversized.

==================================================
15. INPUT STATES
==================================================

Every input must support:

Default
Focused
Filled
Disabled
Error
Valid where useful

Default:

neutral surface
subtle border

Focused:

Lume accent border
subtle accent glow

Error:

error border
error supporting text

Disabled:

reduced contrast
non-interactive appearance

Do not rely on color alone.

==================================================
16. PRIMARY BUTTON
==================================================

Primary authentication button:

Height:
52–56px

Radius:
14–16px

Width:
100%

Font size:
15–16px

Font weight:
650–700

Icon:

16–20px

Recommended structure:

Sign in →
Create account →
Continue →
Update password →

The arrow may subtly animate on hover/press.

==================================================
17. SECONDARY BUTTONS
==================================================

Secondary buttons:

Height:
48–52px

Radius:
14px

Use subtle surface/border treatment.

Examples:

Continue with Google
Continue with Apple

Avoid making every action look like the primary CTA.

==================================================
18. TEXT LINKS
==================================================

Links such as:

Forgot password?
Create account
Sign in
Resend email

must have:

- clear accent color
- minimum 44px touch area where practical
- visible pressed/focused state

Do not make links so subtle that they look like body text.

==================================================
19. AUTHENTICATION CARD RULE
==================================================

Mobile:

Do NOT place the entire login form inside a floating card by default.

The screen itself should be the composition.

Desktop:

A subtle auth surface/card may be used.

Desktop card:

Maximum width:
460px

Padding:
40–48px

Radius:
24–32px

Shadow:
soft / low elevation

Do not use heavy glassmorphism.

==================================================
20. BACKGROUND SYSTEM
==================================================

Authentication background may use:

- soft Lume gradient
- subtle radial light
- atmospheric blur
- abstract translucent forms
- very subtle animated particles

Background opacity should remain restrained.

Content must always have stronger contrast than decorative elements.

Background motion should be extremely slow.

Recommended ambient cycle:

8–20 seconds

Never use rapid looping background animations.

==================================================
21. AUTHENTICATION COLOR TOKENS
==================================================

Define semantic authentication tokens rather than hardcoding colors.

### Brand

auth.brand.primary
auth.brand.primaryPressed
auth.brand.primarySoft

### Background

auth.background
auth.backgroundElevated
auth.backgroundAmbient

### Surface

auth.surface
auth.surfaceElevated
auth.surfaceInteractive

### Text

auth.text.primary
auth.text.secondary
auth.text.tertiary
auth.text.inverse

### Border

auth.border
auth.borderFocused
auth.borderError
auth.borderSuccess

### Status

auth.status.success
auth.status.warning
auth.status.error
auth.status.info

These tokens must reference the global Lume color system.

Authentication must not invent an unrelated palette.

==================================================
22. AUTHENTICATION LIGHT MODE TOKENS
==================================================

Example semantic values:

auth.background:
Lume light background

auth.surface:
white / elevated Lume surface

auth.surfaceElevated:
white

auth.text.primary:
Lume primary text

auth.text.secondary:
Lume secondary text

auth.border:
subtle neutral border

auth.brand.primary:
Lume primary brand accent

auth.status.success:
semantic success

auth.status.error:
semantic error

Exact hex values must inherit from the master Lume color tokens.

Do not duplicate global color definitions.

==================================================
23. AUTHENTICATION DARK MODE TOKENS
==================================================

Dark mode must be intentionally designed.

Do NOT simply invert light mode.

Use:

auth.background:
deep Lume dark background

auth.surface:
dark elevated surface

auth.surfaceElevated:
higher dark surface

auth.text.primary:
high-emphasis light text

auth.text.secondary:
muted light text

auth.border:
subtle dark-mode border

auth.brand.primary:
dark-mode-compatible Lume accent

Charts, illustrations and ambient elements must also adapt.

==================================================
24. TYPOGRAPHY TOKENS
==================================================

Define:

auth.type.display
auth.type.heading
auth.type.subheading
auth.type.body
auth.type.label
auth.type.caption
auth.type.button
auth.type.link
auth.type.error

Recommended:

Display:
40–48px / 700–750

Heading:
32–40px / 700

Subheading:
16–18px / 500–600

Body:
15–17px / 400–500

Label:
13–14px / 550–650

Caption:
12–13px / 400–500

Button:
15–16px / 650–700

Typography must inherit the Lume font family.

==================================================
25. SPACING TOKENS
==================================================

Authentication uses the Lume spacing scale.

Recommended semantic tokens:

auth.space.xs = 4px
auth.space.sm = 8px
auth.space.md = 12px
auth.space.lg = 16px
auth.space.xl = 24px
auth.space.2xl = 32px
auth.space.3xl = 40px
auth.space.4xl = 48px
auth.space.5xl = 64px

Do not introduce arbitrary spacing values unless required by responsive layout.

==================================================
26. RADIUS TOKENS
==================================================

auth.radius.input = 14px
auth.radius.button = 14–16px
auth.radius.card = 24–32px
auth.radius.visual = 24–32px
auth.radius.pill = 999px

Maintain consistent geometry across auth screens.

==================================================
27. ELEVATION TOKENS
==================================================

Authentication should use restrained elevation.

auth.elevation.none
auth.elevation.subtle
auth.elevation.card
auth.elevation.floating

Avoid deep shadows.

The premium appearance should come primarily from:

- spacing
- typography
- contrast
- surfaces
- subtle borders
- controlled depth

not large shadows.

==================================================
28. ICON TOKENS
==================================================

Authentication icons:

Default size:
20–22px

Small:
16px

Large visual:
24–32px

Stroke:

approximately 1.75–2px

Use one consistent icon family.

Do not mix unrelated icon styles.

==================================================
29. MOTION TOKENS
==================================================

Define authentication-specific motion tokens.

auth.motion.instant:
100–150ms

auth.motion.fast:
150–200ms

auth.motion.standard:
250–350ms

auth.motion.emphasis:
400–600ms

auth.motion.success:
500–800ms

auth.motion.ambient:
8–20s

Use standard easing curves.

Interactive controls should feel responsive.

Decorative elements should move slowly.

==================================================
30. SCREEN TRANSITION TOKENS
==================================================

Forward navigation:

Fade + slight vertical movement

Duration:
250–350ms

Backward navigation:

Reverse transition

Duration:
200–300ms

Major success:

Scale/fade emphasis

Duration:
500–800ms

Do not use aggressive page rotations, 3D transitions or excessive parallax.

==================================================
31. INPUT MOTION
==================================================

Focus:

150–200ms

Border/color transition.

Error:

200–300ms

Subtle horizontal movement if appropriate.

Success:

150–250ms

Subtle validation state.

Password visibility:

150–200ms

Icon transition.

==================================================
32. BUTTON MOTION
==================================================

Press:

100–150ms

Slight scale:

0.98–0.99

Release:

150–200ms

Loading:

content fades into spinner.

Success:

spinner transitions into checkmark.

Do not allow the button to visually jump when switching between states.

==================================================
33. AUTHENTICATION LOADING TOKEN
==================================================

Loading indicator:

16–20px

Primary button remains the same width and height.

Example:

```text
┌───────────────────────────────┐
│          ◌ Signing in         │
└───────────────────────────────┘
```

Never replace the entire authentication screen with a giant spinner for a normal form submission.

==================================================
34. ERROR VISUAL TOKEN
==================================================

Errors should use:

- semantic error color
- subtle tinted background where appropriate
- error icon when useful
- supporting explanation
- recovery action

Example:

┌─────────────────────────────────┐
│ !  Couldn't sign in             │
│    Check your details and try   │
│    again.                       │
└─────────────────────────────────┘

Do not rely on bright red everywhere.

==================================================
35. SUCCESS VISUAL TOKEN
==================================================

Success should use:

- Lume success semantic color
- circular confirmation visual
- checkmark
- subtle glow
- controlled motion

Avoid excessive confetti.

==================================================
36. FOCUS ACCESSIBILITY
==================================================

Keyboard focus must have a clearly visible focus state.

Focus indicator:

2px semantic accent treatment

Do not remove focus indicators.

All controls must support keyboard navigation on desktop.

==================================================
37. REDUCED MOTION
==================================================

When reduced motion is enabled:

Disable:

- ambient looping animation
- particles
- parallax
- large entrance movement
- repeated decorative effects

Retain:

- essential state transitions
- success/error communication
- focus transitions

Transitions should become shorter and simpler.

==================================================
38. KEYBOARD-AWARE LAYOUT
==================================================

When the software keyboard opens:

- focused input remains visible
- form scrolls naturally
- CTA remains reachable
- error text remains visible
- bottom content may temporarily move above the keyboard

Never allow the keyboard to permanently cover:

- password field
- primary CTA
- active validation message

==================================================
39. FORM VALIDATION BEHAVIOR
==================================================

Do not validate everything immediately on first render.

Recommended:

Initial:
neutral

After interaction:
validate field

On submit:
validate all required fields

Errors appear close to the relevant field.

Do not move the entire layout dramatically when an error message appears.

Reserve enough vertical flexibility for supporting text.

==================================================
40. AUTHENTICATION LEGAL COPY
==================================================

If terms/privacy acceptance is required:

Place compact supporting copy below the primary form.

Example:

By creating an account, you agree to the
Terms and Privacy Policy.

Typography:

12–13px

Do not dominate the screen.

Links must remain accessible.

==================================================
41. DESKTOP PREMIUM AUTH VISUAL

Desktop authentication may use:

LEFT:

Lume animated visual environment

RIGHT:

Authentication surface

Example:

```text
┌───────────────────────┬───────────────────────────────┐
│                       │                               │
│                       │          LUME                 │
│                       │                               │
│    Lume ambient       │     Welcome back              │
│    animation          │     Continue your journey.    │
│                       │                               │
│    subtle brand       │     Email                     │
│    message            │     [____________________]    │
│                       │                               │
│                       │     Password                  │
│                       │     [____________________]    │
│                       │                               │
│                       │     [ Sign in → ]             │
│                       │                               │
│                       │     Forgot password?           │
│                       │                               │
└───────────────────────┴───────────────────────────────┘
```

The visual side should not contain excessive copy.

Authentication remains the primary task.

==================================================
42. AUTHENTICATION VISUAL HIERARCHY

Priority 1:
Heading

Priority 2:
Primary input/action

Priority 3:
Supporting explanation

Priority 4:
Secondary authentication options

Priority 5:
Decorative visual

Decoration must never overpower the form.

==================================================
43. AUTHENTICATION DENSITY

Authentication uses:

LOW → MEDIUM density

Unlike Markets, authentication should NOT be information-dense.

Premium authentication requires breathing room.

The visual density should feel intentional and calm.

==================================================
44. AUTHENTICATION COMPONENT ANATOMY

Every authentication screen is constructed from:

AuthShell
│
├── AuthHeader
│
├── Brand
│
├── AmbientVisual
│
├── AuthHeading
│
├── AuthSupportingText
│
├── AuthForm
│   ├── AuthInput
│   ├── AuthPasswordInput
│   └── ValidationMessage
│
├── PrimaryAction
│
├── SecondaryActions
│
├── RecoveryAction
│
└── AuthFooter

Not every screen needs every component.

==================================================
45. AUTH SCREEN-SPECIFICATION CONTRACT

Every auth screen must define:

screen_id
screen_purpose
entry_point
exit_destination
header
brand
hero
fields
primary_action
secondary_actions
validation
loading_state
error_state
success_state
motion
keyboard_behavior
responsive_layout
accessibility
analytics_event
deep_link_behavior

This makes authentication implementation deterministic.

==================================================
46. AUTHENTICATION SCREEN MATRIX

| Screen | Density | Primary Composition | Main Visual |
|---|---|---|---|
| Sign In | Low | Form + brand | Ambient |
| Sign Up | Low/Medium | Progressive form | Ambient |
| Forgot Password | Low | Recovery form | Recovery visual |
| Reset Password | Low | Password form | Security visual |
| Email Verification | Low | Status + action | Email visual |
| Account Created | Low | Success | Animated success |
| Session Expired | Low | Message + CTA | Minimal |
| Authentication Error | Low | Recovery state | Minimal |

==================================================
47. FINAL AUTHENTICATION QUALITY TEST

Before implementation is considered complete, verify:

□ Authentication does not look like a generic form.

□ Sign In, Sign Up and Recovery feel like one cohesive experience.

□ Exact content hierarchy is preserved.

□ Mobile layout uses the defined composition.

□ Desktop layout uses the defined premium composition.

□ Inputs use the authentication tokens.

□ Buttons use the authentication tokens.

□ Typography uses Lume tokens.

□ Colors reference semantic Lume tokens.

□ Dark mode is intentionally designed.

□ Animations are purposeful.

□ Reduced Motion is supported.

□ Keyboard behavior is correct.

□ Loading states preserve layout dimensions.

□ Error states do not cause destructive layout jumps.

□ Success states have premium motion.

□ Authentication never invents user information.

□ Authentication integrates with the Profile and Notification systems.

□ Back navigation is correct.

□ Deep links can resume after authentication.

==================================================
48. NON-NEGOTIABLE AUTHENTICATION RULE

The implementation must NOT generate a generic authentication screen based only on:

"Create a modern login screen."

It must implement the defined:

- layout
- hierarchy
- dimensions
- spacing
- typography
- semantic colors
- surfaces
- radii
- motion
- states
- responsive behavior
- accessibility behavior

The Lume authentication experience should feel deliberately art-directed and product-specific.

Authentication is the user's first major interaction with Lume.

It must therefore meet the same visual quality bar as the rest of the application.