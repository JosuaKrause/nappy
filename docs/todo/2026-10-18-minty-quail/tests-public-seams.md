# Tests drive public seams and real frames

Tests reach into private members and call `_process`/`_physics_process` directly; count them with
`rg -v '^\s*#' tests/*.gd | rg -o '\._[a-z]\w*' | wc -l` (private reads, per file with `rg -c`) and
`rg -v '^\s*#' tests/*.gd | rg -c '\._(physics_)?process\('` (direct frame calls); `rg -l 'main\.tscn|main.gd'
tests` finds the suites that instantiate `main`. `test_ground_floor.gd`, `test_car_views.gd` and
`test_walker_views.gd` are done and live nowhere but the record (`tools/decisions.sh minty-quail-43`);
`test_home_block.gd` (near 249) copies `City._height_for`'s random stream;
`test_camera_start.gd` depends on `main._ready()` holding exactly two awaits. `SceneRecipeRuntime`
rebuilds placement from other classes' private functions (`SealPlanner._eligible`, `_place`,
`_seal_along_tile`, `_mark_soft_sealed`; `EventScheduler._build_placement`, `_room_around`,
`_street_ground`; `RegionPlanner._add_door_bodies`; `instance._advance_gait`), so authored scenes drift from the game. `SceneRecipeRuntime.walk_spec` is a
public field only tests read, and two checks compare it with the value just assigned; no test
reaches the crowd's or `ResistanceDirector`'s fallback to the map's navigator, or `main` handing
`SceneRecipeRuntime.install()` the spec its clock runs on.

**Build:** as each owner is extracted (the items above), it gets public seams and injected
dependencies, and the tests that reached into it move to the seams, with fakes injected instead of
statics patched; since the test runner lets frames pass, scene-level tests step real frames. Planners
get public "place this at this site" entry points that the scheduler and recipes both call. It is
one pass after the last refactor item, "once the refactor is done let's rewrite the tests with
dependency injection and through public APIs", and a step may convert the tests it touches early,
"you can also do it as a bit with each step as long as the final result is the same" (inbox #813 in curly-moose).
