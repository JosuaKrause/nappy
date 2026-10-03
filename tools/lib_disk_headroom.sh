# Disk-space preflight shared by the tools that allocate a batch: a worktree, an import, a build,
# an export or a capture. Not a script of its own -- `source` it, then call
#
#   headroom_preflight TOOL DESTINATION HINT JOB[:COUNT]...
#
# before the first byte of the batch is written. It compares the space the volume holding
# DESTINATION has available (`df -Pk`, on DESTINATION's nearest existing ancestor, since a build
# directory need not exist yet) with the batch's estimated peak, and with that peak plus a reserve.
# Three bands *(2026-10-04, inbox #496: "Yes tool should warm and only refuse if it's not
# possible")*:
#   - below the estimated peak the batch cannot finish, so it refuses: it names the available
#     space, the shortfall, the smaller-batch step HINT (empty when there is none) and the cleanup
#     action on stderr and returns 1, and the caller writes `headroom_preflight ... || exit 1`;
#   - at or above the peak but below peak plus reserve it fits, but would leave the disk in the
#     range where the player's warnings appear, so it prints a warning naming the same figures and
#     the cleanup action, and returns 0 so the batch runs;
#   - at or above peak plus reserve it is silent and returns 0.
# Bash 3.2-safe, like the rest of tools/.
#
# **Every estimate is a measured peak, never a guessed threshold.** The table in
# `headroom_measured_peak_mib` holds the peak additional allocation `tools/measure-disk-peak.sh`
# recorded for one unit of each job, and an estimate at or above it; each row's comment states
# both and how far apart they are. The large jobs carry 27-65% over their measured peaks; the
# small ones are rounded up to a few MiB, several times what was measured. The method, the environment and the raw results are under
# docs/evidence/teal-ibis-headroom-2026-10-03/.
# A job missing from the table has no estimate, and the preflight refuses it rather than guessing
# one: measure it, then add the row or set its variable below. The figures are allocated sizes
# (`du`), which on APFS can count shared clone blocks, so they are upper bounds on what a job
# takes rather than space its removal is promised to return.
#
# **The reserve is the free space a batch should leave behind, and only ever warns.** The player's
# disk warnings were reported with about 2.5 GiB free (docs/decisions/2026-10-03-teal-ibis.md), so
# the default, HEADROOM_DEFAULT_RESERVE_MIB below, warns before a batch ends below that. The
# warning is taken seriously but enforced by nobody: the using-tools and orchestrating skills say
# what to do on seeing it, which is to start no new task and sort out the space first.
#
# Configuration, all from the environment:
#   NAPPY_HEADROOM_PEAK_MIB_<JOB>  replaces one job's measured MiB per unit, the job's name
#                                  upper-cased with '-' as '_' (NAPPY_HEADROOM_PEAK_MIB_SHOT=8)
#   NAPPY_HEADROOM_RESERVE_MIB     the reserve in MiB (default HEADROOM_DEFAULT_RESERVE_MIB)
#   NAPPY_HEADROOM_CHECK=off       skips the check, saying so on stderr
# Each value is a whole number of MiB; anything else is refused, never read as zero.

HEADROOM_DEFAULT_RESERVE_MIB=3072

# The measured peak, in MiB, of one unit of JOB; nothing and status 1 for a job never measured.
# Each comment gives the measured figure and how far the estimate is above it.
headroom_measured_peak_mib() {
    case "$1" in
        # `git worktree add` of every tracked file: 1,130,972 KiB (checkout 1,128,768 plus its
        # admin directory), about 1,104 MiB. Estimate +27%.
        worktree-full) echo 1400 ;;
        # The same with docs/evidence, docs/reference and docs/style-references left out:
        # 24,416 KiB, about 24 MiB. Estimate +34%.
        worktree-sparse) echo 32 ;;
        # tools/check.sh on a fresh checkout -- the atlas bake, the import into .godot/ and the
        # boot: 2,152 KiB. Estimate about 7.6 times that. The repair run.sh, shot.sh and record.sh
        # start when the cache is stale.
        import) echo 16 ;;
        # tools/bake-atlases.sh on a tree with no pages: 1,148 KiB. Estimate about 3.6 times that.
        atlas-bake) echo 4 ;;
        # tools/export-web.sh into an empty build/: 39,624 KiB for the debug export, and 33,076 KiB
        # for the release one on a fresh checkout, its bake and import included. Estimate +65% over
        # the larger.
        web-export) echo 64 ;;
        # tools/build-web-template.sh on a cache miss: the downloads, the Emscripten SDK, the engine
        # source and its objects under build/web-template-work/, which the build removes once it
        # succeeds: 2,832,532 KiB at the largest of samples five seconds apart. Estimate +48%, since a
        # sample can miss a peak between two and the link's own temporary files are not counted.
        web-template-build) echo 4096 ;;
        # tools/scene-recipes.sh, per recipe, without screenshots: 112 KiB for ten recipes, about
        # 11 KiB each. Estimate the smallest whole MiB, about 90 times that.
        scene-recipe) echo 1 ;;
        # The same, per recipe, with --screenshots: 436 KiB for one, the still most of it.
        # Estimate about 4.7 times that.
        scene-capture) echo 2 ;;
        # One tools/shot.sh still at the default 1280x720 with its logs: about 430 KiB measured.
        # The estimate, about 9.5 times that, is the frame's raw RGBA size, 3.5 MiB, rounded up:
        # its PNG does not meaningfully exceed that whatever is on screen. A larger RESOLUTION
        # scales it.
        shot) echo 4 ;;
        # One second of game time recorded by tools/record.sh, at 60 frames: the first four seconds
        # of day 1, 242 frames and their WAV, held 38,816 KiB (160 KiB a frame, about 9.5 MiB a
        # second), and a busy city still is 410 KiB. The estimate is 512 KiB a frame plus the WAV,
        # about 3.3 times the quiet frames measured and 25% over the busy still.
        record-second) echo 31 ;;
        *) return 1 ;;
    esac
}

