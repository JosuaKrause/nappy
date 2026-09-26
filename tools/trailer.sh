#!/usr/bin/env bash
# Render the trailer from the game itself, frame-locked, from the checked-in shot list.
#
#   tools/trailer.sh                  # every shot, joined -> build/trailer/trailer.mp4
#   tools/trailer.sh --shot choice    # one shot alone     -> build/trailer/shot-choice.mp4
#   tools/trailer.sh --check choice   # render it twice and compare every frame's hash
#   tools/trailer.sh --check all      # the same for every shot
#   tools/trailer.sh --list           # print the shot list and render nothing
#
# PLAYTEST-139: "we can use recordings from a frame locked game. the trailer will be a set of
# paths in pre determined seeds with fixed events so we can reproduce it easily" · "we need to be
# careful not to directly check in either the images or the video so it should be possible to
# run by me and I can generate the video myself. so the setting scripts need to produce the same
# output every time."
#
# Each shot in tools/trailer/shots.json is one Godot launch through its own movie writer
# (`--write-movie <tmp>/frame.png --fixed-fps <fps>`): the game runs frame-locked -- every frame
# advances the clock by exactly 1/fps however long it takes to draw and save -- and writes one PNG
# per frame plus `frame.wav`, the game's own audio mixed at the same clock. The shot's cut is
# taken out of those frames, faded in and out of black and encoded, and the frames are deleted
# before the next shot starts; the shots are then joined into one H.264/AAC file. Everything this
# writes is under build/ (gitignored) or a temporary directory it removes, and it fails, naming the
# paths, if the working tree's own status changed while it ran.
#
# The window opens at the game's own resolution (project.godot's viewport size), takes no focus
# and hears no stray key: the movie writer (`--write-movie`) makes DevFlags.recording() true, which
# is itself one of is_rig()'s conditions, so the game's M195 lockdown applies without any dev flag
# of its own, and the same focus guard tools/shot.sh uses hands focus straight back. Every shot also
# carries `--player-view`, so the frame is the release build's own HUD with the debug readout off
# rather than a rig's, and `--no-focus-pause`, since a window that never has real OS focus in the
# first place would otherwise open the pause screen on its own first frame and every frame shows
# that instead of the day it was sent to render. A shot is killed from outside if it outlives the
# movie writer's own deadline
# (see rig_kill_after_movie_seconds in tools/lib_dev_flags.sh).
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHOTS_FILE="$PROJECT_DIR/tools/trailer/shots.json"
OUT_DIR="$PROJECT_DIR/build/trailer"
# shellcheck source=tools/lib_dev_flags.sh
source "$PROJECT_DIR/tools/lib_dev_flags.sh"

usage() {
    cat <<EOF
usage: tools/trailer.sh [--help|-h] [--list | --shot NAME | --check NAME|all]

Renders the trailer from tools/trailer/shots.json: each shot through Godot's movie writer,
frame-locked, at the game's own resolution with its audio; then fades, joins and encodes them.
Frames are deleted as soon as each shot is encoded. Output goes to build/trailer/ (gitignored).

  (no flag)        render every shot and join them into build/trailer/trailer.mp4
  --shot NAME      render one shot alone into build/trailer/shot-NAME.mp4
  --check NAME     render the shot twice and compare every frame's hash; exits non-zero on a
                   difference inside the shot's cut
  --check all      the same for every shot in the list
  --list           print the shot list (name, seed, day, parent, length, caption); render nothing

  tools/trailer.sh --shot choice

Opens a window for each shot. Needs jq and ffmpeg on PATH, and Godot 4.7 at \$GODOT.
EOF
}

MODE="all"
TARGET=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --list)
            [[ "$MODE" == "all" ]] || { echo "--list cannot be combined with --$MODE" >&2; usage >&2; exit 1; }
            MODE="list"; shift ;;
        --shot|--check)
            [[ "$MODE" == "all" ]] || { echo "$1 cannot be combined with --$MODE" >&2; usage >&2; exit 1; }
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "$1 is missing its shot name" >&2; echo >&2; usage >&2; exit 1
            fi
            MODE="${1#--}"; TARGET="$2"; shift 2 ;;
        *)
            echo "unrecognized argument: $1" >&2; echo >&2; usage >&2; exit 1 ;;
    esac
done

for tool in jq ffmpeg; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "trailer.sh: $tool not found on PATH" >&2
        exit 127
    fi
done
if [[ ! -f "$SHOTS_FILE" ]]; then
    echo "trailer.sh: no shot list at ${SHOTS_FILE#"$PROJECT_DIR"/}" >&2
    exit 1
