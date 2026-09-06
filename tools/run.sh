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
# Refuse and say what to run, rather than import here. check.sh's import pass costs about two
# seconds even with nothing to import, on a script reached twenty times a session, and it is also
# the pass known to rewrite project.godot and docs/ARCHITECTURE.md as a side effect -- neither is
# a price this quick, common path should pay on the chance the cache happens to be stale.
#
# **The test is which classes are cached, not which files are newer.** A modification time says
# only that a script changed, which is what every ordinary edit does -- refusing on that would
# make "edit a script, play it" cost a full import every time, which buys the fix by wrecking the
# common case. What actually breaks the boot is a `class_name` the cache has never heard of, and
# that is exactly checkable: every name declared in the tree must appear in the cache's own
# `"class": &"Name"` list. Costs a couple of greps and has no false positives.
CACHE="$PROJECT_DIR/.godot/global_script_class_cache.cfg"
if [[ ! -f "$CACHE" ]]; then
    echo "no class cache at ${CACHE#"$PROJECT_DIR"/}, so no global class resolves" >&2
    echo "run tools/check.sh once to build it, then try again" >&2
    exit 1
fi
missing=$(comm -23 \
    <(grep -rhE '^class_name [A-Za-z_][A-Za-z0-9_]*' \
            --include='*.gd' "$PROJECT_DIR/src" "$PROJECT_DIR/tests" \
        | awk '{print $2}' | sort -u) \
    <(grep -oE '"class": &"[A-Za-z_][A-Za-z0-9_]*"' "$CACHE" \
        | sed 's/.*&"//; s/"$//' | sort -u))
if [[ -n "$missing" ]]; then
    echo "stale class cache: ${missing//$'\n'/, }" >&2
    echo "  declared in the tree but absent from ${CACHE#"$PROJECT_DIR"/}," >&2
    echo "  so every reference to them fails to parse" >&2
    echo "run tools/check.sh to rebuild it -- then check git status, because its import" >&2
    echo "pass sometimes rewrites project.godot and docs/ARCHITECTURE.md as a side effect" >&2
    exit 1
fi

# `--` separates Godot's own arguments from the game's.
exec "$GODOT" --path "$PROJECT_DIR" -- "$@"
