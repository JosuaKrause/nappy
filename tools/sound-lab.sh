#!/usr/bin/env bash
# Builds and serves the Copper lark sound-effects listening lab locally, instead of downloading a
# zip and an index.html from a pull request each time.
#
#   tools/sound-lab.sh                    # build + serve the newest pass on localhost:8070
#   tools/sound-lab.sh --pass pass-3      # a named pass instead of the newest
#   tools/sound-lab.sh --no-serve         # build only; print the directory and stop
#   tools/sound-lab.sh --lan              # also print an address a phone on the network can open
#   tools/sound-lab.sh 8090               # a different port
#
# The player, 2026-09-26: "its findings are useful but I'm a bit irritated by having to download
# an index.html each time. is there a better way to approach this?" -- on a local command that
# builds and serves the listening page: "yeah I'd prefer a local command"; "same as with the
# trailer / video" (tools/trailer.sh, which renders into gitignored build/ from a committed shot
# list, tools/trailer/shots.json). This is that shape for sound: tools/sound-lab/passes.json
# records the seed, extra flags and the exact commit whose tools/synthesize-sfx.py built each
# pass -- the smallest committed description that rebuilds a pass byte for byte -- and this script
# extracts that commit's generator with `git show`, runs it through the locked `uv` environment,
# checks the result against the recipe's own recorded hashes, and serves the pass from git-ignored
# build/sound-lab/<pass>/. Nothing here is committed audio: see .claude/skills/sound-effects.
#
# Every pass is rebuilt from its own commit rather than the tracked tools/synthesize-sfx.py
# directly, uniformly: a pass is a frozen listening artifact, and pinning it to the commit that
# made it is what lets it keep rebuilding byte for byte after the generator moves on. Live
# iteration on the generator itself is `uv run python tools/synthesize-sfx.py` straight, per the
# sound-effects skill, into a scratch --output of your own choosing.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECIPE_FILE="$PROJECT_DIR/tools/sound-lab/passes.json"
BUILD_ROOT="$PROJECT_DIR/build/sound-lab"

usage() {
    cat <<'EOF'
usage: tools/sound-lab.sh [--help|-h] [--pass NAME] [--lan] [--no-serve] [port]

Rebuilds a Copper lark sound-effects listening pass from tools/sound-lab/passes.json and the
generator commit that built it, writes it to git-ignored build/sound-lab/<pass>/, verifies every
WAV against the recipe's own recorded hashes, and serves it over plain HTTP.

  --pass NAME    a pass named in tools/sound-lab/passes.json (default: the newest)
  --lan          also print an address a phone on the same network can open
  --no-serve     build and verify only; print the directory and stop, serving nothing
  port           the local port to serve on (default: 8070)

  tools/sound-lab.sh
  tools/sound-lab.sh --pass pass-3 --no-serve
  tools/sound-lab.sh --lan
EOF
}

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
    esac
done

PASS_NAME=""
LAN=0
NO_SERVE=0
PORT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pass)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "sound-lab.sh: --pass is missing its name" >&2
                echo >&2
                usage >&2
                exit 1
            fi
            PASS_NAME="$2"
            shift 2
            ;;
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
    (if ($top.default_pass | type) == "string" then empty else "default_pass must be a string" end),
    (if ($top.passes | type) == "object" and ($top.passes | length) > 0 then empty
        else "passes must be a non-empty object" end),
    ($top.passes | to_entries[] |
        (.key) as $n |
        (if (.value.generator_commit | type) == "string"
            and (.value.generator_commit | test("^[0-9a-f]{40}$"))
            then empty else "\($n): generator_commit must be a 40-character commit hash" end),
        (if (.value.seed | num) then empty else "\($n): seed must be a number" end),
        (if (.value.args // [] | type) == "array" then empty else "\($n): args must be an array" end),
        (if (.value.hashes | type) == "object" and (.value.hashes | length) > 0 then empty
            else "\($n): hashes must be a non-empty object" end)
    ),
    (if ($top.passes | has($top.default_pass)) then empty
        else "default_pass (\($top.default_pass)) names no pass in passes" end)
' "$RECIPE_FILE" 2>&1)" || {
    echo "sound-lab.sh: ${RECIPE_FILE#"$PROJECT_DIR"/} is not valid JSON" >&2
    exit 1
}
if [[ -n "$schema_errors" ]]; then
    echo "sound-lab.sh: ${RECIPE_FILE#"$PROJECT_DIR"/} is malformed:" >&2
    printf '  %s\n' "$schema_errors" >&2
    exit 1
fi

if [[ -z "$PASS_NAME" ]]; then
    PASS_NAME="$(jq -r '.default_pass' "$RECIPE_FILE")"
fi
if ! jq -e --arg n "$PASS_NAME" '.passes | has($n)' "$RECIPE_FILE" >/dev/null; then
    known="$(jq -r '.passes | keys | join(", ")' "$RECIPE_FILE")"
    echo "sound-lab.sh: no pass named '$PASS_NAME' (known: $known)" >&2
    exit 1
fi

commit="$(jq -r --arg n "$PASS_NAME" '.passes[$n].generator_commit' "$RECIPE_FILE")"
seed="$(jq -r --arg n "$PASS_NAME" '.passes[$n].seed' "$RECIPE_FILE")"
label="$(jq -r --arg n "$PASS_NAME" '.passes[$n].label' "$RECIPE_FILE")"
args=()
while IFS= read -r word; do args+=("$word"); done < <(jq -r --arg n "$PASS_NAME" '.passes[$n].args[]?' "$RECIPE_FILE")

if ! git -C "$PROJECT_DIR" cat-file -e "$commit" 2>/dev/null; then
    echo "sound-lab.sh: commit $commit (recorded for '$PASS_NAME') is not reachable in this checkout" >&2
    echo "(a shallow clone may need 'git fetch --unshallow')" >&2
    exit 1
fi

TEMP_GENERATOR=""
cleanup() { [[ -n "$TEMP_GENERATOR" ]] && rm -f "$TEMP_GENERATOR"; }
trap cleanup EXIT

GENERATOR="$(mktemp "${TMPDIR:-/tmp}/sound-lab-generator.XXXXXX.py")"
TEMP_GENERATOR="$GENERATOR"
if ! git -C "$PROJECT_DIR" show "$commit:tools/synthesize-sfx.py" > "$GENERATOR" 2>/dev/null; then
    echo "sound-lab.sh: cannot rebuild '$PASS_NAME' -- tools/synthesize-sfx.py is unreadable at $commit" >&2
    exit 1
fi

OUT_DIR="$BUILD_ROOT/$PASS_NAME"
echo "building '$PASS_NAME' ($label)" >&2
echo "  generator: $commit, seed $seed${args[*]:+, ${args[*]}}" >&2
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
done < <(jq -r --arg n "$PASS_NAME" '.passes[$n].hashes | to_entries[] | "\(.key)\t\(.value)"' "$RECIPE_FILE")
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

echo
echo "serving ${OUT_DIR#"$PROJECT_DIR"/}"
echo "open:  http://localhost:$PORT/index.html"
if [[ "$LAN" -eq 1 ]]; then
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
cleanup
trap - EXIT
cd "$OUT_DIR" && exec python3 -m http.server "$PORT"
