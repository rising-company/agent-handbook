# ADR-0018 — Design system: tokens in CSS, two themes, three faces

**Status:** Accepted
**Date:** 2026-11-05
**Supersedes:** ADR-0005 (Rising Company Design System, Tailwind 4)

## Context

ADR-0005 said each product's `tailwind.config.ts` mirrors the tokens. It also
fixed the aesthetic as dark HUD and listed two font faces. The design system
has since changed all three, and the apps followed it rather than the ADR.

- **Tokens moved into CSS.** The design system ships `rising.css`, and every
  app defines its tokens in `globals.css` with Tailwind 4's `@theme`. None of
  their stylesheets loads `tailwind.config.ts`; Tailwind 4 reads a JS config
  only through an explicit `@config`, so the copies in `os`, `huddle`, `safe`
  and `id` are no longer used.
- **There are two themes.** Mission (dark) is for operator surfaces. Daylight
  (light) is for anything a stranger sees first.
- **There are three faces.** IBM Plex Sans became the text face. Rajdhani is
  for titles only and Share Tech Mono is for readouts.
- **Motion became required.** Animations are built on Motion (motion.dev).

ADR-0005 also copied token values (colours, spacing, radii) into the ADR. Those
copies drifted: the spacing list predates the 96px landing-section step and the
`control` radius.

## Decision

- **<https://design-system.rising.company/llms.txt> is the only token
  reference.** This ADR does not repeat token values, so it cannot drift from
  them. Fetch `llms.txt` before touching colour, type, spacing, radius or motion.
  Do not invent tokens; propose them in the design-system repo.
- **Tokens live in CSS.** Vendor `rising.css` into the app, either the whole
  file (`huddle` keeps it as `src/app/rising.css`) or the rules you use (`os`
  and `safe` keep them in `globals.css`). Note at the top of the vendored copy
  anything you changed and why. Map its variables to Tailwind utilities with `@theme` in
  `globals.css`. Do not create a `tailwind.config.ts`. Pin `tailwindcss@^4` and
  `@tailwindcss/postcss@^4`.
- **Each product picks a default theme by audience**, using the rules in
  `llms.txt` ("Picking a theme"). Apply it with `data-theme` on `<html>`,
  rendered on the server. `data-theme="auto"` is opt-in.
- **Three faces, one job each:** Rajdhani for titles, IBM Plex Sans for text,
  Share Tech Mono for readouts. Load them with the import URL in `llms.txt`
  or the `next/font` equivalent.
- **Motion is built on Motion (motion.dev),** and reduced motion is honoured.
  React products get the motion scale and `MotionProvider` from `@rising/ui`
  ([ADR-0016](0016-react-components-base-ui.md)).

## Consequences

- Remove the unused `tailwind.config.ts` from `os`, `huddle`, `safe` and `id`
  when each next touches its styles.
- `rising.css` is vendored, so updates are pulled by hand: diff the app's copy
  against the design system's and reconcile. This is the same manual pull
  ADR-0005 described, at the file level instead of the token level.
- A product that shows strangers a black screen at sign-in is off-standard,
  even if its app behind the login is Mission.
- ADR-0016's amendment to ADR-0005 carries over unchanged: React products also
  install `@rising/ui` for components that carry behaviour.
