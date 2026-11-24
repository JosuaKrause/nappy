priority: later
after: 2026-10-18-minty-quail

# grassy-badger — CityMap.tiles_of_type() keeps its per-type cache across witness_only() and restore_edges() · filed 2026-11-23

**What is wrong.** `CityMap.tiles_of_type()` (`src/city/city_map.gd`) caches each type's tile list in `_tiles_by_type` and clears the cache only where tiles change (`repaint()` and the places that write tiles). `witness_only()` and `restore_edges()` switch a scene's edges off and on (`_recipe_exterior` and `stretch_active`), and `activate_stretch()` sets `stretch_active` too; that changes which tiles `tile_at()` answers, and none of the three clears the cache. A list asked for before or after the switch can then answer the other state's tiles. A city defect (**city** governs). A filing from a review, not from the player's words; the band, `later`, is the filer's proposal.

**Found by** the design of the scene recipes' pass (`.claude/briefs/designs/minty-quail-scene-recipes-pass.md`, untracked in the orchestrator's checkout).

**What a builder does.** First establish by a test whether the answer really differs across the switch (does `tile_at()` read those two flags, switched by `witness_only()`, `restore_edges()` and `activate_stretch()`); if it does, clear the cache in those three (or key it on the flags), and if it does not, say so in a comment on the cache and close the entry.

**Shown fixed.** A suite on a map with a bounded recipe asks `tiles_of_type()`, calls `witness_only()`, asks again, calls `restore_edges()` and asks again, then calls `activate_stretch()` and asks again, and each answer equals a fresh scan of `tile_at()`.
