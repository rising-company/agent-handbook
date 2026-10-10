# Project guidelines

## Architecture

This project follows the Rising Company shared architecture. Each decision below is captured as an ADR — read them before making structural changes.

- [ADR-0001 — Next.js App Router + React 19 + TypeScript strict](adr/0001-nextjs-react-typescript-stack.md)
- [ADR-0002 — Supabase as backend (auth, data, storage)](adr/0002-supabase-backend.md)
- [ADR-0003 — Server Actions for mutations (no REST/API routes)](adr/0003-server-actions-for-mutations.md)
- [ADR-0004 — Middleware-based auth gate](adr/0004-middleware-auth-gate.md) — *superseded by ADR-0012*
- [ADR-0005 — Rising Company Design System (Tailwind 4)](adr/0005-rising-design-system.md) — tokens at <https://design-system.rising.company/> ([llms.txt](https://design-system.rising.company/llms.txt))
- [ADR-0006 — Vitest with `node` environment, tests/ folder](adr/0006-vitest-tests-layout.md)
- [ADR-0007 — Migration immutability and local-first DB workflow](adr/0007-migration-immutability.md)
- [ADR-0008 — Branding via `src/lib/config.ts`](adr/0008-branding-config.md)
- [ADR-0009 — Security assurance baseline](adr/0009-security-assurance-baseline.md)
- [ADR-0010 — Data retention and disposal policy](adr/0010-data-retention-disposal.md)
- [ADR-0011 — Accessibility assurance](adr/0011-accessibility-assurance.md)
- [ADR-0012 — Better Auth as central identity (id.rising.company)](adr/0012-better-auth-central-identity.md) — supersedes ADR-0004
- [ADR-0013 — Every product ships a link preview card](adr/0013-link-preview-card.md)
- [ADR-0014 — Applicable products ship an MCP server](adr/0014-mcp-server.md) — so products are AI-native; reference: `os`
- [ADR-0015 — UI pull requests show their change, hosted on Capture](adr/0015-pr-visual-evidence.md) — before/after screenshots and a GIF as a PR comment

See [`adr/README.md`](adr/README.md) for the full index. Deviating from an ADR is allowed but should add a new ADR that supersedes the old one.

## Checklists

Run through the relevant checklist before declaring a task complete. ADRs explain decisions; checklists tell you what to verify.

- [New project checklist](checklists/new-project-checklist.md) — bootstrapping or auditing a Rising Company app
- [Pull request checklist](checklists/pull-request-checklist.md) — before pushing a branch or opening a PR

See [`checklists/README.md`](checklists/README.md) for the full index.

## Development workflow

### Red-green development (always)

Follow strict red-green-refactor for every change:

1. **Red** — write a failing test that captures the desired behavior. Run it and confirm it fails for the *right reason* (assertion failure, not import error or typo).
2. **Green** — write the smallest amount of code that makes the test pass. Resist the urge to add anything beyond what the test requires.
3. **Refactor** — clean up only after the test is green. Tests stay green throughout.

Rules:
- No production code without a failing test first.
- One failing test at a time. Don't write multiple tests up-front.
- If you find yourself wanting to write code without a test, stop and write the test.
- When fixing a bug, the first step is a failing test that reproduces it.

## UI testing

### Use the `agent-browser` skill for end-to-end UI verification

For any change that affects the UI (components, routes, styles, user-facing behavior), drive the app end-to-end with the [`agent-browser`](https://agent-browser.dev) skill before reporting the task complete.

How to use it:

- Load the workflow content first: `agent-browser skills get core` (or `--full` for the complete command reference). The installed CLI serves the up-to-date guide; do not run commands from memory.
- For exploratory testing / QA / bug-hunt sessions, also load: `agent-browser skills get dogfood`.
- The CLI drives Chrome/Chromium via CDP and exposes accessibility-tree snapshots with `@eN` element refs — use those refs rather than guessing CSS selectors.

What to verify:

- Exercise the golden path *and* the edge cases of the change.
- Watch for regressions in adjacent features, not just the one you touched.
- Type checks and unit tests verify code correctness, not feature correctness — they are not a substitute for actually using the feature.
- If `agent-browser` is unavailable or the change can't be exercised in a browser (e.g. backend-only), say so explicitly rather than claiming UI verification.

## Pull requests

### Show UI changes with the `share-screenshot` skill (Capture)

When a PR changes anything a user can see, post its **visual story** as one PR
comment ([ADR-0015](adr/0015-pr-visual-evidence.md)): one sentence of context,
**before**, **after**, a **GIF** of the interaction, and the states that matter.
Use the [`share-screenshot`](skills/share-screenshot/SKILL.md) skill, which
uploads to <https://capture.rising.company> and returns markdown. Its section
"Showing a UI change in a PR" has the format and a worked command.

- **Reuse the `agent-browser` frames** from the UI verification above, instead
  of shooting the same views again.
- **Check every frame before uploading.** Anyone with the link can view the
  image, so use seed or demo data and keep secrets, tokens and real people's
  records out.
- **If the CLI isn't ready, say so in your report.** That means `capture whoami`
  shows not signed in, or the account is pending approval. Hand the person the
  `capture login` URL and code, or tell them the account is waiting for a
  Capture admin. Don't silently skip the story.
- **A PR that changes nothing visible** says so in one line of its description.

Setup, once per machine:
`npm i -g https://capture.rising.company/capture-cli.tgz && capture login && capture skill install --global`.