fi

# ------------------------------------------------------------------- the shot list, checked ---
# Every shot is checked before any window opens: the fields a shot must carry, the dev flags it
# forwards (against the game's own DEV_FLAG_TABLE, the same way run.sh and shot.sh check theirs),
# and the whole cut against the list's own `max_seconds` -- PLAYTEST-139's "30s should be max".
schema_errors="$(jq -r '
    def num: type == "number";
    (if (.fps | num) and .fps > 0 then empty else "fps must be a positive number" end),
    (if (.max_seconds | num) then empty else "max_seconds must be a number" end),
    (if (.shots | type) == "array" and (.shots | length) > 0 then empty
        else "shots must be a non-empty array" end),
    ((.shots // [])[] |
        (.name // "?") as $n |
        (if (.name | type) == "string" and (.name | test("^[a-z0-9-]+$")) then empty
            else "a shot name must be lower-case letters, digits and dashes: \($n)" end),
        (if (.seed | num) and .seed > 0 then empty else "\($n): seed must be a positive number" end),
        (if (.day // 1 | num) then empty else "\($n): day must be a number" end),
        (if .parent == "mother" or .parent == "father" then empty
            else "\($n): parent must be mother or father" end),
        (if (.length | num) and .length > 0 then empty else "\($n): length must be positive" end),
        (if (.in // 0 | num) and (.in // 0) >= 0 then empty else "\($n): in must be >= 0" end),
        (if (.gap // 0 | num) and (.gap // 0) >= 0 then empty else "\($n): gap must be >= 0" end),
        (if (.flags // [] | type) == "array" and all(.flags // [] | .[]; type == "string")
            then empty else "\($n): flags must be an array of strings" end)
    ),
    (if ([.shots[]?.name] | length) == ([.shots[]?.name] | unique | length) then empty
        else "two shots share a name" end)
' "$SHOTS_FILE" 2>&1)" || { echo "trailer.sh: ${SHOTS_FILE#"$PROJECT_DIR"/} is not valid JSON" >&2; exit 1; }
if [[ -n "$schema_errors" ]]; then
    echo "trailer.sh: ${SHOTS_FILE#"$PROJECT_DIR"/} is malformed:" >&2
    printf '  %s\n' "$schema_errors" >&2
    exit 1
fi

FPS="$(jq -r '.fps' "$SHOTS_FILE")"
MAX_SECONDS="$(jq -r '.max_seconds' "$SHOTS_FILE")"
DEFAULT_FADE="$(jq -r '.fade // 0.25' "$SHOTS_FILE")"
SHOT_NAMES=()
while IFS= read -r name; do SHOT_NAMES+=("$name"); done < <(jq -r '.shots[].name' "$SHOTS_FILE")

# One field of one shot, or $3 when the shot does not carry it.
shot_field() {
    jq -r --arg n "$1" --arg f "$2" --arg d "${3:-}" \
        '.shots[] | select(.name == $n) | (.[$f] // $d) | tostring' "$SHOTS_FILE"
}

# The dev flags a shot forwards to the game, one per line: its seed, day, parent and walk, the
# `--after` its cut needs, its free-form `flags`, and its caption and title card.
shot_game_flags() {
    local name="$1" walk caption title after
    walk="$(shot_field "$name" walk)"
    caption="$(shot_field "$name" caption)"
    title="$(shot_field "$name" title)"
    after="$(shot_render_seconds "$name")"
    printf '%s\n' --player-view --no-save --no-focus-pause \
        --seed "$(shot_field "$name" seed)" --day "$(shot_field "$name" day 1)" \
        --parent "$(shot_field "$name" parent)" --after "$after"
    [[ -n "$walk" ]] && printf '%s\n' --walk "$walk"
    jq -r --arg n "$name" '.shots[] | select(.name == $n) | (.flags // [])[]' "$SHOTS_FILE"
    [[ -n "$caption" ]] && printf '%s\n' --caption "$caption"
    [[ -n "$title" ]] && printf '%s\n' --title-card "$title"
    return 0
}

# How long the game runs for a shot: to the end of its cut and a few frames past it, so the last
# frame of the cut is always written before the game quits.
shot_render_seconds() {
    awk -v a="$(shot_field "$1" in 0.5)" -v b="$(shot_field "$1" length)" \
        'BEGIN { printf "%.3f\n", a + b + 0.2 }'
}

total_seconds="$(jq -r '[.shots[] | (.gap // 0) + .length] | add' "$SHOTS_FILE")"
if awk -v t="$total_seconds" -v m="$MAX_SECONDS" 'BEGIN { exit !(t > m + 0.0001) }'; then
    echo "trailer.sh: the shot list runs ${total_seconds}s, over its own max_seconds ($MAX_SECONDS)" >&2
    exit 1
fi

for name in "${SHOT_NAMES[@]}"; do
    flags=()
    while IFS= read -r word; do flags+=("$word"); done < <(shot_game_flags "$name")
    if ! validate_dev_flags "${flags[@]}"; then
        echo "trailer.sh: shot '$name' forwards a flag the game does not know (see above)" >&2
        exit 1
    fi
done

if [[ "$MODE" == "shot" || "$MODE" == "check" ]] && [[ "$TARGET" != "all" || "$MODE" == "shot" ]]; then
    found=""
    for name in "${SHOT_NAMES[@]}"; do [[ "$name" == "$TARGET" ]] && found=1; done
    if [[ -z "$found" ]]; then
        echo "trailer.sh: no shot named '$TARGET' in the list (${SHOT_NAMES[*]})" >&2
        exit 1
    fi
fi

if [[ "$MODE" == "list" ]]; then
    printf '%-10s %10s %4s %-7s %6s %5s  %s\n' shot seed day parent length gap caption
    for name in "${SHOT_NAMES[@]}"; do
        text="$(shot_field "$name" caption)"
        [[ -z "$text" ]] && text="$(shot_field "$name" title)"
        printf '%-10s %10s %4s %-7s %6s %5s  %s\n' "$name" "$(shot_field "$name" seed)" \
            "$(shot_field "$name" day 1)" "$(shot_field "$name" parent)" \
            "$(shot_field "$name" length)" "$(shot_field "$name" gap 0)" "$text"
    done
    echo "total ${total_seconds}s of ${MAX_SECONDS}s"
    exit 0
fi

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT" >&2
    echo "install Godot 4.7, or point GODOT at your binary:" >&2
    echo "  GODOT=/path/to/Godot tools/trailer.sh" >&2
    exit 127
fi

# The game's own resolution, read where the game declares it.
WIDTH="$(sed -n 's/^window\/size\/viewport_width=//p' "$PROJECT_DIR/project.godot")"
HEIGHT="$(sed -n 's/^window\/size\/viewport_height=//p' "$PROJECT_DIR/project.godot")"
if ! [[ "$WIDTH" =~ ^[0-9]+$ && "$HEIGHT" =~ ^[0-9]+$ ]]; then
    echo "trailer.sh: could not read the viewport size from project.godot" >&2
    exit 1
fi

# The baked atlas pages, repaired the way tools/shot.sh repairs them -- see its own comment.
if ! "$PROJECT_DIR/tools/bake-atlases.sh" --check >/dev/null 2>&1; then
    "$PROJECT_DIR/tools/bake-atlases.sh" --check >&2 || true
    echo "rebuilding with tools/check.sh -- this takes a few seconds" >&2
    if ! "$PROJECT_DIR/tools/check.sh" >/dev/null; then
        echo "tools/check.sh failed; run it directly to see why" >&2
        exit 1
    fi
fi

# ------------------------------------------------------------------------------ rendering ---
WORK="$(mktemp -d "${TMPDIR:-/tmp}/nappy-trailer.XXXXXX")"
FOCUS_WATCHER_PID=""
cleanup() {
    rig_focus_watch_stop "$FOCUS_WATCHER_PID"
    rm -rf "$WORK"
}
trap cleanup EXIT

TREE_BEFORE="$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || true)"

# Renders shot $1's frames and audio into directory $2 (created empty). Fails loudly if Godot
# did not quit on its own or did not write the frames the cut needs.
render_frames() {
    local name="$1" dir="$2" after kill_after flags=()
    rm -rf "$dir"; mkdir -p "$dir"
    while IFS= read -r word; do flags+=("$word"); done < <(shot_game_flags "$name")
    after="$(shot_render_seconds "$name")"
    kill_after="$(rig_kill_after_movie_seconds "$after")"
    echo "rendering '$name' (${after}s of game at ${FPS}fps)..." >&2
    local noted
    noted="$(rig_focus_note)"
    "$GODOT" --path "$PROJECT_DIR" --resolution "${WIDTH}x${HEIGHT}" --disable-vsync \
        --write-movie "$dir/frame.png" --fixed-fps "$FPS" \
        -- "${flags[@]}" > "$dir/godot.log" 2>&1 &
    local pid=$!
    FOCUS_WATCHER_PID="$(rig_focus_watch_start "$pid" "$noted")"
    if ! wait_or_kill "$pid" "$kill_after"; then
        rig_focus_watch_stop "$FOCUS_WATCHER_PID"; FOCUS_WATCHER_PID=""
        echo "trailer.sh: killed Godot after ${kill_after}s rendering '$name' -- it did not quit" >&2
        tail -20 "$dir/godot.log" >&2
        return 1
    fi
    rig_focus_watch_stop "$FOCUS_WATCHER_PID"; FOCUS_WATCHER_PID=""
    if [[ "$WAIT_OR_KILL_STATUS" -ne 0 ]]; then
        echo "trailer.sh: Godot exited $WAIT_OR_KILL_STATUS rendering '$name'" >&2
        tail -20 "$dir/godot.log" >&2
        return 1
    fi
    if grep -qE '^(SCRIPT )?ERROR' "$dir/godot.log"; then
        echo "trailer.sh: '$name' printed an engine error while rendering:" >&2
        grep -E -A2 '^(SCRIPT )?ERROR' "$dir/godot.log" | head -20 >&2
        return 1
    fi
    local need last
    need="$(awk -v a="$(shot_field "$name" in 0.5)" -v b="$(shot_field "$name" length)" \
        -v f="$FPS" 'BEGIN { printf "%d\n", int((a + b) * f + 0.5) }')"
    last="$(printf '%s/frame%08d.png' "$dir" "$need")"
    if [[ ! -f "$last" ]]; then
        echo "trailer.sh: '$name' wrote too few frames (no $(basename "$last"))" >&2
        return 1
    fi
}

# Encodes shot $1's cut out of the frames in $2 into $3: trimmed to [in, in + length], faded in
# from and out to black, preceded by `gap` seconds of black and silence.
encode_shot() {
    local name="$1" dir="$2" out="$3"
    local in length gap fade_in fade_out start count
    in="$(shot_field "$name" in 0.5)"
    length="$(shot_field "$name" length)"
    gap="$(shot_field "$name" gap 0)"
    fade_in="$(shot_field "$name" fade_in "$DEFAULT_FADE")"
    fade_out="$(shot_field "$name" fade_out "$DEFAULT_FADE")"
    start="$(awk -v a="$in" -v f="$FPS" 'BEGIN { printf "%d\n", int(a * f + 0.5) }')"
    count="$(awk -v a="$length" -v f="$FPS" 'BEGIN { printf "%d\n", int(a * f + 0.5) }')"
    local out_start total
    out_start="$(awk -v l="$length" -v o="$fade_out" 'BEGIN { printf "%.4f\n", l - o }')"
    total="$(awk -v l="$length" -v g="$gap" 'BEGIN { printf "%.4f\n", l + g }')"
    local audio=(-f lavfi -i "anullsrc=r=48000:cl=stereo")
    [[ -f "$dir/frame.wav" ]] && audio=(-i "$dir/frame.wav")
    local gap_ms
    gap_ms="$(awk -v g="$gap" 'BEGIN { printf "%d\n", int(g * 1000 + 0.5) }')"
    ffmpeg -hide_banner -loglevel error -y \
        -framerate "$FPS" -start_number "$start" -i "$dir/frame%08d.png" "${audio[@]}" \
        -filter_complex "\
[0:v]trim=end_frame=${count},setpts=PTS-STARTPTS,\
fade=t=in:st=0:d=${fade_in},fade=t=out:st=${out_start}:d=${fade_out},\
tpad=start_duration=${gap}:color=black,format=yuv420p[v];\
[1:a]atrim=start=${in}:duration=${length},asetpts=PTS-STARTPTS,aformat=sample_rates=48000:channel_layouts=stereo,\
afade=t=in:st=0:d=${fade_in},afade=t=out:st=${out_start}:d=${fade_out},\
adelay=${gap_ms}:all=1,apad,atrim=duration=${total}[a]" \
        -map "[v]" -map "[a]" -r "$FPS" -c:v libx264 -preset veryfast -crf 12 \
        -c:a pcm_s16le "$out"
}

# Joins the encoded shots named in "$@" (paths) into the final file $OUTPUT.
join_shots() {
    local inputs=() streams="" i=0
    for f in "$@"; do
        inputs+=(-i "$f")
        streams+="[$i:v][$i:a]"
        i=$(( i + 1 ))
    done
    mkdir -p "$(dirname "$OUTPUT")"
    ffmpeg -hide_banner -loglevel error -y "${inputs[@]}" \
        -filter_complex "${streams}concat=n=${i}:v=1:a=1[v][a]" \
        -map "[v]" -map "[a]" -r "$FPS" -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
        -c:a aac -b:a 192k -movflags +faststart "$OUTPUT"
}

# Hashes every frame of a render, one "hash  frameNNNNNNNN.png" line each, sorted by frame.
frame_hashes() {
    (cd "$1" && shasum -a 1 frame*.png | sort -k2)
}

check_shot() {
    local name="$1" a="$WORK/check-a" b="$WORK/check-b"
    render_frames "$name" "$a" || return 1
    frame_hashes "$a" > "$WORK/hash-a"
    local audio_a=""
    [[ -f "$a/frame.wav" ]] && audio_a="$(shasum -a 1 < "$a/frame.wav")"
    rm -rf "$a"
    render_frames "$name" "$b" || return 1
    frame_hashes "$b" > "$WORK/hash-b"
    local audio_b=""
    [[ -f "$b/frame.wav" ]] && audio_b="$(shasum -a 1 < "$b/frame.wav")"
    rm -rf "$b"
    local start end total differ in_cut first
    start="$(awk -v a="$(shot_field "$name" in 0.5)" -v f="$FPS" 'BEGIN { printf "%d\n", int(a * f + 0.5) }')"
    end="$(awk -v a="$(shot_field "$name" in 0.5)" -v b="$(shot_field "$name" length)" -v f="$FPS" \
        'BEGIN { printf "%d\n", int((a + b) * f + 0.5) }')"
    total="$(wc -l < "$WORK/hash-a" | tr -d ' ')"
    # Frames present in one render and not the other count as differences too.
    differ="$(diff "$WORK/hash-a" "$WORK/hash-b" | grep -E '^[<>]' | awk '{print $3}' | sort -u || true)"
    in_cut=0
    first=""
    while IFS= read -r frame; do
        [[ -z "$frame" ]] && continue
        [[ -z "$first" ]] && first="$frame"
        local n=$(( 10#$(printf '%s' "$frame" | tr -dc '0-9') ))
        if (( n >= start && n < end )); then in_cut=$(( in_cut + 1 )); fi
    done <<< "$differ"
    local n_differ
    n_differ="$(printf '%s' "$differ" | grep -c . || true)"
    local audio_note="audio identical"
    [[ "$audio_a" != "$audio_b" ]] && audio_note="audio DIFFERS"
    if [[ "$n_differ" -eq 0 ]]; then
        echo "check '$name': $total frames, every one identical; $audio_note"
    else
        echo "check '$name': $n_differ of $total frames differ ($in_cut inside the cut," \
            "frames $start-$((end - 1))); first: $first; $audio_note"
    fi
    [[ "$in_cut" -eq 0 && "$audio_a" == "$audio_b" ]]
}

# Fails, naming them, if the working tree's status moved while this ran: nothing this writes may
# be something git tracks or would offer to add.
assert_tree_untouched() {
    local after
    after="$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || true)"
    if [[ "$after" != "$TREE_BEFORE" ]]; then
        echo "trailer.sh: the working tree's status changed while rendering:" >&2
        diff <(printf '%s\n' "$TREE_BEFORE") <(printf '%s\n' "$after") >&2 || true
        return 1
    fi
}

status=0
case "$MODE" in
    check)
        targets=("$TARGET")
        [[ "$TARGET" == "all" ]] && targets=("${SHOT_NAMES[@]}")
        for name in "${targets[@]}"; do
            check_shot "$name" || status=1
        done
        ;;
    shot)
        OUTPUT="$OUT_DIR/shot-$TARGET.mp4"
        render_frames "$TARGET" "$WORK/frames"
        encode_shot "$TARGET" "$WORK/frames" "$WORK/00.mkv"
        rm -rf "$WORK/frames"
        join_shots "$WORK/00.mkv"
        echo "wrote ${OUTPUT#"$PROJECT_DIR"/}"
        ;;
    all)
        OUTPUT="$OUT_DIR/trailer.mp4"
        encoded=()
        i=0
        for name in "${SHOT_NAMES[@]}"; do
            render_frames "$name" "$WORK/frames"
            part="$(printf '%s/%02d.mkv' "$WORK" "$i")"
            encode_shot "$name" "$WORK/frames" "$part"
            rm -rf "$WORK/frames"
            encoded+=("$part")
            i=$(( i + 1 ))
        done
        join_shots "${encoded[@]}"
        echo "wrote ${OUTPUT#"$PROJECT_DIR"/} (${total_seconds}s, ${#SHOT_NAMES[@]} shots)"
        ;;
esac
assert_tree_untouched || status=1
exit "$status"
