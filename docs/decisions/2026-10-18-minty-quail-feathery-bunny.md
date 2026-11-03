# minty-quail — Ten more city suites read what the game already calls and hand each city its own run (tests through public seams) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the second city pass, ten of the
seventeen suites it was given, partly. The item lists what each still reads and the seven untouched.

**Built.**
- No `src/` change. The suites read members the game already calls in place of privates:
  `SealPlanner.positions_across()` for `_hard_positions`, `CityMap.is_main_road()` for
  `_is_the_main_road`, day 1's `plan_day()` for `_eligible`, a plan's `wall_bodies` with
  `alley_mouth_rect()` for `_alley_mouth_wall_body`, `EventInstance.runs_vertically()` for
  `_spread_is_vertical`, `contact().complete_now()` for `_on_contact_completed`,
  `reach_obstruction()` for `_reach_blocked`, `Building.window_texture()` for `_window_style` and
  `_windows`.
- Two test fixtures, `RunCity.in_run` and `RunCity.with_own_run` (`tests/fixtures/run_city.gd`),
  hand a city a fresh `RunState`, so the park cordon, spent park and world passability suites no
  longer touch `GameState` (45 lines to 0), and the blocks, home block and barrier suites build
  their cities on a run of their own.
- Private-read lines: seals 6 to 1, shapes 3 to 2, regions 8 to 3, home_block 9 to 5, park_cordon
  8 to 4, park_cordon_seeds 10 to 5; spent_park, world_passability, blocks and barrier_stays
  unchanged. Every check kept but home_block's window-style and lit-pattern checks, merged (four
  fewer); regions gains checks that the plan's wall body stands in each alley mouth. A first
  day-one soft-seal check passed with no soft seals placed, since alley mouths take soft rows too;
  it counts street seals only.

**Not done:** the seven suites that want readers no game class calls (roof art, the excitement
field, a chunk's tiles, the generator's helpers) or a real `Stroller` on frames; the resistance
area's privates the park cordon suites read, reported rather than opened. #990's planner entries
were not yet on main when this pass started.
