# minty-quail — The looks drawn in slices ask through methods · 2026-11-10

**The ask.** "never read fields directly. always read through a method" (inbox #1173 in
gray-dolphin), and a component is handed what it depends on (minty-lemur #794). Row 2b of
`event-interface.md`, the looks: after the probe (minty-quail-polite-newt), the footprints
(minty-quail-mossy-hedgehog) and the base look handed its row and drawer (minty-quail-tall-toad),
this is the two looks that draw a picture longer than a tile in slices, and the scenery behind a
crash's or a burst main's slices.

## What was built

- **`SpreadLook` and `RankLook`** (`views/spread_look.gd`, `views/rank_look.gd`) read nothing of
  their row or the live event but the two reads listed below. `tools/field_reads.txt` lost 17 lines
  and gained none.
- **A slice is handed the look that draws it and its index** when it is made
  (`SpreadLook.Slice.new(look, index)`) and calls the look's public
  `draw_the_slice(canvas, index)`, which `RankLook` overrides. It no longer holds its event, so
  `test_draw_layers`, `test_halo_behind` and `test_protest` find a live event's slices through the
  look's `slices()`.
- **The scenery is handed its atlas and its drawer** by `EventScenery.draw_through(atlas, drawer)`,
  one call before `configure()`; both fields are private, and it tells each of its layers through
  `SceneryLayer.draw_through()` and `show_frame_b()`.

## Questions added

- `EventLook._shows_anything()`, whether anything of the event is shown, from the skip flag the
  look was handed, `event.is_gone()` and `EventFootprints.hidden_by_its_hold(event)`. Asked by
  `SpreadLook` twice; the roadblock's look writes the same test twice and takes it up in its own
  step.
- `SpreadLook._half_run()`, the half of the run a wide picture is drawn along, from the row's
  `drawn_width()` with the floor `NARROWEST_HALF_RUN` (11px). It replaces seven copies of
  `maxf(11.0, event.def.obstructs_radius)`.
- `EventDrawer._scenery_drawer()`, what a built scenery lays its pictures through, overridden by
  `tests/recording_event_drawer.gd` so that a scenery is handed once, through the same call.

## Reads left, each with its reason

- `event.world_map().world` in `SpreadLook._attach_the_slices()`: the map's method for it is another
  track's file.
- `event.age` in `RankLook`'s muzzle flash: its natural name is the field's.
- **`SpreadLook.Slice.index` stays a public variable.** No class under `src/` reads it, but
  `tests/probes/look_fingerprint.gd` names each slice's canvas with `canvas.get(&"index")`, and
  with the field private the probe's `LK` hash moved. It can go private once the probe asks
  `SpreadLook.slices()` for a slice's place; `field-reads.md` holds that.
- **`SceneryLayer.frame_b` and `SceneryLayer.drawer`** are public with no reader under `src/` outside
  their own class, now that the scenery tells each layer through its methods. The file is the city's,
  so this step left them, and `field-reads.md` holds them too.
- The live event's `skip_draw`, `is_finished`, `drawer`, `look` and `def` stay public for readers
  outside these files, the roadblock's look among them. No kept line was added or changed in
  `tools/test_only_members.txt`.
- `EventFootprints.drawn_box_of()` writes the same 11px floor as `NARROWEST_HALF_RUN`, in a file
  outside this step: two statements of one number, left.

## Parity

The look probe's `LK` lines (`a12e4cc9…`, 63070 lines), the excitement fingerprint (`7510c1d0…`)
and the events tick sweep's chains (`bf69e949…`) hash the same on `main` at `8c624413a` and on
`55151bdd4`, the last commit to change code rather than comments, and the run log is line for line
what it was. The sweep exits 1 on both trees with the same six failures of its own check ("the
split step changes every event, agent and meter exactly as the real one", seed 478156010, days 9
and 14), which this step did not cause. `RankLook`'s two muzzle flashes and every body shadow are
drawn straight on the canvas and no probe sees them: the flash's strength is now the base look's
`_share_of_its_peak_now()`, the same number, and the shadows' positions come from `_half_run()` and
the handed index. Nothing was timed.

## History taken out of the comments

`RankLook._draw_firefight()`'s comment said a firefight is people behind cover and "Not a building
on fire, which is what it drew for fourteen milestones — the same five flames as
`burning_building`". The comment keeps the rule, and the history is here.

## Open to the player's overturn

- **A slice holds its look by a `WeakRef`.** A slice is freed at the end of a frame and may draw
  once after its event is gone; the look goes with its event, so the slice then finds no look and
  draws nothing, which is what its old `is_instance_valid(instance)` guard meant. A strong
  reference would keep the look, and through it a reference to the freed event, alive until the
  slice goes. This is reasoned from the code and the engine's reference counting: no test draws a
  slice after its event is freed.
- **The scenery's hand-in is its own call** before `configure()` rather than arguments of it,
  matching the name the city's layers use for the same hand-in.
- **`_spread_run()` keeps the floor as the constant** rather than asking `_half_run()`: its branch
  for a picture with no body is also taken by a row with a body and no shape, where `_half_run()`
  would answer half the body rather than 11px.
- **The names**, the builder's: `_shows_anything()`, `_half_run()`, `NARROWEST_HALF_RUN`,
  `draw_the_slice()`, `EventScenery.draw_through()` and `EventDrawer._scenery_drawer()`.
