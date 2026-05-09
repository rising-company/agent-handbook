# ADR-0003 — Server Actions for mutations (no REST/API routes)

**Status:** Accepted

## Context

Form submissions, button-triggered writes, and other state changes need to run server-side with access to the authenticated user. The two options in App Router are route handlers (`app/api/.../route.ts`) and server actions (`"use server"` functions). We do not have external API consumers — only our own UI talks to the server.

## Decision

- **All mutations go through server actions** under `src/actions/`.
- One file per domain (e.g. `src/actions/huddles.ts`, `src/actions/votes.ts`).
- Each file starts with `"use server"` at the top.
- Route handlers (`app/api/.../route.ts`) are reserved for genuine HTTP endpoints (webhooks, third-party callbacks, cron). They are not the default mutation path.

## Consequences

- No client-side `fetch('/api/...')` for our own mutations — call the action directly.
- Cache revalidation uses `revalidatePath` / `revalidateTag` inside actions.
- Tests for actions live in `tests/actions/` (see ADR-0006) and exercise the action function directly with a test Supabase client.
- If we ever expose an external API, it goes under `app/api/v1/...` and is documented separately — server actions are not part of any public contract.
