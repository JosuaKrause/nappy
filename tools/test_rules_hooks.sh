#!/usr/bin/env bash
# Exercises .claude/hooks/project-rules.sh, session-rules.sh, lint-docs.sh, git-grep-guard.sh and
# github-write-guard.sh directly, feeding them the same synthetic hook JSON on stdin the harness
# would, under a private TMPDIR so no run of this script ever touches a real session's markers.
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
#     src/city/traffic_light.gd, src/ground_shape.gd, src/autoload/telemetry.gd, sound recipes and
#     generated audio) injects its skill
#   - src/visuals/** gets no illustrated-png, which art/illustrated/** alone receives
#   - lint-docs.sh ignores a doc under docs/evidence/ and still lints a top-level docs/*.md
#   - docs/todo/**, docs/review/**, docs/TODO.md and every playtest bring playtest-feedback
#   - lint-docs.sh lints an edited file of the queue, the review items, the records and the
#     playtests (the last two for the duplicate-name check only)
#   - git-grep-guard.sh reads the whole command text, quotes and heredoc bodies included, and
#     denies any git followed by grep as a word of its own with neither -I nor a text-only
#     pathspec: behind a wrapper (timeout, sudo, env, find | xargs), inside a heredoc or quoted
#     code an interpreter runs (bash <<EOF, bash -c, python3 -c, an f-string, VAR="..."; $VAR,
#     bash <<<"..."), and as a mere mention; git log --grep=..., git log -S grep, the bare word
#     git-grep and prose "git, grep" allow
#   - the same denies survive a line continuation, a full path, upper case, a backslash or quote
#     mark inside the word, a quoted -C/-c/--git-dir argument (a space in it included), $'git',
#     $(which git), git${IFS}grep, g$'i't, a path to git's own git-grep program, a redirect or a
#     newline between git and grep, and a Python list, black-formatted or not; -I stays its own
#     flag, never folded together with -i, a quoted "gcc -I" pattern or an -e argument (-eImport,
#     -e -I) is not the flag, and a later -a/--text cancels it
#   - an exclusion-only pathspec (:!*.json, :/!*.json, :(exclude)*.md) denies, and a redirect
#     after a text pathspec (2>/dev/null, 2>&1, > file) is not a pathspec entry, while a quoted or
#     escaped '>' is
#   - a Monitor script is guarded like a Bash command
#   - 31 KB of the densest text, ending in a git grep only the third reading sees, is read in
#     full in under half the hook's 10-second timeout, and a command over
#     32 KB holding both words is denied at once without being read
#   - github-write-guard.sh denies an unwrapped git push and every commit-making git verb (commit;
#     cherry-pick/revert/am unless --abort/--quit; merge/rebase unless --abort/--no-commit/
#     --ff-only; pull unless --ff-only), any gh noun's verb unless it is on the shared read list
#     (view, list, status, diff, checks, checkout, watch, download, clone, token) -- every noun,
#     not only pr/issue/release (workflow run, run rerun/cancel, repo edit, label/secret/variable/
#     cache/gist writes all deny too; browse and search are read nouns whole) -- a gh api call with
#     a non-GET method or -f/-F/--input (attached or not, wherever the flag falls relative to the
#     endpoint: --field=, --raw-field=, --input=, -XPOST, -X=POST, a lowercase method, a flag
#     before the endpoint the way gh itself accepts it) or a GraphQL mutation (a query-only
#     GraphQL call reads even through -f), and a tools/ script that pushes or posts internally
#     (release.sh only with its own push argument, land-prs.sh and update-pr.sh only without their
#     own --dry-run, prune-merged.sh always) in command position only -- past an assignment or a
#     wrapper word's own options/duration, never where its name is merely a read's argument (cat,
#     sed, git log/diff/show --, rg); each as a real invocation and as a mention (an echo, a commit
#     message) alike. A flag between a gh noun and its own verb (gh pr -R O/R merge, gh pr --repo
#     O/R comment) does not skip the check, and neither does a noun/verb landing on a separator
#     (gh status | head) or an endpoint/value merely ending in /gh or /git. A read (git status/
#     log/fetch/diff, gh pr view/list/checks/diff/status/checkout, gh issue/release list/view, gh
#     search, gh browse, a GET gh api, a GraphQL query with no mutation) allows, and so does the
#     same write wrapped in tools/agent-identity.py run <role> -- ..., with or without uv run
#     python in front and with or without run's own --repo before the role -- but only a write
#     inside that wrapper's own -- ... span, never one before it or on a different
#     ;/&/|/newline-separated command, and never a git push, a pushing tools/ script or a
#     merge-type gh write (gh pr merge/update-branch, a gh api endpoint ending in /merge) when the
#     wrapping role is a reviewer (claude-reviewer/codex-reviewer): reviewers never push or merge,
#     whatever GitHub's own contents:write permission allows -- only a coder identity does. Every
#     scan (gh api's, a git verb's abort-flag check) runs to the next separator or the end of the
#     command either way, so many such calls glued with no separator between them stay linear
#     rather than quadratic.
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

Exercises .claude/hooks/project-rules.sh, session-rules.sh, lint-docs.sh, git-grep-guard.sh and
github-write-guard.sh with synthetic hook JSON on stdin, under a private TMPDIR, and asserts the
per-agent marker keying, the compaction/resume reset, every path added to the skill mapping, the
lint-docs.sh governed set, and every git-grep-guard.sh and github-write-guard.sh deny/allow shape.
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
assert_eq "tools/synthesize-sfx.py -> cli + Python + sound-effects" \
    "cli-tools,python-tooling,sound-effects," \
    "$(project_rules_skills sound-recipe-session "" "tools/synthesize-sfx.py")"
assert_eq "a generated WAV -> sound-effects" \
    "sound-effects," \
    "$(project_rules_skills sound-asset-session "" "docs/evidence/sound-lab/example.wav")"

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

# ---------------------------------------------------------------- git-grep-guard.sh -------------
# Prints "deny" or "allow" for one synthetic command through git-grep-guard.sh, as the tool named
# by $2 (Bash when omitted).
guard_decision() {
    local cmd="$1" tool="${2:-Bash}" raw
    # The command goes to jq on stdin, never as an argument: Linux caps one argument at 128 KB, so
    # the long-text rows would fail to build their payload on CI while passing on macOS.
    raw=$(printf '%s' "$cmd" | jq -Rs --arg t "$tool" '{tool_name:$t, tool_input:{command:.}}' \
        | "$root/.claude/hooks/git-grep-guard.sh")
    if [ -z "$raw" ]; then
        printf 'allow'
    else
        printf '%s' "$raw" | jq -r '.hookSpecificOutput.permissionDecision'
    fi
}

