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
# tools/test.sh is deliberately not asserted against an unknown flag here: it forwards anything
# that is not --serial/--plan/--help/-h straight to the test scene as either a suite-name
# substring or a flag the scene itself reads off OS.get_cmdline_user_args() (`--svg` is a real,
# documented example) -- there is no fixed list to validate that free-text surface against, so
# only its --help path is checked.
#
# Bash 3.2-safe (no associative arrays, no mapfile) -- the same reason the rest of tools/ stays
# this side of bash 4; see tools/lint.sh's own header.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# A stand-in for the Godot binary: touches a marker and exits 0, so a test can tell whether a
# script that is supposed to reject its input before ever launching Godot actually did.
GODOT_MARKER="$work_dir/godot-invoked"
GODOT_STUB="$work_dir/godot-stub.sh"
{
    echo '#!/usr/bin/env bash'
    printf 'touch %q\n' "$GODOT_MARKER"
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
assert_exit "check.sh --help"      zero ./tools/check.sh --help
assert_exit "check.sh -h"          zero ./tools/check.sh -h
assert_exit "lint.sh --help"       zero ./tools/lint.sh --help
assert_exit "pycheck.sh --help"    zero ./tools/pycheck.sh --help
assert_exit "export-web.sh --help" zero ./tools/export-web.sh --help
assert_exit "serve-web.sh --help"  zero ./tools/serve-web.sh --help
assert_exit "release.sh --help"    zero ./tools/release.sh --help
assert_exit "run.sh --help"        zero ./tools/run.sh --help
assert_exit "shot.sh --help"       zero ./tools/shot.sh --help
assert_exit "stats.sh --help"      zero ./tools/stats.sh --help
assert_exit "telemetry.sh --help"  zero ./tools/telemetry.sh --help
assert_exit "test.sh --help"       zero ./tools/test.sh --help
assert_exit "clip.sh --help"       zero ./tools/clip.sh --help
assert_exit "reference.sh --help"  zero ./tools/reference.sh --help

# ---------------------------------------- an unknown flag: rejected, usage, non-zero, no work ---
assert_exit "check.sh --bogus"        nonzero ./tools/check.sh --bogus
assert_exit "lint.sh --bogus-flag"    nonzero ./tools/lint.sh --bogus-flag
assert_exit "pycheck.sh --bogus"      nonzero ./tools/pycheck.sh --bogus
assert_exit "export-web.sh --bogus"   nonzero ./tools/export-web.sh --bogus
assert_exit "serve-web.sh --bogus"    nonzero ./tools/serve-web.sh --bogus
assert_exit "release.sh --bogus"      nonzero ./tools/release.sh --bogus
assert_exit "run.sh --bogus"          nonzero ./tools/run.sh --bogus
assert_exit "shot.sh --bogus"         nonzero ./tools/shot.sh "$work_dir/shot-out.png" 1 --bogus
assert_exit "stats.sh --bogus"        nonzero ./tools/stats.sh --bogus
assert_exit "telemetry.sh --bogus"    nonzero ./tools/telemetry.sh --bogus
assert_exit "clip.sh --bogus"         nonzero ./tools/clip.sh --bogus
assert_exit "reference.sh --bogus"    nonzero ./tools/reference.sh --bogus

# A run.sh / shot.sh dev flag missing its required value is the other rejected shape -- checked
# once each here since lib_dev_flags.sh's own arity handling already has a focused smoke test in
# its validate_dev_flags() cases; this only proves the two callers actually wired it in.
assert_exit "run.sh --seed (missing value)"  nonzero ./tools/run.sh --seed
assert_exit "shot.sh --meters (missing values)" nonzero ./tools/shot.sh "$work_dir/shot-out2.png" 1 --meters 3

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
    if printf '%s' "$readme_section" | grep -qF -- "$flag"; then
        echo "ok   README documents $flag"
    else
        echo "FAIL $flag is in dev_flags.gd's DEV_FLAG_TABLE but not in README.md's Dev flags section" >&2
        failures=$(( failures + 1 ))
    fi
done < <(dev_flag_names)

echo
echo "$checks checks, $failures failures"
if [[ "$failures" -gt 0 ]]; then
    exit 1
fi
