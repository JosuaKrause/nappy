# minty-quail — Each suite tests its one module: what moved, what stays · 2026-11-24

`docs/todo/2026-10-18-minty-quail/tests-one-module.md` asked that no test build a real object it
does not test and that a suite test only the module it is named for, unless there is a good reason
(inbox #1159 in gray-dolphin), and that a test read what it tests only through methods (inbox
#1182 in gray-dolphin). Every module has had its pass (the records the item listed, the last
minty-quail-frosty-tapir), so the item's list of suites to convert is gone from the file; the
first text is at `git show 3fa20307d:docs/todo/2026-10-18-minty-quail/tests-one-module.md`.

**What the item holds now.** The reads of a class's field that a test still makes:
`ContactPoint.is_done`, `Crowd.step()` driven by a rig, `WorldMap.blocked`,
`ExcitementSource.player_velocity` and `LaneMover.view`, found by running the field-read check
over a scratch copy of the tree with `tests/` moved under `src/`; and the mast sites a suite
leaves to `tests/game_dawn.gd`'s default. The one suite that keeps a real city,
`tests/test_crowd_bodies_on_a_real_day.gd`, is a kept exception whose header gives its wiring as
the reason.

**Where it is named.** `tools/test_only_members.txt` lines for `Crowd.step` and
`ContactPoint.is_done` and the header of `tools/check_field_reads.py` point at the item.
