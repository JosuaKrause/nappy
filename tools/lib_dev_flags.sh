# Shared by tools/run.sh and tools/shot.sh: the one place either script's accept-list for a
# dev flag it forwards to the game lives. Not a script of its own -- `source` it after PROJECT_DIR
# is set.
#
# The accept-list is read live out of src/dev/dev_flags.gd's own DEV_FLAG_TABLE comment block on
# every call, rather than copied here by hand, so a flag added to that table is accepted the next
# time either script runs and a typo is rejected the same way -- see the cli-tools skill and
# dev_flags.gd's own doc comment for what the table's columns mean.

# Prints "flag arity" pairs, one per line, extracted from dev_flags.gd's DEV_FLAG_TABLE.
_dev_flag_table() {
    local file="$PROJECT_DIR/src/dev/dev_flags.gd"
    sed -n '/^## DEV_FLAG_TABLE$/,/^## END_DEV_FLAG_TABLE$/p' "$file" \
        | sed -e '1d' -e '$d' -e 's/^##[[:space:]]*//' \
        | awk 'NF==2'
}

# Loud failure if the table cannot be found at all -- a renamed marker must not silently make
# every flag "unknown" (nothing would ever work) or silently accept everything (the whole point
# of validating). Call once, before trusting the table for anything.
_dev_flag_table_assert() {
    local count
    count="$(_dev_flag_table | wc -l | tr -d ' ')"
    if [[ "$count" -lt 1 ]]; then
        echo "internal error: no DEV_FLAG_TABLE found in src/dev/dev_flags.gd -- the manifest" >&2
        echo "the accept-list is read from is missing or its markers were renamed" >&2
        exit 70
    fi
}

# Prints every flag name in the table, one per line -- what a script's --help lists.
dev_flag_names() {
    _dev_flag_table | awk '{print $1}'
}

# Prints "--flag ARGS" for every row, ARGS spelled out from the arity code so a script's --help
# says what each flag takes without a second, hand-typed copy of the table to drift from it.
# Semantics (what the value *means*) stay in README.md's own table; this is shape only.
dev_flag_usage_lines() {
    local name arity args
    while read -r name arity; do
        local required="${arity%%[!0-9]*}"
        [[ -z "$required" ]] && required=0
        local suffix="${arity#"$required"}"
        args=""
        local k=0
        while (( k < required )); do args+=" <value>"; k=$(( k + 1 )); done
        case "$suffix" in
            *w\?*) args+=" [value]" ;;
            *\?*)  args+=" [number]" ;;
        esac
        case "$suffix" in
            *\**) args+=" (repeatable)" ;;
        esac
        printf '  %s%s\n' "$name" "$args"
    done < <(_dev_flag_table)
}

# The arity code for $1 (see dev_flags.gd's own doc comment), or a nonzero exit if $1 is not in
# the table at all.
_dev_flag_arity() {
    local flag="$1" name arity
    while read -r name arity; do
        if [[ "$name" == "$flag" ]]; then
            printf '%s\n' "$arity"
            return 0
        fi
    done < <(_dev_flag_table)
    return 1
}

