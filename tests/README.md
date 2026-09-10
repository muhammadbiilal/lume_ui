# Lume verification harnesses

Master Spec §65 and §112 ask for the product to be tested across
personalisation states rather than eyeballed in one. These three harnesses
boot the real `index.html` in jsdom and drive it.

    npm install jsdom     # once, anywhere on the path
    node tests/verify.js    # every tool builds in 5 personalisation states
    node tests/interact.js  # navigation, gating and regional configuration
    node tests/controls.js  # filters, sorting, search, a11y roles, localisation

`verify.js` covers Muslim/non-Muslim × Pakistan/UK/US/Saudi, English/Urdu/
Arabic, and asserts that no hidden feature leaks and no untranslated key
reaches the screen.

`regress.js` holds one assertion per defect found by an adversarial read of
the arithmetic and the edge cases — agenda times in a 12-hour locale, the
`data-loc="global"` fallback, ISO dates west of UTC, the faraid steppers, a
loan with zero tenure, the moon phase, market turnover, the offline banner
and the freshness timestamp. Each of these failed before its fix.

`notify.js` covers the notification system (§100): the engine, the centre,
filtering, read state and dismissal, per-category and per-tool preferences,
the privacy rules, faith/country gating, and the push permission flow —
including that permission is never requested at boot and that a denial is
final.

`verify.js` also enforces §123: a tool with an approved composition in
`toolspec.js` must render its binding sections in that order, or the suite
fails. This is what stops a screen being reinterpreted from its archetype.

`design.js` is the Design System's engineering-handoff section, driven
rather than read. Where the document names a number — the jade palette, the
type scale, 44 px touch targets, a 360-440 px list pane, a 680-760 px
reading cap, 160/260/420 ms motion — that number is asserted. It also runs
the golden pass §10 asks for by name, booting the shell at compact, medium
and expanded widths and checking that the navigation each one shows agrees
with the other two.

`crud.js` is the CRUD guide's closing checklist, driven the same way: that
every state is reachable rather than illustrated, that create and edit
preserve input after a failure, that leaving a changed form asks first,
that a newer version is never silently overwritten, that master-detail
collapses safely below expanded width, and that delete behaviour matches
whether recovery is actually possible.
