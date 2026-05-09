# ADR-0005 — Rising Company Design System (Tailwind 4)

**Status:** Accepted

## Context

We want a consistent visual language across `os`, `huddle`, `venue-map`, and future apps. Diverging palettes, fonts, and spacing scales fragment the brand and waste design effort.

## Decision

- The canonical design tokens live in the public design system. Primary references:
  - <https://design-system.rising.company/> — browsable site (components, examples, narrative docs)
  - <https://design-system.rising.company/llms.txt> — full token reference for LLMs (colors, fonts, spacing, text styles, components)
  - Source repo: <https://github.com/rising-company/design-system>
- The aesthetic is **mission-control / technical HUD**: dark backgrounds, monospace system labels, mint-green accents, generous spacing.
- Implementation:
  - **Tailwind CSS 4** (`tailwindcss@^4`) with `@tailwindcss/postcss@^4`.
  - `tailwind.config.ts` mirrors the tokens in `llms.txt` — colors (`base`, `surface`, `mint`, `accent-blue`, `danger`, `warning`), spacing (`page: 48px`, `section: 32px`, `element: 24px`, `grid: 16px`, `inline: 12px`, `tight: 8px`), borderRadius (`card: 6px`, `tooltip: 4px`, `badge: 3px`), fontFamily (Rajdhani for display, Share Tech Mono for system text).
  - Fonts loaded via Google Fonts: `Share+Tech+Mono` and `Rajdhani:wght@300;500;700`.
- When in doubt, **fetch <https://design-system.rising.company/llms.txt> first** — it is the source of truth. Do not invent new tokens; propose additions in the design-system repo instead.

## Consequences

- New projects copy the tailwind config from this template; updates flow from the design-system site into `tailwind.config.ts` per project.
- One-off color or spacing values in components are a smell — reach for a token first.
- The design system is a public site, not an npm package — there is no version pin. When tokens drift, pull from `llms.txt` and reconcile.
