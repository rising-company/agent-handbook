---
name: pre-push-ui-review
description: |
  Before pushing a branch or opening a PR that changes anything a user can see in a Rising Company app: drive the change end to end with agent-browser as a signed-in user, keep screenshots as you go, record a GIF of the interaction, upload them to Capture, and post the before/after visual story as one PR comment, checked by check-visual-story.sh. Covers signing in through a local id.rising.company (magic link from the dev log, TOTP step-up), the frame ledger that survives handoffs and compaction, owed GIFs, and the agent-browser traps that make a working app look broken. Use when a UI branch is about to be pushed, when opening or updating its PR, or when a reviewer asks to see the change.
argument-hint: "[PR number], or omit it and the skill uses the current branch's PR"
---

# Pre-push UI review: verify in a browser, then show it in the PR

Handbook ADR-0015: a PR that changes what a user can see carries a visual story,
so a reviewer can see the change without checking out the branch. This skill is
the procedure. It turns the `agent-browser` pass the handbook already requires
into frames on Capture and one PR comment.

Ported from swivel PilotDesk's `e2e-agent-browser` and `pre-push-review` step 9.
Their code-review dispatch, review stamp and push gate are **not** part of this.

Uploading uses the **`share-screenshot`** skill (`../share-screenshot/SKILL.md`).
Read its *Read this before you upload* once: anyone with an image URL can view
the image.

## 0. Is this a UI branch?

A UI branch is one where something renders differently: a new surface **or a fix
to an existing one**. A fix "checked in a browser" with no frame posted can't be
told apart from one that wasn't checked.

If nothing renders differently (logging, a refactor, a perf change with
identical output), put one line in the PR description saying so, and stop here.

## 1. Get ready

```bash
agent-browser skills get core        # the CLI's own version-matched guide; once per session
export AGENT_BROWSER_SESSION="$(agent-browser session id --scope worktree --prefix ui-review)"
capture whoami                       # signed in, and status: approved?
LEDGER="$(git rev-parse --git-dir)/claude-ui-frames.md"
```

If `capture whoami` says not signed in, run `capture login`, show the person the
URL and code, and wait for them to approve. If it says `pending`, the account is
waiting for a Capture admin. Either way, keep going with steps 2–3: frames saved
locally can be uploaded later. Say plainly in your report that the story is
blocked, and why.

## 2. Capture the before, first

When the change alters an existing surface, shoot **before** frames from `main`
or the live product while you still can. Once your branch's server holds the
port, the old UI is gone.

```bash
agent-browser open https://<app>.rising.company/<page>    # or main checked out locally
agent-browser screenshot /tmp/before-<view>.png
```

Skip this for a brand-new surface.

## 3. Drive the change, keeping frames as you go

### Signing in locally

Rising apps sign in at id.rising.company (handbook ADR-0012). Locally, run the
sibling `id` repo with these settings in its `.env.local`:

```
AUTH_EMAIL_DEV_LOG=true                   # magic links print to id's console
AUTH_TRUSTED_ORIGINS=http://localhost:<your app port>
```

Point the app's `NEXT_PUBLIC_ID_URL` at it. Then:

```bash
agent-browser open http://localhost:<port>/<protected page>   # bounces to id
agent-browser snapshot -i                                     # find EMAIL + "EMAIL ME A LINK"
agent-browser fill @eN "ui-review-$(date +%s)@example.com"    # per-run address exercises first sign-in
agent-browser click @eM
grep -o 'http://localhost:[0-9]*/api/auth/magic-link/verify[^ "]*' <id log> | tail -1
agent-browser open "<that link>"                              # lands back on your page, signed in
```

Use a per-run address so first-visit provisioning is exercised. Use a fixed one
(an admin, say) when the change needs existing data or a role.

**Two things that cost time here:**

- **Another session may already own id's port.** Don't kill it. Copy the repo,
  run it on a spare port with its own SQLite file (`AUTH_DB_PATH`, blank
  `DATABASE_URL`), and use a real `node_modules` copy (`cp -Rc`): Turbopack
  refuses a symlinked one.
- **Pages that need a second factor** (minting tokens, `os`) send you to id's
  step-up. Enrol at id's `/security`, take the "enter this key manually" value,
  and answer every code prompt with:

  ```bash
  node <this skill's directory>/scripts/totp.mjs <key>
  ```

### Proving what you did

Exercise the golden path **and** the edge cases, and look at adjacent features
too. These are the traps that make a working app look broken:

- **A screenshot proves what rendered, not that your click landed.** A ref click
  can return success and do nothing. Prove it:
  `agent-browser console --clear`, click, then `agent-browser network requests | tail`,
  `get url`, `console`. If a submit fired no request, suspect the click before
  the app.
- **Refs go stale after any re-render.** Re-snapshot right before each
  interaction.
