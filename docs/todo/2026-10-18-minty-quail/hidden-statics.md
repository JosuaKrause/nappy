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

**Where it stands:** the statics under `src/crowd/`, `src/city/`, `src/routes/` and `src/world/` hold
no hidden globals except two: `StreetNetwork`'s lattice memos (`_segments`, `_by_key`,
`_adjacency`), which need a network handed to their static callers, the resistance and finale tests
among them; and `PosterArt._torn`, which needs an owner that outlives the day's city, `main`, handing
it down through `PosterWalls` and `Building`. The constants left there (the `Mover` filters,
`CityMap`'s tile tables) and `Mover._shared`, a pure memo of its flags, are not hidden globals. The other folders' statics are
still to do: `src/events/`, `src/visuals/` (the `AtlasLibrary` statics among them), `src/ui/` (with
`SaveIndicator._home_override`), `src/autoload/`, `src/telemetry/` and the single ones in
`src/resistance/`, `src/sprites.gd`, `src/run_config.gd` and `src/main.gd`
(`rg -n '^\s*static var' src` lists them).