# Validates a list of arguments meant to be forwarded to the game as dev flags: an unknown
# --flag, a flag missing its required value, or a bare word that is not a value some preceding
# flag consumed, each print one line on stderr and return non-zero -- before the caller ever
# spends a Godot launch on finding out the same way. Silent and returns 0 when every argument is
# accounted for.
validate_dev_flags() {
    _dev_flag_table_assert
    local -a args=("$@")
    local n=${#args[@]}
    local i=0
    while (( i < n )); do
        local tok="${args[$i]}"
        if [[ "$tok" == "--" ]]; then
            echo "a bare -- is only accepted as the first argument, before any flag" >&2
            return 1
        fi
        if [[ "$tok" != --* ]]; then
            echo "unrecognized argument (not a known flag, and not the value of the flag before it): $tok" >&2
            return 1
        fi
        local arity
        if ! arity="$(_dev_flag_arity "$tok")"; then
            echo "unknown dev flag: $tok" >&2
            return 1
        fi
        i=$(( i + 1 ))
        local required="${arity%%[!0-9]*}"
        [[ -z "$required" ]] && required=0
        local consumed=0
        while (( consumed < required )); do
            if (( i >= n )); then
                echo "$tok is missing its value" >&2
                return 1
            fi
            i=$(( i + 1 ))
            consumed=$(( consumed + 1 ))
        done
        local suffix="${arity#"$required"}"
        case "$suffix" in
            *w\?*)
                if (( i < n )) && [[ "${args[$i]}" != --* ]]; then
                    i=$(( i + 1 ))
                fi
                ;;
            *\?*)
                if (( i < n )) && [[ "${args[$i]}" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
                    i=$(( i + 1 ))
                fi
                ;;
        esac
    done
    return 0
}

# `RouteRig._arrive()` (src/dev/route_rig.gd) quits the process itself the moment she reaches her
# last target, which can happen before `--screenshot`'s own `--after` timer does -- so the
# combination can silently write nothing rather than a picture. Rejected here, before any Godot
# launch, rather than discovered later as a missing file. `tools/shot.sh` calls this on its own
# forwarded flags alone, since it adds `--screenshot` itself; `tools/run.sh` calls it on the whole
# of "$@", since a caller can pass `--screenshot` there directly.
reject_route_with_screenshot() {
    local saw_route="" saw_screenshot="" tok
    for tok in "$@"; do
        [[ "$tok" == "--route" ]] && saw_route=1
        [[ "$tok" == "--screenshot" ]] && saw_screenshot=1
    done
    if [[ -n "$saw_route" && -n "$saw_screenshot" ]]; then
        echo "--route cannot be combined with --screenshot: RouteRig quits the process the moment" >&2
        echo "she arrives, which can happen before --after's own timer fires, so the picture may" >&2
        echo "never be written. Drive a screenshot rig with --walk/--flee/--press instead." >&2
        return 1
    fi
    return 0
}

# ------------------------------------------------------------------ a rig's own lockdown ---
# M195: a rig's window takes no focus, hears no stray key, and always closes. `rig_flag_present()`
# and `rig_kill_after_seconds()` below are the shell half of the same three-defence lockdown
# `DevFlags.is_rig()`/`_lock_out_a_rig()` (src/main.gd) apply from inside the game -- see the
# `RIG_FLAGS` and `RIG_QUIT_SECONDS` marker blocks in src/dev/dev_flags.gd's own doc comment,
# which both sides read live so shot.sh/run.sh can never name a different set of flags, or a
# different deadline, than the game itself is locking down and timing against.

# The `RIG_FLAGS` list, one flag per line, read live out of dev_flags.gd's own marker block --
# the same shape `_dev_flag_table()` above reads `DEV_FLAG_TABLE` in.
_rig_flag_table() {
    local file="$PROJECT_DIR/src/dev/dev_flags.gd"
    sed -n '/^## RIG_FLAGS$/,/^## END_RIG_FLAGS$/p' "$file" \
        | sed -e '1d' -e '$d' -e 's/^##[[:space:]]*//'
}

# Whether any word in "$@" is one of the flags that mark a run as a rig rather than a person at
# the keyboard -- what decides whether run.sh adds --disable-vsync and wraps the launch in the
# external kill below; shot.sh is always a rig and never has to ask.
rig_flag_present() {
    local tok
    for tok in "$@"; do
        if grep -qxF -e "$tok" <(_rig_flag_table); then
            return 0
        fi
    done
    return 1
}

# "name value" pairs from dev_flags.gd's own RIG_QUIT_SECONDS marker block.
_rig_quit_table() {
    local file="$PROJECT_DIR/src/dev/dev_flags.gd"
    sed -n '/^## RIG_QUIT_SECONDS$/,/^## END_RIG_QUIT_SECONDS$/p' "$file" \
        | sed -e '1d' -e '$d' -e 's/^##[[:space:]]*//' \
        | awk 'NF==2'
}

# The value beside $1 ("margin", "ceiling", "kill_grace" or "movie_slowdown") in RIG_QUIT_SECONDS.
_rig_quit_constant() {
    local name="$1"
    awk -v n="$name" '$1==n {print $2; found=1} END {exit !found}' < <(_rig_quit_table)
}

# `src/autoload/tuning.gd`'s own DAY_LENGTH_SECONDS -- read live, the day-length fallback for a
# rig with no --after and no --day-length of its own (a --route, or a bare --walk/--flee/--press/
# --tap with neither --screenshot nor --frame-trace beside it), matching what
# `DevFlags.rig_quit_seconds()` falls back to on the GDScript side (that side additionally shortens
# it for a curfew day; this side stays with the longer, ordinary-day number, which can only ever
# make the external kill wait a little longer than the in-game timer, never race it).
_tuning_day_length_seconds() {
    grep -oE '^const DAY_LENGTH_SECONDS := [0-9.]+' "$PROJECT_DIR/src/autoload/tuning.gd" \
        | grep -oE '[0-9.]+$'
}

# Whole seconds tools/shot.sh's own external kill (or a rig-flagged tools/run.sh's) waits before
# deciding the in-game timer did not fire and killing the process from outside: the same
# script-length-plus-margin-under-a-ceiling formula `DevFlags.rig_quit_seconds_from()` computes,
# plus its own RIG_KILL_GRACE_SECONDS. Args are the dev flags being forwarded to the game --
# an --after value takes precedence over --day-length, the same order the GDScript side reads.
rig_kill_after_seconds() {
    local margin ceiling grace day_length after=""
    margin="$(_rig_quit_constant margin)"
    ceiling="$(_rig_quit_constant ceiling)"
    grace="$(_rig_quit_constant kill_grace)"
    day_length=""
    local -a args=("$@")
    local n=${#args[@]} i=0
    while (( i < n )); do
        case "${args[$i]}" in
            --after) after="${args[$((i + 1))]:-}" ;;
            --day-length) day_length="${args[$((i + 1))]:-}" ;;
        esac
        i=$(( i + 1 ))
    done
    if [[ -z "$day_length" ]]; then
        day_length="$(_tuning_day_length_seconds)"
    fi
    awk -v after="$after" -v day_length="$day_length" -v margin="$margin" \
            -v ceiling="$ceiling" -v grace="$grace" 'BEGIN {
        script = (after != "") ? after + 0 : day_length + 0
        deadline = script + margin
        if (deadline < margin) deadline = margin
        if (deadline > ceiling) deadline = ceiling
        total = deadline + grace
        printf "%d\n", (total == int(total)) ? total : int(total) + 1
    }'
}

