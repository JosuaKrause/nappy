## M171, the stroller, the head indicators and the crowd — built 2026-09-20

The second consumer move of the milestone, pull request #249.

**Built.** `Stroller` acquires the `stroller` and `head_indicators` groups in `_ready()` and
releases them in `_exit_tree()`; every mother, father, pram, alert and baby constant is a source
path and the draw reads `AtlasLibrary.region()`. `CrowdAgent`'s six view tables are paths with
a small `StringName` cache, the body layer alone takes the tint, and the entry clearance reads
`AtlasLibrary.native_size()`, which answers before anything is acquired — it has to, since the
placement roll in `setup()` runs ahead of the first acquire. `Crowd` owns the `crowd` group for
its own life: the first `start_day()` takes the one reference, `clear()` keeps it, and
`_exit_tree()` gives it back, so the finale's crowd that never starts a day takes nothing.
`crowd_atlas.gd` and its suite are deleted, and with them the synchronous first pack inside a
draw call. `tests/test_atlas_stroller_crowd.gd` holds the lifetimes, the separate body and trim
regions and the page split between the rig and the indicators.

**Found in review.** The first version released only in `clear()`, so a `Crowd` freed mid-day —
the city torn down on quitting to the title — kept its reference for the life of the process,
`AtlasLibrary`'s counts being static. The suite's case for it was seen failing before the fix.

**Overturned by the player before it merged.** The second version released the page in
`clear()` and loaded it again at each day's start, as the membership's "the day" lifetime read.
[PLAYTEST-109](../playtests/PLAYTEST-109.md): *"don't unload anything that might be needed in one
day and in the next."* A release is a reload, and `AtlasLibrary.acquire()`'s `load()` blocks the
moment that calls it; the membership's lifetime for `crowd` now says the node's own life.

**The halo.** `assets/shaders/excitement_halo.gdshader` declares only `fragment()` and reads
alpha at `UV`; the engine's default canvas vertex stage remaps `UV` to an `AtlasTexture`'s
region first, so the shader is region-safe. A shader with its own `vertex()` UV math would not
be.

**Removed with the runtime toggle's last readers.** `test_walker_views.gd` and
`test_car_views.gd`'s checks that an unpaired view falls back to its SVG, and
`test_player_presentation.gd`'s check that warming and the atlas cover both presentations,
pinned `TextureResolver` behaviour against constants that are no longer textures; the parity
they protected is `test_atlas_library.gd`'s bake-parity check.

**Open to overturn.** The owner holds the crowd's one reference rather than each of a couple of
hundred agents holding their own; `CrowdAgent` caches region names.

**Not captured.** No still shows a head indicator over her head: three `shot.sh` windows never
produced one.
