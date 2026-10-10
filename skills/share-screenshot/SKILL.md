---
name: share-screenshot
description: |
  Use whenever a GitHub PR changes something a user can see: post the before/after visual story as a PR comment. Upload a screenshot or screen recording to Capture (https://capture.rising.company) and get back a stable image URL plus pasteable markdown, so visual evidence goes straight into a GitHub PR description, issue, or review comment. Also covers turning a .mov/.webm recording into a GIF small enough to upload. Use whenever you have captured an image (an agent-browser screenshot, a chart, a before/after) and need a human reading the PR to see it, rather than leaving it in /tmp. Covers signing in with Rising ID (`capture login`), the account approval step, what the service refuses and why, and the judgement to make before uploading anything.
argument-hint: "[image path], e.g. /tmp/checkout.png, or omit it and the skill will ask what to upload"
---

# Share a screenshot into a PR

A PR description can only show an image that has a URL. Capture gives a screenshot that URL:
you upload with your Rising ID, anyone with the unguessable URL can read it, and the response
contains ready-to-paste markdown.

## TL;DR

```bash
capture --alt "checkout total after the fix" /tmp/checkout.png
```

Prints exactly one markdown line per image on stdout:

```
![checkout total after the fix](https://capture.rising.company/i/Xk3f9pQ...pQ.png)
```

Paste that into the PR body. That's the whole job.

## First-time setup

Check whether the CLI is installed and signed in:

```bash
capture whoami
```

| What you see | What to do |
| --- | --- |
| `command not found` | `npm i -g https://capture.rising.company/capture-cli.tgz` |
| exit code 3, "not signed in" | `capture login`. It prints a URL and a code. **The person** opens the URL, signs in with Rising ID, checks the code matches, and approves. Show them the URL and code; you can't approve it yourself. |
| `status: pending` | The account is waiting for a Capture admin to approve it. Tell the person; uploads fail with exit code 4 until then. Nothing to retry. |
| `status: suspended` | An admin has suspended uploads for this account. Stop and tell the person. |
| `status: approved` | Ready. |

Approving a CLI sign-in needs a session confirmed with a second factor. If the approval page
asks for one, the person completes it at Rising ID and comes back to the same page.

In CI, set `CAPTURE_TOKEN` to a token created at https://capture.rising.company/tokens rather
than running `capture login`.

## Read this before you upload

Anyone holding the URL can view the image, without logging in. GitHub's rendering forces this:
it fetches images through its `camo` proxy, server-side and anonymously, so there's no request
a credential could ride on. The unguessable key is the only access control.

- **Never upload secrets, credentials, tokens, or customer data.** Check the whole screenshot,
  not only the part you care about. Browser tabs, sidebars, terminal history and notification
  toasts leak things. Crop or redact first, or don't upload.
- **Deleting doesn't reliably unpublish.** `capture delete <url>` stops Capture serving the
  image within a couple of minutes, but GitHub may keep serving its own cached copy. If something sensitive goes up, delete
  it *and* edit or delete the comment that carries the URL.

When in doubt about a screenshot, ask the person before uploading it.

## Capturing the image first

Screenshots of a running app usually come from the `agent-browser` skill:

```bash
agent-browser open http://localhost:3000/checkout
agent-browser screenshot /tmp/checkout.png
capture --alt "checkout total after the fix" /tmp/checkout.png
```

## Options

```bash
capture <image>                              # alt text defaults to the file name
capture --alt "what it shows" <image>        # better: describe it for the reader
capture --source "rising-company/os#61" <image>   # provenance, recorded, never in the URL
capture a.png b.png                          # several at once, one markdown line each
capture --json <image>                       # full response (key, url, bytes) as JSON lines
capture list                                 # your recent uploads
capture delete <key-or-url>                  # stop serving one
```

Prefer real alt text over the file-name default. It's what a screen reader announces and what
shows if the image fails to load, and `shot-3` tells the reader nothing.

## Composing it

stdout carries only markdown, so it drops into a PR body cleanly:

```bash
SHOT=$(capture --alt "before" /tmp/before.png)
gh pr create --title "Fix checkout rounding" --body "$(printf 'Totals drifted by a cent.\n\n%s\n' "$SHOT")"
```

## Showing a UI change in a PR

Every Rising Company PR that changes what a user can see carries a **visual
story** (handbook ADR-0015): a reviewer should see the change without checking
out the branch. A UI change is anything that renders differently, whether a new
surface **or a fix to an existing one**. If nothing renders differently
(logging, a refactor, a perf change with identical output), say so in one line
of the PR description instead, and stop.

Otherwise post **one PR comment**, not the PR body, which stays the written
summary. Write it in this order:

1. **One sentence of context**: what the user was trying to do, and what was
   wrong or missing.
2. **Before**, when the change alters an existing surface: the problem as the
   user saw it. Skip it for a brand-new surface. Capture it from `main` (or the
   live product) before your branch's server takes over the port.
3. **After**: the same view with the change in place, then a GIF (`to-gif.sh`)
   of any interaction the change involves. Use a GIF, not a run of stills.
4. **The states that matter**: empty, populated and error when the change has
   them, plus narrow width (390px) when layout moved, and the other theme when
   colours moved.

Reuse the frames from the `agent-browser` pass the handbook already requires.
Don't shoot the same view twice. Give every image a one-line caption saying
what to look at, and real alt text.

```bash
CTX="Approving a CLI sign-in had no way back after a mistaken deny."
BEFORE=$(capture --alt "approval page, deny is final" /tmp/before.png)
AFTER=$(capture --alt "approval page with undo" /tmp/after.png)
GIF=$(capture --alt "deny, then undo" "$(<this skill's directory>/scripts/to-gif.sh /tmp/rec.webm)")
cat > /tmp/story.md <<MD
$CTX

**Before**: deny was final.
$BEFORE

**After**: deny shows an undo for ten seconds.
$AFTER
$GIF
MD
gh pr comment --body-file /tmp/story.md
```

Check every frame against [Read this before you upload](#read-this-before-you-upload)
before running `gh pr comment`. Seed or demo data, never a real person's
records. If the PR doesn't exist yet, keep the file and post it right after
`gh pr create`. If there's no interaction at all (a colour, a label), add the
line `No GIF: <why>` so the reader sees the reason.

**One story per PR.** A later push posts nothing unless it changed what renders,
and then posts a short follow-up comment covering only that change.

## Exit codes and refusals

| Exit | Server | Meaning | Fix |
| --- | --- | --- | --- |
| 2 | (none) | file missing or over 4 MiB, caught before uploading | fix the path, or shrink it |
| 3 | 401 | not signed in, or token revoked or expired | `capture login` |
| 4 | 403 `not_approved` | account awaiting admin approval | tell the person; wait |
| 4 | 403 `suspended` | uploads suspended by an admin | tell the person |
| 1 | 413 | over 4 MiB (4,194,304 bytes) | shrink it |
| 1 | 415 | not png / jpeg / webp / gif | **SVG is refused on purpose** because it can carry `<script>`. Re-export as PNG |
| 1 | 429 | over 30 uploads a minute | wait a minute |

The server decides the type by sniffing the file's magic bytes, not its extension or the
`Content-Type` header, so renaming `x.svg` to `x.png` still gets a 415.

**One size budget.** The 4 MiB cap sits below GitHub camo's 5 MiB ceiling, so anything
Capture accepts will render in a PR. There's no "uploaded fine but shows a broken icon" case
to watch for.

## Recording a GIF

A GIF is the only moving format that works here. Capture refuses MP4 and WebM (they aren't
images), and `![](...)` won't play a video in a comment anyway.

```bash
agent-browser record start /tmp/rec.webm <url>
agent-browser record stop
GIF=$(<this skill's directory>/scripts/to-gif.sh /tmp/rec.webm)
capture --alt "drawer opens on row click" "$GIF"
```

`<this skill's directory>` is wherever this SKILL.md lives: `.claude/skills/share-screenshot`
in a project, `~/.claude/skills/share-screenshot` (or `$CLAUDE_CONFIG_DIR/skills/…`) when
installed globally, or `agent-handbook/skills/share-screenshot` in the Rising workspace.

`to-gif.sh` encodes down a ladder of width/fps steps and stops at the first that fits under
4 MiB, so you get the best quality that will upload. Options: `--seconds 8` trims (length is
the biggest lever on size), `--out FILE`. Exit `3` means it couldn't fit even at 480px/6fps.
The fix is almost always a shorter clip of just the one interaction. It needs `ffmpeg`.

## Without a shell: MCP

If the agent can't run commands, the person can connect the MCP server instead:
`capture mcp install` (runs `claude mcp add` with their token), or create a token at
https://capture.rising.company/tokens. Tools: `get_context`, `upload_image` (base64),
`list_uploads`, `delete_upload`. Prefer the CLI when you have a shell, because base64 images
cost a lot of context.

## When not to use this

- **Text belongs in text.** Paste stack traces, logs, diffs and tables of numbers as text or
  fenced blocks. Use an image when the visual is the evidence: layout, rendering, a chart, a
  broken state.
- **Anything confidential**, per the rules above.
- **Assets for a website.** Capture is for review evidence, not a CDN.

## If something looks wrong with the service

`https://capture.rising.company/v1/health` returns `{"ok":true}`. The source, design doc and
ADRs are in `rising-company/capture`.
