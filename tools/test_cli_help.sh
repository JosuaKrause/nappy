#!/usr/bin/env bash
# The two-path test the cli-tools skill asks for, for every shell entry point in tools/: --help
# (or -h) prints usage and exits 0 without doing any work, and a flag none of them recognise is
# rejected -- usage on stderr, a non-zero exit -- before any work happens either.
#
#   tools/test_cli_help.sh
#
# Wired into CI in .github/workflows/ci.yml, right beside tools/lint.sh -- it needs nothing but
# bash and the scripts under test, no uv and no real Godot binary: GODOT points at a stub that
# only records whether it was ever invoked, so a script whose own validation regresses and
# launches "Godot" anyway on a bad flag is caught even on a runner with no engine installed.
#
# tools/test.sh is deliberately not asserted against an unknown flag here in general: it forwards
# anything that is not --serial/--plan/--record-costs/--shard/--help/-h straight to the test scene
# as either a suite-name substring or a flag the scene itself reads off
# OS.get_cmdline_user_args() -- there is no fixed list to
# validate that free-text surface against, so only its --help path is checked there. --shard and
# --record-costs are its own recognised flags with their own shape to get wrong, though, and both
# validate before the import pass that would otherwise touch the Godot stub -- so their malformed
# cases are asserted below alongside the rest.
#
# Bash 3.2-safe (no associative arrays, no mapfile) -- the same reason the rest of tools/ stays
# this side of bash 4; see tools/lint.sh's own header.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# A stand-in for the Godot binary: touches a marker, exits 0, and -- since M195 -- also writes an
# empty file at whatever path follows a `--screenshot` in its own argv, standing in for the PNG a
# real `AutoScreenshot._capture()` would save; shot.sh now fails loudly when that file is missing
# (see lib_dev_flags.sh's own doc), so a launch stub that produced no picture at all would make
# every "does shot.sh still launch Godot" case below fail for the wrong reason.
GODOT_MARKER="$work_dir/godot-invoked"
GODOT_STUB="$work_dir/godot-stub.sh"
GODOT_ARGS="$work_dir/godot-args"
{
    echo '#!/usr/bin/env bash'
    printf 'touch %q\n' "$GODOT_MARKER"
    printf 'printf "%%s\\n" "$@" > %q\n' "$GODOT_ARGS"
    echo 'args=("$@")'
    echo 'for i in "${!args[@]}"; do'
    echo '    if [[ "${args[$i]}" == "--screenshot" && $((i + 1)) -lt ${#args[@]} ]]; then'
    echo '        : > "${args[$((i + 1))]}"'
    echo '    fi'
    echo 'done'
    echo 'exit 0'
} > "$GODOT_STUB"
chmod +x "$GODOT_STUB"
export GODOT="$GODOT_STUB"

checks=0
failures=0

# $1 label  $2 "zero"|"nonzero"  $3.. command
assert_exit() {
    local label="$1" expect="$2"
    shift 2
    checks=$(( checks + 1 ))
    rm -f "$GODOT_MARKER"
    local out status
    out="$("$@" 2>&1)"
    status=$?
    if [[ "$expect" == "zero" && "$status" -ne 0 ]]; then
        echo "FAIL $label: expected exit 0, got $status" >&2
        printf '%s\n' "$out" | sed 's/^/    /' >&2
        failures=$(( failures + 1 ))
        return
    fi
    if [[ "$expect" == "nonzero" && "$status" -eq 0 ]]; then
        echo "FAIL $label: expected a non-zero exit, got 0" >&2
        printf '%s\n' "$out" | sed 's/^/    /' >&2
        failures=$(( failures + 1 ))
        return
    fi
    if ! printf '%s' "$out" | grep -qi usage; then
        echo "FAIL $label: no 'usage' anywhere in the output" >&2
        printf '%s\n' "$out" | sed 's/^/    /' >&2
        failures=$(( failures + 1 ))
        return
    fi
    if [[ -f "$GODOT_MARKER" ]]; then
        echo "FAIL $label: launched Godot" >&2
        failures=$(( failures + 1 ))
        return
    fi
    echo "ok   $label"
}

