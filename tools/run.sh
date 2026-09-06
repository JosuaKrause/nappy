#!/usr/bin/env bash
# Play the game. Everything you pass is forwarded to the game as a dev flag.
#
#   tools/run.sh                        # a fresh run
#   tools/run.sh --seed 12345           # a specific city
#   tools/run.sh --day 9 --overview     # look at act III from above
#
# See README.md for the full flag list.
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT" >&2
    echo "install Godot 4.7, or point GODOT at your binary:" >&2
    echo "  GODOT=/path/to/Godot tools/run.sh" >&2
    exit 127
fi

# This execs the binary straight at the project with no import pass of its own, so a checkout
# whose .godot/global_script_class_cache.cfg predates a pulled class_name boots straight into
# 'Identifier "X" not declared in the current scope' -- that cache is how Godot knows a global
# class exists at all, and playing the game (unlike tools/check.sh's own --import) never rebuilds
# it. It is reachable from every `git pull` that adds a class_name, and from no gate: CI and
# check.sh both import from clean, which is exactly why check.sh is green on a tree that will not
# run.
#
# **So detect it here and fix it here, rather than printing an instruction.** The detection is
# cheap enough to pay on every run and the repair only happens when it is actually needed, so the
# common path is unchanged and the rare one just starts. check.sh's own import pass now reverts
# the project.godot and docs/ARCHITECTURE.md rewrites it causes, which is what made calling it
# from here safe.
#
# **The test is which classes are cached, not which files are newer.** A modification time says
# only that a script changed, which is what every ordinary edit does -- rebuilding on that would
# make "edit a script, play it" cost a full import every time. What actually breaks the boot is a
# `class_name` the cache has never heard of, and that is exactly checkable: every name declared in
# the tree must appear in the cache's own `"class": &"Name"` list. Costs a couple of greps and has
# no false positives.
CACHE="$PROJECT_DIR/.godot/global_script_class_cache.cfg"

# Names declared in the tree that the cache has never heard of, one per line; empty when the cache
# is current. A missing cache file counts as every name missing, which is the fresh-clone case.
missing_classes() {
    local declared
    declared=$(grep -rhE '^class_name [A-Za-z_][A-Za-z0-9_]*' \
            --include='*.gd' "$PROJECT_DIR/src" "$PROJECT_DIR/tests" \
        | awk '{print $2}' | sort -u)
    if [[ ! -f "$CACHE" ]]; then
        echo "$declared"
        return
    fi
    comm -23 <(echo "$declared") \
        <(grep -oE '"class": &"[A-Za-z_][A-Za-z0-9_]*"' "$CACHE" \
            | sed 's/.*&"//; s/"$//' | sort -u)
}

missing=$(missing_classes)
if [[ -n "$missing" ]]; then
    if [[ -f "$CACHE" ]]; then
        echo "stale class cache: ${missing//$'\n'/, }" >&2
        echo "  declared in the tree but absent from ${CACHE#"$PROJECT_DIR"/}," >&2
        echo "  so every reference to them would fail to parse" >&2
    else
        echo "no class cache at ${CACHE#"$PROJECT_DIR"/}, so no global class resolves" >&2
    fi
    echo "rebuilding it with tools/check.sh -- this takes a few seconds" >&2
    if ! "$PROJECT_DIR/tools/check.sh" >/dev/null; then
        echo "tools/check.sh failed; run it directly to see why" >&2
        exit 1
    fi
    missing=$(missing_classes)
    if [[ -n "$missing" ]]; then
        echo "still absent after the rebuild: ${missing//$'\n'/, }" >&2
        echo "the import pass ran and did not register them, so this is not a stale cache" >&2
        exit 1
    fi
    echo "class cache rebuilt" >&2
fi

# `--` separates Godot's own arguments from the game's.
exec "$GODOT" --path "$PROJECT_DIR" -- "$@"
