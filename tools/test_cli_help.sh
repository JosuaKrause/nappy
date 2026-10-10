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
    if ! grep -qi usage <<<"$out"; then
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
assert_exit "scene-recipes.sh --help" zero ./tools/scene-recipes.sh --help
assert_exit "scene-recipes.sh -h" zero ./tools/scene-recipes.sh -h
assert_exit "scene-recipes.sh unknown" nonzero ./tools/scene-recipes.sh --not-a-flag
assert_exit "scene-recipes.sh missing value" nonzero ./tools/scene-recipes.sh --recipe
assert_exit "scene-draft.sh --help" zero ./tools/scene-draft.sh --help
assert_exit "scene-draft.sh -h" zero ./tools/scene-draft.sh -h
assert_exit "scene-draft.sh unknown" nonzero ./tools/scene-draft.sh --not-a-flag
assert_exit "scene-draft.sh missing value" nonzero ./tools/scene-draft.sh --recipe
assert_exit "scene-draft.sh no destination" nonzero ./tools/scene-draft.sh --recipe scene-recipes/task-07-package.json
assert_exit "scene-draft.sh two destinations" nonzero ./tools/scene-draft.sh --recipe scene-recipes/task-07-package.json --in-place --output "$work_dir/draft.json"

# A crashed coverage pass and a body still in the void never overwrite an author's recipe.
# This stub runs the actual three-round shell workflow without launching the engine.
draft_stub="$work_dir/draft-stub.sh"
cat > "$draft_stub" <<'EOF'
#!/usr/bin/env bash
set -eu
draft=""
manifest=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --recipe-draft) draft="$2"; shift 2 ;;
        --recipe-manifest) manifest="$2"; shift 2 ;;
        *) shift ;;
    esac
done
if [[ -n "$draft" ]]; then
    cp "$NAPPY_DRAFT_TEST_SOURCE" "$draft"
elif [[ -n "$manifest" ]]; then
    case "$NAPPY_DRAFT_TEST_CASE" in
        crash) exit 9 ;;
        missing) exit 0 ;;
        error) echo 'SCRIPT ERROR: coverage crashed'; exit 0 ;;
        incomplete) echo '{"playback_complete":false}' > "$manifest" ;;
        included) echo '{"playback_complete":true,"in_the_void":[{"tile":[20,20]}]}' > "$manifest" ;;
        rounds)
            round=0
            [[ ! -f "$NAPPY_DRAFT_TEST_STATE" ]] || round="$(cat "$NAPPY_DRAFT_TEST_STATE")"
            round=$((round + 1))
            echo "$round" > "$NAPPY_DRAFT_TEST_STATE"
            printf '{"playback_complete":true,"in_the_void":[{"tile":[%d,20]}]}' "$((20 + round))" > "$manifest" ;;
    esac
fi
EOF
chmod +x "$draft_stub"
printf '{"draft":{"include":[[20,20]]},"playback":{"observations":[]}}\n' > "$work_dir/draft-input.json"
for failure_case in crash missing error incomplete included rounds; do
    checks=$((checks + 1))
    destination="$work_dir/draft-$failure_case.json"
    printf 'keep the authored file\n' > "$destination"
    if NAPPY_DRAFT_TEST_SOURCE="$work_dir/draft-input.json" NAPPY_DRAFT_TEST_CASE="$failure_case" \
            NAPPY_DRAFT_TEST_STATE="$work_dir/round-count" GODOT="$draft_stub" \
            ./tools/scene-draft.sh --recipe "$work_dir/draft-input.json" --output "$destination" \
            >"$work_dir/draft-$failure_case.log" 2>&1 \
            || [[ "$(cat "$destination")" != 'keep the authored file' ]] \
            || [[ ! -s "$destination.rejected" ]]; then
        echo "FAIL scene-draft.sh must reject $failure_case and retain the draft" >&2
        cat "$work_dir/draft-$failure_case.log" >&2
        failures=$((failures + 1))
    else
        echo "ok   scene-draft.sh rejects $failure_case and preserves the authored file"
    fi
done
assert_exit "measure-ground-frames.sh --help" zero ./tools/measure-ground-frames.sh --help
assert_exit "measure-ground-frames.sh -h" zero ./tools/measure-ground-frames.sh -h
assert_exit "measure-ground-frames.sh unknown" nonzero ./tools/measure-ground-frames.sh --not-a-flag
assert_exit "measure-ground-frames.sh missing engine" nonzero ./tools/measure-ground-frames.sh --godot
assert_exit "measure-ground-frames.sh missing output" nonzero ./tools/measure-ground-frames.sh --output
assert_exit "measure-ground-frames.sh stray" nonzero ./tools/measure-ground-frames.sh stray
assert_exit "measure-ground-frames.sh validates before mkdir" nonzero ./tools/measure-ground-frames.sh --output "$work_dir/unwanted-measurement" --not-a-flag
if [[ -e "$work_dir/unwanted-measurement" ]]; then
    echo "FAIL measure-ground-frames.sh created output on invalid arguments" >&2
    failures=$((failures + 1))
fi
assert_exit "lint.sh --help"       zero ./tools/lint.sh --help
assert_exit "pycheck.sh --help"    zero ./tools/pycheck.sh --help
assert_exit "export-web.sh --help" zero ./tools/export-web.sh --help
assert_exit "build-web-template.sh --help" zero ./tools/build-web-template.sh --help
assert_exit "build-web-template.sh -h" zero ./tools/build-web-template.sh -h
assert_exit "build-web-template.sh unknown" nonzero ./tools/build-web-template.sh --not-a-flag
assert_exit "build-web-template.sh missing jobs" nonzero ./tools/build-web-template.sh --jobs
assert_exit "build-web-template.sh invalid jobs" nonzero ./tools/build-web-template.sh --jobs 0
assert_exit "build-web-template.sh stray word" nonzero ./tools/build-web-template.sh stray
assert_exit "measure-disk-peak.sh --help" zero ./tools/measure-disk-peak.sh --help
assert_exit "measure-disk-peak.sh -h" zero ./tools/measure-disk-peak.sh -h
assert_exit "measure-disk-peak.sh unknown" nonzero ./tools/measure-disk-peak.sh --not-a-flag
assert_exit "measure-disk-peak.sh missing path" nonzero ./tools/measure-disk-peak.sh --path
assert_exit "measure-disk-peak.sh no command" nonzero ./tools/measure-disk-peak.sh --path build
assert_exit "measure-disk-peak.sh zero interval" nonzero ./tools/measure-disk-peak.sh --interval 0 --path build -- true
assert_exit "measure-disk-peak.sh validates before running" nonzero ./tools/measure-disk-peak.sh --path "$work_dir" --not-a-flag -- touch "$work_dir/measured-command-ran"
if [[ -e "$work_dir/measured-command-ran" ]]; then
    echo "FAIL measure-disk-peak.sh ran its command on invalid arguments" >&2
    failures=$((failures + 1))