# --------------------------------------------------------- --help / -h: exit 0, usage, no work ---
assert_exit "ci-costs.sh --help"   zero ./tools/ci-costs.sh --help
assert_exit "ci-costs.sh -h"       zero ./tools/ci-costs.sh -h
assert_exit "check.sh --help"      zero ./tools/check.sh --help
assert_exit "check.sh -h"          zero ./tools/check.sh -h
assert_exit "lint.sh --help"       zero ./tools/lint.sh --help
assert_exit "pycheck.sh --help"    zero ./tools/pycheck.sh --help
assert_exit "export-web.sh --help" zero ./tools/export-web.sh --help
assert_exit "serve-web.sh --help"  zero ./tools/serve-web.sh --help
assert_exit "release.sh --help"    zero ./tools/release.sh --help
assert_exit "run.sh --help"        zero ./tools/run.sh --help
assert_exit "shot.sh --help"       zero ./tools/shot.sh --help
assert_exit "trailer.sh --help"    zero ./tools/trailer.sh --help
assert_exit "trailer.sh -h"        zero ./tools/trailer.sh -h
assert_exit "record.sh --help"     zero ./tools/record.sh --help
assert_exit "record.sh -h"         zero ./tools/record.sh -h
assert_exit "stats.sh --help"      zero ./tools/stats.sh --help
assert_exit "telemetry.sh --help"  zero ./tools/telemetry.sh --help
assert_exit "test.sh --help"       zero ./tools/test.sh --help
assert_exit "clip.sh --help"       zero ./tools/clip.sh --help
assert_exit "reference.sh --help"  zero ./tools/reference.sh --help
assert_exit "bake-atlases.sh --help" zero ./tools/bake-atlases.sh --help
assert_exit "bake-atlases.sh -h"     zero ./tools/bake-atlases.sh -h
assert_exit "audit-pck.sh --help"    zero ./tools/audit-pck.sh --help
assert_exit "audit-pck.sh -h"        zero ./tools/audit-pck.sh -h
assert_exit "cost-table.sh --help"   zero ./tools/cost-table.sh --help
assert_exit "cost-table.sh -h"       zero ./tools/cost-table.sh -h
assert_exit "prune-merged.sh --help" zero ./tools/prune-merged.sh --help
assert_exit "prune-merged.sh -h"     zero ./tools/prune-merged.sh -h
assert_exit "agent-status.sh --help" zero ./tools/agent-status.sh --help
assert_exit "agent-status.sh -h"     zero ./tools/agent-status.sh -h
assert_exit "resolve-decisions-top.sh --help" zero ./tools/resolve-decisions-top.sh --help
assert_exit "resolve-decisions-top.sh -h"     zero ./tools/resolve-decisions-top.sh -h
assert_exit "update-pr.sh --help" zero ./tools/update-pr.sh --help
assert_exit "update-pr.sh -h"     zero ./tools/update-pr.sh -h
assert_exit "land-prs.sh --help" zero ./tools/land-prs.sh --help
assert_exit "land-prs.sh -h"     zero ./tools/land-prs.sh -h

