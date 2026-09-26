## docs/ is not a Godot resource folder — 2026-09-09

*(Playtest 50: "hmm, is the evidence / docs folder godot ignored?", "why are there import files for
screenshots?")* It was not. Godot imports every file under the project unless a folder carries a
`.gdignore`, so every screenshot, dusk map and reference photo committed under `docs/` brought a
`.import` sidecar with it, and the evidence tree held over two hundred of them. Nothing in `src`,
`tests` or `tools` loads a `res://docs/` path, so `docs/.gdignore` now keeps the importer out of
the folder and every tracked sidecar under it is deleted. The illustrated-png skill's sentence
that asked for evidence sidecars to be preserved is rewritten; asset sidecars under `assets/` are
unchanged and still repository files.

*("are there other folders worth ignoring?")* Two. `tools/` holds scripts and Python and nothing
Godot should scan, so it carries a `.gdignore` too. `build/` is gitignored and cannot carry a
tracked one, and it is the folder that needed it most: the import pass had found the exported
icons under `build/web/` and written sidecars beside them, Godot importing its own export.
`tools/export-web.sh` now writes `build/.gdignore` every time it exports, so a cleaned folder gets
it back. Hidden folders — `.git`, `.godot`, `.claude` with its agent worktrees, `.codex`,
`.github`, `.agents` — need nothing, because Godot's scanner skips every dot-prefixed directory.
`docs/reference/.gdignore` is removed as redundant under `docs/.gdignore`. `scenes/`, `src/`,
`tests/` and `assets/` are the resource tree and stay scanned.
