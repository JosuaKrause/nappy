#!/usr/bin/env bash
# Show a run log. Exists because `user://` is somewhere nobody can be expected to remember,
# and on macOS it is inside ~/Library, which Finder hides by default.
#
#   tools/telemetry.sh              # print the newest run
#   tools/telemetry.sh -f           # follow the run that is happening right now
#   tools/telemetry.sh -l           # list what is there, newest first
#   tools/telemetry.sh -d           # print the directory and nothing else
#   tools/telemetry.sh 3            # print the third-newest run
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

case "${1:-}" in
    -l)
        for i in "${!LOGS[@]}"; do
            printf '%3d  %s\n' "$((i + 1))" "$(basename "${LOGS[$i]}")"
        done
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