# ---------------------------------------- an unknown flag: rejected, usage, non-zero, no work ---
assert_exit "ci-costs.sh --bogus"        nonzero ./tools/ci-costs.sh --bogus
assert_exit "ci-costs.sh --runs (missing value)" nonzero ./tools/ci-costs.sh --runs
assert_exit "ci-costs.sh --runs (not a number)"  nonzero ./tools/ci-costs.sh --runs abc
assert_exit "ci-costs.sh (stray argument)"       nonzero ./tools/ci-costs.sh bogus-suite
assert_exit "check.sh --bogus"        nonzero ./tools/check.sh --bogus
assert_exit "lint.sh --bogus-flag"    nonzero ./tools/lint.sh --bogus-flag
assert_exit "pycheck.sh --bogus"      nonzero ./tools/pycheck.sh --bogus
assert_exit "export-web.sh --bogus"   nonzero ./tools/export-web.sh --bogus
assert_exit "serve-web.sh --bogus"    nonzero ./tools/serve-web.sh --bogus
assert_exit "release.sh --bogus"      nonzero ./tools/release.sh --bogus
assert_exit "run.sh --bogus"          nonzero ./tools/run.sh --bogus
assert_exit "shot.sh --bogus"         nonzero ./tools/shot.sh "$work_dir/shot-out.png" 1 --bogus
assert_exit "trailer.sh --bogus"      nonzero ./tools/trailer.sh --bogus
assert_exit "trailer.sh --shot (missing name)" nonzero ./tools/trailer.sh --shot
assert_exit "trailer.sh --list --shot (combined)" nonzero ./tools/trailer.sh --list --shot choice
assert_exit "record.sh --bogus"       nonzero ./tools/record.sh --bogus
assert_exit "record.sh (no flags)"    nonzero ./tools/record.sh
assert_exit "record.sh --this-is-not-a-dev-flag" nonzero ./tools/record.sh --this-is-not-a-dev-flag
assert_exit "record.sh --out (missing name)" nonzero ./tools/record.sh --out
assert_exit "stats.sh --bogus"        nonzero ./tools/stats.sh --bogus
assert_exit "telemetry.sh --bogus"    nonzero ./tools/telemetry.sh --bogus
assert_exit "clip.sh --bogus"         nonzero ./tools/clip.sh --bogus
assert_exit "reference.sh --bogus"    nonzero ./tools/reference.sh --bogus
assert_exit "bake-atlases.sh --bogus" nonzero ./tools/bake-atlases.sh --bogus
# --check and --force mean opposite things about whether anything may be written, so asking for
# both is a typo rather than a preference, and it is rejected before either happens.
assert_exit "bake-atlases.sh --check --force" nonzero ./tools/bake-atlases.sh --check --force
assert_exit "audit-pck.sh --bogus"    nonzero ./tools/audit-pck.sh --bogus
assert_exit "audit-pck.sh (two packs)" nonzero ./tools/audit-pck.sh one.pck two.pck
assert_exit "cost-table.sh --bogus"   nonzero ./tools/cost-table.sh --bogus
assert_exit "prune-merged.sh --bogus" nonzero ./tools/prune-merged.sh --bogus feature/x
# With no branch named there is nothing it may safely touch, so it refuses rather than sweeping.
assert_exit "prune-merged.sh (no branch)" nonzero ./tools/prune-merged.sh
assert_exit "agent-status.sh --bogus" nonzero ./tools/agent-status.sh --bogus
assert_exit "resolve-decisions-top.sh --bogus" nonzero ./tools/resolve-decisions-top.sh --bogus
assert_exit "update-pr.sh --bogus" nonzero ./tools/update-pr.sh --bogus
# With nothing to update there is nothing it may safely fetch or merge, so it refuses rather
# than guessing a target.
assert_exit "update-pr.sh (no target)" nonzero ./tools/update-pr.sh
assert_exit "update-pr.sh (two targets)" nonzero ./tools/update-pr.sh 1 2
assert_exit "land-prs.sh --bogus"    nonzero ./tools/land-prs.sh --bogus 1
# With no PR number there is nothing to land, and a non-numeric argument is not a PR number --
# both are rejected before any gh call, same as a real PR number would trigger one.
assert_exit "land-prs.sh (no PR)"        nonzero ./tools/land-prs.sh
assert_exit "land-prs.sh (bad PR number)" nonzero ./tools/land-prs.sh abc
assert_exit "land-prs.sh --timeout (missing value)" nonzero ./tools/land-prs.sh --timeout
assert_exit "land-prs.sh --timeout (not a number)"  nonzero ./tools/land-prs.sh --timeout foo 1

