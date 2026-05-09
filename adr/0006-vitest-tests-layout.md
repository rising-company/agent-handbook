# ADR-0006 — Vitest with `node` environment, tests/ folder

**Status:** Accepted

## Context

We need fast unit tests for `lib/` helpers and server actions. Jest's startup cost and config sprawl are not worth paying. Most of our logic is server-side, so a JSDOM environment would be dead weight.

## Decision

- **Vitest 4** (`vitest@^4.1.5`) is the test runner.
- `@vitejs/plugin-react@^6.0.1` is included so `.tsx` tests work when needed.
- `vitest.config.ts`:
  - `environment: "node"` (no JSDOM)
  - `resolve.alias` mirrors the `@/*` path alias
  - `include` covers `tests/**/*.test.ts` and `tests/**/*.test.tsx`
- Tests live in **`tests/`** at the repo root, organized to mirror `src/` (e.g. `tests/lib/`, `tests/actions/`) **or** by domain when a feature spans multiple folders (e.g. `tests/geo/`, `tests/nominatim/`). Pick whichever is clearer for the feature.
- Naming: `*.test.ts` / `*.test.tsx`.
- End-to-end UI testing is **not** Vitest's job — see CLAUDE.md for the browser-agent workflow.

## Consequences

- A failing build means failing unit tests; CI runs `vitest run` (not `--watch`).
- Server actions are testable as plain async functions — the `"use server"` directive does not interfere with Vitest.
- Adding component tests later (with JSDOM) is a config change, not a runner change.
