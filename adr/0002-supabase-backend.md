# ADR-0002 — Supabase as backend (auth, data, storage)

**Status:** Accepted

## Context

We need auth, a relational database, file storage, and the ability to spin up preview environments per pull request. Building these ourselves is not the point of the business.

## Decision

- **Supabase** is the single backend. Use it for auth, Postgres, storage, and (where useful) realtime + edge functions.
- Pinned versions:
  - `@supabase/ssr` `^0.10.2`
  - `@supabase/supabase-js` `^2.104.1`
- Local dev runs Supabase via Docker (`supabase start`); migrations live in `supabase/migrations/`.
- Three-tier environment topology, integrated with Vercel:
  1. **Local** — Docker-hosted Supabase, seeded with demo data.
  2. **Preview** — ephemeral Supabase branch per PR, auto-provisioned by the Vercel ↔ Supabase integration.
  3. **Production** — the long-lived project.
- Supabase clients live in `src/lib/supabase/`:
  - `client.ts` — browser client
  - `server.ts` — server component / action client (cookie-aware)
  - `middleware.ts` — middleware client (see ADR-0004)
- The seed file (`supabase/seed.sql`) is **local-only** — it must never run in preview or production.

## Consequences

- Every project has a `supabase/` directory checked into the repo.
- Schema changes flow through migrations only (see ADR-0007).
- We bind ourselves to Supabase's Postgres flavor (RLS, `auth.users`, storage buckets) — escape hatch is a manual extraction.