# A bare `--` before the flags -- Godot's own separator, and the form the docs quote -- is
# accepted by run.sh and shot.sh and dropped before forwarding, so the stub sees the flags and
# exactly one `--` (the script's own). Launching the stub is the expected outcome here.
assert_launch() {
    local label="$1"
    shift
    checks=$(( checks + 1 ))
    rm -f "$GODOT_MARKER" "$GODOT_ARGS"
    local out status
    out="$("$@" 2>&1)"
    status=$?
    if [[ "$status" -ne 0 || ! -f "$GODOT_MARKER" ]]; then
        echo "FAIL $label: expected a launch and exit 0, got $status" >&2
        printf '%s\n' "$out" | sed 's/^/    /' >&2
        failures=$(( failures + 1 ))
        return
    fi
    local dashes
    dashes="$(grep -c -x -- '--' "$GODOT_ARGS")"
    if [[ "$dashes" -ne 1 ]] || ! grep -q -x -- '--overview' "$GODOT_ARGS"; then
        echo "FAIL $label: Godot got $dashes bare '--' (want 1) or lost --overview" >&2
        sed 's/^/    /' "$GODOT_ARGS" >&2
        failures=$(( failures + 1 ))
        return
    fi
    echo "ok   $label"
}
# Both launch paths repair before they start the game: run.sh rebuilds .godot's class cache when
# a class_name is missing from it, and run.sh and shot.sh both rebuild the baked atlas pages
# through tools/check.sh when a source hash has moved. Neither repair can succeed with the stub
# standing in for Godot -- it registers no class and bakes no page -- so each script correctly
# refuses to launch, which is not what these two cases are about.
#
# So each runs only where its own precondition is already met, which is a developer's checkout,
# and says so loudly where it is not. What a skip costs is only the proof that a leading `--` is
# dropped and the flags still arrive; the --help and rejection cases above cover both scripts
# everywhere, including on a runner with nothing built.
atlases_current() { ./tools/bake-atlases.sh --check >/dev/null 2>&1; }

# A page whose group no longer exists is staleness, and --check has to say so by name -- the case
# that reaches the player is a group folded into another (head_indicators into ui), whose page
# then sits in assets/atlases/baked/ with every input hash still agreeing. It is not a picture
# anything loads, but that folder is imported, so the engine exports it into the pack.
#
# Only checked where the atlases are already current, for the same reason the two launch cases
# above are: on a checkout with nothing baked, --check is already non-zero for a different reason
# and would pass this vacuously. It plants the page and takes it away again itself; the bake that
# removes one for real needs the engine, which the stub above is not.
checks=$(( checks + 1 ))
if atlases_current; then
    planted="$root/assets/atlases/baked/zz_no_such_group.png"
    cp "$root/assets/atlases/baked/ui.png" "$planted"
    reason="$(./tools/bake-atlases.sh --check 2>&1)"
    status=$?
    rm -f "$planted"
    if [[ $status -eq 0 ]]; then
        echo "FAIL bake-atlases.sh --check called a tree with an orphan page current" >&2
        failures=$(( failures + 1 ))
    elif ! grep -q "zz_no_such_group.png" <<<"$reason"; then
        echo "FAIL bake-atlases.sh --check did not name the orphan page: $reason" >&2
        failures=$(( failures + 1 ))
    else
        echo "ok   bake-atlases.sh --check names a page no group claims"
    fi
    if ! atlases_current; then
        echo "FAIL the orphan-page case left the tree stale" >&2
        failures=$(( failures + 1 ))
    fi
else
    echo "skip bake-atlases.sh --check orphan page (no current atlases in this checkout)"
fi

if [[ -f "$root/.godot/global_script_class_cache.cfg" ]] && atlases_current; then
    assert_launch "run.sh -- --overview (separator dropped)" ./tools/run.sh -- --overview
else
    echo "skip run.sh -- --overview (no import cache or no current atlases in this checkout)"
fi
if atlases_current; then
    assert_launch "shot.sh ... -- --overview (separator dropped)" ./tools/shot.sh "$work_dir/shot-sep.png" 1 -- --overview
else
    echo "skip shot.sh ... -- --overview (no current atlases in this checkout)"
fi
# And only there: a `--` after a flag is not a separator, it is a stray word.
assert_exit "run.sh --overview -- (late separator)"  nonzero ./tools/run.sh --overview -- --debug
assert_exit "shot.sh ... --overview -- (late separator)" nonzero ./tools/shot.sh "$work_dir/shot-sep2.png" 1 --overview --