# $1 label  $2 expected ("deny" or "allow")  $3 command  $4 tool name (Bash when omitted)
assert_guard() {
    checks=$((checks + 1))
    local got
    got="$(guard_decision "$3" "${4:-Bash}")"
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
assert_guard "three quoted text-only globs -> allow" allow \
    "git grep -I -- '*.md' '*.gd' '*.sh'"
assert_guard "rg on the checkout, own search -> allow" allow \
    'rg -n -i "wrap.*corner|goes around" docs/'
assert_guard "unrelated git command -> allow" allow \
    'git status'
assert_guard "git log --grep=foo -> allow, grep glued onto a dash is an option, not the word" allow \
    'git log --grep=foo'
assert_guard "git shortlog --grep=foo -> allow, same reason" allow \
    'git shortlog --grep=foo'
assert_guard "git log piped to an unrelated plain grep -> allow" allow \
    'git log --oneline | grep foo'
assert_guard "a hyphenated mention (git-grep) never tokenizes as the two words -> allow" allow \
    'echo "see git-grep for details"'
assert_guard "wrapped and guarded still allows" allow \
    'sudo git grep -n -I -i "foo" origin/main -- docs/'

# This design prefers a false deny to a false allow: it matches on the raw command text, quotes
# and heredoc bodies included, rather than trying to tell a mention from a real invocation, a
# wrapper from a bare command, or a heredoc's body from a command. So a mention now denies too.
assert_guard "echo mentions the words -> deny, was allow before the adversarial review" deny \
    'echo "git grep is dangerous, be careful"'
assert_guard "commit message mentions the words -> deny, was allow before the adversarial review" deny \
    'git commit -m "explains why git grep needs a guard now"'
assert_guard "rg quoting the phrase -> deny, was allow before the adversarial review" deny \
    'rg "git grep"'

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

# This design does not try to tell a heredoc body from a command: it never scans for a `<<WORD`
# terminator at all, so a body is matched exactly like anything else on the raw command text --
# which is also what closes the "a heredoc fed to an interpreter" gap below.
assert_guard "heredoc body mentions the words, no real invocation follows -> deny, was allow before" deny \
    'cat <<EOF
please run git grep sometime
EOF'
assert_guard "heredoc body mentions the words, an unsafe invocation follows -> deny" deny \
    'cat <<EOF
mentions git grep here
EOF
git grep -n -i "foo" origin/main -- docs/'
assert_guard "heredoc with a quoted delimiter, unsafe body -> deny, was allow before" deny \
    "cat <<'EOF'
git grep -n -i foo origin/main -- docs/
EOF
git status"
assert_guard "heredoc with <<- and a tab-indented delimiter, unsafe body -> deny, was allow before" deny \
    'cat <<-EOF
	git grep -n -i foo origin/main -- docs/
	EOF
git status'

# An adversarial review of this pull request found three more classes of false negative, all
# closed the same way: matching raw text does not care that a wrapper, a nested interpreter or a
# heredoc's own destination sits between the shell and the invocation.
assert_guard "wrapper: timeout -> deny" deny \
    'timeout 5 git grep -n -i "foo" origin/main -- docs/'
assert_guard "wrapper: sudo -> deny" deny \
    'sudo git grep -n -i "foo" origin/main -- docs/'
assert_guard "wrapper: env -> deny" deny \
    'env git grep -n -i "foo" origin/main -- docs/'
assert_guard "wrapper: nice -> deny" deny \
    'nice git grep -n -i "foo" origin/main -- docs/'
assert_guard "wrapper: nohup -> deny" deny \
    'nohup git grep -n -i "foo" origin/main -- docs/'
assert_guard "wrapper: command -> deny" deny \
    'command git grep -n -i "foo" origin/main -- docs/'
assert_guard "wrapper: watch -> deny" deny \
    'watch git grep -n -i "foo" origin/main -- docs/'
assert_guard "find piped to xargs -> deny" deny \
    'find docs | xargs -I{} git grep -n -i "foo" {} -- docs/'
assert_guard "a heredoc fed to bash, unsafe invocation inside -> deny" deny \
    'bash <<EOF
git grep -n -i "foo" origin/main -- docs/
EOF'
assert_guard "a heredoc fed to ssh, unsafe invocation inside -> deny" deny \
    'ssh host <<EOF
git grep -n -i "foo" origin/main -- docs/
EOF'
assert_guard "nested interpreter: bash -c \"git grep ...\" -> deny" deny \
    'bash -c "git grep -n -i pattern origin/main -- docs/"'
assert_guard "nested interpreter: sh -c \"git grep ...\" -> deny" deny \
    'sh -c "git grep -n -i pattern origin/main -- docs/"'
assert_guard "nested interpreter: python3 -c os.system(...) -> deny" deny \
    "python3 -c \"os.system('git grep -n -i pattern origin/main -- docs/')\""
assert_guard "nested interpreter: perl -e system(...) -> deny" deny \
    'perl -e "system(\"git grep -n -i pattern origin/main -- docs/\")"'

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

# A later, adversarial review of the raw-text redesign above found four bypasses that need no
# obfuscation at all: a line continuation, a full path, upper case (real on this Mac's own
# case-insensitive, case-preserving disk) and a mid-word backslash escape. Command text is
# normalised (backslash-newline pairs and remaining backslashes deleted, `git`/`grep` compared by
# last path component, case-insensitively) before tokenising to close all four.
assert_guard "line continuation splits git from grep across a backslash-newline -> deny" deny \
    "$(printf 'git \\\ngrep -n -i "foo" origin/main -- docs/')"
assert_guard "a full path bypasses the exact-string match -> deny" deny \
    '/usr/bin/git grep -n -i "foo" origin/main -- docs/'
assert_guard "upper case, real on this Mac's case-insensitive disk -> deny" deny \
    'GIT GREP -n -i "foo" origin/main -- docs/'
assert_guard "a backslash escape mid-word -> deny" deny \
    'g\it grep -n -i "foo" origin/main -- docs/'

# The same normalisation must not fold -I (skip binary files) and -i (ignore case) together --
# doing so would make a real, unbounded git grep -i ... docs/ (no -I) indistinguishable from a
# guarded one, the one false allow this file cannot reintroduce. (The upper-case-with-only--i case
# is already covered above, "upper case, real on this Mac's own case-insensitive disk -> deny".)
assert_guard "a full path with a real -I still allows" allow \
    '/usr/bin/git grep -I -n -i "foo" origin/main -- docs/'
assert_guard "upper case GIT GREP with a real -I still allows" allow \
    'GIT GREP -I -n -i "foo" origin/main -- docs/'

# Nothing ordinary regresses: the same three allow-shapes the brief named, re-checked against the
# normalised path.
assert_guard "git log --grep=foo still allows after normalisation" allow \
    'git log --grep=foo'
assert_guard "git grep -I ... -- '*.md' still allows after normalisation" allow \
    "git grep -I pattern -- '*.md'"
assert_guard "a git-grep mention still allows after normalisation" allow \
    'echo "see git-grep for details"'

# The `)` closing a command substitution may stand between git and grep, so a git produced by
# $(echo git) or $(which git) is still git.
assert_guard "\$(echo git) grep -> deny" deny \
    '$(echo git) grep -n -i "foo" origin/main -- docs/'

# A third, adversarial review of the normalise-before-match fix above found that a quote mark,
# still its own token at that point, sat between git/grep and the flags or the bare word either one
# needed to be adjacent to -- denying nothing, with no obfuscation, for a quoted -C/-c/--git-dir
# argument, a quoted git or grep, or a Python argument list. Quotes are now deleted in the same
# normalise pass as backslashes, and `,`/`[`/`]` split words like whitespace, so each of these
# shapes (the exact ones the review used, all unbounded and unguarded) denies again.
assert_guard "a quoted -C path, the shape an agent writes with \"\$root\" -> deny" deny \
    'git -C "/Users/krause/workspace/nappy-claude" grep -n -i "foo" origin/main -- docs/'
assert_guard "a single-quoted -C path -> deny" deny \
    "git -C '/tmp/x' grep -n -i foo origin/main -- docs/"
assert_guard "a quoted -c key=value -> deny" deny \
    'git -c "core.quotepath=off" grep -n -i foo origin/main -- docs/'
assert_guard "a quoted --git-dir=... -> deny" deny \
    'git --git-dir="/x/.git" grep -n -i foo origin/main -- docs/'
assert_guard "a double-quoted git -> deny" deny \
    '"git" grep -n -i foo origin/main -- docs/'
assert_guard "a single-quoted git -> deny" deny \
    "'git' grep -n -i foo origin/main -- docs/"
assert_guard "a double-quoted grep -> deny" deny \
    'git "grep" -n -i foo origin/main -- docs/'
assert_guard "a quote mark mid-word (g\"i\"t) -> deny" deny \
    'g"i"t grep -n -i foo origin/main -- docs/'
assert_guard "a Python argument list (subprocess.run([\"git\", \"grep\", ...])) -> deny" deny \
    'python3 -c '"'"'import subprocess; subprocess.run(["git", "grep", "-n", "-i", "foo", "origin/main", "--", "docs/"])'"'"''

# The third reading honours quotes, so a quoted pattern containing " -I" is not the flag.
assert_guard "a quoted pattern containing -I is not the flag -> deny" deny \
    'git grep -n -i "gcc -I" origin/main -- docs/'

# A word glued onto a quote mark (the second reading turns quotes into spaces).
assert_guard "an f-string in python3 -c -> deny" deny \
    'python3 -c '"'"'import subprocess; subprocess.run(f"git grep -n -i {p} origin/main -- docs/", shell=True)'"'"''
assert_guard "an f-string in a python3 heredoc -> deny" deny \
    "python3 - <<'PY'
import subprocess
subprocess.run(f\"git -C {root} grep -n -i {p} -- docs/\", shell=True)
PY"
assert_guard "cmd=\"git grep ...\"; \$cmd -> deny" deny \
    'cmd="git grep -n -i foo origin/main -- docs/"; $cmd'
assert_guard "CMD='git grep ...'; eval \"\$CMD\" -> deny" deny \
    "CMD='git grep -n -i foo -- docs/'; eval \"\$CMD\""
assert_guard "args=\"git grep ...\" in subprocess.run -> deny" deny \
    'python3 -c '"'"'import subprocess; subprocess.run(args="git grep -n -i foo -- docs/", shell=True)'"'"''
assert_guard "bash <<<\"git grep ...\" -> deny" deny \
    'bash <<<"git grep -n -i foo -- docs/"'
assert_guard "os.system(r'git grep ...') -> deny" deny \
    "python3 -c \"import os; os.system(r'git grep -n -i foo -- docs/')\""
assert_guard "os.system(b'git grep ...'.decode()) -> deny" deny \
    "python3 -c \"import os; os.system(b'git grep -n -i foo -- docs/'.decode())\""

# The last of -I and -a/--text wins in git, and an option's argument is never a flag.
assert_guard "-I then -a searches binaries as text -> deny" deny \
    'git grep -I -a -n -i foo -- docs/'
assert_guard "-Ia cluster, a after I -> deny" deny \
    'git grep -Ia -n -i foo -- docs/'
assert_guard "-I then --text -> deny" deny \
    'git grep -I --text -n -i foo -- docs/'
assert_guard "-I then --no-text restores the default -> deny" deny \
    'git grep -I --no-text -n -i foo -- docs/'
assert_guard "-a then -I, -I last -> allow" allow \
    'git grep -a -I -n -i foo -- docs/'
assert_guard "-aI cluster, I after a -> allow" allow \
    'git grep -aI -n -i foo -- docs/'
assert_guard "-eImport, an attached pattern with a capital I -> deny" deny \
    'git grep -n -i -eImport -- docs/'
assert_guard "-e -I, the pattern -I as a separate word -> deny" deny \
    'git grep -n -e -I -- docs/'
assert_guard "-nIe foo, I before the argument letter -> allow" allow \
    'git grep -nIe foo -- docs/'
assert_guard "-e foo -I, the flag after the pattern -> allow" allow \
    'git grep -e foo -I -- docs/'

# A newline may stand between git and grep: black puts each list element on a line of its own.
assert_guard "a black-formatted list in a python3 heredoc -> deny" deny \
    "python3 - <<'PY'
import subprocess
subprocess.run(
    [
        \"git\",
        \"grep\",
        \"-n\",
        \"-i\",
        \"foo\",
        \"--\",
        \"docs/\",
    ]
)
PY"
assert_guard "[\"git\",<newline> \"grep\", ...] -> deny" deny \
    'x = ["git",
     "grep", "-n", "-i", "foo", "--", "docs/"]'

# Global options that take a separate argument.
assert_guard "--config-env with a separate argument -> deny" deny \
    'git --config-env core.pager=PAGER grep -n -i foo -- docs/'
assert_guard "--attr-source with a separate argument -> deny" deny \
    'git --attr-source HEAD grep -n -i foo -- docs/'

# An exclusion alone searches everything else, so it never counts as text-only.
assert_guard "an exclusion-only pathspec :!*.json -> deny" deny \
    "git grep -n -i foo -- ':!*.json'"
assert_guard "an exclusion-only pathspec :^*.md -> deny" deny \
    "git grep -n -i foo origin/main -- ':^*.md'"
assert_guard "combined short magic top+exclude :/!*.json -> deny" deny \
    "git grep -n -i foo -- ':/!*.json'"
assert_guard "combined short magic top+exclude :/^*.md -> deny" deny \
    "git grep -n -i foo -- ':/^*.md'"
assert_guard "combined short magic in the other order :!/*.md -> deny" deny \
    "git grep -n -i foo -- ':!/*.md'"
assert_guard "long magic :(exclude)*.md -> deny" deny \
    "git grep -n -i foo -- ':(exclude)*.md'"
assert_guard "long magic :(top,exclude)*.md -> deny" deny \
    "git grep -n -i foo -- ':(top,exclude)*.md'"
assert_guard "top-only short magic :/*.md is still text -> allow" allow \
    "git grep -n -i foo -- ':/*.md'"
assert_guard "long magic :(glob)**/*.md -> deny (accepted false deny: split at its parentheses)" deny \
    "git grep -n -i foo -- ':(glob)**/*.md'"
assert_guard "a text pathspec with an exclusion too -> deny (accepted false deny)" deny \
    "git grep -n -i foo -- '*.md' ':!x.md'"

# A redirect after the pathspec is not a pathspec entry.
assert_guard "text pathspec, then 2>/dev/null -> allow" allow \
    "git grep -n foo -- '*.md' 2>/dev/null"
assert_guard "text pathspec, then 2>&1 | head -> allow" allow \
    "git grep -n foo -- '*.md' 2>&1 | head"
assert_guard "text pathspec, then > file -> allow" allow \
    "git grep -n foo -- '*.md' '*.gd' > /tmp/out.txt"
assert_guard "a -- with only a redirect after it -> deny" deny \
    'git grep -n -i foo -- 2>/dev/null'
assert_guard "a redirect, then a non-text entry -> deny" deny \
    "git grep -n -i foo -- '*.md' 2>/dev/null docs/"

# A quoted or escaped > or < is a literal argument, not a redirect, so the word after it is a
# pathspec entry.
assert_guard "a quoted '>' before a non-text entry -> deny" deny \
    "git grep -i foo -- '*.md' '>' docs/"
assert_guard "a quoted '<' before a non-text entry -> deny" deny \
    "git grep -i foo -- '*.md' '<' '*.png'"
assert_guard "a double-quoted \"2>\" before a non-text entry -> deny" deny \
    "git grep -i foo -- '*.md' \"2>\" docs/"
assert_guard "an escaped \\> before a non-text entry -> deny" deny \
    "git grep -i foo -- '*.md' \\> docs/"
assert_guard "an unquoted > after a text pathspec is still a redirect -> allow" allow \
    "git grep -i foo -- '*.md' > /tmp/out.txt"

# IFS as a word break, $'...' inside a word, and git's own git-grep program by path.
assert_guard "git\${IFS}grep -> deny" deny \
    'git${IFS}grep -n -i foo -- docs/'
assert_guard "git\$IFS grep -> deny" deny \
    'git$IFS grep -n -i foo -- docs/'
assert_guard "g\$'i't, ANSI-C quoting inside the word -> deny" deny \
    "g\$'i't grep -n -i foo -- docs/"
assert_guard "\"\$(git --exec-path)/git-grep\" -> deny" deny \
    '"$(git --exec-path)/git-grep" -n -i foo -- docs/'
assert_guard "a literal path to libexec git-grep -> deny" deny \
    '/Library/Developer/CommandLineTools/usr/libexec/git-core/git-grep -n -i foo -- docs/'
assert_guard "\"\$(git --exec-path)/git-grep\" -I -> allow" allow \
    '"$(git --exec-path)/git-grep" -I -n -i foo -- docs/'
assert_guard "git -C x log piped to grep -> allow" allow \
    'git -C x log --oneline | grep foo'

# The & of a redirect (2>&1, >&2, &>) is part of the redirect, not a separator, so the words after
# it are still arguments to git.
assert_guard "2>&1 before a non-text entry -> deny" deny \
    "git grep -n foo -- '*.md' 2>&1 docs/"
assert_guard "&>/dev/null before a non-text entry -> deny" deny \
    "git grep -n foo -- '*.md' &>/dev/null docs/"
assert_guard ">&2 before a non-text entry -> deny" deny \
    "git grep -n foo -- '*.md' >&2 docs/"
assert_guard "2>&1 between -I and a cancelling -a -> deny" deny \
    'git grep -I 2>&1 -a foo'
assert_guard "2>&1 between git and grep -> deny" deny \
    'git 2>&1 grep -i foo -- docs/'
assert_guard "text pathspec, then &>/dev/null at the end -> allow" allow \
    "git grep -n foo -- '*.md' &>/dev/null"
assert_guard "a guarded git grep sent to the background with a bare & -> allow" allow \
    "git grep -I -n foo -- docs/ & wait"

# A quoted or escaped separator is an argument, not the end of the command.
assert_guard "a quoted ')' before a non-text entry -> deny" deny \
    "git grep -n foo -- '*.md' ')' docs/"
assert_guard "a quoted '|' before a non-text entry -> deny" deny \
    "git grep -n foo -- '*.md' '|' docs/"
assert_guard "an escaped \\; before a non-text entry -> deny" deny \
    "git grep -n foo -- '*.md' \\; docs/"
assert_guard "git grep's quoted '(' ... ')' grouping, then a cancelling -a -> deny" deny \
    "git grep -I '(' -e foo ')' -a"
assert_guard "git grep's escaped \\( ... \\) grouping, then a cancelling -a -> deny" deny \
    "git grep -I \\( -e foo \\) -a"
assert_guard "a guarded grouping with no -a after it -> allow" allow \
    "git grep -I '(' -e foo --or -e bar ')' -- docs/"
assert_guard "an unquoted ; still ends the command -> allow" allow \
    "git grep -I -n foo; ls docs/"

# The reviewer's minor shapes.
assert_guard "\$'git' grep (ANSI-C quoting) -> deny" deny \
    "\$'git' grep -n -i foo -- docs/"
assert_guard "\$(which git) grep -> deny" deny \
    '$(which git) grep -n -i foo -- docs/'
assert_guard "\`which git\` grep -> deny" deny \
    '`which git` grep -n -i foo -- docs/'
assert_guard "a redirect between git and grep -> deny" deny \
    'git 2>/dev/null grep -n -i foo -- docs/'
assert_guard "a quoted -C path with a space -> deny" deny \
    'git -C "/Users/krause/My Drive/nappy" grep -n -i foo -- docs/'
assert_guard "a quoted -c value with a space -> deny" deny \
    'git -c "color.grep.match=bold red" grep -n -i foo -- docs/'
assert_guard "a quoted --git-dir= path with a space -> deny" deny \
    'git --git-dir="/x y/.git" grep -n -i foo -- docs/'
assert_guard "\"git, grep\" in prose is not an invocation -> allow" allow \
    'git commit -m "Tools: git, grep and rg"'

# Nothing ordinary regresses.
assert_guard "a guarded search for the phrase git grep -> allow" allow \
    'git grep -I -n "git grep" -- docs/'
assert_guard "git -C \"\$root\" grep -I ... -> allow" allow \
    'git -C "$root" grep -I -n -i foo -- docs/'
assert_guard "git log -S grep -> allow" allow \
    'git -C "$root" log -S grep'
assert_guard "git log --format with a comma, piped to grep -> allow" allow \
    'git log --format="%h,%s" | grep fix'

# A git with nothing after it, or only options, is no grep.
assert_guard "git as the last word -> allow" allow \
    'gh pr view 377 --json body --jq .body | grep -n git'
assert_guard "git and an option as the last words -> allow" allow \
    'echo git --version'

# Monitor runs its script in the same shell as Bash, for minutes, so it is guarded the same way;
# a tool that runs no shell is not read at all.
assert_guard "a Monitor script with an unguarded git grep -> deny" deny \
    'git grep -n -i foo -- docs/' Monitor
assert_guard "a Monitor script with a guarded git grep -> allow" allow \
    'git grep -I -n -i foo -- docs/' Monitor
assert_guard "a tool that runs no shell is not read -> allow" allow \
    'git grep -n -i foo -- docs/' Read

# The slowest text measured, just under the 32 KB bound, is still read in full well inside the
# hook's 10-second timeout (a hook that times out lets the command through), and still denies.
# It is `git` on a line of its own, so every word is a candidate, and it ends in an invocation
# only the third, quote-honouring reading can see: the first two split "/x y" into two words and
# never reach `grep`, so all three readings run to the end.
dense_body="$(printf 'git\n%.0s' $(seq 1 8000))"
dense_start=$SECONDS
assert_guard "31 KB of short words, then a git grep only reading 3 catches -> deny" deny \
    "$dense_body
git -C \"/x y\" grep -i foo -- docs/"
checks=$((checks + 1))
if [ $((SECONDS - dense_start)) -lt 5 ]; then
    echo "ok   the 31 KB dense command is read in full in under 5 seconds"
else
    fail "the 31 KB dense command took $((SECONDS - dense_start)) seconds, past half the hook's 10-second timeout"
fi
assert_guard "the same invocation alone is caught only by reading 3 -> deny" deny \
    'git -C "/x y" grep -i foo -- docs/'

# Past 32 KB, a text holding both words is denied without being read, even when the one
# git grep in it is guarded; a long text without both words still allows at once.
huge_body="$(printf 'Lorem ipsum dolor sit amet, "quoted words", '"'"'more'"'"'; x | y (z) [w]\n%.0s' $(seq 1 3200))"
huge_start=$SECONDS
assert_guard "a 200 KB command with only a guarded git grep -> deny (too long to read in full)" deny \
    "echo \"$huge_body\"; git grep -I -n foo -- '*.md'"
assert_guard "a 200 KB command without both words -> allow" allow \
    "echo \"$huge_body\"; git status"
checks=$((checks + 1))
if [ $((SECONDS - huge_start)) -lt 3 ]; then
    echo "ok   both 200 KB commands are decided in under 3 seconds"
else
    fail "the 200 KB commands took $((SECONDS - huge_start)) seconds; the length bound should decide them at once"
fi

# ---------------------------------------------------------------- github-write-guard.sh ---------
# Prints "deny" or "allow" for one synthetic command through github-write-guard.sh, as the tool
# named by $2 (Bash when omitted). Same shape as guard_decision above, for the other hook.
write_guard_decision() {
    local cmd="$1" tool="${2:-Bash}" raw
    raw=$(printf '%s' "$cmd" | jq -Rs --arg t "$tool" '{tool_name:$t, tool_input:{command:.}}' \
        | "$root/.claude/hooks/github-write-guard.sh")
    if [ -z "$raw" ]; then
        printf 'allow'
    else
        printf '%s' "$raw" | jq -r '.hookSpecificOutput.permissionDecision'
    fi
}

# $1 label  $2 expected ("deny" or "allow")  $3 command  $4 tool name (Bash when omitted)
assert_write_guard() {
    checks=$((checks + 1))
    local got
    got="$(write_guard_decision "$3" "${4:-Bash}")"
    if [ "$got" = "$2" ]; then
        echo "ok   $1"
    else
        fail "$1: expected $2, got $got for: $3"
    fi
}

assert_write_guard "git push, unwrapped -> deny" deny 'git push origin main'
assert_write_guard "git commit, unwrapped -> deny" deny 'git commit -m "x"'
assert_write_guard "git -C dir commit, a global option before the subcommand -> deny" deny \
    'git -C /path/to/repo commit --quiet -m "msg"'
assert_write_guard "gh pr create -> deny" deny 'gh pr create --title x --body y'
assert_write_guard "gh pr comment -> deny" deny 'gh pr comment 391 --body hi'
assert_write_guard "gh pr merge -> deny" deny 'gh pr merge 391 --squash'
assert_write_guard "gh pr edit -> deny" deny 'gh pr edit 391 --title x'
assert_write_guard "gh pr review -> deny" deny 'gh pr review 391 --approve --body ready'
assert_write_guard "gh pr close/reopen/ready -> deny" deny 'gh pr close 391'
assert_write_guard "gh issue comment, an unlisted issue write verb -> deny" deny 'gh issue comment 5 --body hi'
assert_write_guard "gh release create -> deny" deny 'gh release create v1.0'
assert_write_guard "gh api with -f -> deny (a field turns it into a POST)" deny \
    'gh api repos/o/r/pulls -f title=x'
assert_write_guard "gh api with -X POST -> deny" deny 'gh api repos/o/r/issues -X POST'
assert_write_guard "gh api with --method POST -> deny" deny 'gh api repos/o/r/issues --method POST'
assert_write_guard "gh -R O/R pr create, gh's own global option before the noun -> deny" deny \
    'gh -R O/R pr create --title x --body y'
assert_write_guard "tools/release.sh patch push, its own write shape -> deny" deny \
    'tools/release.sh patch push'
assert_write_guard "tools/prune-merged.sh, deletes the remote branch -> deny" deny \
    'tools/prune-merged.sh mybranch'
assert_write_guard "./tools/land-prs.sh, merges the PR -> deny" deny './tools/land-prs.sh 391'
assert_write_guard "tools/update-pr.sh, commits and pushes -> deny" deny 'tools/update-pr.sh 391'
assert_write_guard "a mention (an echo naming gh pr merge) -> deny, same call as git-grep-guard's" deny \
    'echo "remember to run gh pr merge 391 after review"'
assert_write_guard "a mention inside a commit message -> deny" deny \
    'git commit -m "documents why git push needs a wrapper now"'

# An adversarial review of PR #391 (against 3e44c3a8) found four real bypasses and fixed them:
# a flag between `gh <noun>` and its own verb skipping the verb lookup, `gh pr` missing several
# write verbs, `gh api`'s attached-value flag forms, and every other `gh` noun besides pr/issue/
# release/api being out of scope entirely. Each is checked here on its own.
assert_write_guard "gh pr -R O/R merge, a flag between the noun and its verb -> deny" deny \
    'gh pr -R JosuaKrause/nappy merge 391'
assert_write_guard "gh pr --repo O/R comment, the long flag form -> deny" deny \
    'gh pr --repo JosuaKrause/nappy comment 391 -b hi'
assert_write_guard "gh pr -R O/R review --approve -> deny" deny 'gh pr -R o/r review 391 --approve'
assert_write_guard "gh pr revert, a write verb the old list missed -> deny" deny 'gh pr revert 391'
assert_write_guard "gh pr update-branch, pushes a merge commit to the PR branch -> deny" deny \
    'gh pr update-branch 391'
assert_write_guard "gh pr lock -> deny" deny 'gh pr lock 391'
assert_write_guard "gh pr unlock -> deny" deny 'gh pr unlock 391'
assert_write_guard "gh pr checkout is local-only -> allow" allow 'gh pr checkout 391'
assert_write_guard "gh api --field=k=v, attached long flag -> deny" deny \
    'gh api repos/x/y --field=body=1'
assert_write_guard "gh api --raw-field=k=v, attached long flag -> deny" deny \
    'gh api repos/x/y --raw-field=body=1'
assert_write_guard "gh api --input=file, attached long flag -> deny" deny \
    'gh api repos/x/y --input=review.json'
assert_write_guard "gh api -XPOST, attached short flag -> deny" deny 'gh api repos/x/y -XPOST'
assert_write_guard "gh api -Xpost, a lowercase attached method -> deny" deny 'gh api repos/x/y -Xpost'
assert_write_guard "gh api -X=POST -> deny" deny 'gh api repos/x/y -X=POST'
assert_write_guard "gh workflow run, every gh noun writes by default now -> deny" deny \
    'gh workflow run build.yml'
assert_write_guard "gh run rerun -> deny" deny 'gh run rerun 123'
assert_write_guard "gh run cancel -> deny" deny 'gh run cancel 123'
assert_write_guard "gh repo edit -> deny" deny 'gh repo edit --description x'
assert_write_guard "gh label create -> deny" deny 'gh label create bug'
assert_write_guard "gh secret set -> deny" deny 'gh secret set FOO'
assert_write_guard "gh variable set -> deny" deny 'gh variable set FOO'
assert_write_guard "gh cache delete -> deny" deny 'gh cache delete 1'
assert_write_guard "gh gist create -> deny" deny 'gh gist create file.txt'

# The same review found the commit-creating git verbs besides commit itself: merge (without
# --no-commit/--ff-only/--abort), cherry-pick, revert, am, and rebase (without --abort) all set
# the player as the committer of a real commit and need the wrapper too.
assert_write_guard "git merge, a real merge commit -> deny" deny 'git merge origin/main'
assert_write_guard "git merge --no-ff --no-commit, merging-main's own shape -> allow" allow \
    'git merge --no-ff --no-commit origin/main'
assert_write_guard "git merge --abort -> allow" allow 'git merge --abort'
assert_write_guard "git rebase, sets the player as committer -> deny" deny 'git rebase origin/main'
assert_write_guard "git rebase --abort -> allow" allow 'git rebase --abort'
assert_write_guard "git cherry-pick -> deny" deny 'git cherry-pick abc123'
assert_write_guard "git revert -> deny" deny 'git revert abc123'
assert_write_guard "git am -> deny" deny 'git am patch.mbox'

assert_write_guard "git status -> allow" allow 'git status'
assert_write_guard "git log -> allow" allow 'git log --oneline'
assert_write_guard "git fetch -> allow" allow 'git fetch origin'
assert_write_guard "git diff -> allow" allow 'git diff --check'
assert_write_guard "gh pr view -> allow" allow 'gh pr view 391'
assert_write_guard "gh pr list -> allow" allow 'gh pr list'
assert_write_guard "gh pr checks -> allow" allow 'gh pr checks 391'
assert_write_guard "gh pr diff -> allow" allow 'gh pr diff 391'
assert_write_guard "gh pr status -> allow" allow 'gh pr status'
assert_write_guard "gh issue list/view -> allow" allow 'gh issue list'
assert_write_guard "gh issue view -> allow" allow 'gh issue view 5'
assert_write_guard "gh release list/view -> allow" allow 'gh release list'
assert_write_guard "gh release view -> allow" allow 'gh release view v1.0'
assert_write_guard "gh api, explicit GET -> allow" allow 'gh api repos/o/r --method GET'
assert_write_guard "gh api, no method or fields, defaults to GET -> allow" allow 'gh api repos/o/r'
assert_write_guard "gh --repo O/R pr view, gh's own global option before a read -> allow" allow \
    'gh --repo O/R pr view 391'
assert_write_guard "gh browse opens a local browser, no GitHub write -> allow" allow 'gh browse 391'
assert_write_guard "gh run view, gh repo view, gh label/secret list -> allow" allow 'gh run view 123'
assert_write_guard "gh repo view -> allow" allow 'gh repo view'
assert_write_guard "gh label list -> allow" allow 'gh label list'
assert_write_guard "gh secret list -> allow" allow 'gh secret list'
assert_write_guard "a read-only tools/ script -> allow" allow 'tools/agent-status.sh'
assert_write_guard "checking status is not itself a write -> allow" allow \
    'uv run python tools/agent-identity.py status claude-coder'
assert_write_guard "a read of a write-script's own name (cat) -> allow, no write happens" allow \
    'cat tools/release.sh'
assert_write_guard "a read of a write-script's own name (sed) -> allow" allow \
    'sed -n 1,40p tools/update-pr.sh'
assert_write_guard "a read of a write-script's own name (git log --) -> allow" allow \
    'git log -- tools/land-prs.sh'
assert_write_guard "a read of a write-script's own name (git diff --) -> allow" allow \
    'git diff main -- tools/prune-merged.sh'
assert_write_guard "a read of a write-script's own name (git show) -> allow" allow \
    'git show HEAD:tools/release.sh'
assert_write_guard "tools/release.sh with no push argument is a dry run -> allow" allow \
    'tools/release.sh patch'
assert_write_guard "tools/land-prs.sh --dry-run -> allow, no GitHub write happens" allow \
    'tools/land-prs.sh --dry-run'
assert_write_guard "tools/update-pr.sh --dry-run -> allow, no GitHub write happens" allow \
    'tools/update-pr.sh --dry-run 315'

assert_write_guard "wrapped git push, uv run python in front -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- git push origin main'
assert_write_guard "wrapped git push, bare python3 in front -> allow" allow \
    'python3 tools/agent-identity.py run claude-coder -- git push -u origin my-branch'
assert_write_guard "wrapped git push, no interpreter in front at all -> allow" allow \
    'tools/agent-identity.py run claude-coder -- git push'
assert_write_guard "wrapped git push, run's own --repo before the role -> allow" allow \
    'uv run python tools/agent-identity.py run --repo O/R claude-coder -- git push'
assert_write_guard "wrapped gh pr comment, as claude-reviewer -> allow" allow \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh pr comment 391 --body hi'
assert_write_guard "wrapped gh pr review --approve, as claude-reviewer -> allow" allow \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh pr review 391 --approve --body ready'
assert_write_guard "wrapped tools/ script -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- tools/release.sh'

# A reviewer identity never pushes through this tool, whatever GitHub's own permission allows
# (contents:write, since a reviewer's own APPROVE needs it) -- only a coder identity does.
assert_write_guard "wrapped git push as claude-reviewer -> deny, reviewers never push" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- git push origin main'
assert_write_guard "wrapped git push as codex-reviewer -> deny, reviewers never push" deny \
    'uv run python tools/agent-identity.py run codex-reviewer -- git push origin main'
assert_write_guard "wrapped write-tool-script as claude-reviewer -> deny, reviewers never push" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- tools/release.sh patch push'
assert_write_guard "wrapped git commit as claude-reviewer -> allow, only push is refused" allow \
    'uv run python tools/agent-identity.py run claude-reviewer -- git commit -m x'
assert_write_guard "wrapped git push as claude-coder still allows" allow \
    'uv run python tools/agent-identity.py run claude-coder -- git push origin main'
assert_write_guard "wrapped git push as codex-coder still allows" allow \
    'uv run python tools/agent-identity.py run codex-coder -- git push origin main'

# A write before the wrapper, or on a different command joined only by a separator, is not
# covered by it: the wrapper's own exemption starts at its literal -- and ends at the next
# ;/&/|/newline, never earlier or later.
assert_write_guard "a write before the wrapper in the same line -> deny" deny \
    'git push; uv run python tools/agent-identity.py run claude-coder -- echo hi'
assert_write_guard "run without the literal -- is no wrapper at all -> deny" deny \
    'uv run python tools/agent-identity.py run claude-coder git push'
assert_write_guard "a write on the next line after an unrelated wrapped call -> deny" deny \
    'uv run python tools/agent-identity.py run claude-coder -- echo hi
git push'

# Monitor is guarded the same way Bash is; a tool that runs no shell is not read at all.
assert_write_guard "a Monitor script with an unwrapped git push -> deny" deny 'git push origin main' Monitor
assert_write_guard "a tool that runs no shell is not read -> allow" allow 'git push origin main' Read

# The one accepted hole this design does not close, matching git-grep-guard.sh's own "accepted
# holes" section: a mention that quotes the wrapper's own shape whole reads like a real wrapped
# call, since nothing here tells a mention from an invocation except by matching words.
assert_write_guard "a mention that quotes the whole wrapped shape -> allow (accepted false allow)" allow \
    'echo "a comment that fully quotes: tools/agent-identity.py run claude-coder -- git push"'

# A review of this hook found detect_gh_api's own scan ran to the next separator or the end of
# the command, so many `gh api ...` calls glued together with no separator between them (no ; & |
# or newline) made each one rescan the rest of the text: 800 repeats measured at 9.4s of the
# hook's 10s timeout, and a timed-out hook lets the command through. Stopping the scan at the next
# git/gh word too (detect_gh_api's own `until` condition) bounds it. 400 repeats of `gh api x `
# (3.6 KB, denser than a real command would ever be) must still decide in well under the timeout.
dense_gh_api="$(printf 'gh api x ' 2>/dev/null; for _ in $(seq 1 400); do printf 'gh api x '; done)"
dense_gh_start=$SECONDS
assert_write_guard "400 glued gh api calls, ending in a write -> deny, decided quickly" deny \
    "${dense_gh_api}gh api repos/o/r -X POST"
checks=$((checks + 1))
if [ $((SECONDS - dense_gh_start)) -lt 5 ]; then
    echo "ok   400 glued gh api calls are decided in under 5 seconds"
else
    fail "400 glued gh api calls took $((SECONDS - dense_gh_start)) seconds, past half the hook's 10-second timeout"
fi

# A review of 8021ba74 found a High regression in 88b660f9: a gh api flag before the endpoint
# (exactly how gh itself accepts -X/--method/-f/-F/--input) skipped the guard entirely, since the
# scan started after skipping leading options instead of right after "api". It also found the
# "stop early on the next git/gh word" fix for the quadratic scan wrongly stopped early on any
# endpoint or flag value merely ending in /gh or /git.
assert_write_guard "gh api -X PUT .../merge, flag before the endpoint -> deny (the regression)" deny \
    'gh api -X PUT repos/o/r/pulls/1/merge'
assert_write_guard "gh api --method=PUT .../merge, flag before the endpoint -> deny" deny \
    'gh api --method=PUT repos/o/r/pulls/1/merge'
assert_write_guard "gh api -XPUT .../merge, attached flag before the endpoint -> deny" deny \
    'gh api -XPUT repos/o/r/pulls/1/merge'
assert_write_guard "gh api --method DELETE, flag before the endpoint -> deny" deny \
    'gh api --method DELETE repos/o/r/git/refs/heads/foo'
assert_write_guard "gh api -f before the endpoint -> deny" deny \
    'gh api -f body=hi repos/o/r/issues/1/comments'
assert_write_guard "gh api --input before the endpoint -> deny" deny \
    'gh api --input review.json repos/o/r/pulls/1/reviews'
assert_write_guard "gh api --paginate -X DELETE, another flag before the write flag -> deny" deny \
    'gh api --paginate -X DELETE repos/o/r/x'
assert_write_guard "an endpoint ending in /gh does not stop the scan early -> deny" deny \
    'gh api repos/o/r/pulls/1/merge --jq x/gh -X PUT'
assert_write_guard "a branch literally named gh does not stop the scan early -> deny" deny \
    'gh api repos/o/r/git/refs/heads/gh -X DELETE'

# Reads the read list wrongly denied.
assert_write_guard "gh search prs, search is a read noun with no verb of its own -> allow" allow \
    'gh search prs --repo x foo'
assert_write_guard "gh search issues -> allow" allow 'gh search issues foo'
assert_write_guard "gh run watch -> allow" allow 'gh run watch 123'
assert_write_guard "gh run download -> allow" allow 'gh run download 1'
assert_write_guard "gh release download -> allow" allow 'gh release download v1'
assert_write_guard "gh repo clone -> allow" allow 'gh repo clone o/r'
assert_write_guard "gh auth token -> allow" allow 'gh auth token'
assert_write_guard "a GraphQL query (no mutation) -> allow, even though -f makes it a POST" allow \
    "gh api graphql -f query=query{me{login}}"
assert_write_guard "a GraphQL mutation -> deny" deny \
    "gh api graphql -f query=mutation{resolveReviewThread(x:1){clientMutationId}}"
assert_write_guard "gh status | head, a noun with no verb before a separator -> allow" allow \
    'gh status | head'
assert_write_guard "gh --version && gh auth status -> allow, not the garbled (gh & &) reason" allow \
    'gh --version && gh auth status'

# git verbs: aborts pass, git pull is guarded, and the quadratic cost that moved to git merge/
# rebase detection is fixed the same way the gh api one is.
assert_write_guard "git cherry-pick --abort -> allow" allow 'git cherry-pick --abort'
assert_write_guard "git revert --abort -> allow" allow 'git revert --abort'
assert_write_guard "git am --abort -> allow" allow 'git am --abort'
assert_write_guard "git cherry-pick --quit -> allow" allow 'git cherry-pick --quit'
assert_write_guard "git pull, can make a merge commit -> deny" deny 'git pull'
assert_write_guard "git pull origin main -> deny" deny 'git pull origin main'
assert_write_guard "git pull --rebase, rewrites the player as committer -> deny" deny 'git pull --rebase'
assert_write_guard "git pull --ff-only -> allow, the only shape with no commit of its own" allow \
    'git pull --ff-only'
dense_merge="$(for _ in $(seq 1 800); do printf 'git merge x '; done)"
dense_merge_start=$SECONDS
assert_write_guard "800 glued git merge calls -> deny, decided quickly" deny "$dense_merge"
checks=$((checks + 1))
if [ $((SECONDS - dense_merge_start)) -lt 5 ]; then
    echo "ok   800 glued git merge calls are decided in under 5 seconds"
else
    fail "800 glued git merge calls took $((SECONDS - dense_merge_start)) seconds, past half the hook's 10-second timeout"
fi

# Command position missed an assignment before the script, and a wrapper word's own option or
# positional argument (timeout's own duration).
assert_write_guard "FOO=1 tools/release.sh patch push -> deny" deny 'FOO=1 tools/release.sh patch push'
assert_write_guard "env FOO=1 tools/prune-merged.sh -> deny" deny 'env FOO=1 tools/prune-merged.sh mybranch'
assert_write_guard "timeout 60 tools/land-prs.sh -> deny, past timeout's own duration" deny \
    'timeout 60 tools/land-prs.sh 1'
assert_write_guard "bash -x tools/prune-merged.sh -> deny, past bash's own option" deny \
    'bash -x tools/prune-merged.sh mybranch'
assert_write_guard "an assignment inside a real wrapper still allows" allow \
    'uv run python tools/agent-identity.py run claude-coder -- env FOO=1 tools/release.sh patch push'

# A reviewer is refused a merge-type write too, not only a push.
assert_write_guard "wrapped gh pr merge as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh pr merge 1'
assert_write_guard "wrapped gh pr update-branch as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh pr update-branch 1'
assert_write_guard "wrapped gh api .../merge as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -X PUT repos/o/r/pulls/1/merge'
assert_write_guard "wrapped gh pr comment as claude-reviewer still allows (not merge-like)" allow \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh pr comment 1 --body hi'
assert_write_guard "wrapped gh pr merge as claude-coder still allows" allow \
    'uv run python tools/agent-identity.py run claude-coder -- gh pr merge 1'

echo
echo "$checks checks, $failures failures"
if [ "$failures" -gt 0 ]; then
    exit 1
fi
