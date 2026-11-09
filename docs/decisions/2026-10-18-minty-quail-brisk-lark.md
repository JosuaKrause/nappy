# minty-quail — The lane strategies ask their mover through a narrow lane interface (minty-quail, field-reads) · 2026-11-09

The conversion of the `LaneMover` and `LaneStrategy` groups of `tools/field_reads.txt`: 62 lines gone
(the two that remain are the fenced `kind` reads in `still_watch.gd` and `day_director.gd`). It follows
the orchestrating session's reading of inbox #1173 in gray-dolphin (open to the player's overturn): the
mover builds a narrow interface of the lane state its strategies may ask about, and the strategies ask
questions and report events through it rather than reading or writing its fields; no per-field method is
added to `LaneMover`.

## What it is

`LaneMover.Lane` is an inner class (the mover's own view of itself) built with the mover and returned by
`LaneMover.lane()`.

- **Questions**, asked by the car and walker strategies, the crowd and the agent's look and excitement:
  `is_vertical()`, `corridor_index()`, `lane_index()`, `direction()`, `lane_centre()`,
  `junction_index()`, `detour()`, `turn()`, `is_in_the_arc()`, `turn_run_up()`, `cruise_speed()`,
  `blocked_in()`, `shape()`, `map()`, `kind()`, `strategy()`, `gap_ahead()`, `leader_speed()`,
  `pedestrian_ahead()`, `junction_hold()`, `gate_hold()`, `door_ahead()`, `door_ahead_along()`.
  A strategy asks the mover itself for its speed (`speed()`) and whether it is mid-turn
  (`is_turning()`).
- **Events**, each carrying the whole change, the mover working out what it already knows:
  `start_in_a_lane()` (a morning's choice), `enter_a_lane()` (a body recycled at a stretch's end),
  `turn_round_into()`, `turn_into(vertical, corridor, direction, lane, from_corridor)` (a walker's
  corner and a car's landing: one call that switches the axis, corridor and way, settles the lane
  and its centre line, drops any sidestep and marks the junction it came down, so the order of the
  parts cannot drift; a negative lane is the pavement nearest where it stands once turned, worked out
  by the mover after the switch),
  `be_in_junction()`, `leave_the_junction()`, `ease_speed_toward()`, `limit_speed_to()`,
  `drive_the_run_up()`, `detour_to_within()`, `end_the_detour()`,
  `look_ahead_afresh()`, `see_a_door_ahead()`, `clear_the_door_ahead()`, `follow_at_a_gap()` and
  `clear_what_is_ahead()`.
- `LaneMover.use_crowd_parts()` is the crowd's one setup call and `LaneMover.nose()` its question about
  the body's length; `LaneStrategy` answers `body_nose()`, `acts_within_tiles()`,
  `scans_from_its_lane_centre()`, `is_shut_by_a_hold()`, `has_nowhere_to_turn()` and
  `ground_stopped_today()` to the mover.
- **What never changes under a strategy is handed to it, not asked for.** The map, the crowd's field,
  the day's traffic and pockets, the mover's random stream and its held move are given to the strategy
  by `LaneStrategy.take_parts()` whenever the mover learns them (setup, kind installed,
  `use_crowd_parts()`) and held as members. The mover's `_field`, `_traffic` and `_pockets` are private
  and are set only through those calls, so the strategy's copies cannot go stale.
- `Crowd.use_traffic()` hands the crowd the index of where its cars are before a day starts. The two
  crowd rigs that read and claim into it hand in their own; it is a line of the kept hand-ins in
  `tools/test_only_members.txt`, since the world layer may not name the index to hand one in.

Which fields stay public: the mover's lane fields (`_vertical`, `_corridor`, `_lane`, `_direction`,
`_speed` and the like, underscore names that some tests and probes read) and its public `kind`,
`strategy`, `shape`, `gap_ahead`, `leader_speed`, `pedestrian_ahead`, `junction_hold`, `gate_hold`,
`door_ahead`, `door_ahead_along`, `view` and `frame_timing`; the fenced `kind` readers keep `kind`.
The strategies still make 49 calls to 11 of the mover's underscore methods (`_along()`,
`_cross()`, `_set_along()` and the like); a later pull request turns those into questions on this
interface (the queue item says so).