# A run.sh / shot.sh dev flag missing its required value is the other rejected shape -- checked
# once each here since lib_dev_flags.sh's own arity handling already has a focused smoke test in
# its validate_dev_flags() cases; this only proves the two callers actually wired it in.
assert_exit "run.sh --seed (missing value)"  nonzero ./tools/run.sh --seed
assert_exit "shot.sh --meters (missing values)" nonzero ./tools/shot.sh "$work_dir/shot-out2.png" 1 --meters 3

# -------------------------------------------- --route + --screenshot: refused, not raced ---
# M195: RouteRig (src/dev/route_rig.gd) quits the process itself the moment she arrives, which can
# beat --screenshot's own --after timer, so the combination could silently write nothing rather
# than a picture. reject_route_with_screenshot() is the shared function both scripts call before
# ever launching Godot -- checked directly here since its own message does not say "usage" (it is
# not a malformed flag, it is a conflict between two well-formed ones), so assert_exit's own grep
# does not fit it.
PROJECT_DIR="$root"
# shellcheck source=tools/lib_dev_flags.sh
source "$root/tools/lib_dev_flags.sh"
checks=$(( checks + 1 ))
if reject_route_with_screenshot --route mark --screenshot out.png; then
    echo "FAIL reject_route_with_screenshot: --route with --screenshot was accepted" >&2
    failures=$(( failures + 1 ))
else
    echo "ok   reject_route_with_screenshot refuses --route with --screenshot"
fi
checks=$(( checks + 1 ))
if ! reject_route_with_screenshot --route mark --seed 1; then
    echo "FAIL reject_route_with_screenshot: a plain --route was refused" >&2
    failures=$(( failures + 1 ))
else
    echo "ok   reject_route_with_screenshot leaves a plain --route alone"
fi
checks=$(( checks + 1 ))
if ! reject_route_with_screenshot --screenshot out.png --seed 1; then
    echo "FAIL reject_route_with_screenshot: a plain --screenshot was refused" >&2
    failures=$(( failures + 1 ))
else
    echo "ok   reject_route_with_screenshot leaves a plain --screenshot alone"
fi

rm -f "$GODOT_MARKER"
out="$(./tools/shot.sh "$work_dir/shot-route.png" 1 --route mark 2>&1)"
status=$?
checks=$(( checks + 1 ))
if [[ $status -eq 0 ]]; then
    echo "FAIL shot.sh --route (implicit --screenshot): expected a non-zero exit, got 0" >&2
    failures=$(( failures + 1 ))
elif ! printf '%s' "$out" | grep -qi -- "--route"; then
    echo "FAIL shot.sh --route: rejection message did not mention --route" >&2
    printf '%s\n' "$out" | sed 's/^/    /' >&2
    failures=$(( failures + 1 ))
elif [[ -f "$GODOT_MARKER" ]]; then
    echo "FAIL shot.sh --route: launched Godot despite the conflict" >&2
    failures=$(( failures + 1 ))
else
    echo "ok   shot.sh --route (implicit --screenshot) is refused before any launch"
fi

# test.sh's own --shard and --record-costs get the same treatment as the rest of tools/: every
# malformed shape is rejected -- usage, non-zero, no launch -- before the import pass that would
# otherwise touch the Godot stub.
assert_exit "test.sh --shard (missing value)" nonzero ./tools/test.sh --shard
assert_exit "test.sh --shard (not I/N)"       nonzero ./tools/test.sh --shard bogus
assert_exit "test.sh --shard 9/8 (I > N)"     nonzero ./tools/test.sh --shard 9/8
assert_exit "test.sh --shard 0/8 (I < 1)"     nonzero ./tools/test.sh --shard 0/8
assert_exit "test.sh --record-costs (with a filter)" nonzero ./tools/test.sh --record-costs bogus