fi
assert_exit "browser-check.mjs help" zero node ./tools/web-template/browser-check.mjs --help
assert_exit "browser-check.mjs unknown" nonzero node ./tools/web-template/browser-check.mjs --not-a-flag
assert_exit "browser-check.mjs missing value" nonzero node ./tools/web-template/browser-check.mjs --export
assert_exit "compare.mjs help" zero node ./tools/web-template/compare.mjs --help
assert_exit "compare.mjs unknown" nonzero node ./tools/web-template/compare.mjs --not-a-flag
assert_exit "compare.mjs missing value" nonzero node ./tools/web-template/compare.mjs --export

if [[ "$(node -p 'Number(process.versions.node.split(".")[0])')" -ge 22 ]]; then
    browser_fixture="$work_dir/browser-startup"
    mkdir -p "$browser_fixture"
    printf '#!/bin/sh\nexit 0\n' > "$browser_fixture/not-executable"
    for browser_case in missing not-executable; do
        checks=$(( checks + 1 ))
        TMPDIR="$browser_fixture" node tools/web-template/browser-check.mjs \
            --export "$browser_fixture" --output "$browser_fixture/$browser_case-result" \
            --browser "$browser_fixture/$browser_case" > "$browser_fixture/$browser_case.log" 2>&1
        browser_status=$?
        browser_result="$browser_fixture/$browser_case-result/result.json"
        if [[ "$browser_status" -eq 0 ]] || ! grep -q '"success": false' "$browser_result" \
                || ! grep -Eq 'ENOENT|EACCES' "$browser_result" \
                || [[ -n "$(find "$browser_fixture" -maxdepth 1 -name 'nappy-web-check-*' -print)" ]]; then
            echo "FAIL browser startup $browser_case did not report failure and clean its profile" >&2
            failures=$(( failures + 1 ))
        else
            echo "ok   browser startup $browser_case reports failure and cleans its profile"
        fi
    done
else
    echo "skip browser startup lifecycle checks (requires Node 22; web-template CI runs them)"
fi

# A cached template must belong to these exact build inputs and its bytes must still match.
# The fake archive is deliberate: this checks invalidation without compiling an engine.
template_repo="$work_dir/template-repo"
mkdir -p "$template_repo/tools/web-template"
cp tools/build-web-template.sh "$template_repo/tools/"
cp tools/web-template/profile.args tools/web-template/pins.env "$template_repo/tools/web-template/"
template_key="$("$template_repo/tools/build-web-template.sh" --key)"
checks=$(( checks + 1 ))
if [[ -e "$template_repo/build" ]] || "$template_repo/tools/build-web-template.sh" --verify >/dev/null 2>&1; then
    echo "FAIL template lookup writes or accepts a missing artifact" >&2
    failures=$(( failures + 1 ))
fi
mkdir -p "$template_repo/build/web-template"
printf 'fixture template\n' > "$template_repo/build/web-template/template.zip"
template_hash="$(shasum -a 256 "$template_repo/build/web-template/template.zip" | awk '{print $1}')"
printf '%s %s\n' "$template_key" "$template_hash" > "$template_repo/build/web-template/receipt"
checks=$(( checks + 1 ))
if ! "$template_repo/tools/build-web-template.sh" --verify >/dev/null; then
    echo "FAIL matching template receipt rejected" >&2
    failures=$(( failures + 1 ))
fi
printf 'corruption\n' >> "$template_repo/build/web-template/template.zip"
checks=$(( checks + 1 ))
if "$template_repo/tools/build-web-template.sh" --verify >/dev/null 2>&1; then
    echo "FAIL corrupted template accepted" >&2
    failures=$(( failures + 1 ))
fi
printf 'fixture template\n' > "$template_repo/build/web-template/template.zip"
printf '\n# changed input\n' >> "$template_repo/tools/web-template/profile.args"
checks=$(( checks + 1 ))
if "$template_repo/tools/build-web-template.sh" --verify >/dev/null 2>&1; then
    echo "FAIL stale profile template accepted" >&2
    failures=$(( failures + 1 ))
