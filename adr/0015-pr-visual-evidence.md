# ADR-0015 — UI pull requests show their change, hosted on Capture

**Status:** Accepted (2026-10-09)

## Context

The handbook already requires every UI change to be driven end to end with
`agent-browser` before it is called done. That pass produces screenshots, and
they used to die in `/tmp`. A reviewer then had two choices: check out the
branch and run it, or approve a UI change they never saw. Agents wrote "verified
in the browser" in a PR body, and nobody could check the claim.

A PR can only show an image that has a URL, and GitHub's camo proxy fetches it
anonymously. `capture.rising.company` (rising-company/capture) exists for exactly
this. You upload with a Rising ID and get back an unguessable URL plus markdown.
swivel's PilotDesk runs the same practice through its pre-push review: a
before/after "visual story" PR comment for every branch a user can see.

## Decision

- **Every PR that changes what a user can see carries a visual story.** That
  covers a new surface or a fix to an existing one. Post it as **one PR
  comment** in this order: one sentence of context, **before** (for a change to
  an existing surface), **after**, a **GIF** of any interaction, then the
  states that matter (empty / populated / error, 390px width when layout moved).
  A PR that renders nothing differently says so in one line of its description.
- **Images go on Capture, through the `share-screenshot` skill**
  ([`skills/share-screenshot/`](../skills/share-screenshot/SKILL.md)). Use the
  `capture` CLI when you have a shell. MCP is for clients that don't, because
  base64 screenshots are unreliable in a tool call.
- **The frames come from the `agent-browser` pass the handbook already
  requires.** Shooting them again is wasted work.
- **Anyone with a link can see the image.** Use seed or demo data. Never
  upload secrets, tokens, or a real person's records. Deleting stops Capture
  serving an image within a couple of minutes, but GitHub may keep its cached
  copy.
- **One story per PR.** A later push posts a short follow-up only when it
  changed what renders.

## Consequences

- Agents need the skill and a signed-in CLI: `npm i -g
  https://capture.rising.company/capture-cli.tgz`, then `capture login` (the
  person approves in a browser with Rising ID and a second factor) and
  `capture skill install --global`. A new account uploads only after a Capture
  admin approves it. Until then the agent says the story is blocked on
  approval, rather than skipping it silently.
- The skill's source of truth is `rising-company/capture`. The copy here tracks
  it, and `capture skill install` installs the version that matches the
  deployed service.
- Review gets cheaper and claims of UI verification become checkable, at the
  cost of a minute or two per UI PR.
