# ADR-0011 — Accessibility assurance

**Status:** Accepted

## Context

Our apps are user-facing React UIs built on the Rising Company Design System ([ADR-0005](0005-rising-design-system.md)). Accessibility regressions — missing labels, poor contrast, non-focusable controls, broken keyboard paths — are easy to introduce and invisible until someone using a screen reader or keyboard hits them. Caught at review time they are cheap; caught in production they are a usability failure and, for many of our customers, a legal-compliance one. Like security ([ADR-0009](0009-security-assurance-baseline.md)) and data retention ([ADR-0010](0010-data-retention-disposal.md)), accessibility cannot be a per-project afterthought decided case by case — it needs one baseline that every UI-bearing Rising Company app is held to, enforced automatically before code merges.

The engine is **[axe-core](https://github.com/dequelabs/axe-core)** (Deque, MPL-2.0): an accessibility testing engine that checks against **WCAG 2.2 level A and AA** (plus 2.0/2.1 and best-practice rules). It is the de-facto standard, designed for zero false positives, so a violation it reports is real. The honest caveat shapes this policy: axe-core finds roughly **57% of WCAG issues automatically** — the automated gates below are a *floor that blocks known-bad*, not a substitute for the manual keyboard-and-screen-reader pass that the `agent-browser` UI verification workflow (see CLAUDE.md) covers.

## Decision

Every project that renders a UI must satisfy the following baseline. (Backend-only or library projects are exempt but must state so — see consequence below.)

1. **Three automated layers, axe-core where it sees the DOM.** Accessibility is checked at three points, each catching what the layer above cannot:
   - **Static (lint):** `eslint-plugin-jsx-a11y` runs in the standard ESLint config, flagging the markup-level mistakes (missing `alt`, label-less inputs, bad ARIA) that need no DOM.
   - **Component:** `vitest-axe` (axe-core under Vitest) asserts `toHaveNoViolations()` on rendered components. This needs the JSDOM environment, which ADR-0006 already treats as a config change, not a runner change.
   - **End-to-end:** axe-core runs against the *running* app — via `@axe-core/playwright` or injected through the `agent-browser` workflow — to scan fully-composed routes, where contrast and cross-component issues only then become visible.
2. **Pre-commit catches early.** A pre-commit hook (Husky + lint-staged) runs the static a11y lint over staged files, and the relevant `vitest-axe` component tests, so a contributor sees violations before the commit lands rather than in CI minutes later. The hook is fast by scoping to staged files.
3. **CI is the enforced gate.** CI runs the full a11y suite — lint, `vitest-axe` component tests, and the axe-core end-to-end scan of key routes — and **a new violation fails the build.** As with ADR-0009's security gates, this is a required merge gate: an unaddressed accessibility violation blocks the merge. Pre-commit is the early warning; CI is the wall.
4. **Standard and scope are explicit.** The conformance target is **WCAG 2.2 AA**. Every primary user-facing route is covered by at least one end-to-end axe scan; new routes add their scan as part of the feature.
5. **Automation is a floor, not the finish line.** Passing axe-core does not mean "accessible." UI changes still get the manual keyboard-navigation and screen-reader pass described in the `agent-browser` workflow before being called done.

A deliberate exception — a specific rule disabled, a route excused — requires a new ADR that supersedes the relevant part of this one, not an inline `eslint-disable` or skipped test left unexplained.

## Consequences

- UI projects gain three dev dependencies and config (`eslint-plugin-jsx-a11y`, `vitest-axe`, `@axe-core/playwright` or the `agent-browser` integration) plus a Husky/lint-staged pre-commit hook.
- Adding `vitest-axe` is the JSDOM-environment addition ADR-0006 anticipated; component a11y tests live in `tests/` alongside the rest.
- A new accessibility violation breaks CI exactly like a failing unit test — accessibility becomes part of "the build is green," not a separate audit.
- Backend-only repos must record their exemption (a line in the project README or new-project checklist), so an empty a11y suite reads as "intentionally not a UI app" rather than "forgot to set this up."
- The [new-project checklist](../checklists/new-project-checklist.md) gains an accessibility line: confirm the lint rule, component-test setup, e2e scan, and pre-commit hook exist before a UI project ships.
