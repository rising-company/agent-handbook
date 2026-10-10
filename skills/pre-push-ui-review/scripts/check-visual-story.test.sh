#!/usr/bin/env bash
# Tests for check-visual-story.sh. Run: bash skills/pre-push-ui-review/scripts/check-visual-story.test.sh
# Ported from swivel PilotDesk's pre-push-review; URLs are Capture's.
set -u
here=$(cd "$(dirname "$0")" && pwd)
SUT="${HOOK_UNDER_TEST:-$here/check-visual-story.sh}"
pass=0; fail=0
ok() { pass=$((pass + 1)); echo "ok   - $1"; }
no() { fail=$((fail + 1)); echo "FAIL - $1${2:+ ($2)}"; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
git init -q "$work/repo"

# Shapes `capture` prints: alt parens escaped, keys carry - and _.
PNG='![after — list \(synthetic\)](https://capture.rising.company/i/jsrSkh9J_ztzF0YCw3CmWpUQmxI.png)'
GIF1='![expand a row \(synthetic\)](https://capture.rising.company/i/84-16vO1aWJDpaAcZgj08kOoEqA.gif)'
GIF2='![timeline jump](https://capture.rising.company/i/Zx_9-ab.gif)'

# expect <name> <rc> <comment-body> [<frames-body>] [<stderr substring>]
expect() {
  local name="$1" want="$2" body="$3" ledger="${4-}" needle="${5-}" rc err
  printf '%s\n' "$body" > "$work/comment.md"
  printf '%s' "$ledger" > "$work/frames.md"
  err=$( (cd "$work/repo" && bash "$SUT" "$work/comment.md" "$work/frames.md") 2>&1 >/dev/null); rc=$?
  if [[ "$rc" != "$want" ]]; then no "$name" "rc=$rc want $want: $err"; return; fi
  if [[ -n "$needle" && "$err" != *"$needle"* ]]; then no "$name" "stderr lacks [$needle]: $err"; return; fi
  ok "$name"
}

expect "stills alone are refused"                1 "$PNG"
expect "one GIF passes"                          0 "$PNG
$GIF1"
expect "a .gif named in prose is not a GIF"      1 "$PNG
recorded to /tmp/rec.gif"
expect "a plain link to a GIF is not an embed"   1 "$PNG
[Download recording](https://capture.rising.company/i/abc.gif)"
expect "two owed, one GIF: refused, both named"  1 "$GIF1" \
  $'owed: gif — expand a row\nowed: gif — timeline jump\n' "timeline jump"
expect "two owed, two GIFs pass"                 0 "$GIF1
$GIF2" $'owed: gif — expand a row\nowed: gif — timeline jump\n'
expect "No GIF with a reason passes"             0 "$PNG
No GIF: a colour change, nothing to interact with"
expect "bold No GIF passes"                      0 "$PNG
**No GIF:** a label rename only"
expect "No GIF cannot waive an owed GIF"        1 "$PNG
No GIF: a layout fix" $'owed: gif — expand a row\n' "still owed"
expect "No GIF with no reason is refused"        1 "$PNG
No GIF:   "
expect "a leaked owed: line is refused"          1 "$GIF1
owed: gif — expand a row" "" "ledger line"

printf '%s\n%s\n' "$PNG" "No GIF: static change" > "$work/comment.md"; : > "$work/frames.md"
out=$( (cd "$work/repo" && bash "$SUT" "$work/comment.md" "$work/frames.md") 2>/dev/null)
[[ "$out" == *"static change"* ]] && ok "the skip reason is echoed" || no "the skip reason is echoed" "$out"

# Without an explicit frames file it reads the repo's ledger.
printf '%s\n' "owed: gif — a" "owed: gif — b" > "$work/repo/.git/claude-ui-frames.md"
printf '%s\n' "$GIF1" > "$work/comment.md"
(cd "$work/repo" && bash "$SUT" "$work/comment.md") >/dev/null 2>&1; rc=$?
[[ "$rc" == 1 ]] && ok "the default ledger is <git-dir>/claude-ui-frames.md" || no "the default ledger is <git-dir>/claude-ui-frames.md" "rc=$rc"

(cd "$work/repo" && bash "$SUT" "$work/missing.md") >/dev/null 2>&1; rc=$?
[[ "$rc" == 2 ]] && ok "an unreadable comment is a usage error" || no "an unreadable comment is a usage error" "rc=$rc"

echo "pass=$pass fail=$fail"
[[ "$fail" == 0 ]]
