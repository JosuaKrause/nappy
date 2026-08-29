#!/usr/bin/env bash
# Show a run log. Exists because `user://` is somewhere nobody can be expected to remember,
# and on macOS it is inside ~/Library, which Finder hides by default.
#
#   tools/telemetry.sh              # print the newest run
#   tools/telemetry.sh -f           # follow the run that is happening right now
#   tools/telemetry.sh -l           # list what is there, newest first, with size and commit
#   tools/telemetry.sh -d           # print the directory and nothing else
#   tools/telemetry.sh -p           # say what is stale; -p yes actually deletes it
#   tools/telemetry.sh 3            # print the third-newest run
#
# `-p` is playtest 10, finding 14: *"is there a mechanism to delete old outdated sessions?"* Since
# M39 the abbreviated commit is in every filename, so "stale" is a question the directory listing
# can answer on its own — a log from a commit that is not the one checked out describes a build that
# no longer exists, and a log under a few kB is a boot that never became a run (`check.sh` and
# `shot.sh` start the game too). Snapshots taken during a run are named after it and go with it.
#
# It never deletes the newest log, and it prints what it would do unless told `yes`, because the one
# thing a trace cannot survive is being thrown away by a tool the person was still exploring.
#
# Note that **one sitting is often several logs**, and that is correct rather than a bug: since M38
# `R` on the pause screen and a finished run both restart, which reloads the scene and opens a new
# log. Each file is one run.
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

# Newest first. `ls -t` rather than sorting the names, so a log still being written to sorts
# where it belongs. Read in a loop rather than with `mapfile`, which macOS's bash 3.2 does
# not have — the same reason the rest of tools/ stays this side of bash 4.
LOGS=()
while IFS= read -r line; do
    LOGS+=("$line")
done < <(ls -t "$DIR"/run-*.log 2>/dev/null || true)
if [[ ${#LOGS[@]} -eq 0 ]]; then
    echo "no run logs in $DIR" >&2
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HEAD_COMMIT="$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
# Under this, a log is a boot rather than a run: a game that started, printed its plan and quit
# writes about half a kilobyte, and the shortest real attempt in any playtest is several.
TINY_BYTES=3000

# The commit a log was played on, read out of its own name. Logs from before M39 have no commit
# in the name at all and answer "older", which is the right answer for them.
commit_of() {
    local stem tag
    stem="$(basename "$1" .log)"
    tag="$(echo "$stem" | sed -E 's/^run-.*-seed[0-9]+-(.+)$/\1/')"
    # No match leaves the whole stem, which is how a pre-M39 name (`run-<stamp>-seed<n>`) answers.
    if [[ "$tag" == "$stem" ]]; then echo "older"; else echo "$tag"; fi
}

size_of() { wc -c < "$1" | tr -d ' '; }

case "${1:-}" in
    -l)
        for i in "${!LOGS[@]}"; do
            printf '%3d  %7s  %-14s  %s\n' "$((i + 1))" \
                "$(size_of "${LOGS[$i]}")" "$(commit_of "${LOGS[$i]}")" \
                "$(basename "${LOGS[$i]}")"
        done
        echo "     bytes   commit          (HEAD is $HEAD_COMMIT)" >&2
        ;;
    -p)
        DOOMED=()
        for i in "${!LOGS[@]}"; do
            [[ $i -eq 0 ]] && continue          # never the newest
            LOG_COMMIT="$(commit_of "${LOGS[$i]}")"
            if [[ "$LOG_COMMIT" != "$HEAD_COMMIT" && "$LOG_COMMIT" != "$HEAD_COMMIT-dirty" ]]; then
                DOOMED+=("${LOGS[$i]}")
            elif [[ "$(size_of "${LOGS[$i]}")" -lt $TINY_BYTES ]]; then
                DOOMED+=("${LOGS[$i]}")
            fi
        done
        if [[ ${#DOOMED[@]} -eq 0 ]]; then
            echo "nothing stale: ${#LOGS[@]} logs, all on $HEAD_COMMIT" >&2
            exit 0
        fi
        for log in "${DOOMED[@]}"; do
            printf '%7s  %-14s  %s\n' "$(size_of "$log")" "$(commit_of "$log")" \
                "$(basename "$log")"
        done
        if [[ "${2:-}" != "yes" ]]; then
            echo "" >&2
            echo "${#DOOMED[@]} of ${#LOGS[@]} are stale or too short to be a run." >&2
            echo "run 'tools/telemetry.sh -p yes' to delete them and their snapshots" >&2
            exit 0
        fi
        for log in "${DOOMED[@]}"; do
            rm -f "$log" "${log%.log}"-*.png
        done
        echo "deleted ${#DOOMED[@]} logs and their snapshots" >&2
        ;;
    -f)
        # A run in progress: every line is flushed as it is written, so this is live.
        echo "== ${LOGS[0]}" >&2
        tail -f "${LOGS[0]}"
        ;;
    ''|*[!0-9]*)
        echo "== ${LOGS[0]}" >&2
        cat "${LOGS[0]}"
        ;;
    *)
        INDEX=$(( $1 - 1 ))
        if [[ $INDEX -lt 0 || $INDEX -ge ${#LOGS[@]} ]]; then
            echo "only ${#LOGS[@]} logs; asked for $1" >&2
            exit 1
        fi
        echo "== ${LOGS[$INDEX]}" >&2
        cat "${LOGS[$INDEX]}"
        ;;
esac
