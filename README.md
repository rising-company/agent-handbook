# agent-handbook

Source of truth for how AI coding agents (primarily Claude Code) work on Rising Company projects. Humans read it too, but the writing is calibrated for an agent picking up a task with no prior context.

## What's inside

- **[`CLAUDE.md`](CLAUDE.md)** — agent operating instructions: TDD discipline, UI verification rules, and links to every ADR. This file is what Claude Code loads on session start.
- **[`adr/`](adr/)** — Architecture Decision Records covering the stack and conventions shared across `os`, `huddle`, `venue-map`, and any future Rising Company app. Start at [`adr/README.md`](adr/README.md).

## How to use it

**Starting a new project:** copy `CLAUDE.md` and `adr/` into the new repo. The ADRs reference relative paths (`adr/0001-...md`) so they keep working unchanged. Update project-specific details in the new copy as needed; structural changes belong here, in the handbook.

**Working on an existing Rising Company project:** the project's own `CLAUDE.md` is authoritative for that project. Treat this repo as the upstream — when a project drifts from an ADR for a good reason, capture the reason in the project's own ADR (or supersede the handbook ADR here).

## How to update it

ADRs are append-mostly. If a decision changes:

1. Don't edit the old ADR's body. Mark its status as **Superseded by ADR-NNNN** and leave the rest intact.
2. Add a new ADR with the new decision and a **Supersedes** line pointing back.
3. Update [`adr/README.md`](adr/README.md) and [`CLAUDE.md`](CLAUDE.md) to point at the new ADR.

The handbook only earns its keep if the ADRs match what we actually do. If you notice a project doing something the handbook doesn't describe — and it's working — that's a candidate for a new ADR.

## Related

- Rising Company Design System — <https://design-system.rising.company/> ([`llms.txt`](https://design-system.rising.company/llms.txt))
