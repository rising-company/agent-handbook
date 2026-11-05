# ADR-0017 — Convex as backend (data, functions, storage)

**Status:** Accepted
**Date:** 2026-11-05
**Supersedes:** ADR-0002 (Supabase as backend), ADR-0007 (migration immutability)

## Context

ADR-0002 made Supabase the single backend and named its own escape hatch: "a
manual extraction." Every Rising Company app has since taken that hatch. Each
recorded the move locally — `os` ADR-0012, `safe` ADR-0017, `venue-map`
ADR-0001 — and `huddle` followed. None of it reached the handbook, so ADR-0002
went on telling new projects to start on a backend that no app uses.

The reasons were consistent. Authorization written as RLS policies could not be
unit-tested without a running database. Realtime needed channel and reconnect
plumbing. Local development needed a Docker stack.

## Decision

- **Convex** is the backend: database, server functions (queries, mutations,
  actions), scheduling and file storage. Pin `convex` `^1.45.0` for new projects.
  Existing apps converge under ADR-0001's lockstep rule.
- **Identity is not Convex's job.** Sign-in lives at `id.rising.company`
  ([ADR-0012](0012-better-auth-central-identity.md)). Each deployment's
  `convex/auth.config.ts` declares that issuer as a `customJwt` provider and
  only validates its tokens. Do not add `@convex-dev/auth`.
- **Schema is one declarative file, `convex/schema.ts`**, applied on deploy.
  There are no migration files.
- **Authorization lives in the functions.** Nothing sits underneath a Convex
  function the way RLS did. Every function that reads or writes user data calls
  a guard first, using the identity from `ctx.auth`, never a user id passed in
  as an argument. Reference: `os` ADR-0013 (`convex/lib/guards.ts`).
- **Three environments, Convex-native:**
  1. **Dev**: a per-developer Convex dev deployment (`npx convex dev`), seeded
     with demo data.
  2. **Preview**: a per-branch Convex preview deployment, created by the Vercel
     build (`convex deploy --preview-name <branch>`). Reference:
     `huddle/scripts/vercel-build.sh`.
  3. **Production**: the long-lived deployment.
- **Layout:** `convex/` holds the schema and functions. `convex/lib/` holds
  guards and pure helpers that both runtimes need. When the app and Convex must
  agree on a calculation, it is defined once there and `src/` re-exports it.
- **Seed data is dev-only.** It never runs against preview or production.

## Consequences

- **No `supabase/` directory, no SQL migrations, no Docker database.** Remove
  `@supabase/ssr` and `@supabase/supabase-js` from the production dependency
  graph.
- **ADR-0007 is superseded.** Its principle still holds: don't rewrite history
  another environment has already applied. It now covers schema changes. A
  change that existing documents don't satisfy (a new required field, a narrowed
  type) ships in steps. Widen the schema, backfill, then narrow.
- **ADR-0009 is amended:**
  - Control 1 (RLS is the boundary) becomes the guard rule above.
  - Control 2 re-authenticates through the Convex identity, not
    `supabase.auth.getUser()`.
  - Control 4 (clean Supabase advisors) has no Convex equivalent. As a merge
    gate it is replaced by **refusal-path tests**: every data function has a
    test proving that an unauthenticated or out-of-scope caller is refused,
    not just that the happy path works.
  - Control 5 (`/security-review`) is unchanged.
  - Control 8: CI deploys to Convex with a stored `CONVEX_DEPLOY_KEY`, scoped
    per Vercel environment. No app deploys to Convex through OIDC today, so this is a
    known exception to "prefer short-lived tokens" and the key is rotated on
    any suspicion of exposure.
- **ADR-0010 is amended.** Data lives in Convex tables and Convex file storage,
  and backup retention means Convex's backup policy. Preview deployments are
  ephemeral because they are created per branch.
- **ADR-0003 is unaffected.** Where an app keeps Server Actions, they call
  Convex. Action tests use a Convex client fake instead of a test Supabase
  client.
- **ADR-0006:** Convex functions run in Convex's V8 runtime. Test them with
  `convex-test` under the `edge-runtime` Vitest environment, not `node`.
  Reference: `os` ADR-0015.
- **Functions the Next.js layer calls must be public** (`query`/`mutation`).
  Internal functions are unreachable from outside Convex, and a string reference
  to one compiles fine but fails at runtime (`safe` ADR-0017). A public function
  that is not user-authenticated must authenticate itself, for example with a
  shared secret.
- **CSP `connect-src` must allow `*.convex.cloud` and `*.convex.site`.** The
  browser talks to Convex directly over https and wss.
- **Lost Postgres guarantees** become application code: unique constraints
  (look, then write), `ON DELETE CASCADE` (a delete removes its own
  dependents), and CHECK constraints (literal unions shared between the schema
  and its writers).
- **We are bound to Convex's document model and runtime.** The way out is
  another manual extraction, the same price ADR-0002 paid.
