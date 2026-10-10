#!/usr/bin/env bash
# Checks a composed visual-story comment before `gh pr comment` (pre-push-ui-review step 5).
# Ported from swivel PilotDesk's pre-push-review.
#
#   check-visual-story.sh <comment-file> [<frames-file>]
#
# The comment passes when it embeds a GIF for every `owed: gif` line in the
# frames file (at least one), or, when nothing is owed, carries a `No GIF:
# <reason>` line the reader can see. A stale owed line is deleted from the ledger.
# frames-file defaults to <git-dir>/claude-ui-frames.md; a missing one owes nothing.
#
# Exit 0 pass, 1 refused (stderr says what is owed), 2 usage.
#
# Tests: check-visual-story.test.sh
set -u

comment="${1:-}"
frames="${2:-}"
[[ -r "$comment" ]] || { echo "usage: check-visual-story.sh <comment-file> [<frames-file>]" >&2; exit 2; }
if [[ -z "$frames" ]]; then
  gd=$(git rev-parse --git-dir 2>/dev/null || true)
  frames="${gd:+$gd/claude-ui-frames.md}"
fi

gifs=$(grep -Eio '!\[[^]]*(\\][^]]*)*\]\(https?://[^)[:space:]]+\.gif\)' "$comment" | wc -l | tr -d ' ')
owed_lines=""
[[ -n "$frames" && -r "$frames" ]] && owed_lines=$(grep -E '^owed: gif' "$frames" || true)
owed=$(printf '%s' "$owed_lines" | grep -c . || true)
reason=$(grep -Em1 '^[*_]*No GIF:[*_]*[[:space:]]+[^[:space:]]' "$comment" || true)

if grep -Eq '^owed: ' "$comment"; then
  echo "visual-story: refused: the comment contains an 'owed:' ledger line; those stay in the frames file" >&2
  exit 1
fi
if [[ -n "$reason" && "$owed" -gt 0 ]]; then
  echo "visual-story: refused: 'No GIF:' cannot waive the $owed GIF(s) still owed:" >&2
  sed 's/^/  /' <<<"$owed_lines" >&2
  echo "  Shoot them, or delete an owed line that no longer applies from the frames file." >&2
  exit 1
fi
if [[ -n "$reason" ]]; then
  echo "visual-story: ok (gifs=$gifs owed=$owed; skipped: ${reason#*No GIF:})"
  exit 0
fi
need=$(( owed > 1 ? owed : 1 ))
if (( gifs >= need )); then
  echo "visual-story: ok (gifs=$gifs owed=$owed)"
  exit 0
fi
{
  echo "visual-story: refused: the comment embeds $gifs GIF(s) and needs $need."
  [[ -n "$owed_lines" ]] && sed 's/^/  /' <<<"$owed_lines"
  echo "  Record each interaction (agent-browser record, then to-gif.sh and capture),"
  echo "  or, when the change has none, add a line 'No GIF: <why>' to the comment."
} >&2
exit 1
