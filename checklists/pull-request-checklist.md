# Pull request checklist

Use before pushing a branch for review or opening a PR on any Rising Company
project. Each item links to the ADR that explains the *why*.

## Correctness

- [ ] **Red-green-refactor followed**: every behaviour change has a test that
  was seen failing first (handbook `CLAUDE.md`, [ADR-0006](../adr/0006-vitest-tests-layout.md)).
- [ ] `lint`, `test` and `build` pass locally.
- [ ] **MCP tools exercised with a real client** if the change touches a tool,
  its inputs or its outputs ([ADR-0014](../adr/0014-mcp-server.md)).

## UI evidence ([ADR-0015](../adr/0015-pr-visual-evidence.md))

- [ ] **Decided whether a user can see the change.** If not, the PR description
  says so in one line, and the rest of this section doesn't apply.
- [ ] **[`pre-push-ui-review`](../skills/pre-push-ui-review/SKILL.md) run**:
  driven end to end with `agent-browser` (golden path and edge cases), with
  frames kept in the ledger as you went.
- [ ] **Visual story posted as one PR comment**: context sentence → before
  (changes to an existing surface) → after → GIF of the interaction → states
  that matter (empty / populated / error; 390px when layout moved). It passed
  `check-visual-story.sh`, with every owed GIF shot or explained.
- [ ] **Every frame checked**: demo or seed data only, no secrets, tokens or
  real people's records. Anyone with the link can view it.
- [ ] **Captions and alt text** say what to look at.
- [ ] **If Capture is not set up** (not signed in, or the account is pending
  approval), the report says the story is blocked and why. It was not skipped
  silently.

## Description

- [ ] The PR body says **what changed and why**, links the ADR when one was
  added or followed, and notes anything not verified.
