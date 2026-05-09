# ADR-0007 — Migration immutability and local-first DB workflow

**Status:** Accepted

## Context

Schema drift between local, preview, and production databases has bitten us. Editing a migration after it has been applied anywhere produces silent divergence — the file no longer matches the schema it created.

## Decision

- Schema changes happen **only** through migration files in `supabase/migrations/`.
- **Migrations are immutable once merged.** Never edit a merged migration; create a new one instead.
- Workflow for any schema change:
  1. `npm run migration:new <name>` to create a numbered migration file.
  2. Write the SQL.
  3. `npm run db:reset` locally — this drops and re-runs every migration plus `seed.sql`. If a reset succeeds, the migration is reproducible from scratch.
  4. Open the PR. Vercel + Supabase spin up a preview branch and run the migration against it.
  5. Merge → migration runs against production via the integration.
- File naming: zero-padded numeric prefix + snake-case description (e.g. `0007_add_huddle_votes.sql`). Pick a prefix width when starting a project and keep it consistent.
- `seed.sql` is **local-only** demo data — not a migration, never runs in preview/prod.

## Consequences

- A "fix" to a recent migration means a follow-up migration, even if the original hasn't shipped to production yet (it has likely run on a teammate's local DB).
- `db:reset` must always succeed on `main` — a broken reset blocks every developer.
- Squashing migrations periodically is allowed but is itself a coordinated event, not a casual cleanup.
