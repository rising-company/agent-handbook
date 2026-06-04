# ADR-0010 — Data retention and disposal policy

**Status:** Accepted

## Context

Our apps store user data — profiles, content, uploads, and the audit trail of how people use the product — in Supabase Postgres, Storage, and `auth.users`. Without a policy, that data accumulates indefinitely: deleted accounts leave orphaned rows and files, expired sessions linger, and we hold personal data long after any business reason to keep it. That is both a privacy-regulation problem (GDPR/CCPA require honoring erasure requests and not retaining personal data beyond its purpose) and a security one — data we no longer need is breach surface we gain nothing from carrying.

This is the data-lifecycle companion to the [security assurance baseline](0009-security-assurance-baseline.md): ADR-0009 governs *who can touch data*; this ADR governs *how long data lives and how it is destroyed*. Every Rising Company app and project (`os`, `huddle`, `venue-map`, …) is held to the baseline below. The organizing principle is **data minimization** — keep the least data, for the shortest time, that the product actually needs.

## Decision

Every project must satisfy the following baseline:

1. **Every store has a documented retention class.** Each user-data table and storage bucket declares what it holds, whether it contains personal data, and how long it is kept (e.g. `indefinite-while-account-active`, `90-days`, `session-lifetime`). Undocumented data has no place to live — if it is worth storing, its retention is worth stating.
2. **Retention is bounded by purpose.** Keep data only as long as it serves the purpose it was collected for. Logs, analytics events, and other operational/ephemeral data get a short, explicit window (default 90 days unless a longer period is justified) and are purged after it.
3. **Account deletion is a first-class path.** Users can request erasure, and deleting an `auth.users` record cascades to all of that user's data — Postgres rows via `ON DELETE CASCADE` (or an explicit deletion routine) and their Storage objects. No personal data outlives the account it belongs to. A deletion request is honored within 30 days.
4. **Disposal is irreversible, after a bounded grace window.** Where soft-delete (e.g. `deleted_at`) is used for undo/recovery, it is a short window (default 30 days), after which the row and its dependents are **hard-deleted** — not left flagged forever. Soft-deleted records are excluded from normal queries via RLS/filters so they are inaccessible during the window.
5. **Storage objects are disposed with their owning rows.** Deleting a record deletes the files it references in the same operation; no bucket cleanup is left as a manual afterthought. Orphaned objects are a retention bug.
6. **Purging is automated, not manual.** Retention windows are enforced by a scheduled job (`pg_cron` or an equivalent scheduled routine), not by someone remembering to run a script. The job is idempotent and logged so its runs are auditable.
7. **Backups have a stated, bounded retention.** Supabase's automated backups are a separate copy of the data — their retention window is documented, and the policy notes that erased data ages out of backups within that window rather than being individually scrubbed from each snapshot.
8. **Non-production data is ephemeral by construction.** Preview-branch databases are torn down with their PR (per [ADR-0002](0002-supabase-backend.md)), and local/preview environments are seeded with demo data, never a copy of production personal data.

A deliberate exception to any control above requires a new ADR that supersedes the relevant part of this one — not an inline override. Cascade and purge behavior is schema, so it ships as migrations under [ADR-0007](0007-migration-immutability.md) and is covered by the same tests.

## Consequences

- New tables and buckets are incomplete until their retention class and disposal path are defined — this is intentional friction, the data-lifecycle counterpart to RLS being insecure-by-default in ADR-0009.
- Cascade rules and purge jobs are part of the schema, so they are written as migrations, reviewed, and verified by `db:reset` like any other DDL.
- The [new-project checklist](../checklists/new-project-checklist.md) gains a retention/disposal line: confirm cascades, the purge job, and the account-deletion path exist before a project handles real user data.
- Honoring an erasure request is a routine, mostly-automated operation rather than a bespoke scramble, because deletion cascades and backup expiry are designed in from the start.
