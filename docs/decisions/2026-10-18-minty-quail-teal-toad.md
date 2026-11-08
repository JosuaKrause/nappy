# minty-quail — The player and the baby's suites build no city and boot no main · 2026-11-07

minty-quail's `tests-one-module.md`, entry 2, the player and the baby, in #1227, a commit per suite.

**Converted.**
- **`test_player_presentation`**: the pose matrix runs on `stroller.tscn` handed `is_male` before
  it enters the tree, with no boot; "main binds the family before the first draw" moved to
  `test_main`.
- **`test_baby_world`**: the baby alone, two `FakeWorld`s on a bare `Stroller` showing she answers
  from the world last handed, and from none as neutral; the three boots moved to `test_main` as one
  case that main hands her the world it puts her in. Two checks of the real city's own answers (its
  events charging a spot, its calm ground's gain) are dropped: they are the city's, and
  `test_meters` holds the meter arithmetic.
- **`test_pelican`** and **`test_loose_dog_arrives`**: no City node. The shared fixture
  `tests/fixtures/street_events.gd` (`StreetEvents.over(t, map, run)`) hands an `EventManager` a
  cached map, a run and a bare world node. The pelican's case from warning to run log stays
  combined, since it spans the manager, the danger edge, the observer and the log.
- **`test_tutorial_dog`**: a hand-drawn street map (`StreetMap.full()`), the director reading only
  streets.

**Kept combined, the reason in each header.** `test_camera_start`, whose subject is main's own boot
order, and `test_move_poses`, a contract between every kind of mover and the map's list; both take
their cities from the cache.

**Measured** (ms, before and after, on a machine at load average 80 to 110, so an order of
magnitude only): `test_player_presentation` 17569 to 38, `test_baby_world` 23528 to 2823,
`test_move_poses` 63861 to 33936, `test_camera_start` 16893 to 11508, `test_pelican` 9915 to 4199,
`test_loose_dog_arrives` 23546 to 18863, `test_tutorial_dog` 93727 to 80750.

**Choices where the design was silent, open to overturn:** `StreetEvents` is a shared fixture, two
suites using it; the baby suite's `FakeWorld` stays its own rather than merged with
`test_meters`' and `test_invincible`'s, which answer other questions; the moved checks went into
`test_main` rather than a new suite.

**Left.** `test_tutorial_dog`'s case asking where the scheduler places the dog
(`EventScheduler.build_day`) is the scheduler's answer and still runs on generated maps; the queue
item names it.
