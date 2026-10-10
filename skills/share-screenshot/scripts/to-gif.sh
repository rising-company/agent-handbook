#!/usr/bin/env bash
#
# Convert a screen recording into a GIF small enough for Capture, by encoding
# down a ladder until it fits a byte budget.
#
#   to-gif.sh recording.mov
#   to-gif.sh --seconds 8 --out /tmp/demo.gif recording.mov
#   to-gif.sh --budget 2000000 recording.mov
#
# Prints the output path on stdout and nothing else, so it composes:
#   GIF=$(to-gif.sh rec.mov) && capture --alt "what it shows" "$GIF"
#
# Everything explanatory goes to stderr. Exit codes: 0 ok, 1 runtime failure,
# 2 usage error, 3 could not reach the budget (see stderr for what to cut).
#
# Ported from swivel's snap. snap needed two budgets because it accepted more
# than GitHub's camo proxy will render (5 MiB). Capture's cap is 4 MiB, under
# camo's, so the one budget is the cap: anything that uploads also renders.
set -euo pipefail

CAPTURE_LIMIT=4194304    # 4 MiB: convex/lib/images.ts MAX_UPLOAD_BYTES
PR_BUDGET=$CAPTURE_LIMIT

BUDGET=$PR_BUDGET
BUDGET_LABEL=pr
SECONDS_LIMIT=""
OUT=""
IN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --budget)
      case "${2:-}" in
        pr)           BUDGET=$PR_BUDGET;   BUDGET_LABEL=pr ;;
        ''|*[!0-9]*) echo "to-gif.sh: --budget takes 'pr' or a byte count" >&2; exit 2 ;;
        *)     BUDGET="$2"; BUDGET_LABEL=custom ;;
      esac
      shift 2 ;;
    --seconds)
      [[ -n "${2:-}" ]] || { echo "to-gif.sh: --seconds needs a value" >&2; exit 2; }
      SECONDS_LIMIT="$2"; shift 2 ;;
    --out)
      [[ -n "${2:-}" ]] || { echo "to-gif.sh: --out needs a value" >&2; exit 2; }
      OUT="$2"; shift 2 ;;
    -h|--help) sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 0 ;;
    -*)        echo "to-gif.sh: unknown flag $1" >&2; exit 2 ;;
    *)
      [[ -z "$IN" ]] || { echo "to-gif.sh: only one input at a time (got $IN and $1)" >&2; exit 2; }
      IN="$1"; shift ;;
  esac
done

[[ -n "$IN" ]] || { echo "usage: to-gif.sh [--budget pr|BYTES] [--seconds N] [--out FILE] <video>" >&2; exit 2; }
[[ -f "$IN" ]] || { echo "to-gif.sh: no such file: $IN" >&2; exit 1; }
command -v ffmpeg >/dev/null || {
  echo "to-gif.sh: ffmpeg not found — brew install ffmpeg, or apt-get install ffmpeg" >&2
  exit 1
}

