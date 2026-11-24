# minty-quail — The tests read the walker, the mover, the turn and the source through methods, and the last item of the one-module pass closes (minty-quail) · 2026-11-24

**The ask.** A test reads what it tests only through methods: on the board's tests-read-fields,
whether a test counts as another object under "fields are not API", "yes" (inbox #1182 in gray-dolphin).
The item was `docs/todo/2026-10-18-minty-quail/tests-one-module.md`; the first part of it is the record
velvet-bunny (`tools/decisions.sh velvet-bunny`). This record is the rest, and the item is deleted with it.

## What was built

- **The five reads the field-read check left in the suites** (a rerun over a scratch copy with `tests/`
  moved under `src/`, the tests' own fakes and the probes aside) were all in
  `tests/test_prediction_reuse.gd`:
  - `CarTurn.travelled` is `_travelled`; the suite moves the arc with `travel_on()` by the difference to
    the distance it wants (`distance_travelled()` says where it is), the call the car's strategy makes.
  - `ExcitementSource.player_expected_total_gross` is `_player_expected_total_gross`. The suite's told
    event source (`ToldEventSource`) keeps the total the halo last told it, as it keeps the motion, and
    the real-halo check compares what the two halos told. The net (`expected_impact_at()`) cannot carry
    the total in that rig: her position is not heard by the events (the manager's tick is off), so the
    projected gross is zero and so is every net.
  - `LaneMover._speed` is set through the lane's `ease_speed_toward()`, which a strategy calls, read
    through `speed()`.
  - `WalkerStrategy._yield_left` is reached through `step_aside()` (somebody walks into the walker along its
    own line) and `forget_the_detour()`; `_door_state` through the door's own walk: the hut seen ahead
    (`see_a_door_ahead()`), joined and waited at, admitted by a real `WalkerDoorHold`
    (`advance_the_door_hold()`), and let out again after `WALKER_DOOR_HOLD_SECONDS`.
- **The mast sites of a suite that plans one city over many days are worked out once, on the city as
  built**, as the game does (`EventWorld.work_out_mast_sites()`): `test_checkpoints`, `test_spent_park`,
  `test_seals` and `test_resistance_alley_siting` hand `MastSites.compute(map)`, taken when the city is
  generated and before any day's paint, to `GameDawn.masts()`. Their checks and their counts are the
  same as before, and no suite got measurably faster (below): the sites are cheap to work out.
  The suites that already hand sites in (`tests/events_shared_city.gd`, `test_events_placement`,
  `test_events_scheduler`, `test_event_spacing`) hand the ones worked out once on their city, read
  one by one; `tests/finale_rig.gd` hands none on purpose (`_NO_MASTS`: the game hands the escape's
  dawn no mast site). The suites that plan one day on a city (`test_return_patrols`, `test_resistance_traps`,
  `test_scheduler_mouse_piles`) and the probes keep the helper's default, which is the same sites on
  the one paint they plan on; `tests/plan_signature.gd` (one day per call) keeps it too.
- **`_the_column()` in `tests/test_resistance_placement_kinds.gd`** skips a convoy truck the day's own
  plan streams in (the event `EventManager.event_of()` names for a plan), so only the trucks the
  happenings sent count; a break (counting every non-convoy event) fails three checks.

## Verification

Each converted check shown failing under a break and passing on restore, all in
`test_prediction_reuse.gd` (6408 checks before and after): the crowd body's velocity frozen at its first
answer fails the speed, yield, door-hold, door-release, heading and changing-turn-tangent checks;
the halo telling each source a different total fails the "real halo publishes identical totals"
check. A `travel_on()` that does nothing leaves the checks passing, since the cached answer and the
reference read the same unchanged arc: those checks hold that the cache sees a change, which the frozen
velocity shows, and not that `travel_on()` moves the arc (`tests/test_crowd_contributions.gd` and
`tests/test_car_views.gd` hold that).

The suites' times, local and on a busy machine, before and after the mast sites: `test_checkpoints`
99.6 s and 100.1 s, `test_resistance_alley_siting` 73.0 s and 72.6 s, `test_spent_park` 125.8 s and
124.8 s, `test_seals` 110.8 s and 109.7 s; `test_prediction_reuse` 1730 ms and 1667 ms.

## What stays, and where each reason lives

- **The kept exception.** `tests/test_crowd_bodies_on_a_real_day.gd` builds a real city for a guarantee
  that spans the event manager's plan, the city's start of the day and the crowd; its header gives the
  wiring as its reason.
- **The twelve reads the check still reports in the suites each have a `[kept]` line**, with its reason, in
  `tools/test_only_members.txt`: `EventManager.world`, `DaySpec.bag`, `DaySpec.wall_row_share`,
  `City.scenery`, `City.scenery_ground`, `SceneryWater.cells`, `SceneryResidency.budget_usec`,
  `ParkCordon.gap` and `last_gap`, `ResistanceHappenings.cordon`, `ModeButton.symbol` and
  `hold_progress`.
- **The probes under `tests/probes/`** (about sixty reads, nearly all underscore fields) stay as they are:
  a probe is a measurement script run by name and no suite runs it, while the rule is about suites (a
  reading of inbox #1182 in gray-dolphin, open to the player's correction).
- **The module-by-module conversion of the suites to mocks** is writing-tests' rule, applied as a pull
  request touches a suite ("A suite a pull request touches for another reason is converted only as far
  as the pull request's change reaches", inbox #1159 in gray-dolphin); the item that carried it is gone.

## The builder's choices, each open to overturn

- **`_direction` and `_turn_back_hold` are still written through `set()` by name** in
  `_test_crowd_mutations()`: the field-read check does not list them (the suite's body extends
  `CrowdAgent`, so they are a descendant's own), and the brief's list named `_speed` only.
- **The mast sites are hoisted only where a suite plans one city over several days with the default**;
  the probes and the suites planning a single day keep the default (above), a reading of "suites that
  plan one city over many days".