fi
assert_exit "serve-web.sh --help"  zero ./tools/serve-web.sh --help
assert_exit "sound-lab.sh --help"  zero ./tools/sound-lab.sh --help
assert_exit "sound-lab.sh -h"      zero ./tools/sound-lab.sh -h
assert_exit "release.sh --help"    zero ./tools/release.sh --help
assert_exit "run.sh --help"        zero ./tools/run.sh --help
assert_exit "shot.sh --help"       zero ./tools/shot.sh --help
assert_exit "trailer.sh --help"    zero ./tools/trailer.sh --help
assert_exit "trailer.sh -h"        zero ./tools/trailer.sh -h
trailer_list="$(./tools/trailer.sh --list)"
trailer_rows="$(printf '%s\n' "$trailer_list" | awk 'NR > 1 && $1 != "total" { print $1, $2 }')"
trailer_expected_rows="$(jq -r '.shots[] | "\(.name) \(.kind // "scene")"' tools/trailer/shots.json)"
trailer_reported_total="$(printf '%s\n' "$trailer_list" | awk '/^total / { sub(/s$/, "", $2); print $2 }')"
trailer_expected_total="$(jq -r '[.shots[] | (.gap // 0) + .length] | add' tools/trailer/shots.json)"
checks=$(( checks + 1 ))
if [[ "$trailer_rows" == "$trailer_expected_rows" ]] \
    && awk -v reported="$trailer_reported_total" -v expected="$trailer_expected_total" \
        'BEGIN { exit !((reported - expected)^2 < 0.0001) }'; then
    echo "ok   trailer.sh --list reports every configured shot and the cut's total"
else
    echo "FAIL trailer.sh --list disagrees with its shot list" >&2
    failures=$(( failures + 1 ))
fi
assert_exit "record.sh --help"     zero ./tools/record.sh --help
assert_exit "record.sh -h"         zero ./tools/record.sh -h
assert_exit "stats.sh --help"      zero ./tools/stats.sh --help
assert_exit "telemetry.sh --help"  zero ./tools/telemetry.sh --help
assert_exit "test.sh --help"       zero ./tools/test.sh --help
assert_exit "clip.sh --help"       zero ./tools/clip.sh --help
assert_exit "reference.sh --help"  zero ./tools/reference.sh --help
assert_exit "goatcounter.sh --help" zero ./tools/goatcounter.sh --help
assert_exit "goatcounter.sh -h"     zero ./tools/goatcounter.sh -h
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
assert_exit "update-pr.sh --help" zero ./tools/update-pr.sh --help
assert_exit "update-pr.sh -h"     zero ./tools/update-pr.sh -h
assert_exit "land-prs.sh --help" zero ./tools/land-prs.sh --help
assert_exit "land-prs.sh -h"     zero ./tools/land-prs.sh -h
assert_exit "new-name.sh --help" zero ./tools/new-name.sh --help
assert_exit "new-name.sh -h"     zero ./tools/new-name.sh -h
assert_exit "decisions.sh --help" zero ./tools/decisions.sh --help
assert_exit "decisions.sh -h"     zero ./tools/decisions.sh -h
assert_exit "queue.sh --help" zero ./tools/queue.sh --help
assert_exit "queue.sh -h"     zero ./tools/queue.sh -h

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
assert_exit "sound-lab.sh --bogus"    nonzero ./tools/sound-lab.sh --bogus
assert_exit "sound-lab.sh --pass (there is one pass; the flag is gone)" nonzero ./tools/sound-lab.sh --pass pass-4
assert_exit "sound-lab.sh (bad port)" nonzero ./tools/sound-lab.sh notaport
assert_exit "release.sh --bogus"      nonzero ./tools/release.sh --bogus
assert_exit "run.sh --bogus"          nonzero ./tools/run.sh --bogus
assert_exit "shot.sh --bogus"         nonzero ./tools/shot.sh "$work_dir/shot-out.png" 1 --bogus
assert_exit "trailer.sh --bogus"      nonzero ./tools/trailer.sh --bogus
assert_exit "trailer.sh --shot (missing name)" nonzero ./tools/trailer.sh --shot
assert_exit "trailer.sh --check-load (missing name)" nonzero ./tools/trailer.sh --check-load
assert_exit "trailer.sh --validate --shot (combined)" nonzero ./tools/trailer.sh --validate --shot choice
assert_exit "trailer.sh --list --shot (combined)" nonzero ./tools/trailer.sh --list --shot choice
assert_exit "trailer.sh --list --auditions (combined)" nonzero ./tools/trailer.sh --list --auditions
assert_exit "trailer.sh --selected --selected-remix (combined)" nonzero ./tools/trailer.sh --selected --selected-remix
assert_exit "record.sh --bogus"       nonzero ./tools/record.sh --bogus
assert_exit "record.sh (no flags)"    nonzero ./tools/record.sh
assert_exit "record.sh --this-is-not-a-dev-flag" nonzero ./tools/record.sh --this-is-not-a-dev-flag
assert_exit "record.sh --out (missing name)" nonzero ./tools/record.sh --out
assert_exit "record.sh --out --recipe (missing name)" nonzero ./tools/record.sh --out --recipe scene.json
assert_exit "record.sh --recipe-validate (owned)" nonzero ./tools/record.sh --recipe-validate
assert_exit "record.sh refuses free recipe before launch" nonzero env GODOT=/missing/godot ./tools/record.sh --recipe scene.json --recipe-mode free
assert_exit "stats.sh --bogus"        nonzero ./tools/stats.sh --bogus
assert_exit "telemetry.sh --bogus"    nonzero ./tools/telemetry.sh --bogus
assert_exit "clip.sh --bogus"         nonzero ./tools/clip.sh --bogus
assert_exit "reference.sh --bogus"    nonzero ./tools/reference.sh --bogus
assert_exit "goatcounter.sh --bogus"  nonzero ./tools/goatcounter.sh --bogus
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
assert_exit "new-name.sh --bogus" nonzero ./tools/new-name.sh --bogus todo "x"
# A name with no kind or no title would write an empty or an unfindable thing, so it writes none.
assert_exit "new-name.sh (no title)" nonzero ./tools/new-name.sh todo
assert_exit "new-name.sh (unknown kind)" nonzero ./tools/new-name.sh entry "x"
assert_exit "new-name.sh --entry on a todo" nonzero ./tools/new-name.sh todo --entry M1 "x"
assert_exit "new-name.sh --priority on a review" nonzero ./tools/new-name.sh review --priority now "x"
assert_exit "new-name.sh --priority (unknown band)" nonzero ./tools/new-name.sh todo --priority soon "x"
assert_exit "new-name.sh --priority (missing value)" nonzero ./tools/new-name.sh todo --priority
assert_exit "decisions.sh --bogus" nonzero ./tools/decisions.sh --bogus
assert_exit "decisions.sh --in (unknown folder)" nonzero ./tools/decisions.sh --in archive M129
assert_exit "queue.sh --bogus" nonzero ./tools/queue.sh --bogus
assert_exit "queue.sh --band (unknown band)" nonzero ./tools/queue.sh --band soon
assert_exit "queue.sh --band (missing value)" nonzero ./tools/queue.sh --band
assert_exit "queue.sh (a stray word)" nonzero ./tools/queue.sh next

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
elif ! grep -qi -- "--route" <<<"$out"; then
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
    if grep -qF -- "$flag" <<<"$readme_section"; then
        echo "ok   README documents $flag"
    else
        echo "FAIL $flag is in dev_flags.gd's DEV_FLAG_TABLE but not in README.md's Dev flags section" >&2
        failures=$(( failures + 1 ))
    fi
done < <(dev_flag_names)

# --------------------- tools/trailer.sh's kill deadline follows the shot's length, not the day's ---
checks=$(( checks + 1 ))
if rig_flag_present --recipe scene.json --recipe-mode scripted \
    && ! rig_flag_present --recipe scene.json \
    && ! rig_flag_present --recipe-mode free --recipe scene.json; then
    echo "ok   scripted recipes are supervised while free recipes keep physical input"
else
    echo "FAIL recipe rig detection disagrees with the game" >&2
    failures=$(( failures + 1 ))
fi

checks=$(( checks + 1 ))
free_record_output="$(GODOT=/missing/godot ./tools/record.sh --recipe scene.json --recipe-mode free 2>&1)"
if [[ "$free_record_output" == *"requires --recipe-mode scripted"* ]]; then
    echo "ok   free recipe recording is refused before checking Godot"
else
    echo "FAIL free recipe recording lacks its specific mode diagnostic" >&2
    failures=$(( failures + 1 ))
fi

checks=$(( checks + 1 ))
cp scene-recipes/trailer-birds.json "$work_dir/relative.json"
relative_output="$(cd "$work_dir" && GODOT="$GODOT_STUB" "$root/tools/scene-recipes.sh" --recipe relative.json --output captures 2>&1)"
if [[ "$relative_output" == *"scene assertions failed:"*"relative.json"*"log:"* ]] \
    && grep -qF "$work_dir/relative.json" "$GODOT_ARGS"; then
    echo "ok   caller-relative recipes are resolved and failed assertions name their log"
else
    echo "FAIL caller-relative recipe or failure diagnostic: $relative_output" >&2
    failures=$(( failures + 1 ))
fi
# A successful engine exit and passing manifest must not hide its diagnostics, on either
# the action or screenshot path. The capture stub writes the still and provenance too.
# Exercise the real runner and shot wrapper without depending on this checkout's baked art:
# the no-Godot Linux gate has no atlas cache, and its engine stub cannot repair one. Only that
# unrelated prerequisite is stubbed; flag validation, process supervision and log checks stay real.
recipe_project="$work_dir/recipe-project"
mkdir -p "$recipe_project/tools" "$recipe_project/src/dev"
cp tools/scene-recipes.sh tools/shot.sh tools/lib_dev_flags.sh tools/lib_disk_headroom.sh "$recipe_project/tools/"
cp src/dev/dev_flags.gd "$recipe_project/src/dev/"
printf '#!/usr/bin/env bash\nexit 0\n' > "$recipe_project/tools/bake-atlases.sh"
chmod +x "$recipe_project/tools/bake-atlases.sh"
recipe_stub="$work_dir/recipe-stub.sh"
cat > "$recipe_stub" <<'EOF'
#!/usr/bin/env bash
set -eu
capture=false
manifest=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --recipe-manifest) manifest="$2"; shift 2 ;;
        --screenshot) capture=true; touch "$2"; shift 2 ;;
        *) shift ;;
    esac
