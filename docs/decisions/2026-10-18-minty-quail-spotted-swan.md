# minty-quail — The layer map corrects its own mistakes (minty-quail, the layers) · 2026-11-10

**The ask.** A layer depends only on the layers below it, and the layer map (`tools/layer_map.py`)
says which file is in which layer (the designing-classes skill; the layers the player decided,
inbox #904 in freckled-moose). The design review read some of the map's listed breaks as mistakes
in the map, not in the code (`standing-layer-breaks.md`); a Fable planning agent cut their
correction as one pull request.

## What was built

- **The halo a body composes is placed on the world layer**: `EntityHalo` and `SourceRim` get an
  entry each in the map's `FILES` (the files stay in `src/ui/`), and their two listed breaks go. Its
  one number, `MAX_ALPHA` (0.75), moves from `ExcitementHalo` to `EntityHalo` unchanged; the suites
  read it there, with no forwarder left. The two `src/world/` excitement files are typed and lose
  their first-line opt-out, `rim` and `use_rim()` typed `SourceRim`.
- **`DrawnFrame` is placed on the observers layer, `CrowdLanes` and `DayEnd` on the model**, each
  listed break going with it.
- `tools/check_layers.py --list` counts 110 listed uses in 52 entries where it counted 132 in 57.
  The map's layer texts and `docs/ARCHITECTURE.md` say where the halo's rim stands.

## Left, and what stops each

- **`GroundTiles`** names `CityMap`, so the data layer cannot hold it; it waits on the ground
  picture builder reading the tile from something handed to it.
- **`CityEdge`'s kinds** are read by `main.gd`, the city, the route rig's planner, the day files,
  telemetry and many suites; moving them touches files outside this pull request.
- **`Prop`'s trees** would become a data constant read by a file another pull request types.

## Parity

What every source charges her and every event, crowd agent and meter on every tick give one hash
each on `main` at `651606332` and on the code commit `6bbf725b2`; the run log is line for line what
it was.
