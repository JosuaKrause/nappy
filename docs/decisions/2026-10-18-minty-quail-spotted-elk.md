# minty-quail — The gatehouse day is worked out once, by the day's spec · 2026-11-07

minty-quail's `re-derived-cases.md`, the gatehouse day: whether today is the day the region wall
first divides the city (`Tuning.REGION_WALL_FIRST_DAY`, day 9) or after it, in #1229.

**Before.** Three places compared the day number with the constant for themselves: `DaySpec.for_day()`
to keep a share of the catalogue's walls, `ClosurePlanner.closures_wanted()` to cut the closure
quota, and `SealPlanner.plan_day()` and `_seal_alley_mouths()` to thin the seals and the alley-mouth
chance.

**Built.**
- `DaySpec.for_day()` works the fact out once into a private field, and
  `DaySpec.region_wall_stands()` answers it. The spec owns it because it is already the one object
  every reader is handed for the day, and it is plain data built before anything plans the day.
- Each share stays with the planner that uses it, at 0.5.
- `ClosurePlanner.plan_day()` and `closures_wanted()` take a `DaySpec` instead of the day number,
  as `SealPlanner.plan_day()` already did; `City._close_streets()` and the scene-recipe city
  builder hand it on. `DaySpec.day_number()` is a new getter, so no new reader of the `number`
  field is added.
- `tests/test_day_spec.gd` checks the answer on days 8, 9, 10 and 14 and on both escape sections,
  and that the catalogue's walls are thinned on exactly the days the wall stands, building no city.
  `tests/fake_day_spec.gd` (`FakeDaySpec.on(day, wall_stands)`) hands a planner either answer; the
  seal share and closure quota tests use it.

**Measured.** The placement fingerprint is identical to main's at 3aa31087: 15787 placements, the
two sets of `FP ` lines byte for byte the same.

**Choices where the design was silent, open to overturn.**
- The escape's two sections answer no, though their day numbers are past 9: the halved alley-mouth
  chance the old comparison gave them was never rolled, since the escape seals every alley mouth.
- The answer is stored when the spec is built; a hand-built `DaySpec.new()` answers no.
- `ClosurePlanner` takes the spec rather than a true/false, to match `SealPlanner` and take the fake.
- The planner tests hand both answers on every day, including pairs the game never produces (the
  wall standing on day 3).

**Left.** Three readers in files #1169 holds still compare the day with the constant; the queue
item names them.