done
[[ -z "$manifest" ]] || echo '{"playback_complete":true,"observations":[{"passed":true}]}' > "$manifest"
if $capture; then
    touch "$NAPPY_RECIPE_TEST_LOG"
    echo "[Telemetry] $NAPPY_RECIPE_TEST_LOG"
fi
if [[ "$NAPPY_RECIPE_TEST_PATH" == action ]] || $capture; then
    echo "$NAPPY_RECIPE_TEST_ERROR"
fi
exit 0
EOF
chmod +x "$recipe_stub"
for diagnostic in 'ERROR: denied' 'SCRIPT ERROR: failed' 'Parse Error: invalid'; do
    for action_path in action capture; do
        checks=$((checks + 1))
        if NAPPY_RECIPE_TEST_ERROR="$diagnostic" NAPPY_RECIPE_TEST_PATH="$action_path" \
                NAPPY_RECIPE_TEST_LOG="$work_dir/recipe-run.log" GODOT="$recipe_stub" \
                "$recipe_project/tools/scene-recipes.sh" --recipe "$work_dir/relative.json" \
                --output "$work_dir/recipe-diagnostic" --screenshots > "$work_dir/diagnostic.log" 2>&1; then
            echo "FAIL scene-recipes accepts $action_path $diagnostic" >&2
            failures=$((failures + 1))
        elif ! grep -qE 'scene assertions failed:|scene capture engine error:' "$work_dir/diagnostic.log"; then
            echo "FAIL scene-recipes rejected $action_path for the wrong reason" >&2
            cat "$work_dir/diagnostic.log" >&2
            [[ ! -f "$work_dir/recipe-diagnostic/relative-start-capture.log" ]] || \
                cat "$work_dir/recipe-diagnostic/relative-start-capture.log" >&2
            failures=$((failures + 1))
        else
            echo "ok   scene-recipes rejects $action_path $diagnostic despite exit 0"
        fi
    done
done
source "$root/tools/lib_movie_evidence.sh"
for scope in bounded full stretch unknown; do
    printf '{"classification":"normal","scope":"%s","bounds":[0,0,10,10]}' "$scope" > "$work_dir/movie.json"
    checks=$((checks + 1))
    movie_manifest_check "$work_dir/movie.json" > "$work_dir/movie-check.log" 2>&1
    status=$?
    if { [[ "$scope" == unknown ]] && [[ "$status" -ne 0 ]]; } \
            || { [[ "$scope" != unknown ]] && [[ "$status" -eq 0 ]]; }; then
        echo "ok   movie manifest checks scope $scope"
    else
        echo "FAIL movie manifest scope $scope returned $status" >&2
        failures=$((failures + 1))
    fi
done

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

# ------------------------------------------------- new-name.sh and decisions.sh, on a scratch tree ---
# Both work on the repository they sit in, so they are copied into a throwaway tree with a docs/
# of its own: new-name.sh must write what it names and never reuse a pair of words, and
# decisions.sh must find a record by its title and by its text.
names_repo="$work_dir/names-repo"
mkdir -p "$names_repo/tools/names" "$names_repo/docs/todo/2026-09-26-M210" "$names_repo/docs/decisions" \
    "$names_repo/docs/review" "$names_repo/docs/playtests"
cp "$root/tools/new-name.sh" "$root/tools/decisions.sh" "$root/tools/queue.sh" "$names_repo/tools/"
printf 'busy\n' > "$names_repo/tools/names/adjectives.txt"
printf 'badger\notter\n' > "$names_repo/tools/names/animals.txt"
printf 'priority: next\n\n## M210 — The brief is the coming day\x27s · asked for 2026-09-26\n' \
    > "$names_repo/docs/todo/2026-09-26-M210/README.md"
printf '# Playtest busy-badger — Taken\n' > "$names_repo/docs/playtests/2026-09-01-busy-badger.md"

check_that() {
    checks=$(( checks + 1 ))
    if eval "$2"; then
        echo "ok   $1"
    else
        echo "FAIL $1" >&2
        failures=$(( failures + 1 ))
    fi
}

# ------------------------------------------------ wait_or_kill leaves nothing holding the pipe ---
# The process lives 0.3s, long enough for the watchdog to have forked its `sleep 7`. The call's
# output is captured, so the command substitution only returns once every holder of the pipe has
# closed it: a watchdog `sleep` that outlived wait_or_kill would keep it open for the whole 7s.
wok_started=$SECONDS
wok_out="$(
    # shellcheck source=tools/lib_dev_flags.sh
    source "$root/tools/lib_dev_flags.sh"
    sleep 0.3 &
    wait_or_kill "$!" 7
    echo "returned $? status $WAIT_OR_KILL_STATUS"
)"
wok_elapsed=$(( SECONDS - wok_started ))
check_that "wait_or_kill returns at once for a process that exited, with no watchdog holding the pipe" \
    '[[ "$wok_out" == "returned 0 status 0" && $wok_elapsed -lt 5 ]]'

