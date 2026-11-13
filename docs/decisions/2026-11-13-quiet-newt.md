# quiet-newt — A timed system asks timing.is_on(): the call measured against the field read · 2026-11-13 · not from an entry



**The ask.** The telemetry skill told a per-frame timed system to read the field `on` of its `FrameTiming`, "two reads
and no call, which every player pays", while designing-classes says one object never reads another's field. The
orchestrator proposed measuring the call's cost and, if negligible, switching the readers and the skill; the player:
"yes start it" (said in the orchestrating session of 2026-11-13, not captured to the inbox).

## The measurement

Headless desktop Godot on `main` at `2672e3eba`, a real `FrameTiming` with the record off, 20M iterations, 7
repetitions:

| Loop | ns per check | spread |
|---|---|---|
| empty loop (floor) | 19.3 | 17.9 to 20.8 |
| `if timing.on:` | 40.6 | 39.2 to 42.1 |
| `if timing.is_on():` | 105.0 | 101.1 to 114.8 |

The call costs about 65 ns more per check. The two field readers ran once per live event per frame
(`EventInstance._process()`) and once per physics tick (`EventManager._physics_process()`): about 2 us a frame at a
realistic 30 live events (an estimate from the streaming radius, not a measurement) and 13 us at 200, under 0.1% of a
16.7 ms frame on desktop, and about 0.5% at worst on a phone at the desktop-to-phone ratio the record M124 measured for
the physics tick (about 6x). The phone itself was not measured, and the game was not: in the frame record's own
evidence (`docs/evidence/m159-frame-record-2026-10-04/`) a timed call cost about 4x what a microbenchmark predicted.
At that ratio the bound is about 50 us a desktop frame at 200 live events, about 0.3 ms (2% of a 16.7 ms frame) on a
phone at 6x, and about 0.3% of a phone frame at 30 events; `measure.py cost` in that folder is how an in-game number
would be taken. The switch was made on that bound.

**What it overturns.** The record M159-5 had a live event copy the switch when made and pay one member read; a timed
system now asks the method instead, since designing-classes' "Fields are not API" holds wherever the cost allows.

## What was built

- `EventInstance` and `EventManager` ask `timing.is_on()`; `FrameTiming.on` became `_on` behind `is_on()`, set and read
  by its subclass `FrameRecord` alone; `tools/field_reads.txt` lost its `[FrameTiming]` group.
- The telemetry skill and `docs/TELEMETRY.md` say `is_on()`.

## Choices open to overturn

- **`on` made private**, the builder's pick, since no reader outside its class hierarchy was left. Over: keeping the
  public field beside the method.
