# ADR-0012 — Better Auth as central identity for all Rising Company apps

**Status:** Accepted
**Date:** 2026-09-15
**Supersedes:** ADR-0004 (middleware-based auth gate), `os` ADR-0014 (Rising OS ships without a second factor)

## Context

Four apps — `os`, `huddle`, `safe`, `venue-map` — each run their own
`@convex-dev/auth` instance against their own Convex deployment, with their own
`users` table. There is no shared identity: the same person signing into two
apps is two unrelated accounts.

Each app also rebuilt the same magic-link plumbing independently, and each
rediscovered the same two failures: `signIn` must not await the SMTP round-trip
or the Next.js route 504s, and the auto-redeeming `?code=` URL must be rewritten
to a confirmation page or link-scanner prefetches burn the one-time code. Four
implementations, four divergent fixes, ~1,150 lines of auth UI.

`@convex-dev/auth` has no second factor. `os` ADR-0014 accepted that as a
permanent reduction rather than a gap, on the grounds that the app had two
operators on a restricted email domain, and named its own revisit trigger:
growth beyond those two users, or data whose loss is worse than its contents.
Adding apps to the portfolio is that trigger arriving from the other direction —
the blast radius grew even though the per-app user count did not.

Paid options were priced. Clerk is ~$25/mo (MFA requires Pro) and its native
subdomain session sharing fits our topology; WorkOS AuthKit is free to 1M MAU
but $99/mo for a branded login domain; Logto Cloud is $72/mo because MFA is a
$48 add-on. Self-hosted Logto is $25–50/mo of infrastructure plus ongoing
patching, backups and uptime ownership for an internet-facing auth service.

## Decision

A single Better Auth instance is the identity provider for all Rising Company
apps, deployed as an ordinary Next.js app at **`id.rising.company`** on the
existing Vercel account, backed by its own Postgres (Neon).

- **Session sharing is by cookie, not OIDC.** Every app is a subdomain of
  `rising.company`, so `crossSubDomainCookies` scoped to `.rising.company`
  shares one session across all four. No redirect flow, no client registration,
  no `oauth-provider` plugin.
- **Convex trusts the issuer directly.** Each deployment's `auth.config.ts`
  uses `type: "customJwt"`, which requires only an issuer and a JWKS URL — no
  `/.well-known/openid-configuration`, and the JWKS may live at any path. Better
  Auth's `jwt()` plugin serves it and lets issuer, audience and path be
  configured to match.
- **Sign-in is email magic link *and* password.** This reverses the checklist's
  "passwordless is the default, no password field" rule, which existed to avoid
  the password-reset flow and the leaked-password risk class. A second factor
  covers that risk better than the absence of a password field did.
- **A second factor is available and enforceable.** The `twoFactor()` plugin
  provides TOTP, email/SMS OTP, backup codes and 30-day trusted devices —
  a superset of what Supabase provided before the Convex migration.
- **The IdP is assembled, not implemented.** We own the deployment, the schema
  and the login UI. We do not implement OIDC, password hashing, TOTP
  verification or recovery codes.

Not adopted: the `@convex-dev/better-auth` component. It is built for auth
*inside* one Convex app, which is the opposite shape — its SSO plugin is
explicitly incompatible, `organization`/`passkey`/`admin` need custom schema
work, and it pins `better-auth <1.7` while the current line is 1.7.x.

## Consequences

- **`os` ADR-0014 is reversed.** `MFA_ENFORCED` in `convex/lib/orgAccess.ts` can
  be flipped on once a real assurance claim reaches the guard, and the stage
  deleted from `proxy.ts` must be reinstated. Both operators must enrol an
  authenticator; the old Supabase TOTP secrets are not portable.
- **ADR-0004 no longer describes reality.** The middleware gate stops calling
  `supabase.auth.getUser()` and starts validating a Better Auth session. The
  default-deny allowlist and the matcher exclusions survive unchanged; only the
  session-refresh mechanism is replaced.
- **A `.rising.company` cookie is a trust boundary.** Every subdomain we ever
  host — staging, marketing, a vendor on a CNAME — sits inside the session
  scope. Pointing a third-party CNAME at the apex domain becomes a security
  decision, not a DNS chore. This is the price of skipping OIDC; the
  `oauth-provider` plugin is the upgrade path if we ever need an app off
  `rising.company`.
- **User identity changes in all four apps.** Every app keys rows by
  `@convex-dev/auth` user ids, so each needs a relink pass by email. The pattern
  exists three times already: `os` `legacy_users`, `huddle` `relinkByEmail`,
  `safe` `auth-relink.test.ts`.
- **Better Auth 1.7 is young and has churned.** 1.7 removed `oidc-provider` in
  favour of `@better-auth/oauth-provider` and changed account-identity
  normalization. We depend on `jwt()`, `twoFactor()` and `magicLink()`, not the
  provider plugin, which limits exposure — but upgrades need reading, not
  `npm update`.
- **Marginal hosting cost is ~$0–5/mo** (Vercel seat already paid; Neon free
  tier covers an auth DB at this scale), against $25–50/mo self-hosted Logto or
  $25/mo Clerk. The saving is real but small; the reason to choose this is
  control and stack fit, and it should not be defended on price alone.
- **Tenancy stays in the apps.** `id.rising.company` answers who someone is,
  not what they may do. `os` models organizations and membership in a way
  particular to `os`, and that does not generalise across the portfolio, so the
  `organization()` plugin is deliberately not adopted here — authorization
  remains each app's own concern, reading identity from the token.
- **`id.rising.company` is a single point of failure for every app.** Today a
  Convex outage takes down one app; after this, an IdP outage locks everyone out
  of all four. Convex can validate tokens without reaching the IdP (JWKS may be
  inlined as a `data:` URI), which limits this to sign-in rather than all
  traffic.

## Still open

Handbook ADR-0002 (Supabase as backend) has been dead in practice since all four
apps moved to Convex — recorded in `os` ADR-0012, `safe` ADR-0017 and
`venue-map` ADR-0001, but never upstreamed. It needs its own ADR; this one does
not cover it.
