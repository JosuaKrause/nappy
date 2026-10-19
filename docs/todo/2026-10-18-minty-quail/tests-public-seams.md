# Tests drive public seams and real frames

Tests make 5,748 accesses to private members (`test_resistance.gd` 479, `test_main.gd` 322,
`test_save.gd` 310, `test_pause.gd` 224) and 497 direct `_process`/`_physics_process` calls; 21 suites
instantiate `main`; `test_home_block.gd` (near 249) copies `City._height_for`'s random stream;
`test_camera_start.gd` depends on `main._ready()` holding exactly two awaits. `SceneRecipeRuntime`
rebuilds placement from other classes' private functions (`SealPlanner._eligible`, `_place`,
`_seal_along_tile`, `_mark_soft_sealed`; `EventScheduler._build_placement`, `_room_around`,
`_finale_ground`, `_without_its_aftermath`; `RegionPlanner._add_door_bodies`; `city.events._plans`;
`instance._advance_gait`), so authored scenes drift from the game.

**Build:** as each owner is extracted (the items above), it gets public seams and injected
dependencies, and the tests that reached into it move to the seams, with fakes injected instead of
statics patched; once `test-runner.md` lets frames pass, scene-level tests step real frames. Planners
get public "place this at this site" entry points that the scheduler and recipes both call. Do this
with each extraction, not as one sweep.
