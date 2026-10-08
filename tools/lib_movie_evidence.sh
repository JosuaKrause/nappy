#!/usr/bin/env bash
# Compact provenance shared by recording and trailer tools. No recipe schema lives here:
# the game resolves and validates recipes, and these checks consume its result only.

movie_manifest_check() {
    local manifest="$1" normal="${2:-false}"
    [[ -s "$manifest" ]] || { echo "missing scene manifest: $manifest" >&2; return 1; }
    if ! jq -e 'type == "object" and (.classification == "normal" or .classification == "fixture")
        and (.scope == "bounded" or .scope == "full" or .scope == "stretch")
        and (.bounds | type == "array" and length == 4 and all(.[]; type == "number"))' \
        "$manifest" >/dev/null; then
        echo "invalid scene classification in $manifest" >&2; return 1
    fi
    if [[ "$normal" == true ]] && ! jq -e '.classification == "normal"' "$manifest" >/dev/null; then
        echo "trailer refuses test-only fixture: $manifest" >&2; return 1
    fi
}

# A successful writer exit is insufficient: the recipe must reach its required moments.
movie_playback_check() {
    local manifest="$1" required="${2:-true}"
    if ! jq -e --argjson required "$required" '.playback_complete == true and
        (.observations | type == "array" and (length > 0 or $required == false)
        and all(.[]; .passed == true))' "$manifest" >/dev/null; then
        echo "scene playback did not complete its required observations: $manifest" >&2
        return 1
    fi
}

movie_recipe_preflight() {
    local recipe="$1" manifest="$2" normal="${3:-false}" mode="${4:-scripted}"
    local log="${manifest%.json}.log" pid
    shift 4
    local flags=(--recipe "$recipe" --recipe-mode "$mode" --no-save)
    [[ $# -eq 0 ]] || flags=("$@")
    "$GODOT" --headless --path "$PROJECT_DIR" -- "${flags[@]}" \
        --recipe-validate --recipe-manifest "$manifest" > "$log" 2>&1 &
    pid=$!
    if ! wait_or_kill "$pid" 120 || [[ "$WAIT_OR_KILL_STATUS" -ne 0 ]] || \
        grep -qE '^(SCRIPT )?ERROR|Parse Error' "$log"; then
        echo "scene recipe preflight failed: $recipe" >&2
        tail -30 "$log" >&2
        return 1
    fi
    movie_manifest_check "$manifest" "$normal"
}

# SHA-256 PNG hashes remain compact after raw frames are deleted. Read one filename at a
# time: a whole recorded route can exceed the shell's argument-size limit.
movie_frame_hashes() {
    local dir="$1" file
    for file in "$dir"/frame[0-9]*.png; do
        [[ -f "$file" ]] || continue
        printf '%s  %s\n' "$(shasum -a 256 < "$file" | awk '{print $1}')" "${file##*/}"
    done
}

movie_evidence() {
    local dir="$1" output="$2" fps="$3" label="$4"
    mkdir -p "$output"
    rm -f "$output/audio.sha256" "$output/manifest.json" "$output/atlases.sha256"
    movie_frame_hashes "$dir" > "$output/frames.sha256"
    [[ -f "$dir/frame.wav" ]] && shasum -a 256 < "$dir/frame.wav" > "$output/audio.sha256"
    [[ -f "$dir/manifest.json" ]] && cp "$dir/manifest.json" "$output/manifest.json"
    cp "$dir/godot.log" "$output/godot.log"
    local revision tree dirty engine settings engine_hash
    revision="$(git -C "$PROJECT_DIR" rev-parse HEAD)"
    tree="$(git -C "$PROJECT_DIR" rev-parse HEAD^{tree})"
    dirty="$(git -C "$PROJECT_DIR" diff HEAD -- | shasum -a 256 | awk '{print $1}')"
    engine="$("$GODOT" --version)"
    engine_hash="$(shasum -a 256 < "$GODOT" | awk '{print $1}')"
    settings="$(shasum -a 256 < "$PROJECT_DIR/project.godot" | awk '{print $1}')"
    jq -n --arg revision "$revision" --arg tree "$tree" --arg dirty "$dirty" \
        --arg engine "$engine" --arg engine_hash "$engine_hash" --arg settings "$settings" --arg label "$label" \
        --argjson fps "$fps" --argjson width "$WIDTH" --argjson height "$HEIGHT" \
        '{revision:$revision,tracked_tree:$tree,working_diff_sha256:$dirty,engine:$engine,engine_sha256:$engine_hash,
          project_settings_sha256:$settings,label:$label,fps:$fps,width:$width,height:$height,
          capture:"Godot PNG movie writer",claim_scope:"same recipe, revision, assets, engine and settings"}' \
        > "$output/settings.json"
    # Baked atlases are ignored build artifacts; a source tree alone cannot identify them.
    if [[ -d "$PROJECT_DIR/assets/atlases/baked" ]]; then
        (cd "$PROJECT_DIR" && find assets/atlases/baked -type f -name '*.png' | sort | \
            while IFS= read -r file; do shasum -a 256 "$file"; done) > "$output/atlases.sha256"
    fi
}