# The environment variable that overrides JOB's estimate.
headroom_variable() {
    printf 'NAPPY_HEADROOM_PEAK_MIB_%s\n' \
        "$(printf '%s' "$1" | tr 'abcdefghijklmnopqrstuvwxyz-' 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_')"
}

# Prints the MiB per unit of JOB in effect: its variable when set, else the measured peak.
headroom_peak_mib() {
    local job="$1" variable value
    variable="$(headroom_variable "$job")"
    value="${!variable:-}"
    if [[ -n "$value" ]]; then
        if [[ ! "$value" =~ ^[0-9]+$ ]]; then
            echo "$variable must be a whole number of MiB, got '$value'" >&2
            return 2
        fi
        printf '%s\n' "$((10#$value))"
        return 0
    fi
    headroom_measured_peak_mib "$job"
}

# The available KiB on the volume holding $1, or nothing when df cannot say.
headroom_available_kib() {
    local path="$1"
    while [[ ! -e "$path" ]]; do
        path="$(dirname "$path")"
    done
    df -Pk "$path" 2>/dev/null | awk 'NR==2 && $4 ~ /^[0-9]+$/ {print $4}'
}

headroom_preflight() {
    local tool="$1" destination="$2" hint="$3"
    shift 3
    if [[ "${NAPPY_HEADROOM_CHECK:-on}" == off ]]; then
        echo "$tool: disk headroom check skipped (NAPPY_HEADROOM_CHECK=off)" >&2
        return 0
    fi
    if [[ -n "${NAPPY_HEADROOM_CHECK:-}" && "$NAPPY_HEADROOM_CHECK" != on ]]; then
        echo "$tool: NAPPY_HEADROOM_CHECK must be 'on' or 'off', got '$NAPPY_HEADROOM_CHECK'" >&2
        return 1
    fi
    local reserve="${NAPPY_HEADROOM_RESERVE_MIB:-$HEADROOM_DEFAULT_RESERVE_MIB}"
    if [[ ! "$reserve" =~ ^[0-9]+$ ]]; then
        echo "$tool: NAPPY_HEADROOM_RESERVE_MIB must be a whole number of MiB, got '$reserve'" >&2
        return 1
    fi
    reserve=$((10#$reserve))
    local spec job count unit peak=0 parts="" status
    for spec in "$@"; do
        job="${spec%%:*}"
        count=1
        [[ "$spec" == *:* ]] && count="${spec#*:}"
        if [[ ! "$count" =~ ^[0-9]+$ ]]; then
            echo "$tool: headroom_preflight: bad count in '$spec'" >&2
            return 1
        fi
        count=$((10#$count))
        unit="$(headroom_peak_mib "$job")"
        status=$?
        if [[ $status -eq 2 ]]; then
            echo "$tool: refusing to start: the estimate for $job is not a number" >&2
            return 1
        fi
        if [[ $status -ne 0 || -z "$unit" ]]; then
            echo "$tool: refusing to start: no measured peak for '$job', so the space it needs is unknown." >&2
            echo "  Measure it with tools/measure-disk-peak.sh, then add its row to tools/lib_disk_headroom.sh" >&2
            echo "  or set $(headroom_variable "$job") to the measured MiB." >&2
            return 1
        fi
        peak=$(( peak + unit * count ))
        if [[ $count -eq 1 ]]; then
            parts="$parts${parts:+ + }$job $unit MiB"
        else
            parts="$parts${parts:+ + }$job $unit MiB x $count"
        fi
    done
    local available_kib
    available_kib="$(headroom_available_kib "$destination")"
    if [[ -z "$available_kib" ]]; then
        echo "$tool: refusing to start: could not read the free space on the volume holding $destination (df failed)." >&2
        return 1
    fi
    local available=$(( available_kib / 1024 )) wanted=$(( peak + reserve ))
    if (( available >= wanted )); then
        return 0
    fi
    if (( available < peak )); then
        {
            echo "$tool: refusing to start: not enough free disk space for this batch to finish."
            echo "  volume holding $destination: $available MiB available"
            echo "  needed: estimated peak $peak MiB ($parts)"
            echo "  short by: $(( peak - available )) MiB, before the $reserve MiB reserve"
            [[ -z "$hint" ]] || echo "  smaller batch: $hint"
            headroom_cleanup_lines
        } >&2
        return 1
    fi
    {
        echo "$tool: WARNING: low disk space. Starting anyway, since this batch fits, but it leaves"
        echo "  less than the $reserve MiB reserve free."
        echo "  volume holding $destination: $available MiB available"
        echo "  this batch: estimated peak $peak MiB ($parts); with the reserve $wanted MiB"
        echo "  below the reserve by: $(( wanted - available )) MiB"
        echo "  Take this seriously: start no new task or agent, and start sorting out the space now."
        headroom_cleanup_lines
    } >&2
    return 0
}

headroom_cleanup_lines() {
    echo "  cleanup: tools/prune-merged.sh --all lists retirable worktrees with their sizes (an agent"
    echo "    runs it through tools/agent-identity.py, see the using-tools skill); the session-cleanup"
    echo "    skill's \"Finish the job's storage cleanup\" says what else is a job's own to remove."
    echo "    Then measure again with df rather than counting on du's sizes."
    echo "  The estimates are measured peaks in tools/lib_disk_headroom.sh; its header names the"
    echo "    variables that override one, the reserve, or the check."
}
