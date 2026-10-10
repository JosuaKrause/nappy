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
#   - a chain of git words whose options swallow the next one (git -c git -c ..., git > git > ...),
#     at 10 KB and at the 32 KB bound, is decided in under half the timeout too, and so is a
#     quoted script of git -C "a b" at the bound
#   - inside a quoted script (bash -c '...' or "..."), a -C/-c argument quoted with a space is one
#     word and a quoted pattern holding -I is not the flag, so the search still denies
#   - past 32 KB (too_long), one regex decides rather than the three readings: an obscured pair
#     (g\it, g"r"ep, g$'i't, a backslash-newline between two letters) still denies, "git" alone
#     (no "grep" anywhere) allows, and so does prose whose lines end in "g" and start with "it" or
#     "rep", since only a backslash joins two lines; 1 MB of a' and 1 MB of backslash-newlines,
#     both holding neither word and dense in the characters the readings drop, allow in under a
#     second; past 1 MB (hard_cap) every command denies without being read
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
#     message) alike, outside three whole-command shapes whose text is told apart for certain: cat >
#     FILE <<'EOF' (the delimiter quoted), a coder's or the orchestrator's wrapped git commit -F -
#     <<'EOF', and a lone rg or grep with one quoted pattern -- each allows with prose naming gh
#     issue comment, git push and tools/prune-merged.sh, and each near miss (an unquoted delimiter,
#     <<-, a second command, a pipe, a reviewer's commit, rg --pre, a $ in the pattern) and every
#     reproduction from PR #429's three reviews decides as main's guard does. A flag between a gh noun and its own verb (gh pr -R O/R merge, gh pr --repo
#     O/R comment) does not skip the check, and neither does a noun/verb landing on a separator
#     (gh status | head) or an endpoint/value merely ending in /gh or /git. A read (git status/
#     log/fetch/diff, gh pr view/list/checks/diff/status/checkout, gh issue/release list/view, gh
#     search, gh browse, a GET gh api, a GraphQL query with no mutation) allows, and so does the
#     same write wrapped in tools/agent-identity.py run <role> -- ..., with or without uv run
#     python in front and with or without run's own --repo before the role -- but only a write
#     inside that wrapper's own -- ... span, never one before it or on a different
#     ;/&/|/newline-separated command, and never a git push, a pushing tools/ script or a
#     merge-type gh write (gh pr merge/update-branch, a gh api write to /merge, /merges,
#     /update-branch, /contents/ or /git/refs) when the wrapping role is a reviewer
#     (claude-reviewer/codex-reviewer), whatever GitHub's own contents:write permission allows --
#     only a coder identity or claude-orchestrator pushes or merges by those routes, and
#     claude-orchestrator, a wrapping role like the coders, gets every write through (push, commit,
#     gh pr create/merge, gh label create, gh run rerun, a pushing tools/ script); unwrapped, each
#     of those still denies, and both deny messages name it. A gh issue write verb (create, close,
#     reopen, comment, edit) denies wrapped or not, and so does a gh api write to an issue
#     endpoint (repos/o/r/issues or repositories/<id>/issues, issues/N, its labels/assignees/lock,
#     issues/comments/N, the owner and repository in a variable or a substitution) or a GraphQL
#     issue mutation (closeIssue, addLabelsToLabelable, ..., compact or in a variable the same
#     command sets), since tools/inbox.py is the one way an agent writes an issue, and its message
#     names the script; a comment POST to issues/N/comments and GraphQL's addComment, which pull
#     requests share, stay allowed. Every
#     scan (gh api's, a git verb's abort-flag check) runs to the next separator or the end of the
#     command either way, so many such calls glued with no separator between them stay linear
#     rather than quadratic, and so do the shapes where a walk from each word would reach the end
#     of the command (git -c git -c ..., ; env -c ; env -c ..., gh pr -R gh -R ..., a pushing
#     script rewrapped before each repeat, a heredoc naming gh api on every line), at 16 KB and at
#     the 64 KB bound; a gh api mentioned inside another call's scan still denies on a write flag
#     of its own before its next separator. An option's argument is one shell word however it
#     is quoted, escaped or joined by a comma (git -C "/x y" push, git -c 'a=b c' push, git -c
#     k=a,b push, FOO="a b" tools/release.sh patch push, the same inside bash -c '...', and in an
#     unsure command), a wrapper option's argument (sudo -u, nice -n, timeout -s, xargs -n) is
#     skipped before the command word, and the script after bash -c is a command of its own; the
#     wrapped forms and the reads through the same wrappers still allow.
#   - where no identity can work (a cloud session, or no identity directory) and the player's
#     NAPPY_ASK_FOR_PLAYER_WRITES=1 is set, github-write-guard.sh asks about a commit or local
#     history step, a branch push (to a remote whose name starts with v too, past an option's own
#     value or a --, a quoted separator that belongs to another command or to the push's own
#     quoted script) and gh pr create/comment/edit/ready, and still denies a push of a tag, of
#     every branch or of a * pattern (in a refspec, a git -c before push or a push refspec set by
#     one), a forced, deleting, mirroring or pruning push in any prefix of its long option or
#     through a git -c, a push with a $ or a backtick among its words or in a git -c push refspec,
#     a push whose own quoted word holds a separator, a git or gh whose options hold an unquoted
#     command substitution, a gh issue write bare or wrapped, a merge, a release, a gh api write
#     and a pushing script, while git tag, a read, a search for a write's words and a
#     tools/inbox.py call allow; with the switch unset, 0 or yes, every one of those writes denies
#   - xargs/gxargs and parallel/env_parallel input makes an unwrapped push or missing/nonliteral
#     git subcommand or gh noun/verb unreadable; pushing scripts behind their options are guarded;
#     input can append tools/release.sh's own push, so release.sh under one is a write without it;
#     a custom replacement token remains unreadable even when it is lowercase or spells a known
#     read; the wrappers' documented value-taking options do not hide a pushing script; reads,
#     later separate branch pushes and coder identity wrappers keep their existing behavior
#   - a backslash-escaped separator given as an input-wrapper option's value (xargs -d \;,
#     parallel --colsep \|) is that value, not the end of the wrapper's command
#   - an input-supplied git subcommand or gh noun/verb is unreadable only for a git or gh the
#     wrapper runs in command position, never one that is an argument (xargs grep -l git, rg
#     'xargs git') or that carries --version/--help; git p4 is a plain subcommand
#   - GNU parallel with no command of its own (parallel ::: cmd) runs its arguments as commands,
#     so a pushing script or git/gh among them is unreadable
#   - a gh api call under xargs or parallel is a write unless its every flag is written: input
#     placed only at a replacement token inside a word of the call; a GraphQL call there writes
#   - input that reaches an issue write (a verb input supplies to gh issue, a noun input supplies
#     to gh, flags input adds to a written issue endpoint, a written gh issue under unreadable
#     wrapper options) is denied wrapped or not, like a written gh issue write; a gh issue read
#     and the shared issues/N/comments path under input keep their behavior
#   - common no-value options (parallel --tag, --pipe, -X, -m, --xargs; xargs -o) and value options
#     (parallel --tagstring, xargs --process-slot-var) leave a read under them a read
#   - input-wrapper clusters and values share one parser: flag-shaped values never select a new
#     replacement token, unknown option arity fails closed, and a long chain of consumed values
#     named xargs stays bounded; the corresponding known reads and identity controls still pass
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

# The time in seconds, to the millisecond: bash 3.2's own $SECONDS counts whole seconds, which
# turns a 5-second bound into one that can fail from 4.0 s.
now() { perl -MTime::HiRes=time -e 'printf "%.3f\n", time'; }

# $1 label  $2 decision function (guard_decision or write_guard_decision)  $3 expected decision
# $4 command  $5 bound in seconds (default 8)
#
# Asserts the decision and that the hook reached it inside the bound. A timing check guards two
# things: a hook that runs past its 10-second timeout lets the command through, and a reading that
# walks again from every word costs the square of the command's length. The default bound, 8
# seconds, keeps the first with a margin, and a run past a bound is timed once more before it
# fails, since a loaded machine slows one run by well under twice while a quadratic walk is slower
# by ten times or more on both.
assert_decided_in_time() {
    local label="$1" decide="$2" want="$3" cmd="$4" bound="${5:-8}" started secs got try
    for try in 1 2; do
        started=$(now)
        got="$("$decide" "$cmd")"
        secs=$(perl -e 'printf "%.2f", $ARGV[1] - $ARGV[0]' "$started" "$(now)")
        perl -e 'exit($ARGV[0] < $ARGV[1] ? 0 : 1)' "$secs" "$bound" && break
    done
    checks=$((checks + 2))
    if [ "$got" = "$want" ]; then
        echo "ok   $label"
    else
        fail "$label: expected $want, got $got"
    fi
    if perl -e 'exit($ARGV[0] < $ARGV[1] ? 0 : 1)' "$secs" "$bound"; then
        echo "ok   $label: decided in ${secs}s, under ${bound}s"
    else
        fail "$label: took ${secs}s on its second try too, past ${bound}s"
    fi
}
assert_guard_timed() { assert_decided_in_time "$1" guard_decision "$2" "$3" "${4:-8}"; }
assert_write_guard_timed() { assert_decided_in_time "$1" write_guard_decision "$2" "$3" "${4:-8}"; }

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
assert_eq "a generated WAV under docs/evidence -> sound-effects + verify" \
    "sound-effects,verify," \
    "$(project_rules_skills sound-asset-session "" "docs/evidence/sound-lab/example.wav")"
assert_eq "docs/evidence/** -> verify" \
    "verify," \
    "$(project_rules_skills evidence-session "" "docs/evidence/experiment/README.md")"
