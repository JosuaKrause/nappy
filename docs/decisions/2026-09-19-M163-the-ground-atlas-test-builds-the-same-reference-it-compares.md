## M163 — The ground atlas test builds the same reference it compares · built 2026-09-19

> "create a todo for the bug report with enough detail to pick it up without additional
> investigative work"

`./tools/test.sh ground_layers` printed one engine error, `No TileSet atlas source with id N`,
for each of the eight route-curb twin sources (IDs 58 to 65), reported no failure and exited 0.
The defect was in the test, not in production: `GroundLayers.build_tile_set()` registers the
twins in both presentation modes, and the test's reference builder `_unpacked_tile_set(true)`,
the forced-SVG path, resolved the authored sources and never called the registrar. The packed
TileSet had 66 sources and its reference 58; `TileSet.get_source()` printed the error, returned
null, and the comparison skipped the eight generated sources.

**Built.** The reference builder mirrors production's own branch: `_register_route_kerb_twins(
result, {})` for SVG, `_compose_layers()` for PNG, with `GroundTiles.ROUTE_KERB_TWIN` and the
production registrar still the only place the IDs are written. The test asserts that the packed
and reference source counts agree and asks `reference.has_source(id)` before `get_source(id)`,
so a missing reference fails by name and never reaches the engine.

**Measured.** Before: 8 engine errors, 21191 checks, 0 failures, exit 0. After: 0 lines matching
`ERROR:`, `SCRIPT ERROR`, `Parse Error` or the missing-source message, 21373 checks, 0 failures.
With the registrar call replaced by `pass`: exit 1, no engine error, 9 failures, the count
("66 against 58") and one named failure per ID 58 to 65. `tests/test_ground_layers.gd` is the
only file changed. It landed before M164, engine errors make the test gate red, so that the
gate does not go red on a known fixture error, and before M171, build-time atlases, which
rewrites what this suite guards.
