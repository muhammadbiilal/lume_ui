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
