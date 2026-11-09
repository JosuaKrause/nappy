# minty-quail — The lane strategies ask their mover through a narrow lane interface (minty-quail, field-reads) · 2026-11-09

The conversion of the `LaneMover` and `LaneStrategy` groups of `tools/field_reads.txt`: 62 lines gone
(the two that remain are the fenced `kind` reads in `still_watch.gd` and `day_director.gd`). It follows
the orchestrating session's reading of inbox #1173 in gray-dolphin (open to the player's overturn): the
mover builds a narrow interface of the lane state its strategies may ask about, with methods named for
the questions they ask, and hands it to each strategy; no per-field method is added to `LaneMover`.

## What it is

- `LaneMover.Lane` is an inner class (so, by the field-read rule, the mover's own view of itself)
  built with the mover and returned by `LaneMover.lane()`. It answers and sets what the car and walker
  strategies, the crowd, the agent's look and its excitement ask: `is_vertical()`, `corridor_index()`,
  `lane_index()`, `direction()`, `speed()`, `lane_centre()`, `junction_index()`, `detour()`, `turn()`,
  `turn_run_up()`, `scanned_at()`, `gap_ahead()`, `door_ahead()` and the setters for the ones the
  strategies write. `use_crowd_parts()` is the crowd's one setup call and `clear_what_is_ahead()` its
  one reset.
- **What never changes under a strategy is handed to it, not asked for.** The map, the crowd's field,
  the day's traffic and pockets, the mover's random stream and its held move are given to the
  strategy by `LaneStrategy.take_parts()` whenever the mover learns them (setup, kind installed, the
  crowd's parts), and held as members. They were about half of all the reads, so this is dependency
  injection doing the work a method call would otherwise do on every access.
- `LaneStrategy` answers `body_nose()`, `acts_within_tiles()`, `scans_from_its_lane_centre()`,
  `is_shut_by_a_hold()`, `has_nowhere_to_turn()` and `ground_stopped_today()` to the mover and the
  crowd.

## What it costs, and the choice made

The strategies read the mover's lane state about 330 times in code that runs for every agent every
physics tick, and the mover's own comment says a member read is several times cheaper than asking
another object. Measured with `tests/probes/m159_crowd_tick_cost.gd` (the crowd's whole physics tick
on two fixed seeds, days 1, 9 and 14, two walks, three repetitions; its SHA-256 chain over every
agent's position and speed after every tick), main and this branch run side by side in two worktrees
at the same time, on a debug build:

- **The chain is identical on every configuration**: no agent is anywhere else on any tick.
- **The first form**, every read a call on the interface, cost about 3.5 times main's tick (day 1 on
  seed 4242: 3.6 ms on main, 13.5 ms on the branch). The map alone was 42% of the interface's
  calls.
- **What brought it down**: handing each strategy what never changes under it (the map, the
  crowd's field, the day's traffic and pockets, the mover's random stream and its held move) through
  `LaneStrategy.take_parts()`, which removed about two thirds of the calls, and caching the turn in
  the two functions that follow it.
- **The result**, two paired rounds: the branch's tick is 3.6% and 6.0% above main's in total (round
  one 51.1 ms against 52.9 ms summed over the twelve configurations, round two 29.6 ms against
  31.4 ms). Most configurations are 5 to 10% above and a few are inside noise; one configuration moves
  10% between rounds. About ten interface calls per agent per tick are left.
- **A release build was not measured**: the pair needs the export templates and a separate export of
  each revision, which was not set up for this change. The debug build runs GDScript calls slower than
  a release one, so the figures above are likely an upper bound.

**The orchestrator's choice, open to the player's overturn:** keep the interface and its few percent
of the crowd's tick in a debug build, with positions identical tick for tick. **Rejected: folding the
car and walker strategies into `lane_mover.gd` as inner classes**, which the checker would allow and
which costs nothing per frame. It would escape the rule instead of keeping it (inbox #1173: fields are
not API) and break designing-classes' one class per concern, for a file of about 3,700 lines.

## Not done

The fenced `kind` reads, and the fields staying public: the mover's lane fields are read and set by
tests (`tests/crowd_rig.gd` and others), so they are not made underscore-private here.