assert_eq "primary captures keep their specific rule alongside verify" \
    "session-captures,verify," \
    "$(project_rules_skills capture-session "" "docs/evidence/archive/session-captures/frame.png")"

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
if grep -q '^+ governed=1$' <<<"$todo_trace"; then
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
if grep -q '^+ governed=1$' <<<"$evidence_trace"; then
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
# More than four arguments is a broken case, not extra ones to ignore: a missing newline after a
# command's closing quote runs the next case's words into this one, and the next case never runs.
assert_guard() {
    checks=$((checks + 1))
    if [ "$#" -gt 4 ]; then
        fail "$1: $# arguments, at most 4 (a missing line break after the command?)"
        return
    fi
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
assert_guard_timed "31 KB of short words, then a git grep only reading 3 catches -> deny" deny \
    "$dense_body
git -C \"/x y\" grep -i foo -- docs/"
assert_guard "the same invocation alone is caught only by reading 3 -> deny" deny \
    'git -C "/x y" grep -i foo -- docs/'

# Inside a quoted script, reading 4 keeps the script's own quoted arguments whole: a -C or -c
# argument with a space in it, quoted with the other kind of quote or with \", is skipped as one
# word, and a quoted pattern holding -I is not the -I flag.
assert_guard "bash -c '...' with a double-quoted -C argument holding a space -> deny" deny \
    "bash -c 'git -C \"/x y\" grep x'"
assert_guard "bash -c \"...\" with an escaped-quote -C argument holding a space -> deny" deny \
    'bash -c "git -C \"/x y\" grep x"'
assert_guard "bash -c \"...\" with a single-quoted -c argument holding a space -> deny" deny \
    "bash -c \"git -c 'a=b c' grep x\""
assert_guard "bash -c '...' whose only -I is inside a quoted pattern -> deny" deny \
    "bash -c 'git grep \"gcc -I\" x'"
assert_guard "bash -c '...' with a quoted -C argument and a real -I -> allow" allow \
    "bash -c 'git -C \"/x y\" grep -I x'"
# An empty quoted -C argument is still git's argument (-C "" stays in the current directory).
assert_guard "git -C \"\" grep -> deny" deny 'git -C "" grep x'
assert_guard "git -C '' grep -> deny" deny "git -C '' grep x"
assert_guard "bash -c 'git -C \"\" grep x' -> deny" deny "bash -c 'git -C \"\" grep x'"
assert_guard "git -C \"\" grep -I -> allow" allow 'git -C "" grep -I x'

# A `git` whose options swallow the next word (`-c`, `-C`, a `>` redirect) can swallow another
# `git`, so in a chain of them the run of options from every `git` reaches the end of the chain.
# Each check here is a chain like that: at 10 KB, ending in a search only reading 3 sees (all
# three readings run to the end), and at 16 KB and the 32 KB bound, ending in a guarded search that
# allows. The guard reads the options from one table built once, so every chain is decided in
# about the time of one pass. A walk from every `git` takes most of the 10-second timeout on the
# 10 KB chains and runs jq out of memory on the longer ones, which denies what should allow.
chain_c_10k="$(printf 'git -c %.0s' $(seq 1 1420))"
chain_c_16k="$(printf 'git -c %.0s' $(seq 1 2330))"
chain_c_32k="$(printf 'git -c %.0s' $(seq 1 4675))"
chain_redirect_10k="$(printf 'git > %.0s' $(seq 1 1660))"
chain_redirect_32k="$(printf 'git > %.0s' $(seq 1 5455))"
assert_guard_timed "10 KB of git -c git -c ..., then a git grep only reading 3 catches -> deny" deny \
    "${chain_c_10k}; git -C \"/x y\" grep -i foo -- docs/"
assert_guard_timed "16 KB of git -c git -c ..., then a guarded git grep -> allow" allow \
    "${chain_c_16k}; git grep -I x"
assert_guard_timed "32 KB of git -c git -c ..., then a guarded git grep -> allow" allow \
    "${chain_c_32k}; git grep -I x"
assert_guard_timed "10 KB of git > git > ..., then a git grep only reading 3 catches -> deny" deny \
    "${chain_redirect_10k}; git -C \"/x y\" grep -i foo -- docs/"
assert_guard_timed "32 KB of git > git > ..., then a guarded git grep -> allow" allow \
    "${chain_redirect_32k}; git grep -I x"
# The same at the bound inside a quoted script, where every quoted -C argument is grouped by the
# fourth reading and all four readings run to the end.
chain_quoted_32k="$(printf 'git -C "a b" %.0s' $(seq 1 2512))"
assert_guard_timed "32 KB of bash -c 'git -C \"a b\" ...', then a guarded git grep -> allow" allow \
    "bash -c '${chain_quoted_32k}'; git grep -I x"

# Past 32 KB, a text holding both words is denied without being read, even when the one
# git grep in it is guarded; a long text without both words still allows at once.
huge_body="$(printf 'Lorem ipsum dolor sit amet, "quoted words", '"'"'more'"'"'; x | y (z) [w]\n%.0s' $(seq 1 3200))"
assert_guard_timed "a 200 KB command with only a guarded git grep -> deny (too long to read in full)" deny \
    "echo \"$huge_body\"; git grep -I -n foo -- '*.md'" 2
assert_guard_timed "a 200 KB command without both words -> allow" allow \
    "echo \"$huge_body\"; git status" 2

# Past 32 KB (too_long), one regex decides instead of building $raw/$bare/$flat over the whole
# text: a backslash-newline pair, a lone backslash, a quote mark or $ between the letters of
# git/grep still reads as the word, so an obscured pair over the bound denies too, and one holding
# only "git" (no "grep" anywhere) allows -- it cannot be a git ... grep invocation without the
# second word. A newline on its own is not skipped: the shell joins two lines only at a backslash,
# so prose whose lines end in "g" and start with "it" or "rep" names neither word.
over_bound_filler="$(head -c 40000 /dev/zero | tr '\0' 'a')"
assert_guard "over 32 KB, g\\\\it and g\"r\"ep obscured -> deny" deny \
    "echo '${over_bound_filler}'; g\\it status; g\"r\"ep foo"
assert_guard "over 32 KB, g\$'i't and gr\$'e'p (an ANSI-C string between letters) -> deny" deny \
    "echo '${over_bound_filler}'; g\$'i't status; gr\$'e'p foo"
assert_guard "over 32 KB, a backslash-newline between the letters of both words -> deny" deny \
    "echo '${over_bound_filler}'; g\\
it status; gr\\
ep foo"
assert_guard "over 32 KB, git only (no grep anywhere) -> allow" allow \
    "echo '${over_bound_filler}'; git status"
assert_guard "over 32 KB, lines ending in g and starting with it and rep -> allow" allow \
    "cat <<EOF
${over_bound_filler} drawing
item one, PNG
replacement
EOF"

# The two shapes dense in the characters the readings drop (1 MB of `a'` and 1 MB of `x\` +
# newline) hold neither word and allow, decided by the one regex in well under a second each;
# past hard_cap (1 MB) every command denies without being read, the same as
# github-write-guard.sh, obscured words or none.
over_cap="$(head -c 1100000 /dev/zero | tr '\0' 'a')"
near_cap_quotes="$(head -c 1000000 /dev/zero | tr '\0' "'" | sed "s/''/a'/g")"
near_cap_lines="$(yes 'x\' | head -n 330000)"
assert_guard_timed "over 1 MB, obscured g\\\\it and g\"r\"ep -> deny" deny \
    "echo '${over_cap}'; g\\it status; g\"r\"ep foo" 2
assert_guard_timed "over 1 MB, naming neither word -> deny, not read at all" deny \
    "echo '${over_cap}'" 2
assert_guard_timed "1 MB of a', naming neither word -> allow, decided quickly" allow \
    "echo ${near_cap_quotes}" 2
assert_guard_timed "1 MB of backslash-newlines, naming neither word -> allow, decided quickly" allow \
    "echo ${near_cap_lines}" 2

# ---------------------------------------------------------------- github-write-guard.sh ---------
# Prints "deny", "ask" or "allow" for one synthetic command through github-write-guard.sh, as the
# tool named by $2 (Bash when omitted). Same shape as guard_decision above, for the other hook.
# Every case below runs as a machine with identities set up, so the guard's own deny is what it
# sees wherever the suite runs; a cloud session or a runner with no identity directory would turn
# an ordinary write into an ask. `write_guard_remote` and `write_guard_agents` switch that for the
# ask cases further down.
write_guard_agents="${TMPDIR:-/tmp}/write-guard-agents"
mkdir -p "$write_guard_agents"
write_guard_remote=""
write_guard_switch=""
write_guard_decision() {
    local cmd="$1" tool="${2:-Bash}" raw
    raw=$(printf '%s' "$cmd" | jq -Rs --arg t "$tool" '{tool_name:$t, tool_input:{command:.}}' \
        | env -u CLAUDE_CODE_REMOTE -u NAPPY_ASK_FOR_PLAYER_WRITES \
            ${write_guard_remote:+CLAUDE_CODE_REMOTE=true} ${write_guard_switch:+NAPPY_ASK_FOR_PLAYER_WRITES=$write_guard_switch} \
            NAPPY_AGENTS_DIR="$write_guard_agents" "$root/.claude/hooks/github-write-guard.sh")
    if [ -z "$raw" ]; then
        printf 'allow'
    else
        printf '%s' "$raw" | jq -r '.hookSpecificOutput.permissionDecision'
    fi
}

# $1 label  $2 expected ("deny" or "allow")  $3 command  $4 tool name (Bash when omitted)
# More than four arguments is a broken case, as for assert_guard above.
assert_write_guard() {
    checks=$((checks + 1))
    if [ "$#" -gt 4 ]; then
        fail "$1: $# arguments, at most 4 (a missing line break after the command?)"
        return
    fi
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
assert_write_guard "coder-wrapped xargs push still allows" allow \
    'uv run python tools/agent-identity.py run codex-coder -- xargs git push origin < tags.txt'
assert_write_guard "xargs invoking the coder wrapper still allows" allow \
    'xargs -I{} uv run python tools/agent-identity.py run codex-coder -- git push origin {}'
assert_write_guard "reviewer-wrapped xargs push still denies" deny \
    'uv run python tools/agent-identity.py run codex-reviewer -- xargs git push origin < tags.txt'
assert_write_guard "coder-wrapped parallel push still allows" allow \
    'uv run python tools/agent-identity.py run codex-coder -- parallel git push origin < tags.txt'
assert_write_guard "parallel invoking the coder wrapper still allows" allow \
    'parallel uv run python tools/agent-identity.py run codex-coder -- git push origin {}'
assert_write_guard "reviewer-wrapped parallel push still denies" deny \
    'uv run python tools/agent-identity.py run codex-reviewer -- parallel git push origin < tags.txt'
assert_write_guard "coder-wrapped input-supplied git subcommand allows" allow \
    'uv run python tools/agent-identity.py run codex-coder -- gxargs git'
assert_write_guard "coder-wrapped input-supplied gh verb allows" allow \
    'uv run python tools/agent-identity.py run codex-coder -- env_parallel gh pr'
assert_write_guard "input wrapper invoking coder-wrapped gh with no noun denies: input can name issue" deny \
    'parallel uv run python tools/agent-identity.py run codex-coder -- gh'
assert_write_guard "reviewer-wrapped input-supplied git subcommand denies" deny \
    'uv run python tools/agent-identity.py run codex-reviewer -- gxargs git'
assert_write_guard "reviewer-wrapped input-supplied gh verb can merge and denies" deny \
    'uv run python tools/agent-identity.py run codex-reviewer -- env_parallel gh pr'
assert_write_guard "input wrapper invoking reviewer-wrapped incomplete gh denies" deny \
    'parallel uv run python tools/agent-identity.py run codex-reviewer -- gh'
assert_write_guard "coder-wrapped lowercase xargs replacement subcommand allows" allow \
    'uv run python tools/agent-identity.py run codex-coder -- xargs -Icmd git cmd origin v1'
assert_write_guard "input wrapper replacement invoking the coder wrapper allows" allow \
    'parallel -Icmd uv run python tools/agent-identity.py run codex-coder -- git cmd origin v1'
assert_write_guard "reviewer-wrapped lowercase parallel replacement subcommand denies" deny \
    'uv run python tools/agent-identity.py run codex-reviewer -- parallel -Icmd git cmd origin v1'
assert_write_guard "input wrapper replacement invoking the reviewer wrapper denies" deny \
    'xargs -Icmd uv run python tools/agent-identity.py run codex-reviewer -- gh pr cmd 3'
assert_write_guard "coder-wrapped gh api with input-supplied arguments allows" allow \
    'uv run python tools/agent-identity.py run claude-coder -- xargs gh api repos/o/r/pulls/3'
assert_write_guard "reviewer-wrapped gh api with input-supplied arguments can merge and denies" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- xargs gh api repos/o/r/pulls/3'

# GNU parallel's -l takes an optional number, clustered too: -kl reads as -k then -l, so a word
# after it that is no number (or a cluster's rest that is none, -kli) leaves command position
# unknown, while a numeric -l and a no-value cluster stay reads.
for clustered_optional in \
    'ls | parallel -kl tools/release.sh patch push' \
    'parallel -kl tools/update-pr.sh' \
    'parallel -kli status git status origin v1'; do
    assert_write_guard "clustered optional -l with no number denies: $clustered_optional" deny "$clustered_optional"
done
assert_write_guard "reviewer-wrapped clustered optional -l denies" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- parallel -kl tools/update-pr.sh'
assert_write_guard "coder-wrapped clustered optional -l allows" allow \
    'uv run python tools/agent-identity.py run claude-coder -- parallel -kl tools/update-pr.sh'
assert_write_guard "orchestrator-wrapped clustered -kli before gh issue denies as an issue write" deny \
    'uv run python tools/agent-identity.py run claude-orchestrator -- parallel -kli status gh issue status 5'
for clustered_read in \
    'parallel -kl2 git status' \
    'parallel -kl1 gh pr view {}' \
    'parallel -k git log'; do
    assert_write_guard "clustered read stays a read: $clustered_read" allow "$clustered_read"
done

# Input placed at a replacement token replaces the word holding it, so a read flag holding the
# token is no read flag: the dry run, --version and the abort-like flags fall to input.
for input_replaced_flag in \
    'ls | xargs -I--dry-run tools/update-pr.sh --dry-run' \
    'parallel -I--dry-run tools/land-prs.sh --dry-run' \
    'xargs -Idry tools/update-pr.sh --dry-run' \
    'xargs -I--version git --version' \
    'xargs -I--ff-only git merge --ff-only' \
    'xargs -I--abort git rebase --abort' \
    'parallel -I--ff-only git pull --ff-only' \
    'xargs -I--quit git cherry-pick --quit'; do
    assert_write_guard "a read flag input replaces denies: $input_replaced_flag" deny "$input_replaced_flag"
done
for input_fixed_flag in \
    'xargs tools/update-pr.sh --dry-run' \
    'xargs -I{} tools/update-pr.sh --dry-run {}' \
    'xargs git --version' \
    'xargs -I{} git merge --ff-only {}' \
    'xargs git rebase --abort'; do
    assert_write_guard "a read flag input cannot reach still allows: $input_fixed_flag" allow "$input_fixed_flag"
done
assert_write_guard "coder-wrapped replaced dry run still allows" allow \
    'uv run python tools/agent-identity.py run claude-coder -- xargs -I--dry-run tools/update-pr.sh --dry-run'
assert_write_guard "reviewer-wrapped replaced dry run denies" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- xargs -I--dry-run tools/update-pr.sh --dry-run'

# Input that reaches a gh issue write is an issue write, denied wrapped or not like a written one
# (the inbox rule): a verb input supplies to a written gh issue, a noun input supplies (it can be
# issue), flags input adds to a written issue endpoint, and a written gh issue whose wrapper's
# options cannot be read. A read verb, a non-issue endpoint and the comments path stay as before.
for input_issue_write in \
    "sh -c 'echo comment 5 --body x | xargs gh issue'" \
    'xargs -I{} gh issue {} 5' \
    "sh -c 'ls | xargs --foo gh issue close 5'" \
    "sh -c 'echo issue close 5 | xargs gh'" \
    'xargs gh api repos/o/r/issues' \
    'parallel gh api repos/o/r/issues/5'; do
    assert_write_guard "orchestrator-wrapped input issue write denies: $input_issue_write" deny \
        "uv run python tools/agent-identity.py run claude-orchestrator -- $input_issue_write"
    assert_write_guard "coder-wrapped input issue write denies: $input_issue_write" deny \
        "uv run python tools/agent-identity.py run claude-coder -- $input_issue_write"
done
assert_write_guard "unwrapped input-supplied gh issue verb denies" deny \
    'echo comment 5 --body x | xargs gh issue'
assert_write_guard "orchestrator-wrapped gh issue read under xargs allows" allow \
    'uv run python tools/agent-identity.py run claude-orchestrator -- xargs gh issue view'
assert_write_guard "unwrapped gh issue read under xargs allows" allow \
    'echo 5 | xargs gh issue view'
assert_write_guard "coder-wrapped input to the shared comments path allows" allow \
    'uv run python tools/agent-identity.py run claude-coder -- xargs gh api repos/o/r/issues/5/comments'

# The shared input option parser keeps role policy after consuming clusters/values and when an
# unknown option makes command position unreadable. The synthetic commands are only hook JSON.
for input_option_command in \
    'xargs -rIstatus git status origin v1' \
    'xargs -Istatus -E -Iother git status origin v1' \
    'parallel --timeout 5 tools/update-pr.sh' \
    'parallel --new-option 5 tools/update-pr.sh' \
    'parallel --new-option 5 gh pr view'; do
    assert_write_guard "coder retains exemption: $input_option_command" allow \
        "uv run python tools/agent-identity.py run codex-coder -- $input_option_command"
    assert_write_guard "reviewer cannot exempt unreadable publishing: $input_option_command" deny \
        "uv run python tools/agent-identity.py run codex-reviewer -- $input_option_command"
done
assert_write_guard "unknown input options still find an invoked coder identity" allow \
    'parallel --new-option 5 uv run python tools/agent-identity.py run codex-coder -- tools/update-pr.sh'
assert_write_guard "unknown input options still refuse an invoked reviewer identity" deny \
    'parallel --new-option 5 uv run python tools/agent-identity.py run codex-reviewer -- tools/update-pr.sh'

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
assert_write_guard_timed "400 glued gh api calls, ending in a write -> deny, decided quickly" deny \
    "${dense_gh_api}gh api repos/o/r -X POST"

# The same inside one quoted string, where every separator is soft: each call's scan stops at the
# next soft separator that starts a git/gh command, so this stays linear too. And a long quoted
# commit message, read one character at a time for its quotes, stays linear in its length.
quoted_gh_api="$(for _ in $(seq 1 400); do printf "gh api x --jq '.a|.b'; echo hi; "; done)"
long_message="$(head -c 60000 /dev/zero | tr '\0' 'a')"
assert_write_guard_timed "400 glued gh api calls inside bash -c, ending in a write -> deny" deny \
    "bash -c \"${quoted_gh_api}gh api repos/o/r -X POST\""
assert_write_guard_timed "a 60000-character quoted commit message, wrapped -> allow" allow \
    "uv run python tools/agent-identity.py run claude-coder -- git commit -m '${long_message}'"

# An unsure command (here a heredoc) reads every separator as soft for a gh api call's flags, so
# each call's scan runs to the next git/gh command rather than to its own pipe; 400 glued calls
# with a pipe and a plain command between them still stay linear.
unsure_gh_api="$(for _ in $(seq 1 400); do printf 'gh api x --jq .a | head -1; echo hi; '; done)"
assert_write_guard_timed "400 glued gh api reads beside a heredoc, ending in a write -> deny" deny \
    "cat <<EOF
x
EOF
${unsure_gh_api}gh api repos/o/r -X POST"

# A flag before the endpoint is how gh itself accepts a write (-X/--method/-f/-F/--input), so the
# scan starts right after "api"; and an endpoint or flag value ending in /gh or /git is part of
# the call, not the start of a new command.
assert_write_guard "gh api -X PUT .../merge, flag before the endpoint -> deny" deny \
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
assert_write_guard_timed "800 glued git merge calls -> deny, decided quickly" deny "$dense_merge"

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

# claude-orchestrator is a wrapping role, not a reviewer: it makes every write on a pull request
# with no code changes (committing, "Who a commit and a pull request are from"), pushes and merges
# included, so each of those is let through wrapped and denied bare; its issue writes go through
# tools/inbox.py alone (below).
orch="uv run python tools/agent-identity.py run claude-orchestrator --"
assert_write_guard "wrapped git push as claude-orchestrator -> allow, not a reviewer" allow \
    "$orch git push -u origin feature/docs"
assert_write_guard "wrapped git commit as claude-orchestrator -> allow" allow \
    "$orch git commit -F /tmp/msg"
assert_write_guard "wrapped gh pr create as claude-orchestrator -> allow" allow \
    "$orch gh pr create --draft --title t --body-file /tmp/body"
assert_write_guard "wrapped gh pr merge as claude-orchestrator -> allow, not a reviewer" allow \
    "$orch gh pr merge 1 --squash"
assert_write_guard "wrapped gh api .../merge as claude-orchestrator -> allow, not a reviewer" allow \
    "$orch gh api -X PUT repos/o/r/pulls/1/merge"
assert_write_guard "wrapped gh label create as claude-orchestrator -> allow" allow \
    "$orch gh label create inbox"
assert_write_guard "wrapped gh run rerun as claude-orchestrator -> allow" allow \
    "$orch gh run rerun 99 --failed"
assert_write_guard "wrapped tools/prune-merged.sh as claude-orchestrator -> allow, not a reviewer" allow \
    "$orch tools/prune-merged.sh feature/docs"
assert_write_guard "wrapped tools/land-prs.sh as claude-orchestrator -> allow" allow \
    "$orch tools/land-prs.sh 12"
assert_write_guard "bare gh issue create -> deny, the orchestrator's writes are wrapped too" deny \
    'gh issue create --title t --body-file /tmp/note --label inbox'
assert_write_guard "bare gh issue close -> deny" deny 'gh issue close 12'
assert_write_guard "bare gh issue comment -> deny, the orchestrator's writes are wrapped too" deny \
    "gh issue comment 12 --body 'Filed in #13'"
assert_write_guard "a write after the orchestrator's wrapped command, on its own line -> deny" deny \
    "$orch git fetch"$'\n''git push'

# An issue is written through tools/inbox.py alone (leafy-finch; bouncy-heron, statement 14: "an
# agent shouldn't use gh issue directly"): a direct gh issue write denies wrapped or not, as the
# orchestrator or any other role, and the script itself, which wraps its own writes, is let through.
assert_write_guard "wrapped gh issue create as claude-orchestrator -> deny, the script writes issues" deny \
    "$orch gh issue create --title t --body-file /tmp/note --label inbox"
assert_write_guard "wrapped gh issue close as claude-orchestrator -> deny" deny \
    "$orch gh issue close 12 --comment 'Filed in #13'"
assert_write_guard "wrapped gh issue reopen as claude-orchestrator -> deny" deny "$orch gh issue reopen 12"
assert_write_guard "wrapped gh issue comment as claude-orchestrator -> deny" deny \
    "$orch gh issue comment 12 --body 'Filed in #13'"
assert_write_guard "wrapped gh issue edit --add-label as claude-orchestrator -> deny" deny \
    "$orch gh issue edit 12 --add-label queue_now"
assert_write_guard "wrapped gh -R O/R issue close as claude-coder -> deny" deny \
    'uv run python tools/agent-identity.py run claude-coder -- gh -R o/r issue close 12'
assert_write_guard "wrapped gh issue view -> allow, a read" allow "$orch gh issue view 12"
# The API's issue writes are issue writes too, wrapped or not; a comment POST to issues/N/comments
# (and GraphQL's addComment) is the one route left, since a pull request's own conversation
# comments share it.
assert_write_guard "wrapped gh api issue create -> deny" deny \
    "$orch gh api repos/JosuaKrause/nappy/issues -f title=x -f body=y"
assert_write_guard "wrapped gh api issue create to issues/ from --input -> deny" deny \
    "$orch gh api repos/o/r/issues/ --input body.json"
assert_write_guard "wrapped gh api issue create to issues?query -> deny" deny "$orch gh api 'repos/o/r/issues?x=1' -f title=t"
assert_write_guard "wrapped gh api -X PATCH issues/N state=closed -> deny" deny \
    "$orch gh api -X PATCH repos/JosuaKrause/nappy/issues/423 -f state=closed"
assert_write_guard "the same as claude-coder, with a leading slash -> deny" deny \
    'uv run python tools/agent-identity.py run claude-coder -- gh api -X PATCH /repos/o/r/issues/423 -f state=closed'
assert_write_guard "wrapped PATCH repositories/<id>/issues/N -> deny, the same issue by id" deny \
    "$orch gh api -X PATCH repositories/123/issues/423 -f state=closed"
assert_write_guard "wrapped gh api label add -> deny" deny \
    "$orch gh api repos/JosuaKrause/nappy/issues/423/labels -f 'labels[]=queue_now'"
assert_write_guard "wrapped gh api -X DELETE of a label -> deny" deny \
    "$orch gh api -X DELETE repos/JosuaKrause/nappy/issues/423/labels/inbox"
assert_write_guard "wrapped gh api assignees -> deny" deny "$orch gh api repos/o/r/issues/5/assignees -f 'assignees[]=x'"
assert_write_guard "wrapped gh api -X PUT lock -> deny" deny "$orch gh api -X PUT repos/o/r/issues/5/lock"
assert_write_guard "wrapped gh api -X PATCH issues/comments/N -> deny" deny \
    "$orch gh api -X PATCH repos/JosuaKrause/nappy/issues/comments/123 -f body=hi"
assert_write_guard "wrapped gh api -X DELETE issues/comments/N -> deny" deny "$orch gh api -X DELETE repos/o/r/issues/comments/9"
assert_write_guard "a header value before the issue endpoint does not hide it -> deny" deny \
    "$orch gh api -H 'Accept: application/vnd.github+json' -X PATCH repos/o/r/issues/5 -f state=closed"
# The owner and the repository need not be literal: a variable or a substitution in their place
# (the shape tools/release.sh itself uses for gh api) is still an issue endpoint.
assert_write_guard "wrapped PATCH repos/\$R/issues/423 state=closed -> deny" deny \
    "R=JosuaKrause/nappy; $orch gh api -X PATCH \"repos/\$R/issues/423\" -f state=closed"
assert_write_guard "wrapped PATCH repos/\$(gh repo view ...)/issues/423 -> deny" deny \
    "$orch gh api -X PATCH \"repos/\$(gh repo view --json nameWithOwner -q .nameWithOwner)/issues/423\" -f state=closed"
assert_write_guard "wrapped PATCH repos/\${R}/issues/423 -> deny" deny \
    "$orch gh api -X PATCH \"repos/\${R}/issues/423\" -f state=closed"
assert_write_guard "wrapped issue create at repos/\$R/issues -> deny" deny "$orch gh api \"repos/\$R/issues\" -f title=t"
assert_write_guard "wrapped label add at repos/\$R/issues/423/labels -> deny" deny \
    "$orch gh api \"repos/\$R/issues/423/labels\" -f 'labels[]=x'"
assert_write_guard "wrapped PATCH of a full URL with \$R -> deny" deny \
    "$orch gh api -X PATCH \"https://api.github.com/repos/\$R/issues/423\" -f state=closed"
assert_write_guard "wrapped comment POST to repos/\$R/issues/429/comments -> allow, PR comments share it" allow \
    "$orch gh api \"repos/\$R/issues/429/comments\" -F body=@c.md"
assert_write_guard "wrapped PATCH repos/\$R/pulls/5 -> allow, not an issue" allow \
    "$orch gh api -X PATCH \"repos/\$R/pulls/5\" -f body=x"
assert_write_guard "wrapped repos/\$(...)/issues/423 with -X PATCH after the endpoint -> deny" deny \
    "$orch gh api \"repos/\$(gh repo view --json nameWithOwner -q .nameWithOwner)/issues/423\" -X PATCH -f state=closed"
assert_write_guard "wrapped PATCH repos/\`echo o/r\`/issues/5, a bare backtick -> deny" deny \
    "$orch gh api -X PATCH repos/\`echo o/r\`/issues/5 -f state=closed"
assert_write_guard "wrapped comment POST to repos/\$(...)/issues/429/comments -> allow" allow \
    "$orch gh api \"repos/\$(gh repo view --json nameWithOwner -q .nameWithOwner)/issues/429/comments\" -F body=@c.md"
assert_write_guard "wrapped GraphQL closeIssue -> deny" deny \
    "$orch gh api graphql -f query='mutation { closeIssue(input: {issueId: \"x\"}) { clientMutationId } }'"
assert_write_guard "wrapped GraphQL addLabelsToLabelable -> deny" deny \
    "$orch gh api graphql -f query='mutation { addLabelsToLabelable(input: {labelableId: \"x\", labelIds: [\"y\"]}) { clientMutationId } }'"
assert_write_guard "wrapped GraphQL createIssue under an alias -> deny" deny \
    "$orch gh api graphql -f query='mutation { made: createIssue(input: {repositoryId: \"r\", title: \"t\"}) { issue { number } } }'"
# A query written with no spaces still names its mutation inside a longer word, and a query held
# in a variable, a file or standard input the same command fills is read where it is filled.
assert_write_guard "wrapped compact GraphQL mutation{closeIssue(...)} -> deny" deny \
    "$orch gh api graphql -f query='mutation{closeIssue(input:{issueId:\"x\"}){clientMutationId}}'"
assert_write_guard "wrapped compact GraphQL mutation{deleteIssue(...)} -> deny" deny \
    "$orch gh api graphql -f query='mutation{deleteIssue(input:{issueId:\"x\"}){clientMutationId}}'"
assert_write_guard "wrapped compact named mutation Close{closeIssue(...)} -> deny" deny \
    "$orch gh api graphql -f query='mutation Close{closeIssue(input:{issueId:\"x\"}){clientMutationId}}'"
assert_write_guard "wrapped compact alias mutation{a:closeIssue(...)} -> deny" deny \
    "$orch gh api graphql -f query='mutation{a:closeIssue(input:{issueId:\"x\"}){clientMutationId}}'"
assert_write_guard "Q='mutation { closeIssue ... }', then a wrapped -f query=\"\$Q\" -> deny" deny \
    "Q='mutation { closeIssue(input: {issueId: \"x\"}) { clientMutationId } }'; $orch gh api graphql -f query=\"\$Q\""
assert_write_guard "the same with -F query=\"\$Q\" -> deny" deny \
    "Q='mutation{closeIssue(input:{issueId:\"x\"}){clientMutationId}}'; $orch gh api graphql -F query=\"\$Q\""
assert_write_guard "a wrapped -F query=@- reading a heredoc closeIssue -> deny" deny \
    "$orch gh api graphql -F query=@- <<'EOF'
mutation{closeIssue(input:{issueId:\"x\"}){clientMutationId}}
EOF"
assert_write_guard "a closeIssue written to m.json, then a wrapped --input m.json -> deny" deny \
    "cat > m.json <<'EOF'
{\"query\":\"mutation{closeIssue(input:{issueId:\\\"x\\\"}){clientMutationId}}\"}
EOF
$orch gh api graphql --input m.json"
# Every issue mutation in GitHub's schema is named: the verbs replace, apply and reject, a middle
# holding a digit (ProjectV2), and an issue's dependencies and linked branches.
for issue_mutation in \
    'replaceActorsForAssignable(input:{assignableId:"x",actorIds:[]})' \
    'applyPendingIssueSuggestions(input:{issueId:"x"})' \
    'rejectPendingIssueSuggestions(input:{issueId:"x"})' \
    'addBlockedBy(input:{issueId:"x",blockingIssueId:"y"})' \
    'removeBlockedBy(input:{issueId:"x",blockingIssueId:"y"})' \
    'convertProjectV2DraftIssueItemToIssue(input:{itemId:"x",repositoryId:"r"})' \
    'createLinkedBranch(input:{issueId:"x",oid:"y"})' \
    'deleteLinkedBranch(input:{linkedBranchId:"x"})'; do
    assert_write_guard "wrapped GraphQL ${issue_mutation%%(*} -> deny, an issue mutation" deny \
        "$orch gh api graphql -f query='mutation{${issue_mutation}{clientMutationId}}'"
done
# A reaction and a comment's minimizing serve a pull request as readily as an issue, like
# addComment, so they stay open, and so does a pull request's own branch update.
assert_write_guard "wrapped GraphQL addReaction -> allow, it serves pull requests too" allow \
    "$orch gh api graphql -f query='mutation{addReaction(input:{subjectId:\"x\",content:HOORAY}){clientMutationId}}'"
assert_write_guard "wrapped GraphQL minimizeComment -> allow, it serves pull requests too" allow \
    "$orch gh api graphql -f query='mutation{minimizeComment(input:{subjectId:\"x\",classifier:OUTDATED}){clientMutationId}}'"
assert_write_guard "wrapped GraphQL updatePullRequestBranch -> allow, a pull request's own write" allow \
    "uv run python tools/agent-identity.py run claude-coder -- gh api graphql -f query='mutation{updatePullRequestBranch(input:{pullRequestId:\"x\"}){clientMutationId}}'"
assert_write_guard "wrapped compact GraphQL addComment -> allow, the comment route" allow \
    "$orch gh api graphql -f query='mutation{addComment(input:{subjectId:\"x\",body:\"y\"}){clientMutationId}}'"
assert_write_guard "a reviewer's wrapped compact resolveReviewThread -> allow" allow \
    "uv run python tools/agent-identity.py run claude-reviewer -- gh api graphql -f query='mutation{resolveReviewThread(input:{threadId:\"x\"}){thread{id}}}'"
assert_write_guard "a reviewer's wrapped resolveReviewThread from a file -> allow" allow \
    "uv run python tools/agent-identity.py run claude-reviewer -- gh api graphql -F query=@resolve.graphql -F id=PRRT_x"
assert_write_guard "wrapped gh api comment POST to issues/N/comments -> allow, PR comments share it" allow \
    "$orch gh api repos/JosuaKrause/nappy/issues/429/comments -F body=@/tmp/b.md"
assert_write_guard "wrapped GraphQL addComment -> allow, the same route" allow \
    "$orch gh api graphql -f query='mutation { addComment(input: {subjectId: \"x\", body: \"y\"}) { clientMutationId } }'"
assert_write_guard "a reviewer's wrapped GraphQL resolveReviewThread -> allow, not an issue mutation" allow \
    "uv run python tools/agent-identity.py run claude-reviewer -- gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: \"x\"}) { thread { id } } }'"
assert_write_guard "a GraphQL read naming an issue -> allow" allow \
    "gh api graphql -f query='query { repository(owner: \"o\", name: \"r\") { issue(number: 5) { title } } }'"
assert_write_guard "gh api GET of an issue and its comments -> allow" allow \
    "gh api repos/o/r/issues/423 && gh api repos/o/r/issues/423/comments --jq '.[].body'"
assert_write_guard "gh api -X GET issues with a field -> allow, a read" allow "gh api -X GET repos/o/r/issues -f labels=inbox"
assert_write_guard "wrapped gh api -X PATCH pulls/N -> allow, a pull request's own write" allow \
    "$orch gh api -X PATCH repos/o/r/pulls/5 -f body=x"
# gh sends what follows a ? as the query and drops what follows a #, so the comments exception is
# read on the path alone: a query string or fragment ending in /issues/N/comments does not make
# an issue write a comment.
assert_write_guard "wrapped PATCH issues/5?x=/issues/1/comments -> deny, the query is not the path" deny \
    "$orch gh api -X PATCH 'repos/o/r/issues/5?x=/issues/1/comments' -f state=closed"
assert_write_guard "wrapped PATCH issues/5#/issues/1/comments -> deny, the fragment is dropped" deny \
    "$orch gh api -X PATCH 'repos/o/r/issues/5#/issues/1/comments' -f state=closed"
assert_write_guard "wrapped issue create through issues?/issues/1/comments -> deny" deny \
    "$orch gh api 'repos/o/r/issues?/issues/1/comments' -f title=x -f body=y"
assert_write_guard "wrapped DELETE issues/comments/9?/issues/1/comments -> deny" deny \
    "$orch gh api -X DELETE 'repos/o/r/issues/comments/9?/issues/1/comments'"
assert_write_guard "wrapped comment POST to issues/429/comments?per_page=1 -> allow, still the comments path" allow \
    "$orch gh api 'repos/o/r/issues/429/comments?per_page=1' -F body=@c.md"
# The accepted gaps the guard's header names, pinned so a change to them is a decision: each is
# allowed wrapped, as main allows every wrapped write.
assert_write_guard "a wrapped PATCH of an endpoint held in \$E -> allow (accepted gap)" allow \
    "E=repos/o/r/issues/5; $orch gh api -X PATCH \"\$E\" -f state=closed"
assert_write_guard "a wrapped closeIssue built by printf -> allow (accepted gap)" allow \
    "$orch gh api graphql -f query=\"\$(printf 'mutation{%sIssue(input:{issueId:\"x\"}){clientMutationId}}' close)\""
assert_write_guard "a wrapped -F query=@- fed by cat of a file -> allow (accepted gap)" allow \
    "cat q.graphql | $orch gh api graphql -F query=@-"
assert_write_guard "a wrapped -F query=@q.graphql no command here wrote -> allow (accepted gap)" allow \
    "$orch gh api graphql -F query=@q.graphql"
assert_write_guard "a wrapped graphql --input m.json no command here wrote -> allow (accepted gap)" allow \
    "$orch gh api graphql --input m.json"
assert_write_guard "a wrapped gh alias for issue close -> allow (accepted gap)" allow \
    "$orch gh alias set ic 'issue close'; $orch gh ic 423"
assert_write_guard "tools/inbox.py list, a read -> allow" allow 'uv run python tools/inbox.py list'
assert_write_guard "tools/inbox.py close with its own role -> allow" allow \
    'uv run python tools/inbox.py --role claude-orchestrator close --pr 430'
assert_write_guard "tools/inbox.py ask, wrapped as the orchestrator -> allow" allow \
    "$orch uv run python tools/inbox.py ask 423 --body-file /tmp/question.md"
assert_write_guard "tools/inbox.py capture from a heredoc of plain words -> allow" allow \
    "uv run python tools/inbox.py --role claude-orchestrator capture --band next <<'NOTE'
shadows are misplaced
NOTE"
# A capture whose words name a write is read as main reads any heredoc fed to a program, so the
# words go to a file first (the first text shape, below) and the capture takes --body-file.
assert_write_guard "tools/inbox.py capture from a heredoc naming gh issue close -> deny, not a text shape" deny \
    "uv run python tools/inbox.py --role claude-orchestrator capture --band next <<'NOTE'
the agent should never use gh issue close directly, and git push only wrapped
NOTE"
assert_write_guard "tools/inbox.py capture --body-file -> allow" allow \
    'uv run python tools/inbox.py --role claude-orchestrator capture --band next --body-file /tmp/note.md'
assert_write_guard "tools/inbox.py append --body-file -> allow" allow \
    'uv run python tools/inbox.py --role claude-orchestrator append 504 --body-file /tmp/more.md --context-file /tmp/context.md'
assert_write_guard "a direct gh issue comment, the append's own write outside the script -> deny" deny \
    'gh issue comment 504 --body-file /tmp/more.md'
assert_write_guard "a wrapped direct gh issue comment -> deny" deny \
    "$orch gh issue comment 504 --body-file /tmp/more.md"

# **The three text shapes** (the guard's header; plaid-tapir, statement 4: the player's "B"). Each
# is the whole command, and its text -- here prose naming gh issue comment, git push and
# tools/prune-merged.sh -- is not read as commands. The two denials the write-guard item named, a
# heredoc writing a brief and a heredoc commit message, allow in these shapes.
assert_write_guard "shape 1: cat > brief <<'EOF' naming gh issue comment, git push, prune-merged -> allow" allow \
    "cat > /tmp/brief.md <<'EOF'
run gh issue comment only through tools/inbox.py; git push only wrapped; tools/prune-merged.sh after
EOF"
assert_write_guard "shape 1: cat <<'EOF' > file, a forced push and an issue close in the body -> allow" allow \
    "cat <<'EOF' > /tmp/brief.md
git push --force origin main and gh issue close 423
EOF"
assert_write_guard "shape 1: cat >> file <<\"EOF\" -> allow" allow "cat >> /tmp/brief.md <<\"EOF\"
git push
EOF"
assert_write_guard "shape 1: cat >file <<\\EOF -> allow" allow "cat >/tmp/brief.md <<\\EOF
gh issue close 423
EOF"
assert_write_guard "shape 1: a quoted END-OF-BRIEF delimiter, \$(...) and a backtick in the body, a blank line after -> allow" allow \
    "cat > .claude/briefs/x.md <<'END-OF-BRIEF'
\$(git push --force origin main) \`gh issue close 1\`
END-OF-BRIEF
"
assert_write_guard "shape 1: prose 'if tools/land-prs.sh is named' -> allow" allow \
    "cat > m.txt <<'EOF'
if tools/land-prs.sh is named, it is read.
EOF"
assert_write_guard "shape 2: a wrapped git commit -F - <<'EOF' naming writes -> allow" allow \
    "uv run python tools/agent-identity.py run claude-coder -- git commit -F - <<'EOF'
Deny gh issue comment; run tools/prune-merged.sh and git push only wrapped

Co-Authored-By: x
EOF"
assert_write_guard "shape 2: .venv python, --repo, the orchestrator, -a and --file=- -> allow" allow \
    ".venv/bin/python tools/agent-identity.py run --repo o/r claude-orchestrator -- git commit -a --file=- <<'MSG'
git push
MSG"
assert_write_guard "shape 2: codex-coder, -F /dev/stdin -> allow" allow \
    "uv run python tools/agent-identity.py run codex-coder -- git commit --amend -F /dev/stdin <<'EOF'
gh issue close 423
EOF"
assert_write_guard "shape 3: rg -n with a quoted pattern naming gh issue comment -> allow" allow \
    'rg -n "gh issue comment" .claude/'
assert_write_guard "shape 3: grep -c with a quoted pattern naming git push -> allow" allow "grep -c 'git push' tools/land-prs.sh"
assert_write_guard "shape 3: rg for tools/prune-merged.sh or gh issue close -> allow" allow \
    "rg -n 'tools/prune-merged.sh|gh issue close' .claude/skills tools"
# A near miss of a shape is read as main's guard reads it, so each of these denies.
assert_write_guard "near shape 1: an unquoted delimiter -> deny" deny "cat > /tmp/b.md <<EOF
git push
EOF"
assert_write_guard "near shape 1: <<- -> deny" deny "cat > /tmp/b.md <<-'EOF'
	git push
	EOF"
assert_write_guard "near shape 1: a second command after the terminator -> deny" deny "cat > /tmp/b.md <<'EOF'
prose
EOF
git push"
assert_write_guard "near shape 1: no terminator -> deny" deny "cat > /tmp/b.md <<'EOF'
git push"
assert_write_guard "near shape 1: mkdir -p && cat > ... <<'EOF' -> deny" deny "mkdir -p /tmp/a && cat > /tmp/a/b.md <<'EOF'
git push
EOF"
assert_write_guard "near shape 1: cat with no file -> deny" deny "cat <<'EOF'
git push
EOF"
assert_write_guard "near shape 1: cat > \"\$f\" -> deny" deny "cat > \"\$f\" <<'EOF'
git push
EOF"
assert_write_guard "near shape 1: cat > \$(...) -> deny" deny "cat > \$(git push) <<'EOF'
x
EOF"
assert_write_guard "near shape 1: a glob for the file -> deny" deny "cat > a*.md <<'EOF'
git push
EOF"
assert_write_guard "near shape 1: tee instead of cat -> deny" deny "tee /tmp/b.md <<'EOF'
git push
EOF"
assert_write_guard "near shape 1: two heredocs one after the other -> deny" deny "cat > /tmp/a.md <<'EOF'
run git push only wrapped
EOF
cat > /tmp/b.md <<'EOF'
never gh issue close by hand
EOF"
assert_write_guard "near shape 2: a reviewer's commit -> deny" deny \
    "uv run python tools/agent-identity.py run claude-reviewer -- git commit -F - <<'EOF'
git push
EOF"
assert_write_guard "near shape 2: an unwrapped git commit -F - -> deny" deny "git commit -F - <<'EOF'
msg
EOF"
assert_write_guard "near shape 2: a wrapped git commit -m \"\$(cat <<'EOF' ...)\" -> deny" deny \
    "uv run python tools/agent-identity.py run claude-coder -- git commit -m \"\$(cat <<'EOF'
git push
EOF
)\""
assert_write_guard "near shape 2: a push after the commit's terminator -> deny" deny \
    "uv run python tools/agent-identity.py run claude-coder -- git commit -F - <<'EOF'
x
EOF
git push"
assert_write_guard "shape 2: ./tools/agent-identity.py, no python in front -> allow" allow \
    "./tools/agent-identity.py run claude-coder -- git commit -F - <<'EOF'
git push
EOF"
assert_write_guard "shape 2: python3 tools/agent-identity.py -> allow" allow \
    "python3 tools/agent-identity.py run claude-coder -- git commit -F - <<'EOF'
git push
EOF"
# The shape trusts the repository's own wrapper and a python it can name, never any program that
# is merely called agent-identity.py or python: a planted one could run the body as shell.
assert_write_guard "near shape 2: a planted /tmp/x/agent-identity.py -> deny" deny \
    "/tmp/x/agent-identity.py run claude-coder -- git commit -F - <<'EOF'
git push --force origin main
EOF"
assert_write_guard "near shape 2: a planted /tmp/x/python -> deny" deny \
    "/tmp/x/python tools/agent-identity.py run claude-coder -- git commit -F - <<'EOF'
git push --force origin main
EOF"
assert_write_guard "near shape 2: --author=x, an option with a value -> deny" deny \
    "uv run python tools/agent-identity.py run claude-coder -- git commit --author=x -F - <<'EOF'
git push
EOF"
assert_write_guard "near shape 3: rg piped into sh -> deny" deny 'rg -o "git push --force origin main" x.md | sh'
assert_write_guard "near shape 3: rg, then ; git push -> deny" deny 'rg "x" y; git push'
assert_write_guard "near shape 3: rg --pre sh -> deny, --pre runs a program" deny 'rg --pre sh "git push" x'
assert_write_guard "near shape 3: rg --pre=sh -> deny" deny 'rg --pre=sh "git push" x'
assert_write_guard "near shape 3: a \$(...) in a double-quoted pattern -> deny" deny 'rg "$(git push)" x'
assert_write_guard "near shape 3: two quoted words -> deny" deny "rg -g '*.md' \"gh issue close\" ."
assert_write_guard "near shape 3: paths naming gh issue close -> deny" deny 'rg "x" gh issue close'
assert_write_guard "near shape 3: an assignment prefix -> deny" deny 'LC_ALL=C grep "git push" x'
assert_write_guard "near shape 3: a glob path -> deny" deny 'rg "git push" *.md'
assert_write_guard "near shape 3: a redirection -> deny" deny 'rg "git push" x > /tmp/out'
assert_write_guard "near shape 3: egrep -> deny, only rg and grep" deny 'egrep "git push" x'
assert_write_guard "an echo of a quoted forced push -> deny, no text shape" deny 'echo "git push --force origin main"'

# Every reproduction from PR #429's three reviews, each denied by main's guard: none is a text
# shape, so each is read as main reads it and denies here too.
assert_write_guard "review 1: cat <<EOF around \$(gh issue close 423) -> deny" deny "cat <<EOF
\$(gh issue close 423)
EOF"
assert_write_guard "review 1: cat <<EOF > note.md around a backticked forced push -> deny" deny "cat <<EOF > note.md
see \`git push --force origin main\`
EOF"
assert_write_guard "review 1: echo \"\$(cat <<EOF\" around \$(git push --force origin main) -> deny" deny \
    "echo \"\$(cat <<EOF
\$(git push --force origin main)
EOF
)\""
assert_write_guard "review 1: tee note.md <<EOF around \$(gh issue close 423) -> deny" deny "tee note.md <<EOF
\$(gh issue close 423)
EOF"
assert_write_guard "review 1: grep -c x <<EOF around \$(gh issue close 423) -> deny" deny "grep -c x <<EOF
\$(gh issue close 423)
EOF"
assert_write_guard "review 1: a heredoc in \$(...) ended by EOF), hiding a forced push -> deny" deny \
    "echo \"\$(cat <<'EOF'
x
EOF)\"
git push --force origin main
echo \"\$(cat <<'EOF'
y
EOF
)\""
assert_write_guard "review 1: the same hiding gh issue close -> deny" deny \
    "echo \"\$(cat <<'EOF'
x
EOF)\"
gh issue close 423
echo \"\$(cat <<'EOF'
y
EOF
)\""
assert_write_guard "review 1: echo of a quoted gh issue close |& sh -> deny" deny 'echo "gh issue close 423" |& sh'
assert_write_guard "review 1: echo of a quoted forced push |& bash -> deny" deny 'echo "git push --force origin main" |& bash'
assert_write_guard "review 1: cat > /tmp/x.sh <<'EOF' then bash /tmp/x.sh -> deny" deny \
    "cat > /tmp/x.sh <<'EOF'
git push --force origin main
EOF
bash /tmp/x.sh"
assert_write_guard "review 1: cat > /tmp/x.sh <<'EOF' then chmod +x and run it -> deny" deny \
    "cat > /tmp/x.sh <<'EOF'
gh issue close 423
EOF
chmod +x /tmp/x.sh && /tmp/x.sh"
assert_write_guard "review 1: echo > /tmp/y.sh; sh /tmp/y.sh -> deny" deny \
    'echo "gh issue close 423" > /tmp/y.sh; sh /tmp/y.sh'
assert_write_guard "review 2: cat <<EOF-1 ended at EOF-1, a forced push, then a bare EOF -> deny" deny 'cat <<EOF-1
text
EOF-1
git push --force origin main
EOF'
assert_write_guard "review 2: cat <<\\EOF-1 ended at EOF-1, gh issue close, then a bare EOF -> deny" deny 'cat <<\EOF-1
text
EOF-1
gh issue close 423
EOF'
assert_write_guard "review 2: cat <<EOF\"X\" ended at EOFX, a forced push, then a bare EOF -> deny" deny 'cat <<EOF"X"
text
EOFX
git push --force origin main
EOF'
assert_write_guard "review 2: cat > note.md <<EOF. ended at EOF., gh issue close, then a bare EOF -> deny" deny 'cat > note.md <<EOF.
text
EOF.
gh issue close 423
EOF'
assert_write_guard "review 2: cat <<EOF around \$\\ and (git push --force) on the next line -> deny" deny 'cat <<EOF
$\
(git push --force origin main)
EOF'
assert_write_guard "review 2: cat > note.md <<EOF around \$\\ and (gh issue close 423) -> deny" deny 'cat > note.md <<EOF
$\
(gh issue close 423)
EOF'
assert_write_guard "review 2: cat > /tmp/x.sh <<'EOF' then bash /tmp/x''.sh -> deny" deny \
    "cat > /tmp/x.sh <<'EOF'
git push --force origin main
EOF
bash /tmp/x''.sh"
assert_write_guard "review 2: cat > /tmp/x.sh <<'EOF' then bash /tmp/x\\.sh -> deny" deny \
    "cat > /tmp/x.sh <<'EOF'
git push --force origin main
EOF
bash /tmp/x\\.sh"
assert_write_guard "review 2: cat > /tmp/zz.sh <<'EOF' then bash /tmp/zz.s? -> deny" deny \
    "cat > /tmp/zz.sh <<'EOF'
git push --force origin main
EOF
bash /tmp/zz.s?"
assert_write_guard "review 2: exec 3>/tmp/z.sh; echo of a quoted issue close >&3; sh /tmp/z.sh -> deny" deny \
    'exec 3>/tmp/z.sh; echo "gh issue close 423" >&3; sh /tmp/z.sh'
assert_write_guard "review 3: a pipe at a line's end, then bash -> deny" deny 'echo "git push --force origin main" |
bash'
assert_write_guard "review 3: a pipe at a line's end, then sh -> deny" deny 'echo "gh issue close 423" |
sh'
assert_write_guard "review 3: a pipe at a line's end, a blank line, then bash -> deny" deny 'echo "git push --force origin main" |

bash'
assert_write_guard "review 3: |& at a line's end, then bash -> deny" deny 'echo "git push --force origin main" |&
bash'
assert_write_guard "review 3: | cat | at a line's end, then bash -> deny" deny 'echo "git push --force origin main" | cat |
bash'
assert_write_guard "review 3: rg -o at a line's end |, then sh -> deny" deny 'rg -o "git push --force origin main" x.md |
sh'
assert_write_guard "review 3: printf at a line's end |, then xargs sh -c -> deny" deny "printf '%s\\n' \"git push --force origin main\" |
xargs -I{} sh -c '{}'"
assert_write_guard "review 3: sort -o /tmp/x.sh <<'EOF' then bash -> deny" deny "sort -o /tmp/x.sh <<'EOF'
git push --force origin main
EOF
bash /tmp/x.sh"
assert_write_guard "review 3: printf | sort -o x.sh; sh x.sh -> deny" deny \
    'printf "git push --force origin main\n" | sort -o x.sh; sh x.sh'
assert_write_guard "review 3: uniq - /tmp/u.sh <<'EOF' then sh -> deny" deny "uniq - /tmp/u.sh <<'EOF'
gh issue close 423
EOF
sh /tmp/u.sh"
assert_write_guard "review 3: cat > \"\$f\" then the literal name run -> deny" deny "f=/tmp/x.sh; cat > \"\$f\" <<'EOF'
git push --force origin main
EOF
bash /tmp/x.sh"
assert_write_guard "review 3: a Makefile then make -> deny" deny "cat > Makefile <<'EOF'
all:
	git push --force origin main
EOF
make"
assert_write_guard "review 3: >> ~/.zshrc then zsh -i -> deny" deny \
    'echo "git push --force origin main" >> ~/.zshrc; zsh -i -c true'
assert_write_guard "review 3: a .githooks file then a wrapped commit -> deny" deny \
    'echo "git push" > .githooks/pre-commit; uv run python tools/agent-identity.py run claude-coder -- git commit -m x'
assert_write_guard "review 3: { then echo of a quoted forced push, then } | bash -> deny" deny '{
echo "git push --force origin main"
} | bash'
assert_write_guard "review 3: { true; echo of a quoted forced push; } | bash -> deny" deny \
    '{ true; echo "git push --force origin main"; } | bash'
assert_write_guard "review 3: a for loop's do, echo, done | bash -> deny" deny 'for x in 1; do
echo "git push --force origin main"
done | bash'
assert_write_guard "review 3: a heredoc inside { ... } | bash -> deny" deny "{
cat <<'EOF'
git push --force origin main
EOF
} | bash"
assert_write_guard "review 3: printf -v c of a quoted forced push, then \$c -> deny" deny \
    'printf -v c "git push --force origin main"; $c'

# A GraphQL call reads only when its query is written inline and holds no "mutation": a query from
# a file, a shell variable, a command substitution, the whole body from --input, or no query field
# at all cannot be checked for the word, so each is a write.
assert_write_guard "gh api graphql -F query=@file, unverifiable -> deny" deny \
    'gh api graphql -F query=@resolve.graphql -F id=PRRT_x'
assert_write_guard "gh api graphql --input, unverifiable -> deny" deny \
    'gh api graphql --input payload.json'
assert_write_guard "gh api graphql -f query=\$Q, a shell variable -> deny" deny \
    'gh api graphql -f query=$Q'
assert_write_guard "gh api graphql -f query=\$(cat f), a command substitution -> deny" deny \
    'gh api graphql -f query=$(cat m.graphql)'
# A quoted query spans lines and parentheses, which split it into several commands here, so the
# check for "mutation" runs to the end of the whole command rather than stopping at the first.
assert_write_guard "gh api graphql, a comment line then a mutation on the next -> deny" deny \
    $'gh api graphql -f \'query=# Resolve the thread\nmutation { resolveReviewThread(input:{threadId:"x"}) { thread { id } } }\''
assert_write_guard "gh api graphql, a fragment then a mutation on the next line -> deny" deny \
    $'gh api graphql -f \'query=fragment F on PullRequest { id }\nmutation { mergePullRequest(input:{pullRequestId:"x"}) { clientMutationId } }\''
assert_write_guard "gh api graphql, a fragment with arguments before a mutation -> deny" deny \
    "gh api graphql -f query='fragment F on X { y(z:1) } mutation { a }'"
assert_write_guard "gh api graphql, a multi-line query with no mutation -> allow" allow \
    $'gh api graphql -f \'query=query {\n  viewer { login }\n}\''
# A separator inside quotes is part of that argument, not the end of the command: a quoted
# `--jq '.a | .b'`, a `(` in an inline query or a `;` in a body never hides a write flag after it.
assert_write_guard "gh api with a piped --jq before -f -> deny" deny \
    "gh api repos/o/r/issues --jq '.html_url | ascii_downcase' -f title=x"
assert_write_guard "gh api graphql, --input after an inline query containing ( -> deny" deny \
    "gh api graphql -f query='query(\$id: ID!) { node(id: \$id) { id } }' --input body.json"
assert_write_guard "gh api with a quoted ; in a --jq before -f -> deny" deny \
    "gh api repos/o/r/issues/1/comments --jq '.id; .url' -f body=x"
assert_write_guard "gh api -X POST with a quoted ; in the body -> deny" deny \
    "gh api -X POST repos/o/r/issues/1/comments -f body='done; thanks'"
assert_write_guard "gh api -X GET with a quoted ; in a field -> allow" allow \
    "gh api -X GET search/issues -f q='is:open; label:x'"
assert_write_guard "gh api read with a piped --jq -> allow" allow \
    "gh api repos/o/r/issues --jq '.[] | .title'"
assert_write_guard "gh api graphql, an inline query with arguments and variables -> allow" allow \
    "gh api graphql -f query='query(\$id: ID!) { node(id: \$id) { id } }' -f id=x"
assert_write_guard "a GET after a quoted separator never turns a write into a read -> deny" deny \
    "gh api repos/o/r/issues -f body='see (docs)' -X GET"
# A quoted separator still starts the next command inside bash -c or \$(...), so a write there is
# still seen, and the wrapper's exemption covers the whole quoted script it runs.
assert_write_guard "bash -c with gh api then gh pr merge, unwrapped -> deny" deny \
    'bash -c "gh api repos/o/r; gh pr merge 1"'
assert_write_guard "bash -c with gh api, echo, then git push, unwrapped -> deny" deny \
    'bash -c "gh api repos/o/r --jq .a; echo hi; git push"'
assert_write_guard "wrapped bash -c running git status then git push -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- bash -c "git status; git push"'
# A wrapper written inside the quoted script reaches only to that script's own next separator, as
# the shell running it does, so a write after the script's own ;, && or newline is the player's.
assert_write_guard "bash -c, a wrapper inside the script, then ; and a bare git push -> deny" deny \
    'bash -c "uv run python tools/agent-identity.py run claude-coder -- git fetch; git push"'
assert_write_guard "bash -c, a wrapped commit inside the script, then && git push -> deny" deny \
    "bash -c 'uv run python tools/agent-identity.py run claude-coder -- git commit -m x && git push'"
assert_write_guard "sh -c, a wrapped read inside the script, then && gh pr merge -> deny" deny \
    'sh -c "cd /tmp && uv run python tools/agent-identity.py run claude-coder -- gh pr view 1 && gh pr merge 1"'
assert_write_guard "bash -lc, a wrapper inside the script, then a newline and git push -> deny" deny \
    $'bash -lc "uv run python tools/agent-identity.py run codex-coder -- git status\ngit push"'
assert_write_guard "bash -c, the whole script one wrapped git push -> allow" allow \
    'bash -c "uv run python tools/agent-identity.py run claude-coder -- git push"'
assert_write_guard "bash -c, a wrapped gh api write whose quoted body holds a ; -> allow" allow \
    "bash -c \"uv run python tools/agent-identity.py run claude-coder -- gh api -X POST repos/o/r/issues/1/comments -f body='x; y'\""
assert_write_guard "bash -c, the same posted to the issue collection -> deny, an issue write" deny \
    "bash -c \"uv run python tools/agent-identity.py run claude-coder -- gh api -X POST repos/o/r/issues -f body='x; y'\""
assert_write_guard "bash -c, a reviewer's wrapper inside the script, then ; git push -> deny" deny \
    'bash -c "uv run python tools/agent-identity.py run claude-reviewer -- gh pr view 1; git push"'
assert_write_guard "a wrapped commit whose quoted message holds -- and ; git push -> allow" allow \
    "uv run python tools/agent-identity.py run claude-coder -- git commit -m 'a -- b; git push'"
# A `#` comment ends at the newline and its apostrophes open no quote, so a wrapper's exemption
# still ends at that newline; a separator inside the comment is hard, so a write named after it
# denies as a mention.
assert_write_guard "a wrapped commit, a comment with an apostrophe, then git push -> deny" deny \
    $'uv run python tools/agent-identity.py run claude-coder -- git commit -m "Fix the ask"  # the player\'s words\ngit push'
assert_write_guard "a wrapped commit, a comment with won't, then gh pr create -> deny" deny \
    $'uv run python tools/agent-identity.py run claude-coder -- git commit -m "Fix"  # won\'t push yet\ngh pr create --title x --body y'
assert_write_guard "cd, a wrapped commit, a comment with an apostrophe, then git push -> deny" deny \
    $'cd /x && uv run python tools/agent-identity.py run claude-coder -- git commit -m x  # player\'s fix\ngit push origin HEAD'
assert_write_guard "a wrapped commit, then a comment holding ; git push -> deny" deny \
    "uv run python tools/agent-identity.py run claude-coder -- git commit -m x # it's fine; git push"
assert_write_guard "a wrapped push with a comment holding an apostrophe -> allow" allow \
    "uv run python tools/agent-identity.py run claude-coder -- git push # it's pushed"
assert_write_guard "a comment, then a wrapped push on the next line -> allow" allow \
    $'# the player\'s fix\nuv run python tools/agent-identity.py run claude-coder -- git push'
# A $'...' string keeps its own escapes: \' does not close it, and \n is a newline.
assert_write_guard "a wrapped commit with \$'...\\'...', then a newline and git push -> deny" deny \
    $'uv run python tools/agent-identity.py run claude-coder -- git commit -m $\'Don\\\'t break\'\ngit push'
assert_write_guard "a wrapped commit with \$'...\\'...', then ; git push -> deny" deny \
    $'uv run python tools/agent-identity.py run claude-coder -- git commit -m $\'Don\\\'t break\'; git push'
assert_write_guard "bash -c \$'git status\\ngit push', unwrapped -> deny" deny \
    $'bash -c $\'git status\\ngit push\''
assert_write_guard "wrapped bash -c \$'git status\\ngit push' -> allow" allow \
    $'uv run python tools/agent-identity.py run claude-coder -- bash -c $\'git status\\ngit push\''
# A command holding $(, a backtick, ${, << or $$', or one the pass ends inside a quote, is read
# unsure: every separator ends a wrapper's exemption, whatever the quotes around it seem to say.
# The heredoc commit is how Claude Code writes every commit, so each body shape that leaves the
# pass misreading a quote is checked, with the forgotten push on the next line and after ;.
heredoc_commit() {
    printf '%s' "uv run python tools/agent-identity.py run claude-coder -- git commit -m \"\$(cat <<'EOF'
$1
EOF
)\""
}
for heredoc_body in "Fix the \"can't push\" error" 'the "x" thing' "\"can't\" and \"won't\"" \
    "it's and it's" 'a lone " here'; do
    assert_write_guard "a wrapped heredoc commit ($heredoc_body), then a newline and git push -> deny" \
        deny "$(heredoc_commit "$heredoc_body")"$'\ngit push'
    assert_write_guard "a wrapped heredoc commit ($heredoc_body), then ; git push -> deny" \
        deny "$(heredoc_commit "$heredoc_body")"'; git push'
done
assert_write_guard "a wrapped heredoc commit whose line ends in 'xargs git' -> allow" allow \
    "$(heredoc_commit $'Names passed through xargs git\nare read.')"
assert_write_guard "a wrapped heredoc commit, then a wrapped push -> allow" allow \
    "$(heredoc_commit "Fix the \"can't push\" error")"$'\nuv run python tools/agent-identity.py run claude-coder -- git push'
assert_write_guard "a wrapped commit with \"\$(printf ... \"it's\")\", then ; git push -> deny" deny \
    "uv run python tools/agent-identity.py run claude-coder -- git commit -m \"\$(printf '%s' \"it's\")\"; git push"
assert_write_guard "an escaped \\\$'...\\'..., then a newline and git push -> deny" deny \
    $'uv run python tools/agent-identity.py run claude-coder -- echo \\$\'it\\\'s\ngit push'
assert_write_guard "\$\$'...\\'...' then ; git push, wrapped at the start -> deny" deny \
    $'uv run python tools/agent-identity.py run claude-coder -- echo $$\'a\\\'; git push; echo \''
assert_write_guard "a heredoc, then gh api with a piped --jq before -f -> deny" deny \
    $'cat <<\'EOF\'\nit\'s\nEOF\ngh api repos/o/r/issues --jq \'.a | b\' -f title=x'
assert_write_guard "a wrapped bash -c \"a; git push\" beside a \$(...) -> deny (unsure, the safe direction)" deny \
    'uv run python tools/agent-identity.py run claude-coder -- bash -c "git status; git push"; echo $(date)'
assert_write_guard "a gh api read in \$(...), no write flag -> allow" allow \
    'N=$(gh api repos/o/r/issues --jq length); echo $N'

# $1 label  $2 command  $3 text the deny reason must contain; more than three arguments is a
# broken case, as for assert_guard above.
assert_write_guard_reason() {
    checks=$((checks + 1))
    if [ "$#" -gt 3 ]; then
        fail "$1: $# arguments, at most 3 (a missing line break after the command?)"
        return
    fi
    local raw
    raw=$(printf '%s' "$2" | jq -Rs '{tool_name:"Bash", tool_input:{command:.}}' \
        | env -u CLAUDE_CODE_REMOTE -u NAPPY_ASK_FOR_PLAYER_WRITES NAPPY_AGENTS_DIR="$write_guard_agents" \
            "$root/.claude/hooks/github-write-guard.sh" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""')
    case "$raw" in
        *"$3"*) echo "ok   $1" ;;
        *) fail "$1: the deny reason lacks '$3': $raw" ;;
    esac
}

# Both deny messages name the orchestrator identity, so an agent told "no" learns which role a
# docs-only pull request's or an issue's write goes out as.
assert_write_guard_reason "the unwrapped deny names claude-orchestrator" \
    'gh pr create --title t --body x' "claude-orchestrator for an issue or a pull request with no code changes"
assert_write_guard_reason "a direct issue write's deny points at tools/inbox.py" \
    'uv run python tools/agent-identity.py run claude-orchestrator -- gh issue close 5' "only through tools/inbox.py"
assert_write_guard_reason "and says wrapping does not help" 'gh issue comment 5 --body x' "wrapped in an identity or not"
assert_write_guard_reason "a gh api issue write's deny points at tools/inbox.py too" \
    'uv run python tools/agent-identity.py run claude-orchestrator -- gh api -X PATCH repos/o/r/issues/5 -f state=closed' \
    "only through tools/inbox.py"
assert_write_guard_reason "the reviewer deny names claude-orchestrator too" \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh pr merge 1' \
    "or claude-orchestrator when the pull request has no code changes"

# A wrapped heredoc body that names a write is a false deny, and its message says why and points
# at a body file rather than claiming the command is unwrapped and stopping there.
wrapped_heredoc_pr="uv run python tools/agent-identity.py run claude-coder -- gh pr create --title t --body \"\$(cat <<'EOF'
Run \`git push\` through the wrapper.
EOF
)\""
assert_write_guard "a wrapped heredoc PR body naming git push -> deny (unsure, the safe direction)" deny \
    "$wrapped_heredoc_pr"
assert_write_guard_reason "that deny says the command may already be wrapped" "$wrapped_heredoc_pr" \
    "If this command is already wrapped"
assert_write_guard_reason "that deny points at a body file" "$wrapped_heredoc_pr" "--body-file"
assert_write_guard_reason "an unwrapped push gets the plain reason" 'git push' "outside any agent identity"

# A backslash-newline joins lines only where the shell joins them: never after an escaped
# backslash, never at the end of a comment.
assert_write_guard "echo C:\\\\, then a newline and git push -> deny" deny $'echo C:\\\\\ngit push'
assert_write_guard "a wrapped fetch, a comment ending in a backslash, then git push -> deny" deny \
    $'uv run python tools/agent-identity.py run claude-coder -- git fetch # note \\\ngit push'
assert_write_guard "git, a continued line, push, unwrapped -> deny" deny $'git \\\npush'
assert_write_guard "a wrapped git, a continued line, push -> allow" allow \
    $'uv run python tools/agent-identity.py run claude-coder -- git \\\npush'
assert_write_guard "a wrapped commit continued onto a second line -> allow" allow \
    $'uv run python tools/agent-identity.py run claude-coder -- git commit -m x \\\n  --amend'

# Over 64 KB, a command naming git, gh or a pushing script is denied without being read, so the
# hook never runs past its timeout (a timed-out hook lets the command through); one naming none
# of them cannot write and is allowed. Just under the bound, the densest text is still read.
over_bound="$(head -c 70000 /dev/zero | tr '\0' 'a')"
assert_write_guard_timed "a wrapped 70 KB commit message -> deny (over the bound)" deny \
    "uv run python tools/agent-identity.py run claude-coder -- git commit -m '${over_bound}'" 2
assert_write_guard_reason "that deny names the bound" \
    "uv run python tools/agent-identity.py run claude-coder -- git commit -m '${over_bound}'" "over 64 KB"
assert_write_guard_timed "a 70 KB command naming no git, gh or pushing script -> allow" allow \
    "echo '${over_bound}'" 2
assert_write_guard_timed "a 70 KB command naming g\\it -> deny (a backslash is skipped)" deny \
    "echo '${over_bound}'; g\\it push" 2
assert_write_guard_timed "a 70 KB command naming gi\\<newline>t -> deny (a backslash-newline is skipped)" deny \
    "echo '${over_bound}'; gi\\
t push" 2
assert_write_guard_timed "a 70 KB command, an escaped backslash, then gi\\<newline>t push -> deny" deny \
    "echo '${over_bound}'
echo x\\\\
gi\\
t push" 2
assert_write_guard_timed "a 70 KB command, lines ending in g and starting with it -> allow" allow \
    "cat <<EOF
${over_bound} drawing
item
EOF" 2
assert_write_guard_timed "a 70 KB command naming g, i and t split by quotes -> deny" deny \
    "echo '${over_bound}'; 'g'\"i\"t push" 2
assert_write_guard_timed "a 70 KB command naming g\$''it (an empty \$'' string) -> deny" deny \
    "echo '${over_bound}'; g\$''it push" 2
assert_write_guard_timed "a 70 KB command naming g\$\"\"it (an empty \$\"\" string) -> deny" deny \
    "echo '${over_bound}'; g\$\"\"it push" 2

# Over 1 MB nothing is read: every command is denied at once. Up to that cap, the over-bound
# search stays one linear regex, so the densest input just under it is decided in well under a
# second.
over_cap="$(head -c 1100000 /dev/zero | tr '\0' 'a')"
near_cap_quotes="$(head -c 1000000 /dev/zero | tr '\0' "'" | sed "s/''/a'/g")"
near_cap_lines="$(yes 'x\' | head -n 330000)"
assert_write_guard_timed "a 1.1 MB command naming nothing -> deny (over the hard cap)" deny "echo '${over_cap}'" 2
assert_write_guard_reason "that deny says the command was not read" "echo '${over_cap}'" "over 1 MB"
assert_write_guard_timed "1 MB of a' naming nothing -> allow, decided quickly" allow "echo ${near_cap_quotes}" 2
assert_write_guard_timed "1 MB of backslash-newlines naming nothing -> allow, decided quickly" allow \
    "echo ${near_cap_lines}" 2
dense_under_bound="$(head -c 65000 /dev/zero | tr '\0' ';')"
assert_write_guard_timed "64 KB of separators in a heredoc, then git push -> deny" deny \
    "cat <<EOF
${dense_under_bound}
EOF
git push"
# An option's argument is skipped as one shell word, however it is quoted, escaped or joined by a
# comma, so a quoted argument with a space in it is skipped whole and the word after it is the
# subcommand: the push after it is read as the push, and wrapped it still allows. An empty quoted
# argument is still a word, and a second-level quoted argument that starts with a space is still
# the option's whole argument.
assert_write_guard "git -C \"\" push (an empty quoted argument) -> deny" deny 'git -C "" push'
assert_write_guard "git -C '' push -> deny" deny "git -C '' push"
assert_write_guard "wrapped git -C \"\" push -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- git -C "" push'
assert_write_guard "echo \"\", then git status -> allow" allow 'echo ""; git status'
assert_write_guard "bash -c \"git -c ' x=1' push\" -> deny" deny "bash -c \"git -c ' x=1' push\""
assert_write_guard "bash -c \"git -C ' /tmp/x' commit\" -> deny" deny "bash -c \"git -C ' /tmp/x' commit -m m\""

# A reserved word (do, then, else, {, !, if, while, until) or time/exec in front of a command
# leaves it in command position, so a gh api call after one is a call of its own and scanned in
# full; a field after a quoted separator counts as a write even under an earlier -X GET; and an
# assignment whose value names a pushing script is not that script.
gh_loop="gh api -X GET repos/o/r/issues --jq '.[].number' > ids; for n in \$(cat ids); do gh api repos/o/r/issues/\$n/comments --jq '.id | tostring' -f body=ping; done"
assert_write_guard "a GET, then a for loop whose do posts a comment -> deny" deny "$gh_loop"
assert_write_guard "the same loop inside bash -c '...' -> deny" deny \
    "bash -c 'gh api -X GET repos/o/r/issues --jq \".[].number\" > ids; for n in \$(cat ids); do gh api repos/o/r/issues/\$n/comments --jq \".id | tostring\" -f body=ping; done'"
assert_write_guard "a GraphQL read piped into { gh api ... -f body=x; } -> deny" deny \
    "gh api graphql -f query='{viewer{login}}' | { gh api repos/o/r/issues/1/comments --jq '.a | .b' -f body=x; }; echo \$(true)"
assert_write_guard "if ...; then gh api ... -f body=x; fi -> deny" deny \
    "if true; then gh api repos/o/r/issues/1/comments --jq '.a | .b' -f body=x; fi; echo \$(true)"
assert_write_guard "an unsure command assigning a pushing script's path, then sed on it -> allow" allow \
    'echo $(date); p=tools/prune-merged.sh; sed -n 1,5p "$p"'
# A call in the script after sh -c or bash -c starts a command too, whichever command-position
# table sees it, so it ends a GraphQL read's scan and is scanned in full.
assert_write_guard "a GraphQL read piped into sh -c \"gh api ... -f body=x\" -> deny" deny \
    "gh api graphql -f query='{viewer{login}}' | sh -c \"gh api repos/o/r/issues/1/comments --jq '.a | .b' -f body=x\"; echo \$(true)"
assert_write_guard "a GraphQL read piped into bash -c \"gh api ... -X POST\" -> deny" deny \
    "gh api graphql -f query='{viewer{login}}' | bash -c \"gh api repos/o/r/issues/1/comments --jq '.a | .b' -X POST\"; echo \$(true)"
# A later call that only the wrapper-options table reads as a command stays inside a GraphQL
# read's scan, and its late field is a write there, as under a GET; a GraphQL read's own variable
# after a quoted --jq pipe still reads.
assert_write_guard "a GraphQL read piped into /usr/bin/env gh api ... -f body=x -> deny" deny \
    "gh api graphql -f query='{viewer{login}}' | /usr/bin/env gh api repos/o/r/issues/1/comments --jq '.a | .b' -f body=x; echo \$(true)"
assert_write_guard "a GraphQL read piped into stdbuf -oL gh api ... -f body=x -> deny" deny \
    "gh api graphql -f query='{viewer{login}}' | stdbuf -oL gh api repos/o/r/issues/1/comments --jq '.a | .b' -f body=x; echo \$(true)"
assert_write_guard "a GraphQL read's own variable after a quoted --jq pipe -> allow" allow \
    "gh api graphql -f query='query(\$n:Int!){a}' --jq '.data | .repository' -F n=398"
# A quoted separator inside a call's own argument ends its scan only where git's and gh's own
# command table sees a command start, so the call's later write flag is still read.
assert_write_guard "gh api --jq '.x; sh -c git' -X POST -> deny" deny \
    "gh api repos/o/r/issues/1/comments --jq '.x; sh -c git' -X POST"
# A wrapper written as a path, and stdbuf, leave the pushing script in command position.
assert_write_guard "/usr/bin/env tools/prune-merged.sh -> deny" deny '/usr/bin/env tools/prune-merged.sh x'
assert_write_guard "stdbuf -oL tools/prune-merged.sh -> deny" deny 'stdbuf -oL tools/prune-merged.sh x'
assert_write_guard "/usr/bin/sudo -u root tools/prune-merged.sh -> deny" deny \
    '/usr/bin/sudo -u root tools/prune-merged.sh x'
assert_write_guard "/usr/bin/env cat tools/release.sh, a read -> allow" allow '/usr/bin/env cat tools/release.sh'
# Accepted: the word api inside a --jq filter's own string reads as another call, so a GET's
# field after it denies.
assert_write_guard "a GET whose --jq holds the word api, then a field -> deny (accepted false deny)" deny \
    "gh api -X GET search/code --jq '.items[] | .path | select(test(\"api\"))' -f q=x"
# A field after a quoted --jq '.a | .b' is still the GET call's own and reads; only a field with a
# gh or api word between the separator and it may be another call's.
assert_write_guard "gh api -X GET with a field after a quoted --jq pipe -> allow" allow \
    "gh api -X GET search/issues --jq '.items[] | .number' -f q='repo:a/b is:open'"
assert_write_guard "gh api --method GET with a field after a quoted --jq pipe -> allow" allow \
    "gh api --method GET repos/o/r/issues --jq 'map(.number) | length' -f state=open"
# An accepted false deny: in an unsure command every newline is a separator, so a line of heredoc
# prose that starts with a reserved word and then a pushing script's path reads as that script
# in command position, in any heredoc that is not one of the text shapes (sed reads this one; the
# same prose under cat > m.txt is the first shape and allows, above).
assert_write_guard "heredoc prose: 'if tools/land-prs.sh is named' -> deny (accepted false deny)" deny \
    "sed s/a/b/ > m.txt <<'EOF'
if tools/land-prs.sh is named, it is read.
EOF"
# A reserved word matches only as the shell spells it, so capitalised prose is not one.
assert_write_guard "heredoc prose: 'If tools/land-prs.sh fails, rerun it.' -> allow" allow \
    "sed s/a/b/ > m.txt <<'EOF'
If tools/land-prs.sh fails, rerun it.
EOF"
assert_write_guard "heredoc prose: 'Then tools/prune-merged.sh cleans up.' -> allow" allow \
    "cat > m.txt <<'EOF'
Then tools/prune-merged.sh cleans up.
EOF"
assert_write_guard "time tools/prune-merged.sh -> deny" deny 'time tools/prune-merged.sh x'
assert_write_guard "exec tools/prune-merged.sh -> deny" deny 'exec tools/prune-merged.sh x'
assert_write_guard "exec -a name tools/prune-merged.sh -> deny" deny 'exec -a name tools/prune-merged.sh x'
assert_write_guard "sudo -iu root tools/prune-merged.sh (a cluster ending in -u) -> deny" deny \
    'sudo -iu root tools/prune-merged.sh x'
assert_write_guard "time cat tools/release.sh, a read -> allow" allow 'time cat tools/release.sh'
assert_write_guard "wrapped time tools/prune-merged.sh -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- time tools/prune-merged.sh x'
assert_write_guard "git -C \"/x y\" push -> deny" deny 'git -C "/x y" push'
assert_write_guard "git -c 'a=b c' push -> deny" deny "git -c 'a=b c' push"
assert_write_guard "git -c k=a,b push (the shell does not split on a comma) -> deny" deny 'git -c k=a,b push'
assert_write_guard "git -C \"a;b\" push (a quoted ; in the argument) -> deny" deny 'git -C "a;b" push'
assert_write_guard "git -C /x\\ y push (an escaped space) -> deny" deny 'git -C /x\ y push'
assert_write_guard "git -C \"\$(pwd)/my dir\" push, an unsure command -> deny" deny 'git -C "$(pwd)/my dir" push'
assert_write_guard "bash -c '...' with a double-quoted -C argument, then push -> deny" deny \
    "bash -c 'git -C \"/x y\" push'"
assert_write_guard "bash -c \"...\" with an escaped-quote -C argument, then push -> deny" deny \
    'bash -c "git -C \"/x y\" push"'
assert_write_guard "bash -c \"...\" with a single-quoted -c argument, then push -> deny" deny \
    "bash -c \"git -c 'a=b c' push\""
assert_write_guard "wrapped git -C \"/x y\" push -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- git -C "/x y" push'
assert_write_guard "wrapped git -C \"\$(pwd)/my dir\" push -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- git -C "$(pwd)/my dir" push'
assert_write_guard "wrapped, run's own --repo quoted with a space -> allow" allow \
    "uv run python tools/agent-identity.py run --repo 'a b' claude-coder -- git push"
assert_write_guard "gh -R 'a b' pr view, a quoted global option before a read -> allow" allow \
    "gh -R 'a b' pr view 1"
assert_write_guard "gh -R 'a b' pr merge -> deny" deny "gh -R 'a b' pr merge 1"
assert_write_guard "FOO=\"a b\" tools/release.sh patch push -> deny" deny \
    'FOO="a b" tools/release.sh patch push'
assert_write_guard "env FOO='a b' tools/prune-merged.sh -> deny" deny "env FOO='a b' tools/prune-merged.sh x"
assert_write_guard "timeout 'x y' tools/prune-merged.sh -> deny" deny "timeout 'x y' tools/prune-merged.sh x"

# A wrapper's own options that take an argument (sudo -u, nice -n, timeout -s, xargs -n) skip
# that argument before the command word, and the script after bash -c or sh -c is a command of
# its own, so a pushing script there is in command position; read through the same wrappers, it
# still allows.
assert_write_guard "sudo -u root tools/prune-merged.sh -> deny" deny 'sudo -u root tools/prune-merged.sh x'
assert_write_guard "nice -n 10 tools/prune-merged.sh -> deny" deny 'nice -n 10 tools/prune-merged.sh x'
assert_write_guard "timeout -s KILL 60 tools/prune-merged.sh -> deny" deny \
    'timeout -s KILL 60 tools/prune-merged.sh x'
assert_write_guard "xargs -n 1 tools/prune-merged.sh -> deny" deny 'xargs -n 1 tools/prune-merged.sh < f'
assert_write_guard "bash -c 'tools/prune-merged.sh x' -> deny" deny "bash -c 'tools/prune-merged.sh x'"
assert_write_guard "sudo -u root bash -c 'tools/prune-merged.sh x' -> deny" deny \
    "sudo -u root bash -c 'tools/prune-merged.sh x'"
assert_write_guard "sudo -u root cat tools/release.sh, a read -> allow" allow 'sudo -u root cat tools/release.sh'
assert_write_guard "bash -c 'cat tools/prune-merged.sh', a read -> allow" allow "bash -c 'cat tools/prune-merged.sh'"
assert_write_guard "bash -c 'tools/release.sh patch', a dry run -> allow" allow "bash -c 'tools/release.sh patch'"
assert_write_guard "timeout -s KILL 60 tools/land-prs.sh --dry-run -> allow" allow \
    'timeout -s KILL 60 tools/land-prs.sh --dry-run 1'
assert_write_guard "wrapped bash -c 'tools/prune-merged.sh x' -> allow" allow \
    "uv run python tools/agent-identity.py run claude-coder -- bash -c 'tools/prune-merged.sh x'"

# Every shape here makes a walk from each word that starts one run to the end of the command, so
# reading it word by word would cost the square of its length: `-c`/`-C`/`-R` swallowing the next
# `git` or `gh`, `env -c` swallowing the `;` after it, a wrapper restarting command position before
# each pushing script, and a heredoc (every separator soft) mentioning `gh api` on every line. The
# runs are read from tables built once and a mentioned `gh api` is scanned only to its own next
# separator, so each is decided in about the time of one pass, at 16 KB and at the 64 KB bound.
w_chain_git_16k="$(printf 'git -c %.0s' $(seq 1 2330))"
w_chain_git_64k="$(printf 'git -c %.0s' $(seq 1 9340))"
w_chain_env_64k="$(printf '; env -c %.0s' $(seq 1 7270))"
w_chain_gh_64k="gh pr $(printf -- '-R gh %.0s' $(seq 1 10900))"
w_chain_tool_64k="$(printf 'tools/release.sh tools/agent-identity.py run claude-coder -- %.0s' $(seq 1 1072))"
w_mentions_16k="$(printf 'we call gh api here and there\n%.0s' $(seq 1 530))"
w_mentions_64k="$(printf 'we call gh api here and there\n%.0s' $(seq 1 2170))"
assert_write_guard_timed "16 KB of git -c git -c ..., then git push -> deny" deny \
    "${w_chain_git_16k}; git push origin main"
assert_write_guard_timed "64 KB of git -c git -c ..., then git push -> deny" deny \
    "${w_chain_git_64k}; git push origin main"
assert_write_guard_timed "64 KB of ; env -c ; env -c ..., then git push -> deny" deny \
    "${w_chain_env_64k}; git push origin main"
assert_write_guard_timed "64 KB of gh pr -R gh -R gh ..., then git push -> deny" deny \
    "${w_chain_gh_64k}; git push origin main"
assert_write_guard_timed "64 KB of release.sh without push, each rewrapped -> allow" allow \
    "${w_chain_tool_64k}echo done"
assert_write_guard_timed "a 16 KB heredoc naming gh api on every line -> allow" allow \
    "cat <<EOF
${w_mentions_16k}
EOF"
assert_write_guard_timed "a 64 KB heredoc naming gh api on every line -> allow" allow \
    "cat <<EOF
${w_mentions_64k}
EOF"
# Quoted text at the bound: every quoted -C argument grouped inside a script, and one quoted word
# of 64 KB split into its parts.
w_chain_quoted_64k="$(printf 'git -C "a b" %.0s' $(seq 1 5027))"
w_quoted_words_64k="$(printf 'a %.0s' $(seq 1 32650))"
w_input_options_64k="$(printf -- '-E xargs %.0s' $(seq 1 7200))"
assert_write_guard_timed "64 KB of xargs-named option values are consumed once -> allow" allow \
    "xargs ${w_input_options_64k}git status"
assert_write_guard_timed "64 KB of bash -c 'git -C \"a b\" ...' -> allow" allow \
    "bash -c '${w_chain_quoted_64k}'"
assert_write_guard_timed "a 64 KB quoted string of short words, then git push -> deny" deny \
    "echo '${w_quoted_words_64k}'; git push origin main"
# A gh api mentioned inside another call's scan is still read up to its own next separator, so a
# write flag of its own there denies, and one past that separator still counts toward the first
# call's scan.
assert_write_guard "a GET call, then a gh api mention with its own -f in a quoted script -> deny" deny \
    "bash -c \"gh api -X GET x | jq .; echo gh api -f a=b y\""
assert_write_guard "a REST call, a quoted pipe, a gh api mention, then -X POST -> deny" deny \
    "gh api repos/o/r --jq '.a | \"gh api\"' -X POST"
assert_write_guard "wrapped command, then an unquoted ; and a bare git push -> deny" deny \
    'uv run python tools/agent-identity.py run claude-coder -- echo done; git push'
assert_write_guard "a REST write whose field value contains the word graphql -> deny" deny \
    "gh api -X POST repos/o/r/issues/1/comments -f body='use graphql' -f query=x"
assert_write_guard "gh api with a full graphql URL as the endpoint, inline query -> allow" allow \
    "gh api https://api.github.com/graphql -f query='{viewer{login}}'"
assert_write_guard "gh api graphql -fquery=@file, attached -> deny" deny \
    'gh api graphql -fquery=@q.graphql'
assert_write_guard "gh api graphql with no query field -> deny" deny \
    'gh api graphql'
assert_write_guard "gh api graphql, a visible query with no mutation -> allow" allow \
    'gh api graphql -f query=query{me{login}}'
assert_write_guard "gh api graphql, a visible query with spaces, endpoint first -> allow" allow \
    "gh api graphql -f query='query { viewer { login } }'"
assert_write_guard "gh api graphql, a visible query with no spaces, field before the endpoint -> allow" allow \
    "gh api -f query='query{viewer{login}}' graphql"
# The endpoint is the first word that is neither a flag nor a flag's value, and quotes are
# stripped before the split, so a spaced query before the endpoint leaves its later words to be
# taken for the endpoint: a false deny, in the safe direction, answered by writing the endpoint
# first.
assert_write_guard "gh api graphql, a spaced query before the endpoint -> deny (safe direction)" deny \
    "gh api -f query='query { viewer { login } }' graphql"
assert_write_guard "gh api graphql --raw-field=query=..., attached and visible -> allow" allow \
    'gh api graphql --raw-field=query={viewer{login}}'
assert_write_guard "gh api graphql, a visible mutation -> deny" deny \
    'gh api graphql -f query=mutation{resolveReviewThread(x:1){id}}'

# An explicit GET sends -f/-F as query parameters, not a request body, so it reads regardless of a
# field being present.
assert_write_guard "gh api -X GET with a field -> allow" allow \
    "gh api -X GET search/issues -f q='repo:o/r is:open'"
assert_write_guard "gh api --method GET with a field -> allow" allow \
    'gh api --method GET repos/o/r -f x=1'
assert_write_guard "gh api -X POST with a field still denies" deny \
    'gh api -X POST repos/o/r/issues -f title=x'

# A reviewer role's merge-type refusal covers the API forms too: a write to /merge, /merges or
# /update-branch (a trailing slash or a query string included), and a write to /contents/. A GET of
# the same endpoints reads, and stays allowed.
assert_write_guard "wrapped gh api .../update-branch as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -X PUT repos/o/r/pulls/1/update-branch'
assert_write_guard "wrapped gh api .../merges (plural) as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -X POST repos/o/r/merges -f base=a -f head=b'
assert_write_guard "wrapped gh api PUT .../contents/x as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -X PUT repos/o/r/contents/x'
assert_write_guard "wrapped gh api .../merge/ (trailing slash) as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -X PUT repos/o/r/pulls/1/merge/'
assert_write_guard "wrapped gh api .../merge?x=1 (query string) as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -X PUT repos/o/r/pulls/1/merge?x=1'
assert_write_guard "wrapped gh api POST .../comments as claude-reviewer still allows" allow \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -X POST repos/o/r/issues/1/comments -f body=hi'
assert_write_guard "wrapped gh api DELETE .../contents/x as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -X DELETE repos/o/r/contents/x'
assert_write_guard "wrapped gh api, a field before -X PUT .../merge, as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -f commit_title=x -X PUT repos/o/r/pulls/1/merge'
assert_write_guard "wrapped GET .../pulls/1/merge (is it merged?) as claude-reviewer -> allow" allow \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api repos/o/r/pulls/1/merge'
assert_write_guard "wrapped GET .../contents/README.md as claude-reviewer -> allow" allow \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api repos/o/r/contents/README.md'
assert_write_guard "bare GET .../pulls/1/merge -> allow" allow \
    'gh api repos/o/r/pulls/1/merge'
assert_write_guard "gh api with a split -H value before -X PATCH -> deny" deny \
    'gh api -H "Accept: application/vnd.github+json" -X PATCH repos/o/r/issues/1'
assert_write_guard "gh api -X with a separator for its value does not swallow the next command" deny \
    'uv run python tools/agent-identity.py run claude-coder -- gh api repos/o/r -X ; git push'
assert_write_guard "wrapped gh api PATCH .../git/refs/heads/x (moves a branch) as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -X PATCH repos/o/r/git/refs/heads/feature -f sha=abc'
assert_write_guard "wrapped gh api DELETE .../git/refs/heads/x as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api -X DELETE repos/o/r/git/refs/heads/feature'
assert_write_guard "wrapped GET .../git/refs/heads/main as claude-reviewer -> allow" allow \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api repos/o/r/git/refs/heads/main'
assert_write_guard "wrapped reply whose body comes from a file, as claude-reviewer -> allow" allow \
    'uv run python tools/agent-identity.py run claude-reviewer -- gh api repos/o/r/pulls/1/comments/5/replies -F body=@reply.md'
assert_write_guard "wrapped gh api PUT .../merge as claude-coder still allows" allow \
    'uv run python tools/agent-identity.py run claude-coder -- gh api -X PUT repos/o/r/pulls/1/merge'
# A tag push is a push like any other to the wrapper: the coder that cuts a release pushes its tag,
# and a reviewer never pushes one.
assert_write_guard "a tag push, unwrapped -> deny" deny 'git push origin v1.2.0'
assert_write_guard "a tag push wrapped as claude-coder -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- git push origin v1.2.0'
assert_write_guard "git push --tags wrapped as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- git push origin --tags'
assert_write_guard "an abbreviated delete wrapped as claude-coder -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- git push --del origin feature/x'
# A push whose refspec is a shell expansion is a push like any other to the wrapper, and a reviewer
# never makes one. A git or gh option whose argument is an unquoted command substitution ends the
# option run at the substitution, so the subcommand behind it is never reached, and a subcommand
# that is itself an expansion is not read either: a write subcommand's name after it denies, a read
# allows, and gh denies either way.
assert_write_guard "a push of \$(...) wrapped as claude-coder -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- git push origin "$(git branch --show-current)"'
assert_write_guard "a push of \$(...) wrapped as claude-reviewer -> deny" deny \
    'uv run python tools/agent-identity.py run claude-reviewer -- git push origin "$(git branch --show-current)"'
assert_write_guard "git -C \$(pwd) push, unwrapped -> deny" deny 'git -C $(pwd) push origin main'
assert_write_guard "git -C \`pwd\` commit, unwrapped -> deny" deny 'git -C `pwd` commit -m x'
assert_write_guard "git -C \$(pwd) status -> allow" allow 'git -C $(pwd) status'
assert_write_guard "a subcommand that is itself a substitution, before a write's name -> deny" deny \
    'git $(echo push) origin v1'
assert_write_guard "a subcommand that is a variable, with no write's name after -> allow" allow \
    'git $GITFLAGS status'
assert_write_guard "git -C \$(pwd) push wrapped as claude-coder -> allow" allow \
    'uv run python tools/agent-identity.py run claude-coder -- git -C $(pwd) push origin main'
assert_write_guard "gh -R \$(cat r) pr merge, unwrapped -> deny" deny 'gh -R $(cat r) pr merge 3'
assert_write_guard_reason "an unquoted substitution before a subcommand is named in the deny" \
    'git -C $(pwd) push origin main' "git with a shell expansion before its subcommand"
assert_write_guard_reason "xargs input makes push refspecs unreadable" \
    'echo v1 | xargs -I{} git push origin {}' 'git push that cannot be read'

# Where no identity can work -- a Claude Code cloud session, or no identity directory -- and the
# player has switched the asking on (NAPPY_ASK_FOR_PLAYER_WRITES=1), an ordinary write is asked
# about rather than denied (2026-10-02, "Let's do A"); everything a prompt is too easy to click
# through for stays denied. Unset, the switch is off and every write is denied (2026-10-02, "Yes
# default to refusing").
#
# Asked about with the switch on: a local commit or history step, a push of a branch (an explicit
# refs/heads/ destination is a branch even when its name starts with v), and gh pr
# create/comment/edit/ready. The name test reads only refspecs, so a remote whose name starts with
# v (the first word after push that is neither an option nor an option's value, or the first after
# a --) and an option's own value (-o vfoo) are not read as tags; a lone word after push is the
# remote, as git reads it. A git -c before push that sets a branch push refspec, or no refspec at
# all (a $ in another key's value included), leaves an ordinary push; a quoted substitution as an
# option's argument is one word; and a quoted separator is not the push's own when it belongs to
# another command (a commit message) or sits at the push's own level in a quoted script.
write_guard_asked=(
    $'git commit -m "$(cat <<\'EOF\'\nNames passed through xargs git\nare read.\nEOF\n)"'
    'gxargs git status; git push origin feature/x'
    'env_parallel gh pr view && git push origin feature/x'
    'parallel git status | git push origin feature/x'
    'sh -c "env_parallel git status; git push origin feature/x"'
    'parallel git status < paths.txt; git push origin feature/x'
    'xargs git status < paths.txt; git push origin feature/x'
    'echo xargs && git push origin feature/x'
    'sh -c "xargs git status; git push origin feature/x"'
    'git push origin xargs'
    'git commit -m "x"'
    'git merge feature/x'
    'git rebase main'
    'git pull origin main'
    'git cherry-pick abc123'
    'git revert abc123'
    'git am fix.patch'
    'git push vendor HEAD'
    'git push vendor feature/x'
    'git push -u vendor feature/x'
    'git push vendor HEAD:refs/heads/vnext'
    'git push -o ci.skip vendor HEAD'
    'git push -o vfoo origin feature/x'
    'git push --push-option vfoo origin feature/x'
    'git push -uo ci.skip vendor HEAD'
    'git push --repo vendor HEAD'
    'git push --recurse-submodules check vendor HEAD'
    'git push -- vendor HEAD'
    'git push git@github.com:o/v.git HEAD'
    'git push vnext'
    'git push -u origin feature/x'
    'git push origin feature/x'
    'git push origin work/v2-cleanup'
    'git commit -m x && git push origin feature/x'
    'git push origin HEAD:refs/heads/v1'
    'git push origin HEAD:refs/heads/vnext'
    'git push --dry-run origin feature/x'
    'git push --no-tags origin feature/x'
    'git push --thin origin feature/x'
    'git -c remote.origin.push=HEAD:refs/heads/feature/x push origin'
    'git -c user.name=x push origin feature/x'
    'git -c push.default=simple push origin'
    'git -cpush.default=current push origin'
    'git -c user.name=push.default=matching push origin feature/x'
    'git -c "user.email=$E" push origin feature/x'
    'git -C "$(pwd)" push origin feature/x'
    "sh -c 'git -C \"\$(pwd)\" push origin feature/x'"
    'git -C "`pwd`" push origin feature/x'
    'git commit -m "a; b" && git push origin feature/x'
    'git push origin feature/x && git commit -m "c|d"'
    'bash -c "git push origin feature/x; git status"'
    "bash -c 'git push origin feature/x && echo done'"
    'git push origin feature/x 2>&1 | tail -3'
    'gh pr create --title x --body y'
    'gh pr comment 5 --body hi'
    'gh pr edit 5 --title x'
    'gh pr ready 5'
)
# Denied whatever the switch says. A push of a tag or of every branch (a pushed v* tag deploys the
# site, so any ref whose name starts with v reads as a tag, and a branch named v-something pushed
# by that bare name is denied too, to a remote whose own name starts with v as well); any word of
# a push holding a * (refs/*:refs/* pushes every tag, refs/heads/*:refs/heads/* is --all), and a
# git -c before push holding one; where the remote cannot be told for certain (a prefix of a value
# option, -oo, whose value is the second o, a -- that is -o's value), the word after is read as a
# refspec; a forced, deleting, mirroring or pruning push, with each long option also spelled as
# any prefix git accepts, and as the shorter ambiguous ones, or through a git -c naming mirror or a
# + push refspec; a push refspec set by a git -c read like a written one (a v name, a : delete);
# a push with a shell expansion among its words, the remote or an option's value included, or in a
# git -c push refspec, its key, or a --config-env one; a push whose own quoted word holds a
# separator, so the words after it go unread; a git or gh whose options hold an unquoted command
# substitution; a gh issue write, bare or wrapped in an identity, since only tools/inbox.py writes
# an issue (bouncy-heron statement 14: "an agent shouldn't use gh issue directly"); a merge, a
# release, a gh api write and a pushing tools/ script.
write_guard_never_asked=(
    'echo push | xargs -rIstatus git status origin v1'
    'echo merge | xargs -rIview gh pr view 3'
    'echo push | xargs -rI status git status origin v1'
    'echo push | gxargs -0rtIstatus git status origin v1'
    'echo push | xargs -ri status git status origin v1'
    'echo push | xargs -rtistatus git status origin v1'
    'echo push | xargs -Istatus -E -Iother git status origin v1'
    'echo merge | xargs -Iview -E -Iother gh pr view 3'
    'echo push | xargs -Istatus -d -Iother git status origin v1'
    'echo push | xargs -Istatus -a -Iother git status origin v1'
    'echo push | xargs -Istatus -E parallel git status origin v1'
    'echo push | xargs -Iother -E -Iignored -rIstatus git status origin v1'
    'xargs -rIstatus sh -c "git status origin v1"'
    'xargs -rIstatus sh -c "parallel -Iother git status origin v1"'
    'parallel -Istatus --joblog -Iother git status origin v1'
    'parallel --timeout 5 tools/update-pr.sh'
    'parallel --retries 2 tools/update-pr.sh'
    'parallel --results out tools/update-pr.sh'
    'env_parallel --results "out dir" --timeout=5 tools/update-pr.sh'
    'xargs -rI{} env_parallel --retries 2 tools/update-pr.sh'
    'sh -c "parallel --timeout 5 tools/update-pr.sh"'
    'parallel -kj2 tools/update-pr.sh'
    'gxargs -rn1 tools/update-pr.sh'
    'parallel --new-option 5 tools/update-pr.sh'
    'parallel --new-option=5 cat tools/update-pr.sh'
    'parallel --new-option 5 tools/update-pr.sh --dry-run'
    'parallel --new-option 5 tools/release.sh patch'
    'xargs -rZstatus git status origin v1'
    'xargs --rep=status git status origin v1'
    'parallel --new-option status git status'
    'parallel --new-option view gh pr view'
    'xargs --new-option sh -c "git status; tools/update-pr.sh"'
    'echo push | xargs -Icmd git cmd origin v1'
    'echo push | parallel -Icmd git cmd origin v1'
    'echo push | xargs -Istatus git status origin v1'
    'echo merge | xargs -Iview gh pr view 3'
    'echo push | parallel -I status git status origin v1'
    'echo merge | parallel -Iview gh pr view 3'
    'echo push | xargs --replace=cmd git cmd origin v1'
    'echo push | xargs --replace cmd git cmd origin v1'
    'echo push | xargs -icmd git cmd origin v1'
    'echo push | xargs -i cmd git cmd origin v1'
    'echo push | gxargs -Jcmd git cmd origin v1'
    'echo push | gxargs -J cmd git cmd origin v1'
    'echo push | parallel --replace=cmd git cmd origin v1'
    'echo push | parallel --replace cmd git cmd origin v1'
    'echo push | parallel -icmd git cmd origin v1'
    'echo push | parallel -i cmd git cmd origin v1'
    'echo push | parallel -lcmd git cmd origin v1'
    'echo push | parallel -l cmd git cmd origin v1'
    'echo push origin v1 | xargs git'
    'echo push origin v1 | parallel git'
    'echo push | xargs -I{} git {} origin v1'
    'echo commit -m x | xargs git'
    'echo merge 3 | xargs gh pr'
    'echo pr merge 3 | xargs gh'
    'xargs git; git status'
    'parallel gh pr && git status'
    'parallel gh | head'
    'xargs -I REF git REF origin v1'
    'xargs -I % git % origin v1'
    'parallel gh {} merge 3'
    'xargs -I REF gh REF merge 3'
    'xargs -I % gh pr % 3'
    'parallel -I REF gh pr REF 3'
    'xargs git -C repo'
    'parallel gh -R o/r'
    'xargs gh pr -R o/r'
    'xargs -I{} sh -c "git status; git {} origin v1"'
    'parallel sh -c "gh pr view; gh pr {} 3"'
    'echo v1 | gxargs -I{} git push origin {}'
    'echo v1 | env_parallel git push origin'
    'gxargs git'
    'env_parallel gh pr'
    'ls | parallel tools/release.sh patch push'
    'echo push | xargs tools/release.sh patch'
    'echo "patch push" | xargs tools/release.sh'
    'echo push | xargs -I{} tools/release.sh patch {}'
    'echo push | parallel tools/release.sh patch'
    'parallel tools/release.sh patch'
    'parallel tools/land-prs.sh 3'
    'parallel tools/update-pr.sh 3'
    'parallel tools/prune-merged.sh feature/x'
    'echo feature/x | parallel --max-args 1 tools/prune-merged.sh'
    'echo feature/x | parallel --max-replace-args 1 tools/prune-merged.sh'
    'echo feature/x | parallel --max-procs 2 tools/prune-merged.sh'
    'echo feature/x | parallel -P 2 tools/prune-merged.sh'
    'echo 3 | parallel --joblog jobs.log tools/update-pr.sh'
    'echo 3 | env_parallel --jl jobs.log tools/update-pr.sh'
    'echo 3 | parallel --delay 0.1 tools/update-pr.sh'
    'echo 3 | parallel --halt soon,fail=1 tools/update-pr.sh'
    'echo 3 | env_parallel --halt-on-error 2 tools/update-pr.sh'
    'parallel -j 2 --jobs 2 -a inputs --arg-file inputs -I REF -n 1 -N 1 -L 1 -S host --sshlogin host -d , --colsep , tools/land-prs.sh 3'
    'env_parallel -j 2 --jobs 2 -a inputs --arg-file inputs -I REF -n 1 -N 1 -L 1 -S host --sshlogin host -d , --colsep , tools/update-pr.sh 3'
    'gxargs -n 1 -I REF -a inputs tools/prune-merged.sh feature/x'
    '/usr/local/bin/env_parallel --jobs=2 tools/release.sh patch push'
    '/opt/homebrew/bin/gxargs --max-args=1 tools/release.sh patch push'
    'echo v1 | parallel git push origin'
    'parallel git push origin {} < t'
    'ls | parallel -j1 git push origin {}'
    'echo v1 | xargs -I{} git push origin {}'
    'xargs git push origin < tags.txt'
    'xargs -n 1 git push origin < tags.txt'
    'xargs -I REF git push origin REF < tags.txt'
    'xargs --max-args=1 -- git -C repo push origin < tags.txt'
    'xargs --arg-file tags.txt git push origin'
    'env MODE=test /usr/bin/xargs -0 -n 1 timeout 5 git push origin'
    'xargs -n 1 env MODE=test git push origin feature/x'
    'sh -c "xargs -n 1 git push origin"'
    'xargs -I{} sh -c "git status; git push origin {}"'
    'xargs -I{} sh -c "git status && git push origin {}"'
    'xargs -I{} sh -c "echo ${MODE}; git push origin {}"'
    "printf 'v1;v2' | xargs -d \\; git push origin"
    'parallel --colsep \| git push origin {2}'
    'parallel -d \& git push origin'
    'xargs -E \; git push origin'
    "printf 'push;origin;v1' | xargs -d \\; git"
    "printf 'merge;3' | xargs -d \\; gh pr"
    'parallel ::: tools/update-pr.sh'
    'parallel ::: "tools/release.sh patch push"'
    'parallel -j2 ::: tools/prune-merged.sh'
    'echo "-X PUT" | xargs gh api repos/o/r/pulls/3/merge'
    'echo "--method PUT" | xargs gh api repos/o/r/pulls/3/merge'
    'printf %s\\n -X PUT repos/o/r/pulls/3/merge | xargs gh api'
    'echo "-f title=x" | parallel gh api repos/o/r/issues'
    'echo "-X POST -f body=x" | xargs gh api repos/o/r/issues/3/comments'
    'echo "-X PUT" | xargs gh api -X GET repos/o/r/pulls/3/merge'
    'echo -XPUT | xargs -I{} gh api {}'
    'echo 3 | parallel gh api repos/o/r/pulls/{.}/comments'
    "echo 3 | xargs -I{} gh api graphql -f query='query { a(n: {}) }'"
    'ls | parallel --tag git push origin {}'
    'ls | parallel --tagstring x git push origin'
    'ls | parallel --pipe git push origin'
    'ls | parallel -X git push origin'
    'ls | xargs -o git push origin'
    'ls | xargs --process-slot-var=SLOT git push origin'
    'ls | parallel --tagstring x tools/update-pr.sh'
    "git push origin 'refs/*:refs/*'"
    "git push origin 'refs/heads/*:refs/heads/*'"
    "git push origin 'refs/tags/*'"
    "git push origin 'feature/*'"
    "git push origin '+refs/*:refs/*'"
    "git push vendor 'refs/heads/*:refs/heads/*'"
    "git -c 'remote.origin.push=refs/*:refs/*' push origin"
    'git -c remote.origin.mirror=true push origin'
    'git -c remote.origin.push=+refs/heads/x:refs/heads/x push origin'
    'git push vendor vnext'
    'git push vendor HEAD:v1'
    'git push vendor tag v1'
    'git push -u vendor vnext'
    'git push -o ci.skip vendor vnext'
    'git push --repo vendor origin vnext'
    'git push -- vendor vnext'
    'git push --rep vendor vnext'
    'git push -oo vendor vnext'
    'git push -o -- vendor vnext'
    'git push origin v1'
    'git push origin vnext'
    'git push origin HEAD:vnext'
    'git push origin version-two'
    'git push origin +vnext'
    'git tag v1 && git push origin v1'
    'git push origin --tags'
    'git push --follow-tags origin x'
    'git push --all origin'
    'git push --branches origin'
    'git push origin refs/tags/v1'
    'git push origin HEAD:refs/tags/v1.2.0'
    'git push origin tag v1'
    'git push origin tags/v1'
    'git push origin main:v2'
    'git push origin +v1'
    'git -c push.followTags=true push origin x'
    'git -c push.default=matching push origin'
    'git -cpush.default=matching push origin'
    'git -c Push.Default=MATCHING push origin'
    'git -c "push.default=matching" push origin'
    'git -c push.default=matching push origin feature/x'
    'git -c push.default=matching -c push.default=simple push origin'
    'git push --ta origin'
    'git push --t origin'
    'git push --fol origin x'
    'git push --al origin'
    'git push --a origin'
    'git push --force origin feature/x'
    'git push -f origin feature/x'
    'git push -uf origin feature/x'
    'git push --force-with-lease origin feature/x'
    'git push --force-with-lease=feature/x:abc origin feature/x'
    'git push --force-w origin feature/x'
    'git push --force-if origin feature/x'
    'git push --forc origin feature/x'
    'git push --for origin feature/x'
    'git push --fo origin feature/x'
    'git push origin --delete feature/x'
    'git push --del origin feature/x'
    'git push --dele origin feature/x'
    'git push --de origin feature/x'
    'git push --d origin feature/x'
    'git push --mirror origin'
    'git push --mir origin'
    'git push --m origin'
    'git push --prune origin'
    'git push --pru origin'
    'git push --pr origin'
    'git push --p origin'
    'git push origin :feature/x'
    'git push origin +feature/x'
    'gh issue create --title x --body y'
    'gh issue comment 5 --body hi'
    'gh issue edit 5 --title x'
    'gh issue close 5'
    'uv run python tools/agent-identity.py run claude-orchestrator -- gh issue comment 5 --body hi'
    'uv run python tools/agent-identity.py run claude-orchestrator -- gh api -X PATCH repos/o/r/issues/5 -f state=closed'
    'gh pr merge 391 --squash'
    'gh release create v1.0'
    'gh api repos/o/r/issues -X POST'
    'tools/release.sh patch push'
    'git commit -m x && gh pr merge 3'
    'git commit -m x && git push origin v1'
    'git push origin feature/x && gh issue comment 5 --body hi'
    'git -c remote.origin.push=v1.2.0 push origin'
    'git -c remote.origin.push=HEAD:v1.0.0 push origin'
    'git -c remote.origin.push=:feature/x push origin'
    'git -c remote.origin.push=:main push origin'
    'git -c Remote.Origin.Push=vnext push origin'
    'git -c branch.main.merge=v1 push origin'
    'git -c "remote.origin.push=$R" push origin'
    'git -c "$CFG" push origin feature/x'
    'git --config-env=remote.origin.push=R push origin'
    'git --config-env remote.origin.push=R push origin'
    "git -c 'remote.origin.push=a b' push origin"
    'TAG=v1.0.0; git push origin "$TAG"'
    'git push origin "$(git describe --tags)"'
    'git push origin `echo v1.0.0`'
    'git push origin ${TAG}'
    'git push "$REMOTE" feature/x'
    'git push -o "$X" origin feature/x'
    'git push origin HEAD:"$B"'
    "git push -o 'a;b' origin v1"
    "git push origin 'x;y' v1"
    'git push origin \; v1'
    'git push -o "ci(skip)" origin feature/x'
    "bash -c \"git push -o 'a;b' origin v1\""
    'git -C $(pwd) push origin feature/x'
    'git -c remote.origin.push=`echo v1` push origin'
    'gh -R $(cat r) pr merge 3'
    'bash -c "git -C $(pwd) push origin v1.0.0"'
    'bash -c "git -C `pwd` push origin v1.0.0"'
    "sh -c 'git -C \$(pwd) push origin v1.0.0'"
    'bash -c "gh -R $(cat r) pr merge 3"'
    'bash -c "gh pr -R $(cat r) merge 3"'
    'bash -c "gh -R `cat r` pr merge 3"'
    'bash -c "gh pr -R `cat r` merge 3"'
)
# A read, and `git tag` itself, which changes only the local repository, stay allowed.
write_guard_allowed=(
    'xargs -rIother -E -Istatus git status'
    'xargs -rIother -E -Iview gh pr view'
    'xargs -rIother -E xargs git status'
    'xargs -rIstatus -Iother git status'
    'xargs -rIother -n1 git status'
    'xargs -rIother -E -Istatus cat tools/update-pr.sh'
    'xargs -rn1 cat tools/update-pr.sh'
    'parallel -kj2 cat tools/update-pr.sh'
    'parallel --timeout 5 cat tools/update-pr.sh'
    'parallel --retries 2 cat tools/update-pr.sh'
    'parallel --results out cat tools/update-pr.sh'
    'env_parallel --results "out dir" --timeout=5 cat tools/update-pr.sh'
    'parallel --timeout 5 tools/update-pr.sh --dry-run 3'
    'parallel -Iother --joblog -Istatus git status'
    'parallel --new-option 5 echo hello; cat tools/update-pr.sh'
    'xargs --new-option 5 echo hello; git status'
    'xargs -Icmd git status'
    'parallel -Icmd gh pr view'
    'xargs -Istatus printf status'
    'xargs -i git status'
    'parallel --replace git status'
    'gxargs -n 1 git status'
    'env_parallel --jobs 2 git log'
    'parallel gh pr view'
    'xargs gh issue list'
    'env_parallel gh browse'
    'gxargs gh search prs'
    'parallel -j 2 cat tools/land-prs.sh'
    'parallel --max-args 1 cat tools/prune-merged.sh'
    'parallel --max-replace-args 1 cat tools/prune-merged.sh'
    'parallel --max-procs 2 cat tools/prune-merged.sh'
    'parallel -P 2 cat tools/prune-merged.sh'
    'parallel --joblog jobs.log cat tools/update-pr.sh'
    'env_parallel --jl jobs.log cat tools/update-pr.sh'
    'parallel --delay 0.1 tools/update-pr.sh --dry-run 3'
    'parallel --halt soon,fail=1 cat tools/release.sh'
    'env_parallel --halt-on-error 2 cat tools/release.sh'
    'env_parallel --colsep , cat tools/update-pr.sh'
    'parallel -d , cat tools/release.sh'
    'gxargs -d , cat tools/prune-merged.sh'
    'gxargs -I REF cat tools/release.sh'
    'parallel --jobs 2 tools/update-pr.sh --dry-run 3'
    'env_parallel -j 2 tools/land-prs.sh --dry-run 3'
    'xargs git status; git'
    'env_parallel git status; gh pr'
    'parallel git status'
    'xargs git status < paths.txt'
    'echo main | xargs -I{} git log --oneline {}'
    'env MODE=test /usr/bin/xargs -0 -n 1 timeout 5 git show'
    'xargs -I{} sh -c "git status; git log --oneline {}"'
    "printf 'v1;v2' | xargs -d \\; git status"
    'ls | xargs grep -l git'
    'ls | xargs grep -n "git"'
    'git ls-files | xargs grep -w gh'
    'git ls-files | xargs grep -c "gh pr"'
    'ls | xargs echo Git LFS'
    'ls | xargs git p4'
    "rg -n 'xargs git' tools/"
    'grep -rn "parallel gh" docs/'
    'echo "jobs run in parallel, git 2.40 needed" > notes.txt'
    'ls | xargs git --version'
    'seq 3 | parallel echo gh {}'
    'ls | xargs gh --help'
    'parallel cat ::: tools/update-pr.sh'
    'parallel tools/update-pr.sh --dry-run ::: 1 2'
    'parallel -j2 ::: "echo a" "echo b"'
    'echo 3 | xargs gh pr view'
    'parallel gh pr view ::: 1 2 3'
    'echo 3 | xargs -I{} gh api repos/o/r/pulls/{}/comments'
    'echo 3 | xargs -I{} gh api -X GET repos/o/r/pulls/{} --jq .title'
    'echo 3 | parallel gh api repos/o/r/pulls/{}/comments'
    'ls | parallel --tag git log -1 -- {}'
    'ls | parallel --tagstring x gh pr view {}'
    'ls | parallel --pipe git status'
    'ls | parallel -X git log -1 --'
    'ls | parallel -m --xargs git log -1 --'
    'ls | xargs -o git status'
    'ls | xargs --open-tty git status'
    'ls | xargs --process-slot-var=SLOT git status'
    'ls | parallel --tag tools/land-prs.sh --dry-run {}'
    'git status'
    'git tag v1'
    'git tag -a v1 -m x'
    'git -C $(pwd) status'
    'bash -c "git -C $(pwd) status"'
    "sh -c 'git -C \$(pwd) status'"
    'gh -R "$(cat r)" pr view 3'
    'gh -R "`cat r`" pr view 3'
    'gh pr -R "$(cat r)" view 3'
    "sh -c 'gh -R \"\$(cat r)\" pr view 3'"
    "rg -n 'gh issue comment' .claude/"
    'uv run python tools/inbox.py --role claude-orchestrator close --pr 5'
)
# The same denial cases on a machine with identities, even when asking is switched on: a
# quoted-script expansion must not disappear before environment policy ever sees the write.
write_guard_switch=1
for write_guard_cmd in "${write_guard_never_asked[@]}"; do
    assert_write_guard "local identities: $write_guard_cmd -> deny" deny "$write_guard_cmd"
done
write_guard_switch=""
for write_guard_mode in remote unconfigured; do
    if [ "$write_guard_mode" = remote ]; then
        write_guard_remote=true
    else
        write_guard_remote=""
        write_guard_agents="${TMPDIR:-/tmp}/write-guard-no-agents"
        rm -rf "$write_guard_agents"
    fi
    write_guard_switch=1
    for write_guard_cmd in "${write_guard_asked[@]}"; do
        assert_write_guard "$write_guard_mode: $write_guard_cmd -> ask" ask "$write_guard_cmd"
    done
    for write_guard_cmd in "${write_guard_never_asked[@]}"; do
        assert_write_guard "$write_guard_mode: $write_guard_cmd -> deny" deny "$write_guard_cmd"
    done
    for write_guard_cmd in "${write_guard_allowed[@]}"; do
        assert_write_guard "$write_guard_mode: $write_guard_cmd -> allow" allow "$write_guard_cmd"
    done
    # The player's switch, unset or anything but 1: the asking is off and every write is denied.
    for write_guard_switch in "" 0 yes; do
        for write_guard_cmd in "${write_guard_asked[@]}" "${write_guard_never_asked[@]}"; do
            assert_write_guard "$write_guard_mode, switch '$write_guard_switch': $write_guard_cmd -> deny" deny \
                "$write_guard_cmd"
        done
        for write_guard_cmd in "${write_guard_allowed[@]}"; do
            assert_write_guard "$write_guard_mode, switch '$write_guard_switch': $write_guard_cmd -> allow" allow \
                "$write_guard_cmd"
        done
    done
    write_guard_switch=""
done
write_guard_remote=""

echo
echo "$checks checks, $failures failures"
if [ "$failures" -gt 0 ]; then
    exit 1
fi
