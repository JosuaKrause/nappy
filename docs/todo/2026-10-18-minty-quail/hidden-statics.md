# Hidden globals held in statics

- **58 `static var`s hold hidden globals** (the review's count at v0.29.0): among them
  `StreetNetwork._segments`, `SealPlanner._candidates` and the `AtlasLibrary` statics. A component
  that reads one depends on whatever the last caller left there, and a test cannot hand it a fake,
  only patch the static and put it back. The README's dependency-injection rule names "a static"
  among the things a component must not fetch what it depends on from.

**Build:** each owner holds its state and is handed it through its setup or constructor, and no
static holds hidden globals; a value that is truly one per process (a table read once from disk) is
held by the owner that reads it and handed to whoever needs it.

*Split out of `main-and-state.md` by the orchestrating session, not the player, open to overturn:*
the statics belong to the city, the routes and the art rather than to the run's state, so the item
that keeps the run's state in one place does not build them.

**Where it stands:** the statics under `src/crowd/`, `src/city/`, `src/routes/` and `src/world/`
hold no hidden globals except `StreetNetwork`'s lattice memos (`_segments`, `_by_key`,
`_adjacency`), which need a network handed to their static callers, the resistance and finale tests
among them. The torn posters are held by a `PosterArt` that `main` keeps and hands down through
`City`, `PosterWalls` and `Building`. The constants left there (the `Mover` filters,
`CityMap`'s tile tables) and `Mover._shared`, a pure memo of its flags, are not hidden globals. What
outlives a scene reload (the controls choice, the held-restart stamp, the save symbol's home, the
frame record's file and the frame record itself, the checkpoint carry, the ground recipe read once
per process, and the save,
`GameSave`, a node under it with its web flush and operation ids) is held by one `Sitting`, which
`main` parks in its home across the reload and hands on; no static holds it. `main` holds the run
configuration it resolves at boot.
The drawing state is held by what it describes: a sprite's base transform on the canvas it is drawn
on, the drawn-view memo on its viewport. `EntityHalo._shared_material` is a shader material built
once and never written, not a hidden global. Still to do, each needing one pass that owns all its
readers, since they are read across the tree: `AtlasLibrary` (`src/visuals/`), the statics under
`src/events/`, and the single one in `src/resistance/resistance_steps.gd` (`rg -n '^\s*static var'
src` lists them).
