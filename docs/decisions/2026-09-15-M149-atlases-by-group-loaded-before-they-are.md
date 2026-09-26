## M149 — Atlases by group, loaded before they are drawn · built 2026-09-15

*(2026-09-14, [PLAYTEST-75](../playtests/PLAYTEST-75.md): "pack together graphics into atlases and
load/unload atlases in a clever way so it happens while the things that will get drawn haven't
been drawn yet"; 2026-09-15, [PLAYTEST-76](../playtests/PLAYTEST-76.md): "it is good to have
everything built into atlases so the composite doesn't have to deal with multiple image
sources"; "make sure telemetry records when a texture is loaded/unloaded — atlas or not —
ideally with timing information".)* Seven agent commits on `feature/m149-atlases`, reviewed on
the PR; the runs and the still are `evidence/m149-atlases-2026-09-15/`, with a README that
carries the table and the commands.

**What it is.** `TextureAtlas` (`src/visuals/texture_atlas.gd`) is `CrowdAtlas`'s shelf packer
lifted into a general one: `request(name, sources)` resolves every source through
`TextureResolver.resolve()`, reads the images on the main thread, plans a tallest-first layout
with a pixel of padding under the 2048 px side, and hands the blit to a `WorkerThreadPool`
task; `collect()` on the main thread makes the `ImageTexture`; `texture_for(name, key, source)`
answers the `AtlasTexture` once collected and the caller's own source before, after
`release()`, and for a group never requested, so nothing ever draws a missing picture; the
pump is the first thing `Main._process()` does, above its early returns. `CrowdAtlas` is a
user of it with its API and suite unchanged. The groups: her family and the five head
indicators as two groups requested in `Stroller._ready()` — two, because they are drawn for
different reasons and the suite can assert the marks are on a different texture from her
body; one group per `EventDef.Look`, requested by `EventManager` when the first instance of a
look is placed and released when the last retires, the set recomputed from the live list after
every change rather than counted, since instances leave it by four paths; the street's
decoration — litter, tree bed, trees, swing frame, bollard, sack and pile — as one group
requested in `City.build()`; and the ground, where `GroundLayers.pack_into_one_texture()` runs
last in `build_tile_set()` and points every `TileSetAtlasSource` at one sheet through
`margins`, `texture_region_size` and `separation` untouched, synchronous because a `TileSet`
has no "until ready" state and its cost is 0.3 ms for 58 sources over 57 pictures into a
2030×100 sheet against the 178 ms the same boot spends warming pictures. Buildings and the
interior are not packed.

**What the run log says.** One kind, `texture`: a line per transfer the resolver reads from
disk with its path and milliseconds, one per atlas as it becomes ready with its group, picture
count, size, the milliseconds from the request and the worker's own share, and one per
release with how long it was drawn from. The observer's `spike` context reads the collected
count the way it reads the resolver's load count. The boot line now warms 75 pictures rather
than 86, because the decoration's request resolves twelve before the warm pass runs.

**What it measured, on the desktop.** The desktop table's walk, draws as the mean of the run
log's `frame` entries from two seconds in:

| | draws | primitives | fps |
|---|---|---|---|
| before | 566 | 4546 | 112 |
| every group packed | 560 | 4539 | 108 |

About six calls, and the fps inside two windowed runs' noise. The crowd was already one atlas,
a `TileMapLayer` batches a screen of tiles into one call whether or not its sources share a
texture, and twenty seconds of that walk put few event families in front of the camera. The
milestone's reason is the composite, not this number; the laptop's and the phone's readings
are in `REVIEW.md`.

**Found while building.** A group whose packing task is never collected crashed the process
at exit — leaked RIDs and a segfault in a mutex after every check passed — because a headless
suite has no pump; `EventManager`, `Stroller` and `City` now release what they requested in
`_exit_tree()`, and `release()` waits for an outstanding blit, which a real game quitting
mid-day needed too. Two ground guards decided whether the grass and damage variant cells
existed by the source texture's width, which every source passes once they share one sheet;
both ask the source's own `has_tile()` now. The merge with M145's tint twins registers the
twins before the pack in both modes, and the twin's tint check reads a source's own tile
region rather than the sheet's origin.

**Not taken, open to overturn.** Offline PNG sheets loaded with
`ResourceLoader.load_threaded_request`, which would need an SVG-mode twin per family and buy
nothing while every source is a `preload` resident from boot; and turning the preload tables
into lazy loads so a released family's memory actually goes, the step after this one if the
phone's memory turns out to be a cost. The agent's other choices are in its commit messages:
the family is the `Look` rather than the catalogue row, a picture two looks share is packed
into both, the 2048 cap is a pure `plan()` the request asserts on, and the still is day 12 so
litter and sacks are in it.
