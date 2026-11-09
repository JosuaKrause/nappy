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

## What it costs

The strategies read the mover's lane state about 330 times in code that runs for every agent every
physics tick, and the mover's own comment says a member read is several times cheaper than asking
another object. Measured with `tests/probes/m159_crowd_tick_cost.gd` (the crowd's whole physics tick
on two fixed seeds, days 1, 9 and 14, two walks, three repetitions; its SHA-256 chain over every
agent's position and speed after every tick), main and this branch run side by side in two worktrees
at the same time, on a debug build:

- **The chain is identical on every configuration**: no agent is anywhere else on any tick.
- The first form, every read a call on the interface, cost about three and a half times main's tick.
  The map was 42% of the calls, so handing the strategy its collaborators (above) cut it to about
  1.05 times main's; caching the turn in the two functions that follow it did the rest of what a
  local could.
- Over two paired rounds the branch's tick is 3.6% and 6.0% above main's in total, 5 to 10% on most
  configurations and inside noise on a few (the same configuration moves by 10% between rounds). It is
  a measurable cost, so it is put to the player.

## Not done

The fenced `kind` reads, and the fields staying public: the mover's lane fields are read and set by
tests (`tests/crowd_rig.gd` and others), so they are not made underscore-private here.
