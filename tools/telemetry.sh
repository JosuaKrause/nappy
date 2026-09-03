#!/usr/bin/env bash
# Show a run log. Exists because `user://` is somewhere nobody can be expected to remember,
# and on macOS it is inside ~/Library, which Finder hides by default.
#
#   tools/telemetry.sh              # print the newest run
#   tools/telemetry.sh -f           # follow the run that is happening right now
#   tools/telemetry.sh -l           # list what is there, newest first, with size and kind
#   tools/telemetry.sh -d           # print the directory and nothing else
#   tools/telemetry.sh -p           # say what is stale; -p yes actually deletes it
#   tools/telemetry.sh 3            # print the third-newest run
#
# **A run is a folder**, `<day>/<minute>/<run>/`, with `run.log` directly inside it and its
# pictures in `auto/`, `maps/` and `asked/` beside that — see docs/TELEMETRY.md and
# `Telemetry.begin_run()`. Every level exists to be deleted on its own: a whole day, a few minutes
# of a busy one, or one run.
#
# **A log says whether anybody was playing it.** *(Playtest 17, finding 3: "otherwise it looks like
# a lot of plays happened when they were just regular tests. this skew statistics and muddies
# inferences we can do".)* The game names a run's own folder `run-` when a person is at the
# controls and `rig-` when it is headless or driven by --screenshot, --walk, --flee or --press. So
# `-l` prints the kind and `-p` treats every rig but the newest as stale.
#
# `-p` is playtest 10, finding 14: *"is there a mechanism to delete old outdated sessions?"* The
# commit is the last part of a run's own folder name, so "stale" is a question the directory listing
# can answer on its own, by path alone — a run whose name does not end in the commit checked out
# describes a build that no longer exists, and a `run.log` under a few kB is a boot that never
# became a run (`check.sh` and `shot.sh` start the game too). **This is the only thing in the game
# that still deletes anything** — `Telemetry` itself no longer prunes on its own, precisely so the
# folder can grow until a person decides to cut into it, by hand or with this flag.
#
# It never deletes the newest run, and it prints what it would do unless told `yes`, because the one
# thing a trace cannot survive is being thrown away by a tool the person was still exploring.
#
# Note that **one sitting is often several runs**, and that is correct rather than a bug: `R` on the
# pause screen and a finished run both restart, which reloads the scene and opens a new run folder.
# Each folder is one run.
#
# See docs/TELEMETRY.md for what the entries mean.
set -euo pipefail

case "$(uname -s)" in
    Darwin) DIR="$HOME/Library/Application Support/Godot/app_userdata/Nappy/telemetry" ;;
    *)      DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/Nappy/telemetry" ;;
esac

if [[ "${1:-}" == "-d" ]]; then
    echo "$DIR"
    exit 0
fi

if [[ ! -d "$DIR" ]]; then
    echo "no telemetry yet: $DIR" >&2
    echo "play a run with tools/run.sh — it is on unless you pass --no-telemetry" >&2
    exit 1
fi

# Every run folder, `$DIR/<day>/<minute>/<run>`, newest first. Neither a plain path sort nor
# `<day>/<run>` gives that, and the second is the trap: the minute folder sits *between* the day and
# the run, so a path sort interleaves two minutes of one day — but a run folder's name leads with
# `run-` or `rig-` rather than with its clock, so keying on the whole name sorts every playtest
# above every rig whatever time either happened. **The key is the day and the run's `HHMMSS` with
# that prefix cut off**, which is the only part of the name that is a time. Read in a loop rather
# than with `mapfile`, which macOS's bash 3.2 does not have — the same reason the rest of tools/
# stays this side of bash 4.
LOGS=()
while IFS= read -r line; do
    LOGS+=("$line")
