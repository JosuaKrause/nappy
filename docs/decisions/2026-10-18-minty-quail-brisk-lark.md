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
  `is_vertical()`, `corridor_index()`, `lane_index()`, `direction()`, `speed()`, `lane_centre()`,
  `junction_index()`, `detour()`, `turn()`, `turn_run_up()`, `cruise_speed()`, `blocked_in()`, `shape()`,
  `map()`, `kind()`, `strategy()`, `gap_ahead()`, `leader_speed()`, `pedestrian_ahead()`,
  `junction_hold()`, `gate_hold()`, `door_ahead()`, `door_ahead_along()`. `traffic()` is asked only by
  two test rigs (`tests/crowd_rig.gd`, `tests/crowd_closures_rig.gd`), which read the day's traffic
  index through it.
- **Events**, named for what happens, each one call where several fields change together:
  `join_a_lane(vertical, corridor, lane, direction)` (a morning's choice, a turn landing, a walker's
  about-face), `change_lane()`, `keep_to_lane_centre()`, `drive_at()`, `be_in_junction()`,
  `detour_by()`, `look_ahead_afresh()`, `use_up_the_run_up()`, `see_a_door_ahead()`,
  `clear_the_door_ahead()`, `follow_at_a_gap()` and `clear_what_is_ahead()`.
- `LaneMover.use_crowd_parts()` is the crowd's one setup call and `LaneMover.nose()` its question about
  the body's length; `LaneStrategy` answers `body_nose()`, `acts_within_tiles()`,
  `scans_from_its_lane_centre()`, `is_shut_by_a_hold()`, `has_nowhere_to_turn()` and
  `ground_stopped_today()` to the mover.
- **What never changes under a strategy is handed to it, not asked for.** The map, the crowd's field,
  the day's traffic and pockets, the mover's random stream and its held move are given to the strategy
  by `LaneStrategy.take_parts()` whenever the mover learns them (setup, kind installed,
  `use_crowd_parts()`) and held as members. The mover's `_field`, `_traffic` and `_pockets` are private
  and are set only through those calls, so the strategy's copies cannot go stale.

Which fields stay public: the mover's lane fields (`_vertical`, `_corridor`, `_lane`, `_direction`,
`_speed` and the like, underscore names that some tests and probes read) and its public `kind`,
`strategy`, `shape`, `gap_ahead`, `leader_speed`, `pedestrian_ahead`, `junction_hold`, `gate_hold`,
`door_ahead`, `door_ahead_along`, `view` and `frame_timing`; the fenced `kind` readers keep `kind`.
The strategies still make about 55 calls to 13 of the mover's underscore methods (`_along()`,
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
- **The form with the handed parts** (before the interface was narrowed to the above) measured +3.6% and
  +6.0% in the author's two rounds and +7.9% and +9.1% in the reviewer's, day 9 near +10%.
- **The narrowed form** (this record's), two paired rounds: +5.3% (46.0 ms on main, 48.4 ms on the
  branch) and +5.4% (28.0 ms and 29.5 ms). Per day, summed over the seeds and walks: +4.6% to +5.6% on
  day 1, +4.7% to +8.8% on day 9, +4.8% to +5.1% on day 14.
- **A release build was not measured**: the pair needs the export templates and a separate export of
  each revision, which was not set up for this change. The debug build runs GDScript calls slower than
  a release one, so the figures are likely an upper bound.

**The orchestrator's choice, open to the player's overturn:** keep the interface and its few percent of
the crowd's tick in a debug build, with positions identical tick for tick. **Rejected: folding the car
and walker strategies into `lane_mover.gd` as inner classes**, which the checker would allow and which
costs nothing per frame. It would escape the rule instead of keeping it (inbox #1173: fields are not
API) and give up separation of concerns and cohesion for a file of about 3,700 lines.

## Checked

The crowd, car, walker, lane, separation, traffic, yields, door and hut, observers (the run-log
baseline), excitement, closure, pocket, signal, gate, recycle, stretch and checkpoint suites pass. The
probes under `tests/probes/` that touch crowd agents were run on main and on the branch: the same
outcome on every one that finished, `m100_map_edge_entries.gd` included (it places its agent through
`setup()` now, and the output is identical to main's), and `excitement_fingerprint.gd`'s output differs
from main's only in its cost lines. `polite_rabbit_wall_costs`, `m159_tick_sweep_events_cost` and
`calm_pelican_fields_layer_cost`, which measure event and layer costs, were not completed.
