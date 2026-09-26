#!/usr/bin/env bash
# Exercises .claude/hooks/project-rules.sh, session-rules.sh, lint-docs.sh and git-grep-guard.sh
# directly, feeding them the same synthetic hook JSON on stdin the harness would, under a private
# TMPDIR so no run of this script ever touches a real session's markers.
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
#   - git-grep-guard.sh denies a git grep with neither -I nor a text-only pathspec, however it is
#     spelled (git -C <dir> grep, git --no-pager grep, an unrecognised global option such as
#     -c name=value or --git-dir=...) or wherever it sits (a for loop, after &&/;/|, an unquoted
#     newline, inside $(...)), skips a heredoc body rather than scanning it as a command, and
#     passes a guarded one, an rg call and a mere mention of the words
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

Exercises .claude/hooks/project-rules.sh, session-rules.sh, lint-docs.sh and git-grep-guard.sh
with synthetic hook JSON on stdin, under a private TMPDIR, and asserts the per-agent marker
keying, the compaction/resume reset, every path added to the skill mapping, the lint-docs.sh
governed set, and every git-grep-guard.sh deny/allow shape.
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

# ---------------------------------------------------------------- git-grep-guard.sh -------------
# Prints "deny" or "allow" for one synthetic Bash command through git-grep-guard.sh.
guard_decision() {
    local cmd="$1" raw
    raw=$(jq -n --arg c "$cmd" '{tool_name:"Bash", tool_input:{command:$c}}' \
        | "$root/.claude/hooks/git-grep-guard.sh")
    if [ -z "$raw" ]; then
        printf 'allow'
    else
        printf '%s' "$raw" | jq -r '.hookSpecificOutput.permissionDecision'
    fi
}

# $1 label  $2 expected ("deny" or "allow")  $3 command
assert_guard() {
    checks=$((checks + 1))
    local got
    got="$(guard_decision "$3")"
    if [ "$got" = "$2" ]; then
        echo "ok   $1"
    else
        fail "$1: expected $2, got $got for: $3"
    fi
}

assert_guard "no -I, no text pathspec, one tree -> deny" deny \
    'git grep -n -i "wrap.*corner\|goes around" origin/main -- docs/'
assert_guard "no -I, working tree only -> deny" deny \
    'git grep -n -i "wrap.*corner\|goes around" -- docs/'
assert_guard "no -- pathspec at all -> deny" deny \
    'git grep -n -i "foo" origin/main'
assert_guard "git -C <dir> grep, no -I -> deny" deny \
    'git -C /tmp/other grep -n -i "foo" origin/main -- docs/'
assert_guard "git --no-pager grep, no -I -> deny" deny \
    'git --no-pager grep -n -i "foo" origin/main -- docs/'
assert_guard "after && -> deny" deny \
    'echo hi && git grep -i "foo" origin/main -- docs/'
assert_guard "inside \$(...) -> deny" deny \
    'x=$(git grep -c "foo" origin/main -- docs/); echo "$x"'
assert_guard "for loop body -> deny" deny \
    'for b in origin/main origin/other; do git grep -n -i "foo" $b -- docs/; done'
assert_guard "multiple trees, no -I -> deny" deny \
    'git grep -n -i "foo" origin/main origin/other -- docs/'

assert_guard "-I present -> allow" allow \
    'git grep -n -I -i "wrap.*corner\|goes around" origin/main -- docs/'
assert_guard "bundled -Ii -> allow" allow \
    'git grep -Ii "foo" origin/main -- docs/'
assert_guard "text-only pathspec -> allow" allow \
    "git grep -n -i 'wrap.*corner' origin/main -- 'docs/*.md'"
assert_guard "rg on the checkout -> allow" allow \
    'rg -n -i "wrap.*corner|goes around" docs/'
assert_guard "echo mentions the words -> allow" allow \
    'echo "git grep is dangerous, be careful"'
assert_guard "commit message mentions the words -> allow" allow \
    'git commit -m "explains why git grep needs a guard now"'
assert_guard "rg quoting the phrase -> allow" allow \
    'rg "git grep"'
assert_guard "unrelated git command -> allow" allow \
    'git status'

# An unquoted newline separates commands exactly like `;` -- a review of the pull request that
# added this file found both of these passed silently, and the second is the incident command
# itself, split onto its own line rather than piped from a single command.
assert_guard "git grep on its own line after an unrelated command -> deny" deny \
    'cd /x
git grep -n -i "wrap.*corner" -- docs/'
assert_guard "incident command's own shape: git fetch, then git grep on the next line -> deny" deny \
    'git fetch -q origin main
git grep -n -i "wrap.*corner" origin/main -- docs/'
assert_guard "guarded git grep on its own line -> allow" allow \
    'cd /x
git grep -n -I -i "wrap.*corner" origin/main -- docs/'

# A heredoc body is never executed, so a mention inside one is not a command and must not be
# scanned -- and must not be mistaken for ending the real command that follows it either.
assert_guard "heredoc body mentions the words, no real invocation follows -> allow" allow \
    'cat <<EOF
please run git grep sometime
EOF'
assert_guard "heredoc body mentions the words, an unsafe invocation follows -> deny" deny \
    'cat <<EOF
mentions git grep here
EOF
git grep -n -i "foo" origin/main -- docs/'
assert_guard "heredoc with a quoted delimiter still skips its body -> allow" allow \
    "cat <<'EOF'
git grep -n -i foo origin/main -- docs/
EOF
git status"
assert_guard "heredoc with <<- and a tab-indented delimiter still skips its body -> allow" allow \
    'cat <<-EOF
	git grep -n -i foo origin/main -- docs/
	EOF
git status'

# An unknown global git option before `grep` must not stop the scan (fail-safe: skip any
# `-`-prefixed token, not only a recognised few), whether or not it is one of the handful that
# take a separate argument token.
assert_guard "-c name=value global option before grep -> deny" deny \
    'git -c pager.grep=false grep -n -i "foo" origin/main -- docs/'
assert_guard "--git-dir=... global option before grep -> deny" deny \
    'git --git-dir=/tmp/x.git grep -n -i "foo" origin/main -- docs/'
assert_guard "--work-tree with a separate argument before grep -> deny" deny \
    'git --work-tree /tmp/wt grep -n -i "foo" origin/main -- docs/'
assert_guard "-P (global --no-pager short form) before grep -> deny" deny \
    'git -P grep -n -i "foo" origin/main -- docs/'
assert_guard "--literal-pathspecs before grep -> deny" deny \
    'git --literal-pathspecs grep -n -i "foo" origin/main -- docs/'
assert_guard "unknown global option, but guarded with -I -> allow" allow \
    'git -c pager.grep=false grep -n -I -i "foo" origin/main -- docs/'

echo
echo "$checks checks, $failures failures"
if [ "$failures" -gt 0 ]; then
    exit 1
fi
