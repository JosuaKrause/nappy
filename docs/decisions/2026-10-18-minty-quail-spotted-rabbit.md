# minty-quail — Main's and the run's members only their own class uses become internal · 2026-11-07

minty-quail's `tests-own-class-members.md`, main and the run, in #1237, a commit per class.

**Built.**
- **`DayDirector.hands_over_to_the_escape`** becomes `_hands_over_to_the_escape`; its test reads
  `finish_day()`'s `DayEnd.hands_over_to_the_escape`, and the scene-recipe case (`escape_follows =
  false`) is a test in its own rig, since `finish_day()` on a won last day ends that run.
- **`DayDirector.facts`** and **`RunCalendar.facts`** become `_facts`; no test changed, since the
  check's "test reads" were `RunState.facts`, another class's.
- **`Main.use_sitting`** is deleted: nothing in the game or the tests called it (the tests'
  `use_sitting()` is `TitleScreen`'s, and suites park a sitting through `use_sitting_home()`), with
  the sentences naming it and the guard in `_take_the_sitting()` it left always true.
- **`Main.configure`** stays public with a `[kept]` line: nothing outward can set the command line a
  boot reads, and the suites that boot the real `main.tscn` hand it their flags, the same reason as
  the kept `EventManager.planner`.

**Choice where the design was silent, open to overturn:** `Main.configure` keeps its name rather
than becoming `use_config`, a rename beyond the item.
