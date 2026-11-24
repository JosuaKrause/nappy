# minty-quail — Each suite tests its one module, and the item goes · 2026-11-24

`docs/todo/2026-10-18-minty-quail/tests-one-module.md` asked that no test build a real object it does not
test and that a suite test only the module it is named for, unless there is a good reason (inbox #1159 in
gray-dolphin). Every module has had its pass (the records the item listed, the last
minty-quail-frosty-tapir), so the file is deleted; its text is at
`git show 3fa20307d:docs/todo/2026-10-18-minty-quail/tests-one-module.md`. The rule stays in **writing-tests**.

**The one leftover is a kept exception, not work.** `tests/test_crowd_bodies_on_a_real_day.gd` keeps its
check that a crash's cars stand on recorded ground; its header says why it builds a real city: the guarantee
spans the event manager's plan filling `CityMap`'s obstructed tiles, the city starting the day and the
crowd walking round what stands there, and the record the manager writes while the city starts the day
against where a live event stands its cars.

**What the item held that no item owns.** A suite that plans one city over many days hands in its mast sites
worked out once per city, as the game does (`EventWorld.work_out_mast_sites()`); the suites that leave them to
`tests/game_dawn.gd`'s default have them worked out at each planned dawn, which can measure masts that move
between days, a thing the game never shows (the orchestrator's choice in placement step 3c, open to
overturn). A suite that is touched hoists them.

**Where it was named.** `tools/test_only_members.txt` lines for `Crowd.step` and `ContactPoint.is_done` and
a sentence of `tools/check_field_reads.py`'s header still name the file, and are code-side.
