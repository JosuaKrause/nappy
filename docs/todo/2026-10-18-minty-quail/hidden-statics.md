# Hidden globals held in statics

- **58 `static var`s hold hidden globals** (the review's count at v0.29.0): among them
  `StreetNetwork._segments`, `SealPlanner._candidates` and the `AtlasLibrary` statics. A component
  that reads one depends on whatever the last caller left there, and a test cannot hand it a fake,
  only patch the static and put it back. The README's dependency-injection rule names "a static"
  among the things a component must not fetch what it depends on from.
- **The calendar's operations live on the `GameState` autoload.** `day_rng()`, `begin_day()`,
  `finish_day()`, `settled_this_act()`, `current_act()` and the other run methods are autoload
  methods, so `DayDirector` is handed the whole autoload (typed `RunState`) rather than an owner of
  them. `begin_day()` on a checkpoint day and the last-nerve go-back hand `GameSave` the run itself
  (`self`), so a fresh `RunState.new()` keeps its checkpoint to itself.

**Build:** each owner holds its state and is handed it through its setup or constructor, and no
static holds hidden globals; a value that is truly one per process (a table read once from disk) is
held by the owner that reads it and handed to whoever needs it.

**Build (carry-over from #860, the orchestrating session's, open to overturn):** `day_rng()`,
`begin_day()`, `finish_day()`, `settled_this_act()`, `current_act()` and the other run methods
`DayDirector` calls on `RunState` (the class of the `GameState` autoload) move off the autoload to an
owner that is handed in.

*Split out of `main-and-state.md` by the orchestrating session, not the player, open to overturn:*
the statics belong to the city, the routes and the art rather than to the run's state, so the item
that keeps the run's state in one place does not build them. The calendar's operations are this entry's
by the carry-over above, since #860 handed the director the autoload as it stands.
