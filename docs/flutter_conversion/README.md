# Lume → Flutter conversion

The Lume web prototype is the design. This folder is the record of turning it
into a native Flutter reference application, in
[`flutter_reference/`](../../flutter_reference/), that later moves into the
Dayroz production app without a second restructuring.

The web prototype is not being replaced, ported or tidied. It stays exactly
where it is and stays authoritative: every Flutter screen is measured against
the rendered web screen, not against a description of it.

## The documents

| Doc | What it answers |
|---|---|
| [WEB_TO_FLUTTER_MAPPING.md](WEB_TO_FLUTTER_MAPPING.md) | Every web concept — token, class, layout, route, state — and its Flutter equivalent |
| [DAYROZ_ARCHITECTURE_MAPPING.md](DAYROZ_ARCHITECTURE_MAPPING.md) | How the reference is organised so it can move into Dayroz, and what will need an adapter |
| [COMPONENT_MATRIX.md](COMPONENT_MATRIX.md) | Every shared component, its states, and its conversion status |
| [SCREEN_MATRIX.md](SCREEN_MATRIX.md) | Every screen and all 85 tools, with archetype, gating and conversion status |
| [VISUAL_VERIFICATION.md](VISUAL_VERIFICATION.md) | The capture pipeline, the viewport matrix and how a screen is proved |
| [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md) | Permitted native differences, contradictions found in the sources, and corrections made |
| [BASELINE_F0.md](BASELINE_F0.md) | The measured state of the web prototype before any Flutter work |

## Source-of-truth order

When two sources disagree, the higher one wins and the lower one gets corrected
in place with the reason recorded in [KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md).

1. The rendered Lume web interface
2. Screen and tool JavaScript
3. Screen- and tool-specific CSS
4. Shared components and CSS
5. Design tokens
6. `responsive.css` and `rtl.css`
7. The Lume test suite
8. `LUME_COMPLETE_DESIGN_SPECIFICATION.md`, `LUME_FEATURES_AND_SCREEN_CAPABILITIES.md`,
   `LUME_SCREEN_BASED_REFACTORING_PLAN.md`, and the two `.docx` guides
9. Older notes and assumptions

Dayroz decides **how the Dart is organised**. Lume decides **what the interface
is**. Where Dayroz's existing visual widgets differ from Lume, Lume wins and the
Dayroz widget is not copied.

## Phases

| Phase | Scope | State |
|---|---|---|
| F0 | Baseline, inventory, architecture, folder structure | **complete — awaiting approval** |
| F1 | Flutter project, fonts, tokens, themes, responsive, l10n, capture harness | not started |
| F2 | Shared component library and gallery | not started |
| F3 | Adaptive shell and navigation | not started |
| F4 | Onboarding and authentication | not started |
| F5 | Global screens | not started |
| F6 | Tool screens, by archetype | not started |
| F7 | CRUD system across every record family | not started |
| F8 | Localisation, accessibility, responsive completion | not started |
| F9 | Final parity, cleanup, acceptance report | not started |

Each phase stops for approval. Nothing continues automatically.
