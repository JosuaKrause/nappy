## M100 — Small, real, and nobody's · the dev rig moves out of main.gd, 2026-09-12

The last of the queue's dev-only leftovers: `DevFlags` had taken the flag parsing out of `main.gd`
and left the code that acts on the flags there, about a sixth of the file, tangled into the boot
sequence. One agent commit on `feature/dev-rig-out-of-main`. **What stands**: `src/dev/dev_rig.gd`,
class `DevRig`, holds the whole `--spawn` target lookup (park, alley, square, playground, event and
`event:<id>`, arterial, `closure:<n>`, `zone:<n>`, landmark, signal, `edge:<side>`, precinct,
`corner:<which>`, contact), `first_event_position`, `pavement_offset`, `nearest_walkable`, the
`--follow` camera, the `--overview` camera, the `--meters` override and the `--day-length`
override, every doc comment moved with its function and behaviour unchanged. It is a
`RefCounted`: the follow camera and the event id it tracks are the only state that survives
across calls, so those are instance members and everything else is static, taking the city, the
resistance director, the baby or a parent node as arguments so it runs headless without booting
`main`. `main.gd` keeps one-line calls and `_somebody_is_playing()`, which is about the run log
rather than a rig. `tests/test_dev_rig.gd` builds a day on a fixed seed and checks the named
targets land on walkable ground, an unknown target warns and falls back to the doorstep, and the
pavement offset crosses the street's own width on both orientations, moved from `tests/test_main.gd`.
Six smoke runs of the moved flags through `tools/shot.sh` each produced a picture and no script
error. `DECISIONS.md`'s older record naming `main._pavement_offset()` is history and stands; the
function is now `DevRig.pavement_offset()`.