# The same kill wait for a rig recording through Godot's movie writer (`--write-movie`, which
# tools/trailer.sh launches every shot with), given the shot's own --after in $1: the game's own
# deadline under the writer stretches the script by `movie_slowdown` -- see
# `DevFlags.rig_quit_seconds_from()`'s `slowdown`, which this mirrors -- and the ceiling still
# bounds it, so this is that deadline plus the same kill grace.
rig_kill_after_movie_seconds() {
    local after="$1" margin ceiling grace slowdown
    margin="$(_rig_quit_constant margin)"
    ceiling="$(_rig_quit_constant ceiling)"
    grace="$(_rig_quit_constant kill_grace)"
    slowdown="$(_rig_quit_constant movie_slowdown)"
    awk -v after="$after" -v slowdown="$slowdown" -v margin="$margin" -v ceiling="$ceiling" \
            -v grace="$grace" 'BEGIN {
        deadline = after * slowdown + margin
        if (deadline < margin) deadline = margin
        if (deadline > ceiling) deadline = ceiling
        total = deadline + grace
        printf "%d\n", (total == int(total)) ? total : int(total) + 1
    }'
}

# Waits for process $1 to exit, killing it (SIGKILL) if it is still alive after $2 whole seconds.
# Returns 0 if it exited on its own -- its real exit status is left in WAIT_OR_KILL_STATUS, since
# this already reaped it and a caller's own second `wait` on the same pid would just error -- or 1
# if this function had to kill it itself.
#
# **A background watchdog timer, not a `kill -0` polling loop.** A process that has already exited
# but not yet been reaped (a zombie) still answers `kill -0` successfully, so polling that way
# would sit out the *entire* timeout even for a process that exited in the first tenth of a second
# -- turning "wait up to N seconds" into "always wait N seconds". `wait "$pid"` is the one call
# that blocks exactly until the real exit and reaps it at the same time; the subshell below is
# only there to SIGKILL it if that has not happened by the deadline, and the marker file is how
# this function tells which of the two actually ended the wait.
WAIT_OR_KILL_STATUS=0
wait_or_kill() {
    local pid="$1" limit="$2"
    local marker
    # `-u`: print a unique name without creating the file. `mktemp` alone *creates* it as part of
    # naming it, which would make the `-f` check below true from this line on regardless of
    # whether the watchdog ever ran -- the bug the first version of this function shipped with,
    # caught by tools/test_cli_help.sh reporting an instant, spurious kill on a stub that exits in
    # milliseconds.
    marker="$(mktemp -u)"
    (
        sleep "$limit"
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null
            : > "$marker"
        fi
    ) &
    local watchdog=$!
    wait "$pid" 2>/dev/null
    WAIT_OR_KILL_STATUS=$?
    # Stop the watchdog if the process already exited on its own -- otherwise it is still asleep
    # and would fire pointlessly, or (rarer, a close race) has already fired and this is a no-op.
    kill "$watchdog" 2>/dev/null
    wait "$watchdog" 2>/dev/null
    if [[ -f "$marker" ]]; then
        rm -f "$marker"
        return 1
    fi
    rm -f "$marker"
    return 0
}

