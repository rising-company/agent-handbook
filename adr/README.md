# Architecture Decision Records

Each ADR captures one decision that is shared across Rising Company projects (`os`, `huddle`, `venue-map`). Deviating from an ADR is allowed but should be deliberate — open a new ADR that supersedes the old one.

## Index

- [ADR-0001 — Next.js App Router + React 19 + TypeScript strict](0001-nextjs-react-typescript-stack.md)
- [ADR-0002 — Supabase as backend (auth, data, storage)](0002-supabase-backend.md)
- [ADR-0003 — Server Actions for mutations (no REST/API routes)](0003-server-actions-for-mutations.md)
- [ADR-0004 — Middleware-based auth gate](0004-middleware-auth-gate.md) — *superseded by ADR-0012*
- [ADR-0005 — Rising Company Design System (Tailwind 4)](0005-rising-design-system.md)
- [ADR-0006 — Vitest with `node` environment, tests/ folder](0006-vitest-tests-layout.md)
- [ADR-0007 — Migration immutability and local-first DB workflow](0007-migration-immutability.md)
- [ADR-0008 — Branding via `src/lib/config.ts`](0008-branding-config.md)
- [ADR-0009 — Security assurance baseline](0009-security-assurance-baseline.md)
- [ADR-0010 — Data retention and disposal policy](0010-data-retention-disposal.md)
- [ADR-0011 — Accessibility assurance](0011-accessibility-assurance.md)
- [ADR-0012 — Better Auth as central identity](0012-better-auth-central-identity.md) — supersedes ADR-0004
- [ADR-0013 — Every product ships a link preview card](0013-link-preview-card.md)

## Format

Each ADR follows: **Status · Context · Decision · Consequences**. Keep them short — one screen if possible.