## What it costs, and the choice made

The strategies read the mover's lane state about 330 times in code that runs for every agent every
physics tick, and the mover's own comment says a member read is several times cheaper than asking
another object. Measured with `tests/probes/m159_crowd_tick_cost.gd` (the crowd's whole physics tick on
two fixed seeds, days 1, 9 and 14, two walks, three repetitions each, and its SHA-256 chain over every
agent's position and speed after every tick), main and this branch run side by side in two worktrees
at the same time, on a debug build. The figure quoted is the total over the twelve configurations in a
round, since one configuration alone moves by up to 30 points between rounds:

- **The chain is identical on every configuration**: no agent is anywhere else on any tick.
- **The first form**, every read a call on the interface, cost about 3.5 times main's tick.
- **The form with the handed parts** (before the interface was narrowed) measured +3.6% and +6.0% in
  the author's two rounds and +7.9% and +9.1% in the reviewer's, day 9 near +10%.
- **This form** (events instead of setters), two paired rounds on a heavily loaded machine (the
  absolute figures are about 1.7 times the earlier rounds'): +6.7% (80.5 ms on main, 85.9 ms on the
  branch) and +8.8% (83.6 ms and 91.0 ms) in total. Per day, summed over the seeds and walks: +6.7% and
  +8.0% on day 1, +8.4% and +13.6% on day 9, +5.9% and +7.5% on day 14.
- **A release build was not measured**: the pair needs the export templates and a separate export of
  each revision, which was not set up for this change. The debug build runs GDScript calls slower than
  a release one, so the figures are likely an upper bound.

**The orchestrator's choice, open to the player's overturn:** keep the interface and its few percent of
the crowd's tick in a debug build, with positions identical tick for tick. **Rejected: folding the car
and walker strategies into `lane_mover.gd` as inner classes**, which the checker would allow and which
costs nothing per frame. It would escape the rule instead of keeping it (inbox #1173: fields are not
API) and give up separation of concerns and cohesion for a file of about 3,700 lines.

## Checked

**Behaviour is unchanged only because a divert regression was found and fixed.** The first events
form worked a walker's fallback pavement out on the old corridor and axis in `WalkerStrategy.divert()`
(the arguments of the join were evaluated before it); the cost probe's chain did not reach that path,
and `m110_bodies.gd` moved on one seed. `turn_into()` now switches the axis and corridor first and
chooses the nearest pavement after, as main did, and `_test_a_walker_turned_into_a_corridor_lands_on_the_pavement_nearest_it_once_turned`
in the crowd rig's streets part checks it (it fails when the choice is made before the switch).

Every crowd probe under `tests/probes/` was run on main (at the tip this branch is merged with) and on
this head and its output compared with timing figures and object ids removed: identical for
`entity_frame_profile_observer`, `excitement_fingerprint`, `m100_map_edge_entries` (which places its
agent through `setup()` now), `m108_walker_stride_sheet`, `m110_bodies`, `m117_decay`, `m152_car_jumps`,
`m156_car_turns`, `m159_contribution_cost`, `m219_precinct_pile`, `m96_crying_at_the_top`,
`minty_quail_lane_parity` (its chains and drawn hashes) and `m159_crowd_tick_cost`'s SHA-256 chain on
all twelve configurations, and the same outcome, differing only in object ids and a timing line, for
`m191_horn_watch`, `minty_quail_crowd_cadence`, `minty_quail_crowd_frames` and
`minty_quail_crowd_yields` (whose three leak failures are main's too). `m128_park_beats` ran to the
end only on the head; main's run reached the probe's time limit, and the part both ran is identical.
The crowd, car, walker, lane, separation, traffic, yields, door and hut, observers (the run-log
baseline), excitement, closure, pocket, signal, gate, recycle, stretch and checkpoint suites pass.
`polite_rabbit_wall_costs`, `m159_tick_sweep_events_cost` and `calm_pelican_fields_layer_cost`, which
measure event and layer costs, were not completed.