# ----------------------------------------------------- macOS: a rig hands focus straight back ---
# M198 (PLAYTEST-133, statements 6 and 7): M195's `DisplayServer.WINDOW_FLAG_NO_FOCUS` keeps keys
# out of a rig's window, but macOS still makes the app itself frontmost once Godot's own AppKit
# startup calls `activateIgnoringOtherApps:` -- an explicit runtime call the process makes on its
# own once its window is ready, not something a launch flag mediates. A background launch (`open
# -g`, measured on the closed PR #357) only delays that call, it does not gate it, and nothing
# reachable from this repo does either -- see #357's own measurement (`lsappinfo front` frontmost
# for 34 of 38 samples of a walking rig) before trying to revive that path.
#
# So this does not try to stop the jump; it undoes it. `rig_focus_note()` (called *before* Godot
# launches) prints whichever app was frontmost then, and `rig_focus_watch_start` arms a background
# watcher that polls `lsappinfo front` and reactivates that app the moment the rig's own Godot
# (matched by pid, never by name, so another agent's own Godot capture is never mistaken for this
# one) becomes frontmost -- for as long as the rig runs. Only a switch *to* this rig's Godot is
# undone: if the player moves to a third app on purpose, this leaves them there, since the watcher
# only ever acts when the frontmost pid is the one it was told to watch.
#
# **No `osascript` and no Apple Events** -- `open -a`/`-b` is a LaunchServices activation request,
# the one mechanism the player agreed to; nothing here sends an event into another app or scripts
# it. `rig_focus_guard_available` gates the whole thing off anywhere it cannot work cleanly: off
# Darwin, and off a checkout with no `lsappinfo` or `open` on PATH (both are stock in every macOS
# install actually able to run Godot windowed, so this is a defensive floor, not a real fork). A
# non-macOS platform and a person's own flagless `run.sh` session are untouched either way -- this
# is only ever reached from inside a rig's own launch, on macOS.

# Whether this Mac can run the watcher below at all.
rig_focus_guard_available() {
    [[ "$(uname -s 2>/dev/null)" == "Darwin" ]] || return 1
    command -v lsappinfo >/dev/null 2>&1 || return 1
    command -v open >/dev/null 2>&1 || return 1
    return 0
}

