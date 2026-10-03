# Disk-space preflight shared by the tools that allocate a batch: a worktree, an import, a build,
# an export or a capture. Not a script of its own -- `source` it, then call
#
#   headroom_preflight TOOL DESTINATION HINT JOB[:COUNT]...
#
# before the first byte of the batch is written. It compares the space the volume holding
# DESTINATION has available (`df -Pk`, on DESTINATION's nearest existing ancestor, since a build
# directory need not exist yet) with the batch's estimated peak plus a reserve, and returns 0 when
# the batch fits. When it does not, it names the shortfall, the measured available space, the
# smaller-batch step HINT (empty when there is none) and the cleanup action, on stderr, and returns
# 1, so the caller writes `headroom_preflight ... || exit 1` and refuses before it allocates.
# Silent on success. Bash 3.2-safe, like the rest of tools/.
#
# **Every estimate is a measured peak, never a guessed threshold.** The table in
# `headroom_measured_peak_mib` holds the peak additional allocation `tools/measure-disk-peak.sh`
# recorded for one unit of each job, rounded up with the margin its comment states; the method,
# the environment and the raw results are under docs/evidence/teal-ibis-headroom-2026-10-03/.
# A job missing from the table has no estimate, and the preflight refuses it rather than guessing
# one: measure it, then add the row or set its variable below. The figures are allocated sizes
# (`du`), which on APFS can count shared clone blocks, so they are upper bounds on what a job
# takes rather than space its removal is promised to return.
#
# **The reserve is the free space the batch must leave behind.** The player's disk warnings were
# reported with about 2.5 GiB free (docs/decisions/2026-10-03-teal-ibis.md), so the default
# reserve keeps a batch from ending below that: NAPPY_HEADROOM_RESERVE_MIB, default 3072.
#
# Configuration, all from the environment:
#   NAPPY_HEADROOM_PEAK_MIB_<JOB>  replaces one job's measured MiB per unit, the job's name
#                                  upper-cased with '-' as '_' (NAPPY_HEADROOM_PEAK_MIB_SHOT=8)
#   NAPPY_HEADROOM_RESERVE_MIB     the reserve in MiB (default 3072)
#   NAPPY_HEADROOM_CHECK=off       skips the check, saying so on stderr
# Each value is a whole number of MiB; anything else is refused, never read as zero.

HEADROOM_DEFAULT_RESERVE_MIB=3072

# The measured peak, in MiB, of one unit of JOB; nothing and status 1 for a job never measured.
# The measured figure is in each comment; the estimate is that figure with the stated margin.
headroom_measured_peak_mib() {
    case "$1" in
        # `git worktree add` of every tracked file: 1,130,972 KiB (checkout 1,128,768 plus its
        # admin directory), about 1.08 GiB. +25%.
        worktree-full) echo 1400 ;;
        # The same with docs/evidence, docs/reference and docs/style-references left out:
        # 24,416 KiB. +25%, rounded up.
        worktree-sparse) echo 32 ;;
        # tools/check.sh on a fresh checkout -- the atlas bake, the import into .godot/ and the
        # boot: 2,152 KiB. The repair run.sh, shot.sh and record.sh start when the cache is stale.
        import) echo 16 ;;
        # tools/bake-atlases.sh on a tree with no pages: 1,148 KiB.
        atlas-bake) echo 4 ;;
        # tools/export-web.sh into an empty build/: 39,624 KiB for the debug export, and 33,076 KiB
        # for the release one on a fresh checkout, its bake and import included. +60%.
        web-export) echo 64 ;;
        # tools/build-web-template.sh on a cache miss: the downloads, the Emscripten SDK, the engine
        # source and its objects under build/web-template-work/, which the build removes once it
        # succeeds: 2,832,532 KiB at the largest of samples five seconds apart. +48%, since a
        # sample can miss a peak between two and the link's own temporary files are not counted.
        web-template-build) echo 4096 ;;
        # tools/scene-recipes.sh, per recipe, without screenshots: 112 KiB for ten recipes.
        scene-recipe) echo 1 ;;
        # The same, per recipe, with --screenshots: 436 KiB for one, the still most of it.
        scene-capture) echo 2 ;;
        # One tools/shot.sh still at the default 1280x720 with its logs: about 430 KiB measured. The
        # estimate is the frame's raw RGBA size, 3.5 MiB, which its PNG does not meaningfully
        # exceed whatever is on screen; a larger RESOLUTION scales it.
        shot) echo 4 ;;
        # One second of game time recorded by tools/record.sh, at 60 frames: the first four seconds
        # of day 1, 242 frames and their WAV, held 38,816 KiB (160 KiB a frame), and a busy city
        # still is 410 KiB. 512 KiB a frame plus the WAV.
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
    local available=$(( available_kib / 1024 )) needed=$(( peak + reserve ))
    if (( available >= needed )); then
        return 0
    fi
    {
        echo "$tool: refusing to start: not enough free disk space for this batch."
        echo "  volume holding $destination: $available MiB available"
        echo "  needed: $needed MiB = estimated peak $peak MiB ($parts) + reserve $reserve MiB"
        echo "  short by: $(( needed - available )) MiB"
        [[ -z "$hint" ]] || echo "  smaller batch: $hint"
        echo "  cleanup: tools/prune-merged.sh --all lists retirable worktrees with their sizes (an agent"
        echo "    runs it through tools/agent-identity.py, see the using-tools skill); the session-cleanup"
        echo "    skill's \"Finish the job's storage cleanup\" says what else is a job's own to remove."
        echo "    Then measure again with df rather than counting on du's sizes."
        echo "  The estimates are measured peaks in tools/lib_disk_headroom.sh; its header names the"
        echo "    variables that override one, the reserve, or the check."
    } >&2
    return 1
}
