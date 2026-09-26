## M104 — The debug view, built 2026-09-10

Asked for the same day: *"create a debug view to show the fields and the shadows and the bounding
boxes. make each layer toggleable (maybe number keys?) also make other debug information
toggleable."* Four agent commits on `feature/the-debug-view` and one merge with main, reviewed
here. Placed ahead of M61's field half because it is how that field is checked by eye.

**What it is.** `DebugLayers` (`src/dev/debug_layers.gd`), one `Node2D` above the world (`z_index`
3, over the y-sorted entities) with three booleans, redrawn every frame from queries of the live
`EventInstance`s, `CrowdAgent`s, `Building`s, `Prop`s and the `Stroller`; nothing about how any of
them draws itself changed. Four number keys read as raw keycodes in `main._unhandled_input`, the
way the pause and title screens read `R` and `Q`, so `project.godot` carries no debug binding: `1`
fields (inner and outer falloff boundary, amber `Palette.MARK_COSTLY`, deep red `MARK_LETHAL` for
a `hard_fail` row), `2` shadows (the polygon `GroundShape.shadow_outline()` traces, which
`draw_shadow()` itself now fills), `3` bounding boxes (every collision body, plus a moving car's
strike box in the lethal colour because it is what ends the day and is not a body), `4` the
readout, whose string is not assembled while it is off. `--layers 1,3` and the page's `?layers=1,3`
set the initial state; with no flag the readout is on and the geometry is off, so an unflagged
debug run looks as it always did. Outside a debug build the node is never created, which
`tests/test_debug_layers.gd` asserts along with the key resolution, the toggles and the outline
geometry. Documented in `docs/TELEMETRY.md`, "The debug view", and `docs/ARCHITECTURE.md`.

**Choices made where the design was silent, open to overturn.** One node with three flags rather
than three `CanvasItem`s, since Godot already skips `_draw()` on an invisible item and a node per
layer bought nothing. The field colours are the caret's own pair rather than a third set; shadows
are a debug-only cyan and bodies a debug-only green, used nowhere else so an outline cannot be
mistaken for a cue. The readout was the only always-on debug furniture found — the snapshot and
burst keys are momentary presses, not overlays. The flock's per-bird point shadows, drawn through
`Sprites.draw_shadow` rather than the event's own shape, are not traced by the shadow layer. A
car's strike box is drawn only while `speed() >= CAR_STRIKE_MIN_SPEED`, mirroring
`will_be_lethal()`'s own guard, so a car stopped at a light shows no lethal box. `4` is not
settable from `--layers` because it defaults on. The getters added for the view are one-line
wraps of existing private logic: `EventInstance.solid_axis()`, `flock_offsets()` and
`flock_outer_radius()`; `CrowdAgent.travel_axis()` and `jolt_radii()`; `City.buildings()` and
`props()`.

**What the first pictures show.** `docs/evidence/m104-layers-all.png` (`--layers 1,2,3`) and
`m104-layers-bodies.png` (`--layers 3`), seed 4242, day 1. Every field is a circle, which is the
disagreement M61's field half is queued to fix. The player's first look, on the agent's working
tree the same day: *"all circles look perfectly round to me even the ones that should be stretched
by the movement"* — correct for this slice; the stretch is M61's. The fields layer over a busy
arterial is dense to the point of illegible, since every walker draws two rings; whether a
per-kind split (events only, crowd only) is worth a key is the first thing a played session on it
will say, and it is not built.