# Prints the `.app` bundle path of whichever app is frontmost right now, or prints nothing at all
# when there is nothing sensible to note: no frontmost ASN (`lsappinfo front` empty, or the info
# lookup on it failed), or the frontmost app is already the same `.app` bundle `$GODOT` launches --
# this rig's own Godot has not launched yet at the point this is called, so a bundle-path match
# here can only mean a Godot window some *other* agent is already running, and handing focus back
# to a Godot window is not what "back" means. Called once, before Godot launches.
rig_focus_note() {
    rig_focus_guard_available || return 0
    local asn path
    asn="$(lsappinfo front 2>/dev/null)"
    [[ -n "$asn" ]] || return 0
    path="$(lsappinfo info -only bundlePath "$asn" 2>/dev/null \
        | sed -n 's/^"LSBundlePath"="\(.*\)"$/\1/p')"
    [[ -n "$path" ]] || return 0
    local godot_app="${GODOT%/Contents/MacOS/*}"
    [[ "$path" == "$godot_app" ]] && return 0
    printf '%s\n' "$path"
}

# How often the watcher below polls `lsappinfo front` while the rig runs -- each poll is two
# short-lived `lsappinfo` calls, so this trades flicker length against how many of those a capture
# spends. 0.1s is the fast end of the brief's suggested 0.1-0.2s range; see this PR's own report
# for the sample counts measured against it.
RIG_FOCUS_POLL_SECONDS="0.1"

# The watcher loop itself -- not called directly, only from rig_focus_watch_start's own background
# job below. Exits on its own once $1 (the rig's Godot pid) is no longer alive, which is what lets
# the watcher "die with the rig" even on a path that skips rig_focus_watch_stop.
_rig_focus_watch_loop() {
    local godot_pid="$1" noted_app="$2"
    while kill -0 "$godot_pid" 2>/dev/null; do
        local asn pid
        asn="$(lsappinfo front 2>/dev/null)"
        if [[ -n "$asn" ]]; then
            pid="$(lsappinfo info -only pid "$asn" 2>/dev/null | sed -n 's/^"pid"=//p')"
            if [[ "$pid" == "$godot_pid" ]]; then
                open -a "$noted_app" >/dev/null 2>&1 || true
            fi
        fi
        sleep "$RIG_FOCUS_POLL_SECONDS"
    done
}

# Starts the watcher above as a background job watching pid $1 for as long as it lives, ready to
# reactivate $2 (a `.app` bundle path, `rig_focus_note`'s own output) whenever it becomes
# frontmost. Prints the watcher's own pid so the caller can stop it early with
# rig_focus_watch_stop, or prints nothing and starts nothing at all when $2 is empty (nothing was
# noted, see rig_focus_note) or the guard is unavailable -- so a caller that always calls this and
# always passes the result to rig_focus_watch_stop needs no platform check of its own.
#
# **The watcher's own stdout and stderr are redirected to /dev/null, not inherited.** A caller
# always invokes this through `x="$(rig_focus_watch_start ...)"` to capture the printed pid, and
# bash does not consider that command substitution finished -- however long ago its own subshell
# printed the pid and exited -- until every process holding its write end of the capture pipe has
# closed it. Left inheriting that pipe, the watcher (which lives for the whole rig, not an instant)
# would hold it open for as long as it runs, so `x="$(...)"` would block until the rig's own Godot
# exits -- which is exactly what `wait_or_kill`'s external kill exists to catch, so the caller
# would never even reach the call that arms it. Found by a live `--after`-ignoring stub: the
# outside kill never fired, because the script was still stuck assigning `FOCUS_WATCHER_PID`.
rig_focus_watch_start() {
    local godot_pid="$1" noted_app="$2"
    [[ -n "$noted_app" ]] || return 0
    rig_focus_guard_available || return 0
    ( _rig_focus_watch_loop "$godot_pid" "$noted_app" ) >/dev/null 2>&1 &
    printf '%s\n' "$!"
}

# Stops a watcher started above. Safe to call with an empty argument (nothing was started) and
# safe to call more than once.
rig_focus_watch_stop() {
    local watcher_pid="$1"
    [[ -n "$watcher_pid" ]] || return 0
    kill "$watcher_pid" 2>/dev/null || true
    wait "$watcher_pid" 2>/dev/null || true
}
