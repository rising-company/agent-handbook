# ADR-0001 — Next.js App Router + React 19 + TypeScript strict

**Status:** Accepted

## Context

All Rising Company web apps are server-rendered, auth-gated, and share a small team. We need a stack that gives us SSR, file-based routing, server-side secret handling, and strong type safety without bespoke infra.

## Decision

- **Next.js 16.2.4** with the **App Router** (`src/app/`).
- **React 19.2.4** + **react-dom 19.2.4**.
- **TypeScript 5** with `"strict": true`.
- Path alias **`@/*` → `./src/*`** in `tsconfig.json`.
- **ESLint 9** with `eslint-config-next@16.2.4` (`core-web-vitals` + `typescript` rule sets).
- Standard layout under `src/`:
  - `app/` — routes, layouts, route handlers
  - `components/` — shared UI
  - `lib/` — framework-agnostic helpers, Supabase clients
  - `actions/` — server actions (see ADR-0003)

## Consequences

- Lockstep upgrades: bumping Next.js or React in one project is a signal to bump the others.
- App Router idioms (server components by default, `"use client"` opt-in) apply throughout.
- `@/` imports — never use deep relative paths (`../../../`).
