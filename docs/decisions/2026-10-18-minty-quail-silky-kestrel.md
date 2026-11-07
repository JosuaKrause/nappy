# minty-quail — The full-run and balance suites start each day the way the game does · 2026-11-06

No queue item: a coverage hole found by the test survey for inbox #1159. `tests/full_run_rig.gd`
(behind `test_full_run_a.gd`, `_b.gd` and `_c.gd`) started each day by hand, copying `main._start_day()`
without `DayDirector.start_day()`, so the three fourteen-day runs never handed the repaint the calm
areas she had used (`CityMap.set_spent_calm()`) or the fenced park (`set_fenced_park_state()`), never
refreshed the street trees, and had no crowd and no gates. `test_balance.gd` called only
`EventManager.start_day()`, so its city was never painted for the day and had no closures and no
spent calm areas. Tests only.

**Built.**
- The full-run rig starts every day through `DayDirector.start_day()`, handed what `main` hands it:
  the city, its events, the resistance, a stroller with the baby riding, and a day clock set up the
  way `main` sets it up (`DayController.setup()`). The hand-copied steps are gone, and so is the
  rig's own write of the day number: the calendar's `finish_day()` moves it, and a check says the
  calendar is on the day the loop expects. Neither she nor the baby takes physics ticks and nothing
  ticks the clock, since nobody steers her and the baby's meters are not this suite's question.
- A won day is one she settled on, so before banking each day the rig stands her on the calm ground
  of the calm area nearest home that she has not used this act and that today's tree has not taken
  off, and the baby falls asleep there (`Baby.force_sleep()`, which announces it the way falling
  asleep does). The clock hears it and remembers the area (`RunCalendar.remember_where_she_settled()`),
  and the events owe the return patrols. New checks: the day is still under way when she settles,
  the area is remembered, on at least one day of the run a used area comes off a later day's tree
  (`CityMap.shut_calm` not empty), and every day has its crowd.
- The day is still banked with `RunCalendar.finish_day(WON)`, not `DayDirector.finish_day()`: a won
  day 14 with every task done hands over to the escape there and leaves the ending unset, so the
  suite's good-ending check would need the escape played.
- The balance suite builds the rig once (her, the baby, the clock, the resistance, the director),
  starts every day through `DayDirector.start_day()`, and rebuilds the crowd round where she stands
  through `DayDirector.start_the_crowd()`, at the day's own density. Each test plays from a fresh run
  on its seed; the every-day test banks each day as won, so the area she fell asleep in is spent on
  the act's later days.
- `tests/fixtures/calm_spot.gd` (`CalmSpot.of()`): the calm tile of an area's calm ground
  (`ClosurePlanner.calm_area_rect()`, the rect the scheduler keeps clean) nearest its centre, where
  both rigs stand her.
- Both suites call `t.gives_back_observers()` first: the days are announced on the bus as the game
  announces them, so the page's visit counter counts them. The first run without it failed on
  `VisitCounter._day` going from 0 to 14.

**What it exposed.** No game bug: the three full runs passed every check, old and new, on their
first run through the director. One rig bug: the balance suite measured each calm area at the
centre of its block's rect, which for a courtyard is a building. Nothing showed it while the city
was never repainted, since the day-1 courtyard came first in the list and won every tie at zero.
Started the game's way, nine of fourteen days failed (2, 3, 6, 7, 9, 10, 11, 13 and 14, run seed 2,
city 4242): on the days the day-1 courtyard was spent and spoiled (0.7 to 1.4 at its centre), or gone
from the calm list (days 13 and 14), the next clean block was measured on its roof, she stood there
all day and the meter stopped at 88 or 75.6. With the spent areas cleared every morning, days 13 and
14 still failed, so the repaint alone shows it too. Measured on calm ground, every day settles her.

**Runtime**, the four suites back to back on one machine, before and after: the balance suite 38.0s
and 38.3s; the full runs 39.8s, 38.4s and 39.5s before, 54.2s, 63.3s and 61.4s after, from the crowd
now ticking and the day director's start each morning.

**Open to overturn:** she settles at the nearest unused calm area after the simulated stretch, by
the baby's dev path to sleep, rather than walking there and letting the meters run; the clock is set
up but never ticked, so no day ends on the clock in either suite.
