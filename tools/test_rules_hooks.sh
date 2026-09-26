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
#   - git-grep-guard.sh reads the whole command text, quotes and heredoc bodies included, and
#     denies any git followed by grep as a word of its own with neither -I nor a text-only
#     pathspec: behind a wrapper (timeout, sudo, env, find | xargs), inside a heredoc or quoted
#     code an interpreter runs (bash <<EOF, bash -c, python3 -c, an f-string, VAR="..."; $VAR,
#     bash <<<"..."), and as a mere mention; git log --grep=... and prose "git, grep" allow
#   - the same denies survive a line continuation, a full path, upper case, a backslash or quote
#     mark inside the word, a quoted -C/-c/--git-dir argument (a space in it included), $'git',
#     $(which git), a redirect or a newline between git and grep, and a Python list, black-
#     formatted or not; -I stays its own flag, never folded together with -i, a quoted "gcc -I"
#     pattern or an -e argument (-eImport, -e -I) is not the flag, and a later -a/--text cancels it
#   - an exclusion-only pathspec (:!*.json, :/!*.json, :(exclude)*.md) denies, and a redirect after a text pathspec
#     (2>/dev/null, 2>&1, > file) is not a pathspec entry, while a quoted or escaped '>' is
#   - a Monitor script is guarded like a Bash command
#   - a 100 KB command is checked in under half the hook's 10-second timeout, and a command over
#     128 KB holding both words is denied at once without the slow reading
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
# Prints "deny" or "allow" for one synthetic command through git-grep-guard.sh, as the tool named
# by $2 (Bash when omitted).
guard_decision() {
    local cmd="$1" tool="${2:-Bash}" raw
    raw=$(jq -n --arg c "$cmd" --arg t "$tool" '{tool_name:$t, tool_input:{command:$c}}' \
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
assert_guard "git log --grep=foo -- the one mention still allowed, an option not a subcommand" allow \
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

# A command far longer than any real one still finishes well inside the hook's 10-second timeout
# (a hook that times out lets the command through), and still denies.
long_body="$(printf 'Lorem ipsum dolor sit amet, "quoted words", '"'"'more'"'"'; x | y (z) [w]\n%.0s' $(seq 1 1500))"
long_start=$SECONDS
assert_guard "a 100 KB heredoc ending in an unguarded git grep -> deny" deny \
    "python3 - <<'PY'
$long_body
import os; os.system('git grep -n -i foo -- docs/')
PY"
checks=$((checks + 1))
if [ $((SECONDS - long_start)) -lt 5 ]; then
    echo "ok   the 100 KB command is checked in under 5 seconds"
else
    fail "the 100 KB command took $((SECONDS - long_start)) seconds, past half the hook's 10-second timeout"
fi

# Past 128 KB, a text holding both words is denied before the slow reading, even when the one
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

echo
echo "$checks checks, $failures failures"
if [ "$failures" -gt 0 ]; then
    exit 1
fi
