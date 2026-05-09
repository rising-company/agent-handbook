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
- [ ] **`src/app/opengraph-image.{png,tsx}`** present so social shares look right.
- [ ] **`src/app/manifest.ts`** (or `manifest.json`) defines name, short_name, theme color.
- [ ] **`src/lib/config.ts`** is the single source for `appName`, `tagline`, `domain`, `supportEmail`, `companyName`, etc., read from env with sensible defaults ([ADR-0008](../adr/0008-branding-config.md)).
- [ ] **No hardcoded brand strings** in components, metadata, or emails — everything imports from `@/lib/config`.
- [ ] **Root `layout.tsx`** populates `metadata` (title, description, OG, Twitter) from `@/lib/config`.

## Auth & middleware

- [ ] **`middleware.ts`** at the repo root gates non-public routes and bounces authenticated users away from `/` ([ADR-0004](../adr/0004-middleware-auth-gate.md)).
- [ ] **`src/lib/supabase/middleware.ts`** exports a reusable `updateSession()` helper — middleware.ts stays thin (this is the `venue-map` pattern; copy it).
- [ ] **`matcher` config** excludes `_next/static`, `_next/image`, favicon, public assets.

## Supabase

- [ ] **`supabase/` folder** with `config.toml`, `migrations/`, and `seed.sql` for demo data ([ADR-0002](../adr/0002-supabase-backend.md)).
- [ ] **Migrations follow `NNN_description.sql`** zero-padded numbering, append-only ([ADR-0007](../adr/0007-migration-immutability.md)). Never edit a merged migration — write a new one.
- [ ] **RLS enabled** on every user-data table. Owner CRUD + public read where appropriate; service-role for system writes.
- [ ] **`src/lib/supabase/`** has at minimum `server.ts`, `client.ts`, and `middleware.ts`. Add `queries.ts` / `storage.ts` as needed.
- [ ] **`src/app/api/` is empty or absent** — mutations are Server Actions, not REST routes ([ADR-0003](../adr/0003-server-actions-for-mutations.md)).

## Build & deploy config

- [ ] **`next.config.ts`** captures `BUILD_DATE` and `BUILD_SHA` at build time (Vercel env vars with `git rev-parse HEAD` fallback) and exposes them via `env`. Copy the pattern from `os/next.config.ts`.
- [ ] **`remotePatterns`** in `next.config.ts` allows `**.supabase.co` for storage-served images.
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

- [ ] `dev` starts Next.js (and Supabase locally if applicable).
- [ ] `build`, `start`, `lint`, `test` all present and passing.
- [ ] For Supabase projects: `db:start`, `db:stop`, `db:reset`, `db:studio`, plus a migration helper. Document them in the README.

## Repo hygiene

- [ ] **`.gitignore`** ignores `.next/`, `node_modules`, `.env*` (except `.env.example`), `coverage/`, `*.tsbuildinfo`, `supabase/.temp/`, `.vercel/`.
- [ ] **`README.md`** covers: what the app does, how to run it locally, env vars (point to `.env.example`), how to run tests, how to run migrations.
- [ ] **`CLAUDE.md`** copied from the handbook and tailored: TDD rules, UI-verification rules, and links to project-specific ADRs.
- [ ] **`adr/`** copied from the handbook so structural decisions travel with the project. Add project-specific ADRs alongside.

## Error & loading states

- [ ] **`src/app/not-found.tsx`** styled with design-system tokens.
- [ ] **`src/app/error.tsx`** (and segment-level `error.tsx` where it matters) styled with design-system tokens.
- [ ] **`src/app/loading.tsx`** for slow segments, or explicit `<Suspense>` boundaries.

## Pre-ship verification

- [ ] `npm run lint` clean.
- [ ] `npm run test` green.
- [ ] `npm run build` succeeds.
- [ ] **UI verified end-to-end** with the `agent-browser` skill — golden path *and* edge cases (see `CLAUDE.md`). If the change is backend-only, say so explicitly.
