# minty-quail — The crowd tells its movers what it found and reports on a bus it is handed (minty-quail, the crowd) · 2026-11-10

**The ask.** "never read fields directly. always read through a method" (inbox #1173 in
gray-dolphin), and a component is handed what it depends on (minty-lemur #794). A Fable planning
agent cut the crowd's module pass: its field reads (`field-reads.md`) and its share of the signal
bus (`standing-layer-breaks.md`), with `crowd.gd` typed.

## What was built

- **The crowd reads and writes no field of its movers.** It asks their lane (`LaneMover.Lane`) for
  their kind and shape, and tells it what it found through six new events under the lane's heading
  "what the crowd finds": `find_a_junction_to_hold_at(distance)` and `find_no_junction_to_hold_at()`
  (which car waits at a junction box), `find_a_gate_to_hold_at(distance)` and
  `find_no_gate_to_hold_at()` (a car stopped at a lowered boom), `see_a_pedestrian_at(at)` and
  `see_no_pedestrian()` (whether she is within a car's sight). Each pass fetches a mover's lane
  (`agent.lane()`) once; only `_meet_the_player()` keeps it in a local, and none of the fetches is
  inside a loop over pairs.
- **`CrowdSources` asks `CrowdAgent.mood()`** in place of reading its `excitement`.
- **The crowd reports on a bus it is handed** (`Crowd.use_bus()`, called by `main.gd` beside
  handing it her) instead of the `EventBus` autoload; its three reports (a bump, a car's strike, a
  horn) come at the moment they did. `crowd.gd` leaves the layer map's `EventBus` group; ten emitter
  files are left in it. One rig (`tests/crowd_rig.gd`, in its horn check
  and its bump check), `tests/test_car_front.gd` and the two probes that count its reports hand it
  the bus, and the cost and parity probes that run a crowd with her hand it the bus as the game does.
- **`crowd.gd` is typed** and loses its first-line opt-out.
- `docs/ARCHITECTURE.md` lists the crowd's hand-in, and the two comments elsewhere that said the
  crowd writes its movers' fields say it tells them. `tools/field_reads.txt` lost six lines.

## Parity

Five probes give one hash each on `main` at `651606332` and on the code commit `b34668cef`: what
every source charges her, every event, crowd agent and meter on every tick, the crowd's own tick, the
lanes' parity (its two timing figures taken out) and the bodies (`m110_bodies.gd`). The run log is
line for line what it was.

## Choices the builder made, open to the player's overturn

- **A pair of events per fact** (`find_a_...` and `find_no_...`, `see_a_pedestrian_at()` and
  `see_no_pedestrian()`) rather than one carrying an infinite distance for none, the shape the
  lane's existing door events have.
- **The verbs.** The junction and gate events say `find`, the crowd's own verb for what it did;
  the pedestrian pair says `see`, as `see_a_door_ahead()` does, so the car is the subject. The
  other four may follow it (`hold_at_a_junction()`, `hold_at_a_gate()`) if the player prefers the
  car as subject throughout.
- **The lane's fields stay public** for the rigs, suites and dev tools that read them.