if [[ -e "$work_dir/shot-out.png" || -e "$work_dir/shot-out2.png" ]]; then
    echo "FAIL: a rejected shot.sh run wrote its output file anyway" >&2
    failures=$(( failures + 1 ))
fi

# --------------------------------- resolve-decisions-top.sh: the one-hunk merge conflict shape ---
# assert_exit's Godot-stub harness has nothing to say about a merge conflict, so this builds a
# throwaway repo under $work_dir and drives an actual `git merge --no-ff --no-commit` to get the
# real diff3/zdiff3 markers the script parses. One case resolves the shape it targets; three
# refuse it (non-empty base, more than one hunk, a hunk that is not directly under # Decisions)
# and must leave the conflicted file byte-for-byte as the merge left it.
decisions_repo="$work_dir/decisions-repo"
setup_decisions_repo() {
    rm -rf "$decisions_repo"
    mkdir -p "$decisions_repo/docs" "$decisions_repo/tools"
    cp "$root/tools/resolve-decisions-top.sh" "$decisions_repo/tools/"
    git init -q -b main "$decisions_repo"
    git -C "$decisions_repo" config user.email test@example.com
    git -C "$decisions_repo" config user.name test
    git -C "$decisions_repo" config merge.conflictstyle zdiff3
}
# $1 base content  $2 branch content  $3 main content -- leaves feature checked out mid-merge,
# docs/DECISIONS.md conflicted.
decisions_conflict() {
    printf '%s' "$1" > "$decisions_repo/docs/DECISIONS.md"
    git -C "$decisions_repo" add docs/DECISIONS.md
    git -C "$decisions_repo" commit -q -m base
    git -C "$decisions_repo" checkout -q -b feature
    printf '%s' "$2" > "$decisions_repo/docs/DECISIONS.md"
    git -C "$decisions_repo" commit -q -am branch
    git -C "$decisions_repo" checkout -q main
    printf '%s' "$3" > "$decisions_repo/docs/DECISIONS.md"
    git -C "$decisions_repo" commit -q -am main
    git -C "$decisions_repo" checkout -q feature
    git -C "$decisions_repo" merge --no-ff --no-commit main >/dev/null 2>&1
}

setup_decisions_repo
decisions_conflict \
    $'# Decisions\n' \
    $'# Decisions\n\n## Branch section\n\nBranch body.\n' \
    $'# Decisions\n\n## Main section\n\nMain body.\n'
checks=$(( checks + 1 ))
out="$(cd "$decisions_repo" && ./tools/resolve-decisions-top.sh 2>&1)"
status=$?
result="$(cat "$decisions_repo/docs/DECISIONS.md")"
expected=$'# Decisions\n\n## Branch section\n\nBranch body.\n\n## Main section\n\nMain body.'
unmerged="$(git -C "$decisions_repo" diff --name-only --diff-filter=U)"
staged="$(git -C "$decisions_repo" diff --cached --name-only)"
unstaged="$(git -C "$decisions_repo" diff --name-only)"
if [[ $status -ne 0 ]]; then
    echo "FAIL resolve-decisions-top.sh two-sided insertion: expected exit 0, got $status" >&2
    printf '%s\n' "$out" | sed 's/^/    /' >&2
    failures=$(( failures + 1 ))
elif [[ "$result" != "$expected" ]]; then
    echo "FAIL resolve-decisions-top.sh two-sided insertion: unexpected result" >&2
    printf '%s\n' "$result" | sed 's/^/    /' >&2
    failures=$(( failures + 1 ))
elif [[ -n "$unmerged" || -n "$unstaged" || "$staged" != "docs/DECISIONS.md" ]]; then
    echo "FAIL resolve-decisions-top.sh two-sided insertion: file not cleanly staged" \
        "(unmerged=[$unmerged] staged=[$staged] unstaged=[$unstaged])" >&2
    failures=$(( failures + 1 ))
else
    echo "ok   resolve-decisions-top.sh resolves the two-sided insertion, ours above theirs, and stages it"
fi

setup_decisions_repo
decisions_conflict \
    $'# Decisions\n\n## Old section\n\nOld body.\n' \
    $'# Decisions\n\n## Old section\n\nBranch body.\n' \
    $'# Decisions\n\n## Old section\n\nMain body.\n'
