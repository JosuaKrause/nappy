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

# The value beside $1 ("margin", "ceiling" or "kill_grace") in RIG_QUIT_SECONDS.
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

# --------------------------------------------------------- macOS: launched without activating ---
# M198: whether `rig_run_backgrounded` below is available at all -- Darwin, and $GODOT resolving
# to a real .app bundle's own binary. A stub (like tools/test_cli_help.sh's own $GODOT override)
# does not match "*/Contents/MacOS/*", so its tests keep exercising the direct launch in
# shot.sh/run.sh unchanged; neither does a Linux checkout, or any Godot binary run from outside a
# .app. This name promises less than it used to: see `rig_run_backgrounded`'s own doc comment for
# what "backgrounded" does and does not deliver on this Mac.
rig_can_launch_in_background() {
    [[ "$(uname -s 2>/dev/null)" == "Darwin" ]] || return 1
    [[ "$GODOT" == */Contents/MacOS/* ]] || return 1
    [[ -x "$GODOT" ]] || return 1
    command -v open >/dev/null 2>&1 || return 1
    command -v pgrep >/dev/null 2>&1 || return 1
    return 0
}

# Launches Godot for a rig through `open -g -n -W` rather than as this script's own direct child,
# waits for it with the same kill-after-N-seconds contract `wait_or_kill` above carries, and relays
# its stdout/stderr live. Args: the whole-run kill deadline in seconds (`rig_kill_after_seconds`'s
# own output), then every argument Godot itself is to see -- engine flags and the game's own, in
# the same order a direct launch would give them; this function adds nothing of its own to that
# list. Returns 1 if the outside kill fired, the same contract `wait_or_kill`'s own return value
# carries; the caller's own file check is still what decides whether a picture exists, exactly as
# for a direct launch.
#
# **This does not make the milestone's own test pass.** M198 asks that a rig's window never
# becomes the active app; measured on this Mac with `lsappinfo front` sampled every 0.2-0.25s
# across many captures, `open -g -n -W` delays Godot becoming frontmost by roughly the time its
# window takes to appear (well under a second) but does not prevent it once the window is up --
# indistinguishable, from that point on, from a direct launch's own front time, for any capture
# that keeps the engine actually doing something (`--walk`, `--flee`, an ordinary `run.sh` session
# -- the two idle-standing trials that looked like a full fix were not reproduced once a moving rig
# was sampled the same way). `strings` on `/Applications/Godot.app/Contents/MacOS/Godot` finds
# `activateIgnoringOtherApps:` and `setActivationPolicy:` in the binary: Godot's own AppKit startup
# activates itself once its window is ready, an explicit runtime call the process makes on its own
# rather than something LaunchServices mediates, so `-g` -- which only tells LaunchServices not to
# switch to the app *at launch* -- has nothing to intercept once that call fires. `-j` (launch
# hidden) was tried too and made it worse (frontmost for the entire run, no delay at all). No
# command-line flag, project setting, or GDScript-reachable API was found that gates either call,
# so nothing inside the engine as scripted here can stop it either. **What this function still
# buys:** the brief delay before activation, which matters for a very short `--after`; the
# orphan-safe kill and live relay below, useful on their own regardless of the activation question;
# and a seam to build a real fix on if one is ever found (an Info.plist change to a private copy of
# Godot.app, or an engine-side activation-policy hook, neither in scope here). **Open to overturn**
# if a live session shows the player's own focus staying put regardless -- this measurement's
# environment is not necessarily identical to an interactive desktop session.
#
# **Why `open`'s own exit status is never read as Godot's.** Killing the real Godot process while
# `open -W` was still waiting on it left `open` itself reporting exit 0 -- proven by force-killing
# the real process mid-run and comparing against a direct launch's `wait`, which correctly reported
# 137. So `open`'s own pid is only ever used for the one thing it is good for -- letting `wait`
# block without spinning -- and its exit code is discarded; `WAIT_OR_KILL_STATUS` is not set by this
# function, and a caller that cares whether the run failed for a reason other than the outside kill
# firing has to keep reading that off the file it asked Godot to write, same as it already did.
#
# **Finding the real process.** LaunchServices reparents the launched app under launchd, not this
# shell, so it is not something `wait` can block on or `kill` reliably reach by any pid this
# function was handed -- it is found the way a person would look for it instead, by the one
# argument that names this worktree and no other: `--path "$PROJECT_DIR"`, distinct from every
# other worktree's own absolute path, including the ones other agents' captures are running from at
# the same time. **Not verified live, open to overturn:** two rigs launched from the same worktree
# at once would collide on that match; nothing here currently runs more than one at a time.
#
# **The same reparenting cuts the other way too, and is why the watchdog below carries its own
# trap.** Measured by running a rig-flagged `run.sh` under an outside `timeout` that tears the
# script down early: a direct launch's Godot child dies in the same sweep (a real child shares this
# shell's own process group, which the kernel signals as a whole), but `open`'s launchd-reparented
# Godot did not -- it kept running, orphaned, until killed by hand. That is a worse version of the
# exact bug M195 exists to stop, so the watchdog subshell below is `trap`-armed against the same
# signal sweep and `disown`ed, so it keeps sleeping toward its own deadline and still reaches the
# real pid by number no matter what happened to `run.sh`, `open`, or this function's own call
# frame in the meantime -- the one thing that still cannot survive is a `SIGKILL` sent to the whole
# process group, which no trap catches; nothing here claims to defend against that.
rig_run_backgrounded() {
    local kill_after="$1"
    shift
    local app="${GODOT%/Contents/MacOS/*}"

    local stdout_file stderr_file
    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"

    open -g -n -W -a "$app" --stdout "$stdout_file" --stderr "$stderr_file" --args "$@" &
    local open_pid=$!

    # Relayed live rather than dumped after the fact -- a rig-flagged run.sh session can run for
    # minutes, and its output is exactly what a person watching it wants as it happens.
    tail -n +1 -f "$stdout_file" &
    local tail_out_pid=$!
    tail -n +1 -f "$stderr_file" >&2 &
    local tail_err_pid=$!

    local real_pid="" tries=0
    while (( tries < 100 )); do
        real_pid="$(pgrep -f -- "--path $PROJECT_DIR " | head -n1 || true)"
        [[ -n "$real_pid" ]] && break
        kill -0 "$open_pid" 2>/dev/null || break
        sleep 0.1
        tries=$(( tries + 1 ))
    done

    # `trap '' TERM HUP` (a fresh subshell, so this does not touch the caller's own traps): the
    # real Godot process is reparented under launchd, not this shell, and measured to survive a
    # SIGTERM sent to this whole process group -- see rig_run_backgrounded's own doc comment above
    # this function for the trial that found it still running after the script that launched it
    # was torn down by an outside `timeout`. Without this trap the watchdog below dies in the same
    # sweep, and nothing is left to kill the orphan except Godot's own in-game wall-clock timer;
    # with it, the watchdog keeps sleeping toward its own deadline and still reaches for the real
    # pid by number, which works regardless of what process group or session it is in by then.
    local marker
    marker="$(mktemp -u)"
    (
        trap '' TERM HUP
        sleep "$kill_after"
        if [[ -n "$real_pid" ]] && kill -0 "$real_pid" 2>/dev/null; then
            kill -9 "$real_pid" 2>/dev/null
            : > "$marker"
        fi
    ) &
    local watchdog=$!
    disown "$watchdog" 2>/dev/null || true

    wait "$open_pid" 2>/dev/null
    kill "$watchdog" 2>/dev/null
    wait "$watchdog" 2>/dev/null

    # A moment for the tails to catch up with whatever Godot last flushed before they are stopped.
    sleep 0.2
    kill "$tail_out_pid" "$tail_err_pid" 2>/dev/null
    wait "$tail_out_pid" "$tail_err_pid" 2>/dev/null
    rm -f "$stdout_file" "$stderr_file"

    if [[ -f "$marker" ]]; then
        rm -f "$marker"
        return 1
    fi
    rm -f "$marker"
    if [[ -z "$real_pid" ]]; then
        echo "rig_run_backgrounded: never found Godot's own process (open -a may have failed)" >&2
        return 1
    fi
    return 0
}
