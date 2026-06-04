# ADR-0009 — Security assurance baseline

**Status:** Accepted

## Context

Our apps are auth-gated, store user data in Supabase, and mutate through Server Actions. Security cannot be a per-project afterthought decided case by case — we need one baseline that every Rising Company app and project (`os`, `huddle`, `venue-map`, …) is held to, plus a way to verify it before code merges. This ADR collects the controls that were previously implicit across ADR-0002, ADR-0003, and ADR-0004 into a single standard, and makes verification a merge gate.

The organizing principle is **[Zero Trust Architecture](https://www.thoughtworks.com/en-us/radar/techniques/summary/zero-trust-architecture) — "never trust, always verify."** There is no trusted internal perimeter: every request is authenticated and authorized at the point it touches data, access is least-privilege, and credentials are short-lived. Thoughtworks calls these non-negotiable defaults regardless of the system being built — and increasingly so as our apps gain AI agents that act with autonomy against sensitive data. The controls below are that principle applied to our stack.

## Decision

Every project must satisfy the following baseline:

1. **RLS is the authorization boundary.** Row Level Security is enabled on every user-data table, default-deny, with explicit policies (owner CRUD, public read where intended, service-role for system writes). Access control is enforced in the database — never on the client. (Reinforces ADR-0002 and the [new-project checklist](../checklists/new-project-checklist.md).)
2. **Server Actions are untrusted endpoints.** Every action re-authenticates the caller (`supabase.auth.getUser()`) and validates and authorizes its input server-side. A `"use server"` function is reachable by anyone — treat it like a public API, not a trusted internal call (ties to ADR-0003).
3. **Secrets stay server-only.** The service-role key and all other secrets never reach the browser. Only `NEXT_PUBLIC_`-prefixed values are client-exposed; everything else is server-side. No secrets are committed to the repo.
4. **Supabase security advisors must be clean.** Run the security advisors (`get_advisors`, type `security` — RLS gaps, exposed views, `SECURITY DEFINER` issues, etc.) and resolve every finding before merge.
5. **Security review before merge.** Run `/security-review` over each branch's diff. Triage every finding as fix-or-justify; an unaddressed finding blocks the merge.
6. **Dependency hygiene.** Dependencies are pinned (per ADR-0001/0002/0006). Review advisories when bumping, and prefer the smallest bump that resolves a known vulnerability.
7. **Security headers on public surfaces.** Embed and other publicly reachable routes set appropriate headers (CSP, etc.) in middleware (per ADR-0004).
8. **Least privilege, short-lived credentials.** Grant the narrowest access that works — scoped database roles, RLS policies, and storage rules rather than blanket access. Prefer short-lived, identity-verified tokens over long-lived static secrets: CI/CD authenticates to cloud and Supabase via OIDC / workload identity where supported, not stored API keys. This applies to AI agents too — an agent gets its own least-privilege identity, never a shared or elevated one.

Controls 4 and 5 are **required merge gates**: clean security advisors and a completed `/security-review` are preconditions for merging. A deliberate exception to any control above requires a new ADR that supersedes the relevant part of this one — not an inline override.

## Consequences

- New tables and Server Actions are insecure-by-default until RLS and server-side checks are added; this is intentional friction.
- The [new-project checklist](../checklists/new-project-checklist.md) and `/security-review` become part of the merge path, not optional extras.
- Security advisors are run against the Supabase project (preview branch or production target) as part of pre-merge verification, so schema changes that break RLS are caught before they ship.
- Carrying these controls in one ADR means a project's security posture can be audited against a single list rather than reconstructed from four separate decisions.
