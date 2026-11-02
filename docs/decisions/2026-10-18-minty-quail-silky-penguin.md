# minty-quail — The drawing statics are held by their owners: the canvas, the viewport and the ground recipe (hidden statics) · 2026-11-02


minty-quail's `hidden-statics.md`: the statics that drawing passed around. The item stays open for
the statics read across the tree.

**Built.**
- `Sprites._base_transform` is gone: `Sprites.set_base_transform(canvas, base)` records the base
  transform on the canvas item being drawn on (identity included, so no draw inserts or erases an
  entry), and `draw_standing()` and
  `mirrored_transform(canvas, at)` read it back from their own canvas, so one canvas's transform
  never reaches another's draw. `CrowdAgent`, `EventLook` and `EntityHalo` set it on themselves.
- `DrawnView._frame`, `_viewport_id` and `_box` are gone: the frame's on-screen box is held on the
  viewport it describes, so two viewports no longer evict each other; `forget()` takes the viewport.
  It is held rather than treated as a pure memo, since the canvas transform can change within a frame.
- `GroundLayers._manifest`, `_manifest_read` and `_manifest_reads` are gone: `GroundRecipe`
  (`src/visuals/ground_recipe.gd`) reads `ground_layers.json` on its first ask and holds it; the
  `Sitting` holds the one per process, `main._new_city()` hands it to `City.ground_recipe`, and
  `GroundLayers.build_tile_set(authored, recipe)` takes it. A city built without one reads its own.
  The file is still read once per process.
- `EntityHalo._shared_material` stays: a shader material built on first use and never written,
  read by every halo built across the crowd and the events.
- The layer map loses its three static exceptions for these, and the runner's shared-state list its
  six entries.

**Not measured:** the base transform kept on the canvas costs about 0.6 µs more per crowd, event or
halo redraw than the old static by the review's headless benchmark (1.20 µs against 0.62 µs); the
remeasuring step reads it in the frame record's `draw` bucket on the phone.

**Open to overturn** (the builder's choices where the brief was silent): the base transform kept on
the canvas rather than passed as an argument through `draw_standing()`'s callers; the recipe held by
the `Sitting` (with `main` holding it, a scene reload would read the file again).
