#!/usr/bin/env bash
# Exercises .claude/hooks/project-rules.sh, session-rules.sh and lint-docs.sh directly, feeding
# them the same synthetic hook JSON on stdin the harness would, under a private TMPDIR so no run
# of this script ever touches a real session's markers.
#
#   tools/test_rules_hooks.sh
#
# Asserts:
#   - the main session and a sub-agent (same session_id, different agent_id) each get godot on
#     their own first .gd edit
#   - a second edit by the same agent gets nothing (the marker already stops it)
#   - after a SessionStart with source:compact, the main session gets orchestrating again and a
#     sub-agent's own markers from before the compact are untouched
#   - each path added to the mapping (src/routes/**, src/city/traffic_signals.gd,
#     src/city/traffic_light.gd, src/ground_shape.gd, src/autoload/telemetry.gd) injects its skill
#   - src/visuals/** gets no illustrated-png, which art/illustrated/** alone receives
#   - lint-docs.sh ignores a doc under docs/evidence/ and still lints a top-level docs/*.md
#   - docs/todo/**, docs/review/**, docs/TODO.md and every playtest bring playtest-feedback
#   - lint-docs.sh lints an edited file of the queue, the review items, the records and the
#     playtests (the last two for the duplicate-name check only)
#
# Needs nothing but bash and the hooks under test -- no uv, no Godot -- so it can run anywhere
# tools/test_cli_help.sh does, right beside it in CI.
#
# Bash 3.2-safe (no associative arrays, no globstar) -- the same reason the rest of tools/ stays
# this side of bash 4; see tools/lint.sh's own header.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

usage() {
    cat <<'EOF'
usage: tools/test_rules_hooks.sh [--help|-h]

Exercises .claude/hooks/project-rules.sh, session-rules.sh and lint-docs.sh with synthetic hook
JSON on stdin, under a private TMPDIR, and asserts the per-agent marker keying, the
compaction/resume reset, every path added to the skill mapping, and the lint-docs.sh governed set.
Takes no arguments besides --help/-h.

  tools/test_rules_hooks.sh
EOF
}

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
        *)
            echo "unknown option: $arg" >&2
            echo >&2
            usage >&2
            exit 2
            ;;
    esac
done

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
TMPDIR="$work_dir"
export TMPDIR

state_root="$TMPDIR/claude-nappy-rules"

checks=0
failures=0

fail() {
    echo "FAIL $1" >&2
    failures=$((failures + 1))
}

# Prints the sorted, comma-joined, deduplicated list of skill names project-rules.sh injected for
# one Edit of $3 (a path relative to $root), for session $1 and agent $2 ("" for the main session).
project_rules_skills() {
    local sess="$1" agent="$2" relpath="$3" payload
    if [ -n "$agent" ]; then
        payload=$(printf '{"session_id":"%s","agent_id":"%s","tool_name":"Edit","tool_input":{"file_path":"%s"}}' \
            "$sess" "$agent" "$root/$relpath")
    else
        payload=$(printf '{"session_id":"%s","tool_name":"Edit","tool_input":{"file_path":"%s"}}' \
            "$sess" "$root/$relpath")
    fi
    printf '%s' "$payload" \
        | "$root/.claude/hooks/project-rules.sh" \
        | jq -r '.hookSpecificOutput.additionalContext // empty' \
        | grep -o 'project rule: [a-z-]*' \
        | sed 's/project rule: //' \
        | sort -u \
        | tr '\n' ','
}

# Prints the sorted, comma-joined, deduplicated list of skill names session-rules.sh injected for
# one SessionStart of session $1, agent $2 ("" for the main session), source $3.
session_rules_skills() {
    local sess="$1" agent="$2" src="$3" payload
    if [ -n "$agent" ]; then
        payload=$(printf '{"session_id":"%s","agent_id":"%s","source":"%s"}' "$sess" "$agent" "$src")
    else
        payload=$(printf '{"session_id":"%s","source":"%s"}' "$sess" "$src")
    fi
    printf '%s' "$payload" \
        | "$root/.claude/hooks/session-rules.sh" \
        | jq -r '.hookSpecificOutput.additionalContext // empty' \
        | grep -o 'project rule: [a-z-]*' \
        | sed 's/project rule: //' \
        | sort -u \
        | tr '\n' ','
}

# $1 label  $2 expected (comma-joined, may be empty)  $3 actual
assert_eq() {
    checks=$((checks + 1))
    if [ "$2" = "$3" ]; then
        echo "ok   $1"
    else
        fail "$1: expected [$2], got [$3]"
    fi
}

# ---------------------------------------------------------------- per-agent marker keying -----
# A synthetic top-level .gd file: not under src/, tests/ or tools/, so the only case arm that can
# fire is the bare `*.gd` -> godot one. Isolates the per-agent and second-touch behaviour from
# every other mapping under test below.
gd_file="zz_test_rules_hooks_probe.gd"

assert_eq "main session, first .gd edit -> godot" \
    "godot," "$(project_rules_skills main-session "" "$gd_file")"