before="$(cat "$decisions_repo/docs/DECISIONS.md")"
checks=$(( checks + 1 ))
out="$(cd "$decisions_repo" && ./tools/resolve-decisions-top.sh 2>&1)"
status=$?
after="$(cat "$decisions_repo/docs/DECISIONS.md")"
if [[ $status -eq 0 ]]; then
    echo "FAIL resolve-decisions-top.sh non-empty base: expected a non-zero exit, got 0" >&2
    failures=$(( failures + 1 ))
elif [[ "$after" != "$before" ]]; then
    echo "FAIL resolve-decisions-top.sh non-empty base: the conflicted file changed despite refusal" >&2
    failures=$(( failures + 1 ))
elif ! printf '%s' "$out" | grep -qi "not empty"; then
    echo "FAIL resolve-decisions-top.sh non-empty base: refusal message did not name the base" >&2
    printf '%s\n' "$out" | sed 's/^/    /' >&2
    failures=$(( failures + 1 ))
else
    echo "ok   resolve-decisions-top.sh refuses a non-empty base and leaves the file untouched"
fi

setup_decisions_repo
decisions_conflict \
    $'# Decisions\n\n## Section A\n\nbody a\n\n## Section B\n\nbody b\n' \
    $'# Decisions\n\n## Section A\n\nbody a branch\n\n## Section B\n\nbody b branch\n' \
    $'# Decisions\n\n## Section A\n\nbody a main\n\n## Section B\n\nbody b main\n'
before="$(cat "$decisions_repo/docs/DECISIONS.md")"
checks=$(( checks + 1 ))
out="$(cd "$decisions_repo" && ./tools/resolve-decisions-top.sh 2>&1)"
status=$?
after="$(cat "$decisions_repo/docs/DECISIONS.md")"
if [[ $status -eq 0 ]]; then
    echo "FAIL resolve-decisions-top.sh two hunks: expected a non-zero exit, got 0" >&2
    failures=$(( failures + 1 ))
elif [[ "$after" != "$before" ]]; then
    echo "FAIL resolve-decisions-top.sh two hunks: the conflicted file changed despite refusal" >&2
    failures=$(( failures + 1 ))
elif ! printf '%s' "$out" | grep -qi "one hunk"; then
    echo "FAIL resolve-decisions-top.sh two hunks: refusal message did not name the hunk count" >&2
    printf '%s\n' "$out" | sed 's/^/    /' >&2
    failures=$(( failures + 1 ))
else
    echo "ok   resolve-decisions-top.sh refuses more than one hunk and leaves the file untouched"
fi

setup_decisions_repo
decisions_conflict \
    $'# Decisions\n\n## Existing\n\nExisting body.\n' \
    $'# Decisions\n\n## Existing\n\nExisting body.\n\n## Branch new\n\nbranch body\n' \
    $'# Decisions\n\n## Existing\n\nExisting body.\n\n## Main new\n\nmain body\n'
before="$(cat "$decisions_repo/docs/DECISIONS.md")"
checks=$(( checks + 1 ))
out="$(cd "$decisions_repo" && ./tools/resolve-decisions-top.sh 2>&1)"
status=$?
after="$(cat "$decisions_repo/docs/DECISIONS.md")"
if [[ $status -eq 0 ]]; then
    echo "FAIL resolve-decisions-top.sh hunk elsewhere: expected a non-zero exit, got 0" >&2
    failures=$(( failures + 1 ))
elif [[ "$after" != "$before" ]]; then
    echo "FAIL resolve-decisions-top.sh hunk elsewhere: the conflicted file changed despite refusal" >&2
    failures=$(( failures + 1 ))
elif ! printf '%s' "$out" | grep -qi "directly under"; then
    echo "FAIL resolve-decisions-top.sh hunk elsewhere: refusal message did not name the location" >&2
    printf '%s\n' "$out" | sed 's/^/    /' >&2
    failures=$(( failures + 1 ))