# A limit that is not whole seconds is refused, never turned into an instant kill, and the
# caller's own fd 9 is the same file after a call as before it.
wok_fd_file="$work_dir/wok-fd9"
wok_out="$(
    # shellcheck source=tools/lib_dev_flags.sh
    source "$root/tools/lib_dev_flags.sh"
    exec 9>"$wok_fd_file"
    sleep 0.2 &
    sleep 30 &
    wok_bad=$!
    wait_or_kill "$wok_bad" 1.5 2>&1
    echo "rc $?"
    kill -0 "$wok_bad" 2>/dev/null && echo "bad-limit process still running"
    sleep 0.2 &
    wait_or_kill "$!" 5
    echo "after" >&9
    echo "fd9 ok"
)"
check_that "wait_or_kill refuses a limit that is not whole seconds and leaves the caller's fd 9 alone" \
    '[[ "$wok_out" == *"limit must be whole seconds"*"rc 2"*"fd9 ok" && "$wok_out" != *"still running"* && "$(cat "$wok_fd_file")" == "after" ]]'
check_that "test.sh refuses a TEST_SHARD_TIMEOUT_S that is not whole seconds before any work" \
    '[[ "$(GODOT=/nonexistent TEST_SHARD_TIMEOUT_S=1.5 ./tools/test.sh 2>&1; echo "rc $?")" == *"must be whole seconds"*"rc 2" ]]'

# ------------------------------------------------ audit-pck.sh reads the artefact, not the tree ---
# A minimal format-4 pack keeps this regression independent of Godot and export templates while
# exercising the same directory and file bytes a real export exposes. The dirty fixture carries
# each shape the Web export must lose: a compiled test remap under tests/, a probe resource and a
# global class cache outside tests/ that still points back into that tree. The clean companion is
# what stops a parser failure or an unconditional rejection from satisfying the case vacuously.
clean_pack="$work_dir/audit-clean.pck"
dirty_pack="$work_dir/audit-tests.pck"
recipe_pack="$work_dir/audit-recipes.pck"
python3 - "$clean_pack" "$dirty_pack" "$recipe_pack" <<'PY'
import hashlib
import struct
import sys


def write_pack(path, entries):
    data = bytearray()
    records = []
    for name, contents in entries:
        offset = len(data)
        data.extend(contents)
        encoded = name.encode("utf-8") + b"\0"
        encoded += b"\0" * (-len(encoded) % 4)
        records.append((encoded, offset, len(contents), hashlib.md5(contents).digest()))

    base = struct.calcsize("<6I2Q")
    directory = base + len(data)
    blob = bytearray(struct.pack("<6I2Q", 0x43504447, 4, 4, 7, 2, 0, base, directory))
    blob.extend(data)
    blob.extend(struct.pack("<I", len(records)))
    for name, offset, size, digest in records:
        blob.extend(struct.pack("<I", len(name)))
        blob.extend(name)
        blob.extend(struct.pack("<QQ", offset, size))
        blob.extend(digest)
        blob.extend(struct.pack("<I", 0))
    with open(path, "wb") as handle:
        handle.write(blob)


production = [
    ("src/main.gd.remap", b'path="res://src/main.gdc"\n'),
    (".godot/global_script_class_cache.cfg", b'path="res://src/main.gd"\n'),
]
write_pack(sys.argv[1], production)
write_pack(
    sys.argv[2],
    production[:1]
    + [
        ("tests/test_export.gd.remap", b'path="res://tests/test_export.gdc"\n'),
        ("tests/probes/export_probe.tscn", b'[gd_scene format=3]\n'),
        (
            ".godot/global_script_class_cache.cfg",
            b'path="res://src/main.gd"\npath="res://tests/probes/export_probe.gd"\n',
        ),
    ],
)
write_pack(
    sys.argv[3],
    production + [("scene-recipes/task-06-note.json", b'{"version":1}\n')],
)
PY

out="$(./tools/audit-pck.sh --fatal "$clean_pack" 2>&1)"
status=$?
check_that "audit-pck.sh accepts a pack with only production paths and class-cache entries" \
    '[[ $status -eq 0 && "$out" == *"0 test paths, 0 other files referring to tests"* ]]'
out="$(./tools/audit-pck.sh --fatal "$dirty_pack" 2>&1)"
status=$?
check_that "audit-pck.sh rejects test remaps, probes and a class-cache reference in the pack" \
    '[[ $status -ne 0 && "$out" == *"2 test paths, 1 other files referring to tests"* && "$out" == *"test path: tests/probes/export_probe.tscn"* && "$out" == *"test reference: .godot/global_script_class_cache.cfg"* ]]'
out="$(./tools/audit-pck.sh --fatal "$recipe_pack" 2>&1)"
status=$?
check_that "audit-pck.sh rejects a development scene recipe actually present in the pack" \
    '[[ $status -ne 0 && "$out" == *"1 development recipe paths"* && "$out" == *"development recipe: scene-recipes/task-06-note.json"* ]]'

made="$(cd "$names_repo" && ./tools/new-name.sh --date 2026-09-27 todo "Stars for nerves" 2>/dev/null)"
check_that "new-name.sh takes the one pair not already used, in any folder, whatever its date" \
    '[[ "$made" == 2026-09-27-busy-otter ]]'
check_that "new-name.sh writes the entry's context file with its heading and date" \
    'grep -qx "# busy-otter — Stars for nerves · filed 2026-09-27" "$names_repo/docs/todo/2026-09-27-busy-otter/README.md"'
check_that "new-name.sh opens a new entry with the band line priority: later" \
    '[[ "$(head -n 1 "$names_repo/docs/todo/2026-09-27-busy-otter/README.md")" == "priority: later" ]]'
out="$(cd "$names_repo" && ./tools/new-name.sh playtest "No words left" 2>&1)"
status=$?
check_that "new-name.sh refuses when every pair is taken, and writes nothing" \
    '[[ $status -ne 0 && $(ls "$names_repo/docs/playtests" | wc -l | tr -d " ") -eq 1 ]]'
first="$(cd "$names_repo" && ./tools/new-name.sh review --entry busy-otter "Look at it" 2>/dev/null)"
second="$(cd "$names_repo" && ./tools/new-name.sh review --entry busy-otter "Look again" 2>/dev/null)"
check_that "new-name.sh names a review item after its entry, and a second one with -2" \
    '[[ "$first" == 2026-09-27-busy-otter && "$second" == 2026-09-27-busy-otter-2 ]]'
printf 'otter\nheron\n' > "$names_repo/tools/names/animals.txt"
fresh="$(cd "$names_repo" && ./tools/new-name.sh --date 2026-09-29 decision "Moved out of a docstring" 2>/dev/null)"
check_that "new-name.sh marks a decision drawn without --entry as not from an entry" \
    '[[ "$fresh" == 2026-09-29-busy-heron ]] && grep -q "· not from an entry$" "$names_repo/docs/decisions/$fresh.md"'