assert_eq "main session, second .gd edit -> nothing" \
    "" "$(project_rules_skills main-session "" "$gd_file")"

assert_eq "sub-agent, same session, first .gd edit -> godot (own marker)" \
    "godot," "$(project_rules_skills main-session sub-agent-a "$gd_file")"
assert_eq "sub-agent, second .gd edit -> nothing" \
    "" "$(project_rules_skills main-session sub-agent-a "$gd_file")"

# A second, distinct sub-agent in the same session must also get its own first touch -- proof
# the keying is per-agent, not just "main vs. one other".
assert_eq "second sub-agent, same session, first .gd edit -> godot (own marker)" \
    "godot," "$(project_rules_skills main-session sub-agent-b "$gd_file")"

# ------------------------------------------------------------- compaction brings rules back ----
compact_session="compact-session"
# Establish the main session's orchestrating marker (a fresh startup), and a sub-agent's own
# markers via a real edit, before compacting.
session_rules_skills "$compact_session" "" startup >/dev/null
sub_before="$(project_rules_skills "$compact_session" sub-agent-c "src/city/traffic_signals.gd")"
assert_eq "sub-agent under $compact_session picks up city + crowd-traffic + godot + orchestrating before compact" \
    "city,crowd-traffic,godot,orchestrating," "$sub_before"

after_compact="$(session_rules_skills "$compact_session" "" compact)"
assert_eq "main session gets orchestrating again after source:compact" \
    "orchestrating," "$after_compact"

sub_state_dir="$state_root/$compact_session-sub-agent-c"
checks=$((checks + 1))
sub_markers="$(ls "$sub_state_dir" 2>/dev/null | sort | tr '\n' ',')"
if [ "$sub_markers" = "city,crowd-traffic,godot,orchestrating," ]; then
    echo "ok   sub-agent's own markers survive the main session's compact untouched"
else
    fail "sub-agent's own markers changed across the main session's compact: got [$sub_markers]"
fi

# A sub-agent's own compact must likewise only ever clear its own directory.
sub_after_own_compact="$(session_rules_skills "$compact_session" sub-agent-c compact)"
assert_eq "a sub-agent's own source:compact re-injects orchestrating for that sub-agent" \
    "orchestrating," "$sub_after_own_compact"

# ------------------------------------------------------------------------- new path mappings ---
assert_eq "src/routes/street_network.gd -> city (M... routes gap)" \
    "city,godot,orchestrating," "$(project_rules_skills routes-session "" "src/routes/street_network.gd")"
assert_eq "src/city/traffic_signals.gd -> city + crowd-traffic" \
    "city,crowd-traffic,godot,orchestrating," "$(project_rules_skills traffic-signals-session "" "src/city/traffic_signals.gd")"
assert_eq "src/city/traffic_light.gd -> city + crowd-traffic" \
    "city,crowd-traffic,godot,orchestrating," "$(project_rules_skills traffic-light-session "" "src/city/traffic_light.gd")"
assert_eq "src/ground_shape.gd -> crowd-traffic (not city -- it is not under src/city/)" \
    "crowd-traffic,godot,orchestrating," "$(project_rules_skills ground-shape-session "" "src/ground_shape.gd")"
assert_eq "src/autoload/telemetry.gd -> telemetry" \
    "godot,orchestrating,telemetry," "$(project_rules_skills telemetry-session "" "src/autoload/telemetry.gd")"

# src/visuals/ holds loader code, not pictures: it gets the GDScript rules and never the
# PNG-drawing ones, which govern art/illustrated/ alone.
assert_eq "src/visuals/atlas_library.gd -> godot + orchestrating, not illustrated-png" \
    "godot,orchestrating," "$(project_rules_skills visuals-session "" "src/visuals/atlas_library.gd")"
assert_eq "art/illustrated/**.png -> illustrated-png" \
    "illustrated-png," "$(project_rules_skills illustrated-session "" "art/illustrated/svg-transfer/x/y.png")"

# The queue, the review items and the playtests all bring playtest-feedback: an entry's context
# file and an item file, a review item, a new playtest named by date and two words, and an old
# numbered one.
assert_eq "docs/todo/<entry>/README.md -> playtest-feedback" \
    "playtest-feedback," "$(project_rules_skills todo-readme-session "" "docs/todo/2026-09-26-M210/README.md")"
assert_eq "docs/todo/<entry>/<item>.md -> playtest-feedback" \
    "playtest-feedback," "$(project_rules_skills todo-item-session "" "docs/todo/2026-09-27-busy-otter/stack-in-front.md")"
assert_eq "docs/review/<name>.md -> playtest-feedback" \
    "playtest-feedback," "$(project_rules_skills review-session "" "docs/review/2026-09-27-busy-otter.md")"
assert_eq "docs/playtests/<date>-<words>.md -> playtest-feedback" \
    "playtest-feedback," "$(project_rules_skills new-playtest-session "" "docs/playtests/2026-09-27-quiet-heron.md")"