done < <(
    find "$DIR" -mindepth 3 -maxdepth 3 -type d \( -name 'run-*' -o -name 'rig-*' \) 2>/dev/null |
    while IFS= read -r path; do
        day="$(basename "$(dirname "$(dirname "$path")")")"
        run="$(basename "$path")"
        printf '%s/%s\t%s\n' "$day" "${run#*-}" "$path"
    done | sort -r | cut -f2-
)
if [[ ${#LOGS[@]} -eq 0 ]]; then
    echo "no runs in $DIR" >&2
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HEAD_COMMIT="$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
# Under this, a run is a boot rather than a play: a game that started, printed its plan and quit
# writes about half a kilobyte, and the shortest real attempt in any playtest is several.
TINY_BYTES=3000

# The commit a run was played on, read off the tail of the run folder's own name:
# `run-<HHMMSS>-seed<N>-<commit>`, the commit last so a busy folder still sorts by age. `sed`
# rather than opening `run.log`, so this works by path alone even on a run still being written.
commit_of() {
    local name tag
    name="$(basename "$1")"
    tag="$(echo "$name" | sed -E 's/^(run|rig)-[0-9]+-seed[0-9]+-(.+)$/\2/')"
    if [[ "$tag" == "$name" ]]; then echo "unknown"; else echo "$tag"; fi
}

# Whether a person was at the controls, read off the run folder's own name: `run-` for a playtest,
# `rig-` for a headless boot or anything driven by --screenshot, --walk, --flee or --press.
kind_of() {
    case "$(basename "$1")" in rig-*) echo "rig" ;; *) echo "play" ;; esac
}

size_of() {
    if [[ -f "$1/run.log" ]]; then wc -c < "$1/run.log" | tr -d ' '; else echo 0; fi
}

# A run's path, relative to $DIR — `<day>/<minute>/<run>`, which is the whole identity a folder
# needs to be found and deleted by hand.
rel_of() { echo "${1#"$DIR"/}"; }

case "${1:-}" in
    -l)
        for i in "${!LOGS[@]}"; do
            printf '%3d  %7s  %-5s  %s\n' "$((i + 1))" \
                "$(size_of "${LOGS[$i]}")" "$(kind_of "${LOGS[$i]}")" "$(rel_of "${LOGS[$i]}")"
        done
        echo "     bytes   kind   day/minute/run (HEAD is $HEAD_COMMIT)" >&2
        ;;
    -p)
        DOOMED=()
        for i in "${!LOGS[@]}"; do
            [[ $i -eq 0 ]] && continue          # never the newest
            RUN_COMMIT="$(commit_of "${LOGS[$i]}")"
            # A rig is stale as soon as it is not the newest thing here. It is a screenshot or a
            # headless boot: it was read once, if at all, and keeping it is what made the folder
            # look like a hundred and sixty playtests.
            if [[ "$(kind_of "${LOGS[$i]}")" == "rig" ]]; then
                DOOMED+=("${LOGS[$i]}")
            elif [[ "$RUN_COMMIT" != "$HEAD_COMMIT" && "$RUN_COMMIT" != "$HEAD_COMMIT-dirty" ]]; then
                DOOMED+=("${LOGS[$i]}")
            elif [[ "$(size_of "${LOGS[$i]}")" -lt $TINY_BYTES ]]; then
                DOOMED+=("${LOGS[$i]}")
            fi
        done
        if [[ ${#DOOMED[@]} -eq 0 ]]; then
            echo "nothing stale: ${#LOGS[@]} runs, all on $HEAD_COMMIT" >&2
            exit 0
        fi
        for run in "${DOOMED[@]}"; do
            printf '%7s  %-14s  %s\n' "$(size_of "$run")" "$(commit_of "$run")" "$(rel_of "$run")"
        done
        if [[ "${2:-}" != "yes" ]]; then
            echo "" >&2
            echo "${#DOOMED[@]} of ${#LOGS[@]} are stale or too short to be a run." >&2
            echo "run 'tools/telemetry.sh -p yes' to delete them and their pictures" >&2
            exit 0
        fi
        for run in "${DOOMED[@]}"; do
            rm -rf "$run"
            # The `<minute>` and `<day>` folders above it, only if deleting this run left them
            # empty — nothing else in the game ever removes them, so this is the one place an
            # empty ancestor is cleaned up, and only because a person asked for `yes`.
            minute_dir="$(dirname "$run")"
            rmdir "$minute_dir" 2>/dev/null || true
            day_dir="$(dirname "$minute_dir")"
            rmdir "$day_dir" 2>/dev/null || true
        done
        echo "deleted ${#DOOMED[@]} runs and their pictures" >&2
        ;;
    -f)
        # A run in progress: every line is flushed as it is written, so this is live.
        echo "== $(rel_of "${LOGS[0]}")" >&2
        tail -f "${LOGS[0]}/run.log"
        ;;
    ''|*[!0-9]*)
        echo "== $(rel_of "${LOGS[0]}")" >&2
        cat "${LOGS[0]}/run.log"
        ;;
    *)
        INDEX=$(( $1 - 1 ))
        if [[ $INDEX -lt 0 || $INDEX -ge ${#LOGS[@]} ]]; then
            echo "only ${#LOGS[@]} runs; asked for $1" >&2
            exit 1
        fi
        echo "== $(rel_of "${LOGS[$INDEX]}")" >&2
        cat "${LOGS[$INDEX]}/run.log"
        ;;
esac