rm -f "$names_repo/docs/decisions/2026-09-29-busy-heron.md"
printf 'badger\notter\n' > "$names_repo/tools/names/animals.txt"
closed="$(cd "$names_repo" && ./tools/new-name.sh decision --entry M210 "Built" 2>/dev/null)"
check_that "new-name.sh names an old entry's decision by its folder" \
    '[[ "$closed" == 2026-09-26-M210 && -s "$names_repo/docs/decisions/2026-09-26-M210.md" ]]'
if command -v rg >/dev/null 2>&1; then
    printf 'The brief says what is coming, spent or not.\n' >> "$names_repo/docs/decisions/2026-09-26-M210.md"
    found="$(cd "$names_repo" && ./tools/decisions.sh M210)"
    check_that "decisions.sh finds a record by the milestone in its title" \
        '[[ "$found" == "docs/decisions/2026-09-26-M210.md  M210 — Built · "* ]]'
    found="$(cd "$names_repo" && ./tools/decisions.sh --in all spent coming)"
    check_that "decisions.sh finds a record by words only in its text, under its own line" \
        '[[ "$found" == $'"'"'-- in the text:\ndocs/decisions/2026-09-26-M210.md'"'"'* ]]'
    (cd "$names_repo" && ./tools/decisions.sh nothing-says-this >/dev/null 2>&1)
    status=$?
    check_that "decisions.sh exits non-zero when nothing matches" '[[ $status -ne 0 ]]'
else
    echo "skip decisions.sh's search cases: rg is not on PATH"
fi

# ------------------------------------------------------- lint.sh's checks of the queue's layout ---
# On the same scratch tree: an entry, its review items and an old entry's decision share names on
# purpose and pass; a second use of a pair of words, a checkbox in a queue file, and a link in
# TODO.md to an entry folder that is not there are each a hit.
cp "$root/tools/lint.sh" "$names_repo/tools/"
lint_in_names_repo() {
    (cd "$names_repo" && ./tools/lint.sh "$@" >/dev/null 2>&1)
}
lint_in_names_repo docs/todo/2026-09-27-busy-otter/README.md docs/review/2026-09-27-busy-otter.md \
    docs/review/2026-09-27-busy-otter-2.md docs/decisions/2026-09-26-M210.md
status=$?
check_that "lint.sh passes an entry, its review items and an old entry's decision sharing a name" '[[ $status -eq 0 ]]'
printf '# Playtest busy-otter — A second thing\n' > "$names_repo/docs/playtests/2026-09-28-busy-otter.md"
lint_in_names_repo docs/playtests/2026-09-28-busy-otter.md
status=$?
rm "$names_repo/docs/playtests/2026-09-28-busy-otter.md"
check_that "lint.sh rejects a pair of words used again for another thing" '[[ $status -ne 0 ]]'
printf '# busy-otter — Drawn fresh · 2026-09-27 · not from an entry\n' \
    > "$names_repo/docs/decisions/2026-09-27-busy-otter.md"
lint_in_names_repo docs/decisions/2026-09-27-busy-otter.md
status=$?
rm "$names_repo/docs/decisions/2026-09-27-busy-otter.md"
check_that "lint.sh rejects a decision drawn without --entry that shares its date and pair with an entry" \
    '[[ $status -ne 0 ]]'
printf '# Playtest copper-lark — Typed by hand\n' > "$names_repo/docs/playtests/2026-09-26-copper-lark.md"
printf '# copper-lark — Another thing · 2026-09-28 · not from an entry\n' \
    > "$names_repo/docs/decisions/2026-09-28-copper-lark.md"
lint_in_names_repo docs/decisions/2026-09-28-copper-lark.md
status=$?
rm "$names_repo/docs/decisions/2026-09-28-copper-lark.md"
check_that "lint.sh counts a name whose words are not in tools/names/ as taken" '[[ $status -ne 0 ]]'
lint_in_names_repo docs/playtests/2026-09-26-copper-lark.md
status=$?
rm "$names_repo/docs/playtests/2026-09-26-copper-lark.md"
check_that "lint.sh passes a name typed by hand that nothing else uses" '[[ $status -eq 0 ]]'
printf -- '- [ ] **Do it**\n' > "$names_repo/docs/todo/2026-09-27-busy-otter/do-it.md"
lint_in_names_repo docs/todo/2026-09-27-busy-otter/do-it.md
status=$?
rm "$names_repo/docs/todo/2026-09-27-busy-otter/do-it.md"
check_that "lint.sh rejects a checkbox in an item file" '[[ $status -ne 0 ]]'
printf '# TODO\n\n- [busy-otter](todo/2026-09-27-busy-otter/)\n- [M210](todo/2026-09-26-M210/)\n' \
    > "$names_repo/docs/TODO.md"
lint_in_names_repo docs/TODO.md
status=$?
check_that "lint.sh passes TODO.md's links to entry folders that exist" '[[ $status -eq 0 ]]'
printf -- '- [gone](todo/2026-09-01-quiet-heron/)\n' >> "$names_repo/docs/TODO.md"
lint_in_names_repo docs/TODO.md
status=$?
check_that "lint.sh rejects a link in TODO.md to an entry folder that does not exist" '[[ $status -ne 0 ]]'
printf '# TODO\n' > "$names_repo/docs/TODO.md"
cp "$names_repo/docs/todo/2026-09-26-M210/README.md" "$work_dir/M210-README.md"
sed '1d' "$work_dir/M210-README.md" > "$names_repo/docs/todo/2026-09-26-M210/README.md"
lint_in_names_repo docs/todo/2026-09-26-M210/README.md
status=$?
check_that "lint.sh rejects an entry with no priority line" '[[ $status -ne 0 ]]'
printf 'priority: next\nafter: 2026-09-01-gone-heron\n' > "$names_repo/docs/todo/2026-09-26-M210/README.md"
sed '1d' "$work_dir/M210-README.md" >> "$names_repo/docs/todo/2026-09-26-M210/README.md"
lint_in_names_repo docs/todo/2026-09-26-M210/README.md
status=$?
check_that "lint.sh rejects an after naming no entry" '[[ $status -ne 0 ]]'
cp "$work_dir/M210-README.md" "$names_repo/docs/todo/2026-09-26-M210/README.md"
lint_in_names_repo docs/todo/2026-09-26-M210/README.md
status=$?
check_that "lint.sh passes the entry again once its band line is whole" '[[ $status -eq 0 ]]'
printf 'otter\nwren\n' > "$names_repo/tools/names/animals.txt"
made="$(cd "$names_repo" && ./tools/new-name.sh --date 2026-09-30 todo --priority now "Now it is" 2>/dev/null)"
check_that "new-name.sh --priority writes the band it names" \
    '[[ "$made" == 2026-09-30-busy-wren && "$(head -n 1 "$names_repo/docs/todo/$made/README.md")" == "priority: now" ]]'
