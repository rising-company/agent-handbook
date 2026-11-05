# New project checklist

Use when bootstrapping a new Rising Company app, or auditing an existing one against the shared baseline. Each item links to the ADR that explains the *why*.

The reference projects are [`os`](https://github.com/rising-company/os), [`huddle`](https://github.com/rising-company/huddle), and [`venue-map`](https://github.com/rising-company/venue-map). When in doubt, copy from the most recent one.

## Stack & tooling

- [ ] **Next.js + React + TypeScript stack** matches [ADR-0001](../adr/0001-nextjs-react-typescript-stack.md). Pin to the same versions the other projects use (`next@16.2.4`, `react@19.2.4`, `typescript@^5`); don't drift.
- [ ] **`tsconfig.json`** has `strict: true`, `target: "ES2022"`, `allowJs: false`, `moduleResolution: "bundler"`, and the `@/*` → `./src/*` path alias.
- [ ] **`eslint.config.mjs`** uses flat-config (`eslint@^9`) with `eslint-config-next/core-web-vitals` + `eslint-config-next/typescript`.
- [ ] **`vitest.config.ts`** sets `globals: true`, `environment: "node"`, and the same `@/*` alias as `tsconfig.json` ([ADR-0006](../adr/0006-vitest-tests-layout.md)).

## Design system

- [ ] **Tokens come from the design system** ([ADR-0005](../adr/0005-rising-design-system.md)). Fetch <https://design-system.rising.company/llms.txt> before touching colors, spacing, fonts, or radii. Don't invent tokens.
- [ ] **`tailwind.config.ts`** mirrors the canonical tokens (mint / accent-blue / danger / warning, page/section/element/grid/inline/tight spacing, Rajdhani + Share Tech Mono fonts).
- [ ] **`src/app/globals.css`** declares the `@theme` block and loads Google Fonts for Rajdhani + Share Tech Mono.
- [ ] **No one-off colors, spacings, or fonts** in components. If you need one, propose it upstream in the design-system repo instead.

## Branding & metadata

- [ ] **`src/app/icon.svg`** ships the Rising logo (1145-byte SVG used by `os`, `huddle`, `venue-map`). Copy it as-is unless the project has its own brand.
- [ ] **`src/app/apple-icon.png`** present (180×180).
- [ ] **Link preview card shipped** — required of every Rising product, same standing as the
  rising.company backlink ([ADR-0013](../adr/0013-link-preview-card.md); spec: "Link Preview
  Card (required branding)" in <https://design-system.rising.company/llms.txt>, template:
  `patterns/og-card.html`). The card makes the product's argument out of the product's own
  data — a wordmark on a colored rectangle does not count. 1200 × 630 CSS px, Daylight always,
  shot at 2× to a 2400 × 1260 PNG. Next.js: `src/app/opengraph-image.tsx` (`ImageResponse`,
  `size = { width: 1200, height: 630 }`).
- [ ] **Preview tags complete and absolute** — `canonical`, `description`, `og:type`,
  `og:site_name`, `og:url`, `og:title`, `og:description`, `og:image`, `og:image:width`,
  `og:image:height`, `og:image:alt`, `twitter:card=summary_large_image`, `twitter:title`,
  `twitter:description`, `twitter:image`. `og:title` is the card's headline, not the page title.
- [ ] **`og:image` carries a `?v=YYYY-MM-DD` stamp** on non-Next.js products, bumped in the same
  commit that replaces the PNG. Scrapers cache `og:image` by URL; without a new stamp Slack,
  Facebook and X keep serving the old card for days. (Next.js content-hashes the URL for you.)
- [ ] **A test pins the card** where it is built from product data: the numbers printed on the
  committed PNG against what the data now produces, and the stamp against the data's own
  timestamp. Moving the data without regenerating the card should fail a test, not ship a stale
  share. Reference implementation: `true-cost-to-phone/tests/og.test.mjs`.
- [ ] **`src/app/manifest.ts`** (or `manifest.json`) defines name, short_name, theme color.
- [ ] **`src/lib/config.ts`** is the single source for `appName`, `tagline`, `domain`, `supportEmail`, `companyName`, etc., read from env with sensible defaults ([ADR-0008](../adr/0008-branding-config.md)).
- [ ] **No hardcoded brand strings** in components, metadata, or emails — everything imports from `@/lib/config`.
- [ ] **Root `layout.tsx`** populates `metadata` (title, description, OG, Twitter) from `@/lib/config`.

## Auth & middleware

- [ ] **Sign-in is delegated to `id.rising.company`** ([ADR-0012](../adr/0012-better-auth-central-identity.md)). The app ships no sign-in form, password field or auth email templates of its own. The session arrives as the shared `.rising.company` cookie.
- [ ] **`middleware.ts`** (or `proxy.ts`) at the repo root gates non-public routes against a default-deny allowlist and bounces authenticated users away from `/`. The allowlist and matcher rules from [ADR-0004](../adr/0004-middleware-auth-gate.md) survive; the Supabase session refresh does not.
- [ ] **`matcher` config** excludes `_next/static`, `_next/image`, favicon, public assets.

## Convex

- [ ] **`convex/` folder** with `schema.ts`, the functions, and `lib/` for guards and shared helpers ([ADR-0017](../adr/0017-convex-backend.md)). No `supabase/` folder.
- [ ] **`convex/auth.config.ts`** declares `id.rising.company` as a `customJwt` provider. No `@convex-dev/auth`.
- [ ] **Every data function calls a guard first.** The guard takes the identity from `ctx.auth`, never from an argument. Reference: `os` `convex/lib/guards.ts`.
- [ ] **Refusal-path tests** for each data function, run with `convex-test` on the `edge-runtime` Vitest environment. These replace the Supabase security-advisor merge gate.
- [ ] **Preview deployments per branch**: the Vercel build runs `convex deploy --preview-name <branch>`. Set `ID_ISSUER` and `ID_JWKS` in the Convex dashboard's preview defaults first. Without them a preview deploys cleanly and then refuses every token. Reference: `huddle/scripts/vercel-build.sh`.
- [ ] **Demo seed data is dev-only.** It never runs against preview or production.
- [ ] **CSP `connect-src`** allows `*.convex.cloud` and `*.convex.site`.
- [ ] **`src/app/api/` is empty or absent**: mutations are Server Actions or Convex mutations, not REST routes ([ADR-0003](../adr/0003-server-actions-for-mutations.md)). The MCP endpoint ([ADR-0014](../adr/0014-mcp-server.md)) is the sanctioned exception.

## Build & deploy config

- [ ] **`next.config.ts`** captures `BUILD_DATE` and `BUILD_SHA` at build time (Vercel env vars with `git rev-parse HEAD` fallback) and exposes them via `env`. Copy the pattern from `os/next.config.ts`.
- [ ] **`remotePatterns`** in `next.config.ts` allows `**.convex.cloud` if images are served from Convex storage.
- [ ] **`src/lib/version.ts`** (or similar) reads `BUILD_DATE` / `BUILD_SHA` so the running version is observable at runtime.

## Environment

- [ ] **`.env.example`** lists every variable the app reads, with safe placeholder values and a one-line comment per var.
- [ ] **`.env*` ignored** in `.gitignore` (except `.env.example`).
- [ ] **`NEXT_PUBLIC_*` prefix** used only for values that genuinely belong in the browser bundle.

## Testing

- [ ] **`tests/` folder** mirrors `src/` layout ([ADR-0006](../adr/0006-vitest-tests-layout.md)). Files named `*.test.ts` (not `.spec.ts`).
- [ ] **At least one passing test** exists from day one so CI is green and the harness is wired correctly.
- [ ] **Red-green-refactor discipline** is documented in `CLAUDE.md` and followed in PRs.

## Scripts (`package.json`)

- [ ] `dev` starts Next.js and `convex dev`.
- [ ] `build`, `start`, `lint`, `test` all present and passing.
- [ ] A seed script for the dev deployment's demo data. Document it in the README.

## Repo hygiene

- [ ] **`.gitignore`** ignores `.next/`, `node_modules`, `.env*` (except `.env.example`), `coverage/`, `*.tsbuildinfo`, `.vercel/`.
- [ ] **`README.md`** covers: what the app does, how to run it locally, env vars (point to `.env.example`), how to run tests, how to seed the dev deployment.
- [ ] **`CLAUDE.md`** copied from the handbook and tailored: TDD rules, UI-verification rules, and links to project-specific ADRs.
- [ ] **`adr/`** copied from the handbook so structural decisions travel with the project. Add project-specific ADRs alongside.

## Agent access (MCP)

- [ ] **MCP server shipped, or "not applicable" recorded** in the project's `CLAUDE.md` ([ADR-0014](../adr/0014-mcp-server.md)). It is required wherever the product holds a person's or org's data or does recurring work for them. Reference: `os` (`convex/mcp/`, os ADR-0019).
- [ ] **Tools are shaped like jobs, not tables.** A `get_context` tool to call first, `snake_case` names, and descriptions written for a model.
- [ ] **Agent tokens**: minted in Settings → Agents from a session with a second factor, one org, explicit scopes, stored only as SHA-256, revocable, and dead once the minter leaves the org.
- [ ] **A separate agent guard** that takes the org from the token and checks scope on every call. Hidden tools are still refused.
- [ ] **One write path**: agent tools call the same domain helpers as the Server Actions. Agent-written rows carry `agent_token_id`, and delete tools refuse anything else.
- [ ] **`POST /mcp`** uses stateless JSON Streamable HTTP and refuses requests with an `Origin` header.
- [ ] **Tests** cover the protocol, the guard (unknown, revoked, lapsed-member and out-of-scope tokens) and each tool. **Verified with a real MCP client** (`claude mcp add --transport http …`) running a task end to end.

## Error & loading states

- [ ] **`src/app/not-found.tsx`** styled with design-system tokens.
- [ ] **`src/app/error.tsx`** (and segment-level `error.tsx` where it matters) styled with design-system tokens.
- [ ] **`src/app/loading.tsx`** for slow segments, or explicit `<Suspense>` boundaries.

## Pre-ship verification

- [ ] `npm run lint` clean.
- [ ] `npm run test` green.
- [ ] `npm run build` succeeds.
- [ ] **MCP tools exercised with a real MCP client** if the change touches a tool, its inputs or its outputs.
- [ ] **UI verified end-to-end** with the `agent-browser` skill — golden path *and* edge cases (see `CLAUDE.md`). If the change is backend-only, say so explicitly.
