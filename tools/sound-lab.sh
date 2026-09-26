#!/usr/bin/env bash
# Builds and serves the Copper lark sound-effects listening lab locally, instead of downloading a
# zip and an index.html from a pull request each time.
#
#   tools/sound-lab.sh                    # build + serve the current pass on localhost:8070
#   tools/sound-lab.sh --no-serve         # build only; print the directory and stop
#   tools/sound-lab.sh --lan              # also print an address a phone on the network can open
#   tools/sound-lab.sh 8090               # a different port
#
# The player, 2026-09-26: "its findings are useful but I'm a bit irritated by having to download
# an index.html each time. is there a better way to approach this?" -- on a local command that
# builds and serves the listening page: "yeah I'd prefer a local command"; "same as with the
# trailer / video" (tools/trailer.sh, which renders into gitignored build/ from a committed shot
# list, tools/trailer/shots.json). This is that shape for sound: tools/sound-lab/passes.json
# records the one current pass's seed, extra flags and its own expected hashes -- the smallest
# committed description that lets this script confirm a rebuild matches -- and this script runs
# the tracked tools/synthesize-sfx.py directly (no pinned commit: a pass is squashed away with
# every other branch commit, per the player, 2026-09-26: "yes 384 will get squashed so no
# scrubbing necessary"), checks the result against the recipe's own recorded hashes, and serves it
# from git-ignored build/sound-lab/<pass>/. Nothing here is committed audio: see
# .claude/skills/sound-effects.
#
# A new pass is made by changing the generator's defaults or tools/sound-lab/passes.json's args,
# rebuilding, listening, and once it is worth keeping, overwriting passes.json's seed/args/label
# and every hash with the new build's own -- there is exactly one recorded pass, the current one.
# Live iteration on the generator before it is worth freezing this way is
# `uv run python tools/synthesize-sfx.py` straight, per the sound-effects skill, into a scratch
# --output of your own choosing.
#
# SOUND_LAB_RECIPE_FILE and SOUND_LAB_BUILD_ROOT override the recipe path and the directory a
# pass is rebuilt into; both are test-only escape hatches (tools/test_cli_help.py points them at a
# scratch recipe and a tempfile.TemporaryDirectory() rather than the real passes.json and
# build/sound-lab/, so a test run's own `rm -rf` never touches the checkout, whether the test is
# checking an ordinary rebuild or a rejected malformed pass name). Nobody runs the tool this way by
# hand, so they are not flags.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="$PROJECT_DIR/tools/synthesize-sfx.py"
RECIPE_FILE="${SOUND_LAB_RECIPE_FILE:-$PROJECT_DIR/tools/sound-lab/passes.json}"
BUILD_ROOT="${SOUND_LAB_BUILD_ROOT:-$PROJECT_DIR/build/sound-lab}"

usage() {
    cat <<'EOF'
usage: tools/sound-lab.sh [--help|-h] [--lan] [--no-serve] [port]

Rebuilds the Copper lark sound-effects listening pass tools/sound-lab/passes.json records from
the tracked tools/synthesize-sfx.py, writes it to git-ignored build/sound-lab/<pass>/, verifies
every WAV against the recipe's own recorded hashes, and serves it over plain HTTP.

  --lan          also print an address a phone on the same network can open
  --no-serve     build and verify only; print the directory and stop, serving nothing
  port           the local port to serve on (default: 8070)

  tools/sound-lab.sh
  tools/sound-lab.sh --no-serve
  tools/sound-lab.sh --lan
EOF
}

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
    esac
done

LAN=0
NO_SERVE=0
PORT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --lan) LAN=1; shift ;;
        --no-serve) NO_SERVE=1; shift ;;
        -*)
            echo "sound-lab.sh: unrecognized option: $1" >&2
            echo >&2
            usage >&2
            exit 1
            ;;
        *)
            if [[ -n "$PORT" ]]; then
                echo "sound-lab.sh: unexpected extra argument: $1" >&2
                echo >&2
                usage >&2
                exit 1
            fi
            if ! [[ "$1" =~ ^[0-9]+$ ]]; then
                echo "sound-lab.sh: port must be a number, got '$1'" >&2
                echo >&2
                usage >&2
                exit 1
            fi
            PORT="$1"
            shift
            ;;
    esac
done
PORT="${PORT:-8070}"

if ! command -v jq >/dev/null 2>&1; then
    echo "sound-lab.sh: jq not found on PATH" >&2
    exit 127
fi
if ! command -v uv >/dev/null 2>&1; then
    echo "sound-lab.sh: uv not found -- see .claude/skills/python-tooling/SKILL.md" >&2
    exit 127