rm -rf "$names_repo/docs/todo/2026-09-30-busy-wren"
printf 'badger\notter\n' > "$names_repo/tools/names/animals.txt"
mv "$names_repo/tools/queue.sh" "$work_dir/queue.sh.aside"
lint_in_names_repo docs/todo/2026-09-26-M210/README.md
status=$?
check_that "lint.sh counts a missing queue.sh as a hit rather than skipping the band check" '[[ $status -ne 0 ]]'
printf 'otter\nwren\n' > "$names_repo/tools/names/animals.txt"
made="$(cd "$names_repo" && ./tools/new-name.sh --date 2026-09-30 playtest "Filed without the queue" 2>/dev/null)"
check_that "new-name.sh files a playtest with queue.sh missing, since only an entry needs the bands" \
    '[[ "$made" == 2026-09-30-busy-wren && -s "$names_repo/docs/playtests/$made.md" ]]'
rm -f "$names_repo/docs/playtests/2026-09-30-busy-wren.md"
printf 'badger\notter\n' > "$names_repo/tools/names/animals.txt"
mv "$work_dir/queue.sh.aside" "$names_repo/tools/queue.sh"

# ----------------------------------------------------- queue.sh orders the entries by their bands ---
# A scratch queue: two `now` entries, which print newest first; two old `next` entries under one
# date, which print in milestone-number order; a `next` entry that waits on a `later` one, which
# moves to straight behind it; and a `parked` one last. Then each broken band line --check names.
queue_repo="$work_dir/queue-repo"
mkdir -p "$queue_repo/tools"
cp "$root/tools/queue.sh" "$queue_repo/tools/"
add_entry() {
    # $1 folder name  $2 opening block (band and after lines)  $3 heading
    mkdir -p "$queue_repo/docs/todo/$1"
    printf '%s\n\n## %s\n\nText.\n' "$2" "$3" > "$queue_repo/docs/todo/$1/README.md"
}
add_entry 2026-09-20-quiet-heron "priority: now" "quiet-heron — Older and now · filed 2026-09-20"
add_entry 2026-09-22-busy-otter "priority: now" "busy-otter — Newer and now · filed 2026-09-22"
add_entry 2026-09-01-M40 "priority: next" "M40 — Forty"
add_entry 2026-09-01-M5 "priority: next" "M5 — Five · asked for 2026-09-01"
add_entry 2026-09-01-able-ant "priority: next" "able-ant — Named, filed the same day as M5 · filed 2026-09-01"
add_entry 2026-09-02-calm-fox "$(printf 'priority: next\nafter: 2026-09-25-lazy-cat')" "calm-fox — Waits · filed 2026-09-02"
add_entry 2026-09-25-lazy-cat "priority: later" "lazy-cat — Waited on · filed 2026-09-25"
add_entry 2026-09-03-slow-owl "priority: parked" "slow-owl — Parked · filed 2026-09-03"
order="$(cd "$queue_repo" && LC_ALL=en_US.UTF-8 ./tools/queue.sh 2>/dev/null | awk '{ print $1 " " $2 }' | tr '\n' ' ')"
check_that "queue.sh prints now newest first, the rest oldest first, and an entry behind what it waits on" \
    '[[ "$order" == "now 2026-09-22-busy-otter now 2026-09-20-quiet-heron next 2026-09-01-M5 next 2026-09-01-M40 next 2026-09-01-able-ant later 2026-09-25-lazy-cat next 2026-09-02-calm-fox parked 2026-09-03-slow-owl " ]]'
check_that "queue.sh sorts same-day entries by name whatever the caller's locale (numbers, then words)" \
    '[[ "$order" == *"M40 next 2026-09-01-able-ant"* ]]'
mkdir -p "$queue_repo/docs/decisions"
printf '# gone-bird — Built · 2026-09-04\n' > "$queue_repo/docs/decisions/2026-09-04-gone-bird.md"
add_entry 2026-09-03-slow-owl "$(printf 'priority: parked\nafter: 2026-09-04-gone-bird')" "slow-owl — Parked"
(cd "$queue_repo" && ./tools/queue.sh --check)
status=$?
line="$(cd "$queue_repo" && ./tools/queue.sh --band parked)"
check_that "queue.sh counts an after naming a closed entry (a record, no folder) as satisfied, shown as closed" \
    '[[ $status -eq 0 && "$line" == *"(after 2026-09-04-gone-bird, closed)" ]]'
rm "$queue_repo/docs/decisions/2026-09-04-gone-bird.md"
add_entry 2026-09-03-slow-owl "priority: parked" "slow-owl — Parked"
line="$(cd "$queue_repo" && ./tools/queue.sh --band next | tail -n 1)"
check_that "queue.sh --band prints one band, each line with its title and what it waits on" \
    '[[ "$line" == "next    2026-09-02-calm-fox  calm-fox — Waits  (after 2026-09-25-lazy-cat)" ]]'
(cd "$queue_repo" && ./tools/queue.sh --check)
status=$?
check_that "queue.sh --check passes a queue whose band lines are whole" '[[ $status -eq 0 ]]'
queue_check_fails() {
    # $1 label  $2 text --check's output must contain
    local out status want="$2"
    out="$(cd "$queue_repo" && ./tools/queue.sh --check 2>&1)"
    status=$?
    check_that "$1" '[[ $status -ne 0 && "$out" == *"$want"* ]]'
    out="$(cd "$queue_repo" && ./tools/queue.sh 2>&1)"
    status=$?
    check_that "queue.sh refuses to print the order while --check fails ($2)" '[[ $status -ne 0 ]]'
}
printf '## slow-owl — Parked\n' > "$queue_repo/docs/todo/2026-09-03-slow-owl/README.md"
queue_check_fails "queue.sh --check rejects an entry with no priority line" "no \`priority:\` line"
add_entry 2026-09-03-slow-owl "priority: someday" "slow-owl — Parked"
queue_check_fails "queue.sh --check rejects a band outside the set" "band outside"
add_entry 2026-09-03-slow-owl "$(printf 'priority: parked\nafter: 2026-09-04-gone-bird')" "slow-owl — Parked"
queue_check_fails "queue.sh --check rejects an after naming no entry" "names no entry"
add_entry 2026-09-03-slow-owl "$(printf 'priority: parked\nafter: 2026-09-02-calm-fox')" "slow-owl — Parked"
add_entry 2026-09-25-lazy-cat "$(printf 'priority: later\nafter: 2026-09-03-slow-owl')" "lazy-cat — Waited on"
queue_check_fails "queue.sh --check rejects an after cycle" "cycle"
add_entry 2026-09-25-lazy-cat "priority: later" "lazy-cat — Waited on"
add_entry 2026-09-03-slow-owl "priority: parked" "slow-owl — Parked"
printf 'priority: next\n' >> "$queue_repo/docs/todo/2026-09-03-slow-owl/README.md"
queue_check_fails "queue.sh --check rejects a band line below the opening block" "outside the opening block"
add_entry 2026-09-03-slow-owl "priority: parked" "slow-owl — Parked"

