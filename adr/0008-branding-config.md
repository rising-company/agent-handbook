# ADR-0008 — Branding via `src/lib/config.ts`

**Status:** Accepted

## Context

The same codebase is sometimes deployed under different brands, and even within one brand the app name, tagline, and domain show up in dozens of places (page titles, emails, OG tags, footers). Hardcoded strings make rebrands and white-labeling painful.

## Decision

- All brand-facing strings live in **`src/lib/config.ts`**, read from environment variables with sensible defaults.
- Typical fields: `appName`, `tagline`, `domain`, `supportEmail`, `companyName`.
- Components, metadata, and emails import from `@/lib/config` — they never hardcode "Rising OS", "Rising Company", "rising.company", etc.
- Environment variables are documented in `.env.example` and surfaced through `NEXT_PUBLIC_*` prefixes when needed in the browser.

## Consequences

- A rebrand or white-label deploy is a config change, not a code change.
- Reviewers should reject PRs that introduce hardcoded brand strings.
- Tests that assert on user-visible copy should pull from `config.ts` too, not duplicate the strings.
