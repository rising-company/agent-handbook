# Project guidelines

## Architecture

This project follows the Rising Company shared architecture. Each decision below is captured as an ADR — read them before making structural changes.

- [ADR-0001 — Next.js App Router + React 19 + TypeScript strict](adr/0001-nextjs-react-typescript-stack.md)
- [ADR-0002 — Supabase as backend (auth, data, storage)](adr/0002-supabase-backend.md)
- [ADR-0003 — Server Actions for mutations (no REST/API routes)](adr/0003-server-actions-for-mutations.md)
- [ADR-0004 — Middleware-based auth gate](adr/0004-middleware-auth-gate.md)
- [ADR-0005 — Rising Company Design System (Tailwind 4)](adr/0005-rising-design-system.md) — tokens at <https://design-system.rising.company/> ([llms.txt](https://design-system.rising.company/llms.txt))
- [ADR-0006 — Vitest with `node` environment, tests/ folder](adr/0006-vitest-tests-layout.md)
- [ADR-0007 — Migration immutability and local-first DB workflow](adr/0007-migration-immutability.md)
- [ADR-0008 — Branding via `src/lib/config.ts`](adr/0008-branding-config.md)

See [`adr/README.md`](adr/README.md) for the full index. Deviating from an ADR is allowed but should add a new ADR that supersedes the old one.

## Development workflow

### Red-green development (always)

Follow strict red-green-refactor for every change:

1. **Red** — write a failing test that captures the desired behavior. Run it and confirm it fails for the *right reason* (assertion failure, not import error or typo).
2. **Green** — write the smallest amount of code that makes the test pass. Resist the urge to add anything beyond what the test requires.
3. **Refactor** — clean up only after the test is green. Tests stay green throughout.

Rules:
- No production code without a failing test first.
- One failing test at a time. Don't write multiple tests up-front.
- If you find yourself wanting to write code without a test, stop and write the test.
- When fixing a bug, the first step is a failing test that reproduces it.

## UI testing

### Use the browser agent skill for end-to-end UI verification

For any change that affects the UI (components, routes, styles, user-facing behavior), use the browser agent skill to drive the app end-to-end before reporting the task complete.

- Exercise the golden path *and* the edge cases of the change.
- Watch for regressions in adjacent features, not just the one you touched.
- Type checks and unit tests verify code correctness, not feature correctness — they are not a substitute for actually using the feature.
- If the browser agent is unavailable or the change can't be exercised in a browser (e.g. backend-only), say so explicitly rather than claiming UI verification.