- **When a ref click does nothing, click the DOM node:**
  `agent-browser eval '[...document.querySelectorAll("button")].find(b => b.textContent.trim() === "Save").click()'`.
  Match the DOM text, not the snapshot's: the accessibility tree applies CSS
  `text-transform`, so `SAVE` in the snapshot is `Save` in the DOM.
- **In-page dialogs aren't browser dialogs.** A `[role=dialog]` sits in the DOM
  and blocks the flow. Check
  `agent-browser eval 'document.querySelectorAll("[role=dialog]").length'`.
- **Read state from the DOM, not the picture:** `snapshot | grep`,
  `get value|text|url`.
- **Check the runtime log as well as the screen**: `agent-browser console`, and
  the dev server's output.

### Keeping frames

Shoot the frames the story needs **while the browser is open**. Saving one now is
free, while re-staging the app tomorrow is not. You need:

- **after**: the same view as each before frame;
- **the states that matter**: empty, populated and error when the change has
  them;
- **narrow** when layout moved: `agent-browser set viewport 390 844`;
- **the other theme** when colours moved.

Start each alt text with the state it shows (`before`, `after`, `empty`,
`error`, `390px`). Upload each frame as you go and **append its markdown to the
ledger**, rather than holding it in the conversation, where a handoff or
compaction loses it:

```bash
SRC=$(gh pr view --json number -q .number 2>/dev/null) && SRC="#$SRC" || SRC="@$(git branch --show-current)"
capture --alt "after — approval page with undo" --source "rising-company/<repo>$SRC" /tmp/after.png >> "$LEDGER"
```

A refused upload prints nothing on stdout, so nothing is appended.

### Recording the interaction

When the change involves anything a user *does*, record it:

```bash
agent-browser record start /tmp/rec.webm     # keeps cookies and localStorage, so you stay signed in
agent-browser snapshot -i                    # fresh context: re-read the refs before acting
# … perform the one interaction, deliberately, no detours …
agent-browser record stop
GIF=$(<share-screenshot's directory>/scripts/to-gif.sh /tmp/rec.webm)
capture --alt "deny, then undo" --source "rising-company/<repo>$SRC" "$GIF" >> "$LEDGER"
```

Keep takes short. GIF size is duration × moving pixels, and the cap is 4 MiB.

**A GIF you can't shoot now is owed.** If the UI is still moving, append its
logline instead, and step 5 refuses a comment that skips it:

```bash
echo "owed: gif — deny, then undo within ten seconds" >> "$LEDGER"
```

## 4. Shoot the owed GIFs against the final UI

Right before pushing, record every `owed: gif` line in the ledger against the UI
that will merge, append the upload, and delete the owed line. An earlier take
goes stale when the UI moves. Delete an owed line that no longer applies.

## 5. Compose, check, post

Write **one PR comment** to a file. It goes in a comment, not the PR body, which
stays the written summary. Build it from the ledger's frame lines, without
uploading anything twice, in this order:

1. **One sentence of context**: what the user was trying to do, and what was
   wrong or missing.
2. **Before**, when an existing surface changed.
3. **After**, then the GIF of the interaction.
4. **The states that matter**: empty / populated / error, 390px, the other theme.

Give each image a one-line caption saying what to look at. Re-read every frame
against `share-screenshot`'s upload rules: seed or demo data only, no secrets,
tokens or real people's records. Ledger lines starting `owed:` never go in the
comment.

When the change truly has no interaction (a colour, a label, a static state),
add a line `No GIF: <why>`. That can't waive an owed GIF.

```bash
bash <this skill's directory>/scripts/check-visual-story.sh /tmp/story.md \
  && gh pr comment --body-file /tmp/story.md \
  && rm -f "$LEDGER"
```

The check refuses a comment with fewer GIFs than are owed, with none at all and
no `No GIF:` reason, or with a leaked `owed:` line. If the PR doesn't exist yet,
keep `/tmp/story.md` and post it right after `gh pr create`. Deleting the ledger
once posted stops a branch switch in a shared checkout from handing its frames
to another branch.

**One story per PR.** A later push posts nothing unless it changed what renders,
and then posts a short follow-up comment covering only that change, checked the
same way.

## 6. Report

Tell the person whether the story was posted (with the comment link), is
waiting for the PR, or is blocked (Capture not signed in or not approved). Say
which way the GIF went: shot, owed and shot, or `No GIF:` and why. Mention any
state you couldn't stage.

## Scripts

| Script | What | Tests |
| --- | --- | --- |
| `scripts/check-visual-story.sh <comment> [<ledger>]` | gate before `gh pr comment` | `check-visual-story.test.sh` |
| `scripts/totp.mjs <base32-key>` | current TOTP code, for id's second-factor prompts | `totp.test.sh` |

Run a script's test after touching it, and check that a new case can fail before
trusting it.
