# minty-quail — The ground's picture builder, the building shadows and the decals are typed (minty-quail, typing) · 2026-11-10

**The ask.** Code is typed wherever the language can type it (inbox #1280 in olive-ferret), and a
module's pass types its receivers and deletes its files' first-line opt-out (the godot skill,
"Types"; `docs/todo/2026-10-18-minty-quail/field-reads.md`, "Every receiver gets a class the check
can tell"). A Fable planning agent cut the atlas and scenery module's typing of these four files as
one pull request.

## What was built

Four files lose their opt-out line, each typed where the engine failed it, with no method, name or
member added or deleted:

- **`src/visuals/ground_layers.gd`**: a duplicated image read `as Image`, three loop variables
  typed, and the two rotations named by the engine's own enum values (`CLOCKWISE`,
  `COUNTERCLOCKWISE`), the same numbers they were.
- **`src/visuals/ground_recipe.gd`**: the parsed recipe cast once to a `Dictionary` and read
  through it; anything else still gives an empty one.
- **`src/city/building_shadows.gd`**: two filter lambdas return `bool`, two loop variables are
  `Vector2i`.
- **`src/city/city_decals.gd`**: the two chunk buckets read out of a dictionary as `Array` before
  they are appended to.

No read became newly visible to the field-read check, so no line of `tools/field_reads.txt`
changes.

## Parity

What every source charges her (`probes/excitement_fingerprint.gd`, its `XF` lines less `XF_COST`)
and every event, crowd agent and meter on every tick (`probes/m159_tick_sweep_events_cost.gd`, the
`chain` values) give one hash each on `main` at `651606332` and on the code commit `a16d1d7d1`; the
run log is line for line what it was.