else
    echo "ok   resolve-decisions-top.sh refuses a hunk that is not directly under # Decisions"
fi
rm -rf "$decisions_repo"

# ---------------------------- README.md's Dev flags table stays in step with DEV_FLAG_TABLE ---
# The table in src/dev/dev_flags.gd is the accept-list run.sh and shot.sh validate against and
# is shape only (see lib_dev_flags.sh); README.md's "Dev flags" section is the semantics -- what
# each flag means. Nothing enforces the two staying in step except this: every flag named in the
# table must still appear, literally, somewhere in that one section.
PROJECT_DIR="$root"
# shellcheck source=tools/lib_dev_flags.sh
source "$root/tools/lib_dev_flags.sh"
readme_section="$(sed -n '/^## Dev flags$/,/^## /p' "$root/README.md" | sed '$d')"
while read -r flag; do
    checks=$(( checks + 1 ))
    if printf '%s' "$readme_section" | grep -qF -- "$flag"; then
        echo "ok   README documents $flag"
    else
        echo "FAIL $flag is in dev_flags.gd's DEV_FLAG_TABLE but not in README.md's Dev flags section" >&2
        failures=$(( failures + 1 ))
    fi
done < <(dev_flag_names)

# --------------------- tools/trailer.sh's kill deadline follows the shot's length, not the day's ---
# rig_kill_after_movie_seconds only reads --after/--day-length out of the argv it is given --
# passing it a bare number (tools/trailer.sh once did: `rig_kill_after_movie_seconds "$after"`)
# silently falls back to the day's own length times RIG_MOVIE_SLOWDOWN, killing a hung Godot after
# about 38 minutes instead of about 4 for a short shot. Checked two ways: the function itself
# answers differently for a short --after than for none at all, and trailer.sh's own call site is
# grepped for the exact --after shape rather than a bare value, which is the one thing that would
# have caught this regression at the source instead of only in the function's own unit shape.
checks=$(( checks + 1 ))
short_kill="$(rig_kill_after_movie_seconds --after 5)"
long_kill="$(rig_kill_after_movie_seconds)"
if [[ "$short_kill" -lt "$long_kill" ]]; then
    echo "ok   rig_kill_after_movie_seconds follows --after ($short_kill < $long_kill)"
else
    echo "FAIL rig_kill_after_movie_seconds did not shorten for a short --after ($short_kill vs $long_kill)" >&2
    failures=$(( failures + 1 ))
fi

checks=$(( checks + 1 ))
if grep -qE 'rig_kill_after_movie_seconds +--after +"\$after"' "$root/tools/trailer.sh"; then
    echo "ok   trailer.sh calls rig_kill_after_movie_seconds with --after, not a bare value"
else
    echo "FAIL trailer.sh's call to rig_kill_after_movie_seconds does not pass --after \"\$after\" -- a hung Godot would be killed after the day's own length instead of the shot's" >&2
    failures=$(( failures + 1 ))
fi

# ------------------- every tools/*.sh and tools/*.py entry point has a row in using-tools ---
# The using-tools skill's catalogue is the point of this check -- a tool that is not in it is
# undocumented the way audit-pck.sh, export-web.sh, release.sh, serve-web.sh and stats.sh used to
# be. lib_* and test_* are helpers and this suite's own files, not entry points a person reaches
# for, so they carry no row and are excluded here the same way they are excluded from the skill.
catalogue="$root/.claude/skills/using-tools/SKILL.md"
for f in "$root"/tools/*.sh "$root"/tools/*.py; do
    name="$(basename "$f")"
    case "$name" in
        lib_*|test_*) continue ;;
    esac
    checks=$(( checks + 1 ))
    if grep -qF -- "\`tools/$name\`" "$catalogue"; then
        echo "ok   using-tools catalogues $name"
    else
        echo "FAIL $name has no row in .claude/skills/using-tools/SKILL.md's catalogue" >&2
        failures=$(( failures + 1 ))
    fi
done

echo
echo "$checks checks, $failures failures"
if [[ "$failures" -gt 0 ]]; then
    exit 1
fi
