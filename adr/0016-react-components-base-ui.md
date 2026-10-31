# ADR-0016 — Shared React components in `@rising/ui`, built on Base UI

**Status:** Accepted (2026-10-31). Amends the "not an npm package" consequence of
[ADR-0005](0005-rising-design-system.md) for React products. Supersedes decision 2
("CSS and markup only") of the design system's 2026-10-21 components design doc.

## Context

The design system shipped tokens, `rising.css` and markup recipes in `llms.txt`,
and every product's agent rebuilt the behaviour from the spec. The copies drifted:

- `lib/motion.ts` and `components/motion.tsx` are copied verbatim into `os`,
  `huddle`, `safe` and `venue-map`. A change to the motion scale is four PRs.
- `huddle` and `venue-map` each hand-roll the App Shell user menu. Neither gives
  its items `role="menuitem"`, moves between them with the arrow keys, or returns
  focus to the trigger on Escape. Those are ADR-0011 gaps, written twice.
- `badge`, `eyebrow` and `page-header` already differ between products, and a
  design-system rollout (the 2026-10-24 text-face round) touched about 17 repos
  by hand.

The parts that went wrong were behaviour: focus, keyboard, ARIA, positioning and
exit animation. The parts the spec handles well are looks and layout.

## Decision

- **React products install `@rising/ui`** from the design-system repo (`react/`),
  for components that carry behaviour. Its first release has the motion scale,
  `MotionProvider`/`Reveal`, and `UserMenu`.
- **Native first.** If the platform does the job with no script (`<dialog>`, a
  checkbox with `role="switch"`, radios, `<details>`), the system ships CSS and
  markup only, and the package has no wrapper for it. This keeps the
  native-elements rule from the components design doc and ADR-0011.
- **Otherwise, start from [Base UI](https://base-ui.com)** (`@base-ui/react`).
  That covers menus, popovers, tooltips, toasts, select and combobox. Don't
  hand-roll a focus trap, a roving tabindex or anchor positioning. Base UI is
  unstyled and accessible, it has an active team, and its `render` prop lets
  Motion own the animation. We don't start from shadcn/ui: its styling is
  Tailwind in its own token vocabulary, which we'd throw away, and its copy-in
  distribution is how the drift started.
- **Motion through `render`.** A popup that unmounts uses a controlled `open`,
  `AnimatePresence` around a `keepMounted` portal, and a `motion.div` popup on
  the scale in `@rising/ui/motion`. Exits fade, so Base UI detects them.
- **The package renders `rising.css` classes and ships no CSS.** `llms.txt`
  stays the source of truth. A component needing a new rule adds it to
  `rising.css` and `llms.txt` first, and products pick it up as they do today.
- **Distributed as immutable tarballs on the site.** `npm run release` packs
  `ui/rising-ui-<version>.tgz`, which the site serves at
  `https://design-system.rising.company/ui/`. A product pins that URL; npm checks
  its integrity. A published version is never overwritten. `react`, `react-dom`
  and `motion` are peer dependencies, so the product's `MotionProvider` drives
  the package's animations.
- **A component moves into the package when a second product needs it.** Until
  then it's built in the product from `llms.txt`, on Base UI where the rules
  above say so.
- **Tests:** the package follows ADR-0006 with `environment: "jsdom"`, the config
  change ADR-0006 anticipated. It uses Testing Library and an axe check per
  component (ADR-0011).

## Consequences

- A design-system change to a shared component becomes one release plus a URL
  bump per product, instead of a hand-made PR per product.
- Non-React surfaces (static sites, `true-cost-to-phone`) are unaffected. They
  keep `rising.css` and the markup recipes.
- Base UI is now a dependency of every React product, and its upgrades go
  through the package, not each product.
- The package's API is a contract. Renaming a prop or a class is a new version,
  and products move when they bump.
- An agent building UI in a React product checks `@rising/ui` before building
  from `llms.txt`.
