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
hold no hidden globals: the street lattice is a `StreetNetwork` each `CityMap` holds (`map.network`),
built with the map and handed to its callers with it. The torn posters are held by a `PosterArt` that `main` keeps and hands down through
`City`, `PosterWalls` and `Building`. The constants left there (the `Mover` filters, `CityMap`'s
tile tables) and `Mover._shared`, a pure memo of its flags, are not hidden globals. What outlives a
scene reload (the controls choice, the held-restart stamp, the save symbol's home, the frame
record's file and the frame record itself, the checkpoint carry, the ground recipe read once per
process, and the save, `GameSave`, a node under it with its web flush and operation ids) is held by
one `Sitting`, which `main` parks in its home across the reload and hands on; no static holds it.
`main` holds the run configuration it resolves at boot. The drawing state is held by what it
describes: a sprite's base transform on the canvas it is drawn on, the drawn-view memo on its
viewport. `EntityHalo._shared_material` is a shader material built once and never written, not a
hidden global. The atlas library is an instance the `Sitting` holds, built over a region table
(`AtlasTable`) read once per process and handed down from `main`; code that needs only a picture's
size before any library exists reads that table through `AtlasTable.baked()`, a memo no caller
writes. The statics left under `src/events/` and `ResistanceSteps._all` are constants or pure memos
built once and never written by a caller (the catalogue's tables and derived rows, the heat memo,
the warning sizes read off the baked pictures, the empty bird list and open walls).
`EventScheduler.judgements`, a counter `_judge()` bumps that no game code reads and
`tests/test_siting_judges_once.gd` reads as a difference, decides nothing; handing a counter through
`_best_of()` and every `WalkSiting` call instead is open (`rg -n '^\s*static var' src` lists them).