# ------------------------------------ update-pr.sh stops a branch still on the old single queue ---
# A throwaway origin whose base has the old single-file queue, a main that has it as files, and two
# branches cut from the base: one edited docs/REVIEW.md the old way (which git merges cleanly into
# the new file), one touched nothing of the queue. update-pr.sh must refuse the first before
# merging, naming the file and the converter, and let the second through; land-prs.sh runs the
# same check (tools/lib_old_queue.sh), which is asserted directly since it needs GitHub.
guard_origin="$work_dir/guard-origin.git"
guard_repo="$work_dir/guard-repo"
git init -q --bare -b main "$guard_origin"
git init -q -b main "$guard_repo"
guard_git() { git -C "$guard_repo" -c user.name=t -c user.email=t@example.com "$@"; }
mkdir -p "$guard_repo/tools" "$guard_repo/docs"
cp "$root/tools/update-pr.sh" "$root/tools/lib_old_queue.sh" "$root/tools/lib_agent_role.sh" "$guard_repo/tools/"
printf '# Decisions\n\n## M1 — Old record\n\nText.\n' > "$guard_repo/docs/DECISIONS.md"
printf '# TODO\n\n## The order\n' > "$guard_repo/docs/TODO.md"
printf '# Review\n\nWhat waits.\n\n- **Look at it.**\n' > "$guard_repo/docs/REVIEW.md"
printf 'code\n' > "$guard_repo/code.txt"
guard_git add -A && guard_git commit -q -m base
guard_git remote add origin "$guard_origin"
guard_git checkout -q -b pr-old
printf '# Review\n\n## A section the old way\n\nTry this.\n\nWhat waits.\n\n- **Look at it.**\n' \
    > "$guard_repo/docs/REVIEW.md"
guard_git commit -q -am "old-format review edit"
guard_git checkout -q -b pr-code main
printf 'more code\n' >> "$guard_repo/code.txt"
guard_git commit -q -am "code only"
guard_git checkout -q main
printf '# Decisions\n\n**Every decision is a file of its own.**\n' > "$guard_repo/docs/DECISIONS.md"
guard_git commit -q -am "the queue is files"
guard_git push -q origin main pr-old pr-code 2>/dev/null
out="$(cd "$guard_repo" && ./tools/update-pr.sh --dry-run pr-old 2>&1)"
status=$?
check_that "update-pr.sh refuses a branch that edited the old queue, naming the file and the converter" \
    '[[ $status -ne 0 && "$out" == *"docs/REVIEW.md"* && "$out" == *"tools/convert-queue-edits.py"* ]]'
(cd "$guard_repo" && ./tools/update-pr.sh --dry-run pr-code >/dev/null 2>&1)
status=$?
check_that "update-pr.sh lets a branch that left the queue alone through" '[[ $status -eq 0 ]]'
found="$(cd "$guard_repo" && source tools/lib_old_queue.sh && old_queue_edits pr-old pr-code)"
check_that "the check says nothing while main still has the old queue" '[[ -z "$found" ]]'
found="$(cd "$guard_repo" && source tools/lib_old_queue.sh && old_queue_edits pr-old main)"
check_that "the check land-prs.sh runs names the old queue file a branch edited" '[[ "$found" == docs/REVIEW.md ]]'

# ------------------------- update-pr.sh's whitespace check judges the branch, not main ---
# main carries a trailing-whitespace line in main.txt that the branch never touched: the update
# must go through. A second branch adds its own trailing whitespace: that one must be refused.
# lint.sh and check.sh are stubbed to pass so only the whitespace check can decide.
ws_origin="$work_dir/ws-origin.git"
ws_repo="$work_dir/ws-repo"
git init -q --bare -b main "$ws_origin"
git init -q -b main "$ws_repo"
ws_git() { git -C "$ws_repo" -c user.name=t -c user.email=t@example.com "$@"; }
mkdir -p "$ws_repo/tools"
cp "$root/tools/update-pr.sh" "$root/tools/lib_old_queue.sh" "$root/tools/lib_agent_role.sh" "$ws_repo/tools/"
printf '#!/usr/bin/env bash\nexit 0\n' > "$ws_repo/tools/lint.sh"
cp "$ws_repo/tools/lint.sh" "$ws_repo/tools/check.sh"
chmod +x "$ws_repo/tools/lint.sh" "$ws_repo/tools/check.sh"
printf 'clean\n' > "$ws_repo/main.txt"
printf 'clean\n' > "$ws_repo/branch.txt"
ws_git add -A && ws_git commit -q -m base
ws_git remote add origin "$ws_origin"
ws_git branch pr-clean && ws_git branch pr-dirty
ws_git checkout -q pr-clean
printf 'fine\n' >> "$ws_repo/branch.txt"
ws_git commit -q -am "clean branch work"
ws_git checkout -q pr-dirty
printf 'trailing   \n' >> "$ws_repo/branch.txt"
ws_git commit -q -am "branch with its own whitespace error"
ws_git checkout -q main
printf 'main brings this   \n' >> "$ws_repo/main.txt"
ws_git commit -q -am "main with its own whitespace error"
ws_git push -q origin main pr-clean pr-dirty 2>/dev/null
ws_git checkout -q pr-clean
out="$(cd "$ws_repo" && GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com ./tools/update-pr.sh pr-clean 2>&1)"
status=$?
check_that "update-pr.sh does not blame a branch for whitespace main already carries" \
    '[[ $status -eq 0 && "$out" == *"committed"* ]]'
ws_git checkout -q pr-dirty
out="$(cd "$ws_repo" && GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com ./tools/update-pr.sh pr-dirty 2>&1)"
status=$?
check_that "update-pr.sh refuses a branch that adds its own whitespace error" \
    '[[ $status -ne 0 && "$out" == *"branch.txt"* && "$out" == *"git diff --cached --check"* ]]'

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