# Resolve through symlinks and relative spellings, so the OUT==IN comparison
# below cannot be defeated by ./rec.gif vs rec.gif or by a link.
resolve_path() {
  local p="$1" d b target hops=0
  # Follow a symlinked final component as well as the directory: without this,
  # `--out t.gif s.gif` with s -> t compares two different names for one file
  # and the mv destroys it. Bounded, so a symlink cycle cannot spin here.
  while [[ -L "$p" && $hops -lt 40 ]]; do
    target="$(readlink "$p")"
    case "$target" in
      /*) p="$target" ;;
      *)  p="$(dirname "$p")/$target" ;;
    esac
    hops=$((hops + 1))
  done
  d="$(cd "$(dirname "$p")" 2>/dev/null && pwd -P)" || return 1
  b="$(basename "$p")"
  printf '%s/%s\n' "$d" "$b"
}

if [[ -z "$OUT" ]]; then
  base="$(basename "$IN")"
  stem="${base%.*}"
  # A non-PR budget gets its own name. The skill prescribes encoding the same
  # recording twice — once for the ticket, once for the PR — and with one
  # derived name that sequence wrote the same path twice and silently kept only
  # the second.
  [[ "$BUDGET_LABEL" == "pr" ]] || stem="${stem}-${BUDGET_LABEL}"
  OUT="$(dirname "$IN")/${stem}.gif"
  # A .gif input derives its own name, and the mv below would then destroy the
  # source. That is reachable from the CLI's own advice: it tells you to run
  # to-gif.sh on an oversized file, and an oversized file is very often a GIF.
  if [[ "$(resolve_path "$OUT")" == "$(resolve_path "$IN")" ]]; then
    OUT="$(dirname "$IN")/${stem}-small.gif"
  fi
fi

# An explicit --out that names the input is a mistake worth stopping on rather
# than silently renaming around: the caller asked for that exact path.
if [[ "$(resolve_path "$OUT")" == "$(resolve_path "$IN")" ]]; then
  echo "to-gif.sh: --out is the input file ($IN) — that would destroy it" >&2
  exit 2
fi

# Check the destination is writable BEFORE encoding: a bad --out otherwise
# costs a full ladder rung and then fails at the mv.
# A directory passes the dirname tests below and then receives out.gif inside
# it, while stdout advertises the directory as though it were the file.
[[ -d "$OUT" ]] && { echo "to-gif.sh: --out is a directory: $OUT" >&2; exit 2; }
out_dir="$(dirname "$OUT")"
[[ -d "$out_dir" ]] || { echo "to-gif.sh: no such directory: $out_dir" >&2; exit 2; }
[[ -w "$out_dir" ]] || { echo "to-gif.sh: cannot write to $out_dir" >&2; exit 2; }

# Overwriting is allowed — re-running on the same input should work — but say
# so, because a clobbered file with no message is what made this worth fixing.
[[ -e "$OUT" ]] && echo "to-gif.sh: overwriting existing $OUT" >&2

# Duration is only used to explain a failure, so a missing ffprobe is not fatal.
duration=""
if command -v ffprobe >/dev/null; then
  duration="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN" 2>/dev/null | cut -d. -f1 || true)"
fi

trim=()
[[ -n "$SECONDS_LIMIT" ]] && trim=(-t "$SECONDS_LIMIT")

# The ladder. Width and fps are what actually move GIF bytes; quality degrades
# gently down this list, so the first rung that fits is the best one that fits.
# stats_mode=diff + bayer dithering are tuned for screen capture: flat UI
# colours, small moving region. Floyd-Steinberg roughly doubles the size here
# by scattering noise the palette then has to encode.
LADDER=(
  "1280 15" "1280 12" "1100 12" "960 12"
  "960 10"  "800 10"  "800 8"   "720 8"
  "640 8"   "640 6"   "480 6"
)

# One directory, not two `mktemp -t` calls: those create the extension-less
# files too, and only the .png/.gif suffixed names were being cleaned up, so
# every run leaked a pair. The directory is created by us and removed whole.
# The template needs its own X's: GNU mktemp reads `-t capturegif` as a template
# and exits 1 with "too few X's", which `set -e` turns into a silent abort
# before the first rung. This script runs on Linux — the stat calls below carry
# GNU fallbacks — and SKILL.md already documents this exact trap.
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/capturegif.XXXXXXXX")"
tmp_palette="$tmp_dir/palette.png"
tmp_out="$tmp_dir/out.gif"
cleanup() { [[ -n "${tmp_dir:-}" ]] && rm -rf "$tmp_dir"; }
trap cleanup EXIT

echo "to-gif.sh: budget $BUDGET bytes${duration:+, source ${duration}s}" >&2

for rung in "${LADDER[@]}"; do
  read -r width fps <<<"$rung"

  # -1 keeps the aspect ratio; :flags=lanczos keeps text legible when downscaling.
  # scale never upsamples past the source because of min(iw,W).
  filter="fps=${fps},scale='min(iw,${width})':-1:flags=lanczos"

  ffmpeg -y -v error ${trim[@]+"${trim[@]}"} -i "$IN" \
    -vf "${filter},palettegen=stats_mode=diff" "$tmp_palette" </dev/null

  ffmpeg -y -v error ${trim[@]+"${trim[@]}"} -i "$IN" -i "$tmp_palette" \
    -lavfi "${filter}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
    -loop 0 "$tmp_out" </dev/null

  size="$(stat -f%z "$tmp_out" 2>/dev/null || stat -c%s "$tmp_out")"
  printf 'to-gif.sh:   %4spx %2sfps -> %s bytes\n' "$width" "$fps" "$size" >&2

  if [[ "$size" -le "$BUDGET" ]]; then
    # -f matters: without it, an existing unwritable $OUT makes mv PROMPT under
    # a terminal, and declining (or EOF) leaves the old file in place while mv
    # still exits 0. The script would then print $OUT and succeed, and the
    # documented `GIF=$(to-gif.sh ...) && capture "$GIF"` would upload the
    # PREVIOUS gif to the PR. set -e cannot see a zero exit.
    mv -f "$tmp_out" "$OUT"
    # The stdout contract is "this path is the gif I just made", and the bug
    # above was that contract quietly going false. Assert it rather than trust
    # the exit code a second time.
    # Compare the exact encoded byte count, not merely non-empty: a STALE $OUT
    # is non-empty by construction, so `-s` passed the one case this check
    # exists for. Mutation-tested both ways against a neutered mv.
    written="$(stat -Lf%z "$OUT" 2>/dev/null || stat -Lc%s "$OUT" 2>/dev/null || echo -1)"
    if [[ "$written" != "$size" ]]; then
      echo "to-gif.sh: $OUT is $written bytes, expected $size — the move did not land" >&2
      exit 1
    fi
    printf 'to-gif.sh: %s (%s bytes, %spx %sfps)\n' "$OUT" "$size" "$width" "$fps" >&2
    echo "$OUT"
    exit 0
  fi
done

# Every rung overshot. The lever left is length, which this script will not
# guess at — trimming changes what the evidence shows.
{
  echo "to-gif.sh: could not get under $BUDGET bytes even at 480px/6fps."
  echo "to-gif.sh: GIF size is driven by duration x moving pixels. Options:"
  echo "  --seconds N   trim to the part that actually demonstrates the change"
  [[ -n "$duration" ]] && echo "                (source is ${duration}s; under ~10s is the usual target)"
  echo "  re-record a smaller region of the screen rather than the whole display"
} >&2
exit 3
