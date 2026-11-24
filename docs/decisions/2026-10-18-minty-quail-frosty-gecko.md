# minty-quail — Both scene recipe files are typed and the runtime's own members are internal · 2026-11-24

**Built.** `src/dev/scene_recipe_runtime.gd` and `src/dev/scene_recipe_draft.gd` carry no opt-out
line: every receiver is typed, and a recipe's dictionary keys that were read as fields
(`entry.segment`, `entry.mast_id`, `entry.hold`, `entry.speed`, `drafted.setup.posters`) are read by
subscript. `tools/typing_census.py --check` finds no file under `src/`, `tests/` or `tools/` with
a typing warning left. The runtime's `manifest`, `named`, `tick` and `start_position()` are internal
(their four `[own file only]` lines left `tools/test_only_members.txt`), and so are `built`,
`position_of()`, `subject_of()`, `activity_snapshot()` and `write_manifest()`, which nothing outside
the file called.

**The manifest file is how the scene is read from outside.** The runtime writes its manifest
(`--recipe-manifest PATH`) at `begin()`, at a capture, at the end and at every failure, and now also
when it records that she read the task's mark (`read_tick`), as it already did at an expiry, so a
free-play scene's file says when the mark was read. The two suites read that file through
`tests/recipe_manifest.gd`: the observations, `setup_failed`, `task.read_tick` and
`task.expired_tick`, `initial_actors` and `installed_events`. The clock reads
`roundi(runtime.elapsed() * Engine.physics_ticks_per_second)`. The one-tick-input probe installs the
scene onto a world of stand-ins whose `Stroller` moves a pixel on a pressed tick, so the scene names
its own player instead of the test writing `named`.

**The plan's recipe entry is the runtime's own.** A plan the runtime builds from a recipe entry used
to carry the entry's name, hold, charging and relentless as four `set_meta()` marks on the plan, read
back with `get_meta()` (a Variant) after `start_recipe()`. The runtime keeps a dictionary from each
plan to its entry instead, since state kept on another object from outside is what typing the file
exposed; each read goes through a typed `Dictionary`.

**Measured.** The sixteen recipe suites give the same 1537 checks on `main` and on the branch;
`tools/scene-recipes.sh` passes every recipe; `tools/scene-draft.sh` writes byte-identical drafts
for `task-07-package` and `task-11-mast` on `main` and on the branch.

**Left out.** `ResistanceSteps.Step`'s fields stay as they are: no check lists an inner class's field,
and no queue entry owns them.
