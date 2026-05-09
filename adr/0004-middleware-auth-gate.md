# ADR-0004 — Middleware-based auth gate

**Status:** Accepted

## Context

Almost every route in our apps is auth-gated. Per-page guards are easy to forget and create hydration mismatches. Supabase recommends a middleware-driven session refresh.

## Decision

- A root-level `middleware.ts` enforces auth on every request.
- Pattern:
  1. Construct a server Supabase client with a cookie jar bound to the response.
  2. Call `supabase.auth.getUser()` to refresh the session.
  3. If the request path is **not** in the public allowlist and there is no user → redirect to `/`.
  4. If the request path **is** `/` and there is a user → redirect to the app's home route (e.g. `/work-log`, `/huddles`, `/dashboard`).
- Public routes are an explicit allowlist (auth pages, marketing, embeds, static assets) — default-deny.
- The matcher excludes `_next/static`, `_next/image`, and common file extensions.
- Heavier middleware logic (CSP for embed routes, etc.) lives in `src/lib/supabase/middleware.ts` so `middleware.ts` itself stays scannable.

## Consequences

- Adding a new public route requires updating the allowlist — this is intentional.
- The middleware runs on every request, including static fetches that match the matcher; keep it cheap.
- Auth state on the server can rely on `supabase.auth.getUser()` returning the freshly-refreshed user.