assert_eq "docs/playtests/PLAYTEST-NN.md -> playtest-feedback" \
    "playtest-feedback," "$(project_rules_skills old-playtest-session "" "docs/playtests/PLAYTEST-144.md")"
assert_eq "docs/TODO.md -> playtest-feedback" \
    "playtest-feedback," "$(project_rules_skills todo-session "" "docs/TODO.md")"
assert_eq "docs/decisions/<name>.md -> nothing (a record is written under committing, not a playtest)" \
    "" "$(project_rules_skills decisions-session "" "docs/decisions/2026-09-27-busy-otter.md")"

# Control: an unrelated src/city/*.gd file gets city but not crowd-traffic, proving the new
# crowd-traffic mapping is scoped to the three named files and not all of src/city/.
assert_eq "src/city/some_other_file.gd -> city only, not crowd-traffic" \
    "city,godot,orchestrating," "$(project_rules_skills control-session "" "src/city/some_other_file.gd")"

# ---------------------------------------------------------- lint-docs.sh's governed set ---------
# lint-docs.sh reads the file through tools/lint.sh, so this needs paths that actually exist.
# docs/TODO.md is a real, already-committed, always-lint-clean doc (CI's own lint.sh run requires
# it), so a violation can't be planted in it without risking a real file; instead this checks with
# a debug trace of the hook's own `governed` decision, which is set before tools/lint.sh is ever
# invoked and needs no file content at all to observe.
todo_trace="$(printf '{"tool_input":{"file_path":"%s"}}' "$root/docs/TODO.md" \
    | bash -x "$root/.claude/hooks/lint-docs.sh" 2>&1 >/dev/null)"
checks=$((checks + 1))
if printf '%s' "$todo_trace" | grep -q '^+ governed=1$'; then
    echo "ok   docs/TODO.md is still in lint-docs.sh's governed set"
else
    fail "docs/TODO.md is no longer governed by lint-docs.sh"
fi

# The queue's files and the review items are governed; so, for the duplicate-name check alone,
# are a record and a playtest (lint.sh spares them the sentence rules). A file nested deeper than
# an entry's own is not. None of these need exist: the decision is made before the file is read.
governed_trace() {
    printf '{"tool_input":{"file_path":"%s"}}' "$root/$1" \
        | bash -x "$root/.claude/hooks/lint-docs.sh" 2>&1 >/dev/null | grep -c '^+ governed=1$'
}
for governed_path in docs/todo/2026-09-26-M210/README.md docs/todo/2026-09-26-M210/an-item.md \
    docs/review/2026-09-27-busy-otter.md docs/decisions/2026-09-27-busy-otter.md \
    docs/playtests/2026-09-27-quiet-heron.md docs/playtests/PLAYTEST-144.md; do
    checks=$((checks + 1))
    if [ "$(governed_trace "$governed_path")" -ge 1 ]; then
        echo "ok   lint-docs.sh lints $governed_path"
    else
        fail "lint-docs.sh no longer lints $governed_path"
    fi
done
checks=$((checks + 1))
if [ "$(governed_trace docs/todo/2026-09-26-M210/nested/x.md)" -ge 1 ]; then
    fail "lint-docs.sh lints a file nested below an entry's own"
else
    echo "ok   lint-docs.sh ignores a file nested below an entry's own"
fi

# A path under docs/evidence/ need not exist for this half: the governed check runs, and fails to
# match, before the script ever looks at the file on disk.
evidence_trace="$(printf '{"tool_input":{"file_path":"%s"}}' "$root/docs/evidence/zz-test-rules-hooks/README.md" \
    | bash -x "$root/.claude/hooks/lint-docs.sh" 2>&1 >/dev/null)"
checks=$((checks + 1))
if printf '%s' "$evidence_trace" | grep -q '^+ governed=1$'; then
    fail "docs/evidence/.../README.md is wrongly governed by lint-docs.sh"
else
    echo "ok   lint-docs.sh ignores docs/evidence/.../README.md"
fi

# And end to end, with a real file, on the exact shape that used to slip through: a doc buried
# under docs/evidence/ with a branch-name-shaped string produces no additionalContext at all.
evidence_dir="$root/docs/evidence/zz-test-rules-hooks"
mkdir -p "$evidence_dir"
printf '# smoke\n\nthis references feature/some-branch on the line lint.sh would flag.\n' > "$evidence_dir/README.md"
evidence_output="$(printf '{"tool_input":{"file_path":"%s"}}' "$evidence_dir/README.md" \
    | "$root/.claude/hooks/lint-docs.sh")"
rm -rf "$evidence_dir"
checks=$((checks + 1))
if [ -z "$evidence_output" ]; then
    echo "ok   lint-docs.sh prints nothing for a branch-name-shaped hit under docs/evidence/"
else
    fail "lint-docs.sh flagged a doc under docs/evidence/: $evidence_output"
fi

echo
echo "$checks checks, $failures failures"
if [ "$failures" -gt 0 ]; then
    exit 1
fi