fi
if [[ ! -f "$RECIPE_FILE" ]]; then
    echo "sound-lab.sh: no recipe file at ${RECIPE_FILE#"$PROJECT_DIR"/}" >&2
    exit 1
fi

# ------------------------------------------------------------------ the recipe file, checked ---
schema_errors="$(jq -r '
    . as $top |
    def num: type == "number";
    (if ($top.pass | type) == "string" and ($top.pass | test("^[A-Za-z0-9][A-Za-z0-9._-]*$"))
        then empty else "pass must be a non-empty name of letters, digits, dot, dash or underscore" end),
    (if (.seed | num) then empty else "seed must be a number" end),
    (if (.args // [] | type) == "array" then empty else "args must be an array" end),
    (if (.label | type) == "string" then empty else "label must be a string" end),
    (if (.hashes | type) == "object" and (.hashes | length) > 0 then empty
        else "hashes must be a non-empty object" end)
' "$RECIPE_FILE" 2>&1)" || {
    echo "sound-lab.sh: ${RECIPE_FILE#"$PROJECT_DIR"/} is not valid JSON" >&2
    exit 1
}
if [[ -n "$schema_errors" ]]; then
    echo "sound-lab.sh: ${RECIPE_FILE#"$PROJECT_DIR"/} is malformed:" >&2
    printf '  %s\n' "$schema_errors" >&2
    exit 1
fi

PASS_NAME="$(jq -r '.pass' "$RECIPE_FILE")"
seed="$(jq -r '.seed' "$RECIPE_FILE")"
label="$(jq -r '.label' "$RECIPE_FILE")"
args=()
while IFS= read -r word; do args+=("$word"); done < <(jq -r '.args[]?' "$RECIPE_FILE")

if [[ ! -f "$GENERATOR" ]]; then
    echo "sound-lab.sh: no generator at ${GENERATOR#"$PROJECT_DIR"/}" >&2
    exit 1
fi

OUT_DIR="$BUILD_ROOT/$PASS_NAME"
echo "building '$PASS_NAME' ($label)" >&2
echo "  seed $seed${args[*]:+, ${args[*]}}" >&2
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
if ! (cd "$PROJECT_DIR" && uv run --quiet python "$GENERATOR" --output "$OUT_DIR" --seed "$seed" \
        ${args[@]+"${args[@]}"}); then
    echo "sound-lab.sh: the generator failed for '$PASS_NAME'" >&2
    exit 1
fi

# --------------------------- every recorded hash is checked, so a drift is a stop, not a stale page ---
mismatch=0
checked=0
while IFS=$'\t' read -r filename expected; do
    checked=$(( checked + 1 ))
    actual="$(shasum -a 256 "$OUT_DIR/$filename" 2>/dev/null | cut -d' ' -f1)"
    if [[ -z "$actual" ]]; then
        echo "sound-lab.sh: '$PASS_NAME' recipe names $filename, which the generator did not write" >&2
        mismatch=1
    elif [[ "$actual" != "$expected" ]]; then
        echo "sound-lab.sh: '$PASS_NAME'/$filename hash drifted (recipe $expected, built $actual)" >&2
        mismatch=1
    fi
done < <(jq -r '.hashes | to_entries[] | "\(.key)\t\(.value)"' "$RECIPE_FILE")
if [[ "$checked" -eq 0 ]]; then
    echo "sound-lab.sh: '$PASS_NAME' recorded no hashes to verify" >&2
    exit 1
fi
if [[ "$mismatch" -ne 0 ]]; then
    echo "sound-lab.sh: '$PASS_NAME' did not rebuild byte-for-byte; see above" >&2
    exit 1
fi
echo "verified: all $checked recorded hashes for '$PASS_NAME' match" >&2

if [[ "$NO_SERVE" -eq 1 ]]; then
    echo "built (not served): ${OUT_DIR#"$PROJECT_DIR"/}"
    exit 0
fi

bind="127.0.0.1"
echo
echo "serving ${OUT_DIR#"$PROJECT_DIR"/}"
echo "open:  http://localhost:$PORT/index.html"
if [[ "$LAN" -eq 1 ]]; then
    bind="0.0.0.0"
    lan_ip=""
    for iface in en0 en1 en2; do
        lan_ip="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
        [[ -n "$lan_ip" ]] && break
    done
    if [[ -n "$lan_ip" ]]; then
        echo "phone: http://$lan_ip:$PORT/index.html"
    else
        echo "sound-lab.sh: --lan could not find a network address on en0/en1/en2" >&2
    fi
fi
echo "(Ctrl-C to stop)"
cd "$OUT_DIR" && exec python3 -m http.server --bind "$bind" "$PORT"
