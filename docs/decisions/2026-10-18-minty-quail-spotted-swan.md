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
  their first-line opt-out, `rim` and `use_rim()` typed `SourceRim`. **The world is the
  orchestrator's pick, open to the player's correction**: the excitement source that holds the rim
  is the world's and is typed by it, and the ring draws through `Sprites`, also the world's. The
  alternative ruled out is the simulation layer, where designing-classes' "each thing's own drawing
  is on the layer of the thing it draws" points (the bodies whose rim it is are the simulation's);
  under it only `ExcitementSource.rim` typed `SourceRim` would break (two uses, in
  `excitement_source.gd`).
- **`DrawnFrame` is placed on the observers layer, `CrowdLanes` and `DayEnd` on the model**, each
  listed break going with it.
- **`GroundLayers`** (the ground's picture builder, `src/visuals/ground_layers.gd`) is placed on the
  world layer, and its listed break on `GroundTiles` goes. Only the city scene and the scenery
  ground, both the world's, name it in code; it names `GroundTiles` (model) and the art's data
  classes, all below the world.
- `tools/check_layers.py` counts 51 listed exceptions (one per file and name) standing, 106 uses,
  where on `651606332` it counted 63 exceptions, 132 uses.
  The map's layer texts and `docs/ARCHITECTURE.md` say where the halo's rim stands.

## Left, and what stops each

- **`CityEdge`'s kinds** are read by `main.gd`, the city, the route rig's planner, the day files,
  telemetry and many suites; moving them touches files outside this pull request.
- **`Prop`'s trees** would become a data constant read by a file another pull request types.

## Parity

What every source charges her and every event, crowd agent and meter on every tick give one hash
each on `main` at `651606332` and on the code commit `6bbf725b2`; the run log is line for line what
it was.
