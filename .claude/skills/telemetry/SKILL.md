---
name: telemetry
description: Rules for the run log — the one invariant it must never break, where a per-frame check belongs, and how to add an entry. Load this BEFORE touching src/telemetry/, Telemetry.note, TelemetryObserver, or adding any logging to a gameplay class.
---

# Telemetry

**The rules not to miss:**

- **Telemetry never touches gameplay**: no RNG, no `day_rng()` stream, nothing that changes a
  placement or a roll. A logged roll is the existing roll hoisted into a variable, never a new one.
- **Anything derivable from the seed, `Tuning` or the catalogue stays out of the log.**
- **A per-frame check goes in `TelemetryObserver`**, never in the gameplay class. The frame
  record's timing wrap is the one exception.
- **A timed system wraps its unchanged body in `if timing.on:`** on the `FrameTiming` it is handed,
  and a `_draw()` override carries no counting code.
- **Game logic writes through the `RunTrace` it is handed**, never `Telemetry` itself.
- **A new entry answers a question open in the queue or a playtest doc**, and reuses a kind from
  the table in `docs/TELEMETRY.md`.

The run log is an **ordered log, not a metrics dump** — what happened, in what order, readable top
to bottom with no tool. It records what the code **cannot recompute**, above all the random outcomes
that branch a run: a one-shot that fired, a block arc that advanced. Those depend on run history, so
no seed reproduces them.

Read a run back with `./tools/telemetry.sh`. The table of entry kinds is `docs/TELEMETRY.md`.

## Telemetry never touches gameplay

**No RNG. No `day_rng()` stream. Nothing that changes a placement or a roll.**

Where a system logs a random outcome it **hoists the existing roll into a variable** to print it; it
never adds one. The shape, for a roll compared against a threshold:

```gdscript
# Hoisted out of the comparison purely so it can be written down.
var roll := rng.randf()
if roll > threshold:
    _note(trace, "roll", "%s: %.2f > %.2f — not today" % [what, roll, threshold])
    continue
```

That hoist is a one-line edit with a way to be **catastrophically wrong**: consume one extra value
from a day's RNG and every event placed after it moves, and the determinism invariant takes every
other guarantee in the game down with it.

`tests/test_telemetry.gd` plans every day of the run (`Tuning.RUN_LENGTH_DAYS`) handed no trace and
again handed one that keeps every line, and requires the plans to be **identical event for event**.

## Per-frame checks go in the observer

Anything needing a per-frame check goes in `TelemetryObserver`, **not** in the gameplay class. The
telemetry stays out of the files that decide things, which is what makes the rule easy to keep.

**The one exception is the frame record's timing wrap** (docs/TELEMETRY.md, "Per-system frame
records"). It records what makes a frame spill over its 2ms budget (quiet-yak #510), and the
player accepted the exception itself (azure-tapir #526): a phone has no profiler, so what a system
cost in a frame can only be timed where it runs, which an observer cannot do from outside.

**A timed system is handed its timing sink and wraps its body.** The sink is a `FrameTiming`
(`src/frame_timing.gd`, the null sink whose `on` is false; `FrameRecord` in `src/telemetry/` is the
subclass that feeds the record), kept in a member that whoever builds the system sets. The body
moves into a private function behind one branch, as in `EventManager`:

```gdscript
func _physics_process(delta: float) -> void:
	if timing.on:
		var outer := timing.enter(FrameTiming.EVENTS)
		_tick_the_events(delta)
		timing.leave(outer)
	else:
		_tick_the_events(delta)
```

`on`, `enter()` and `leave()` are the handed sink's, never statics of a class. `enter()` answers
the bucket that was being charged, so a timed system inside another is charged to itself alone.
Off, the wrap is two reads and no call, which every player pays: a live event wraps its
`_process()` the same way, a couple of hundred of them a frame. An event's step and a crowd
agent's step are not timed on their own, since each runs inside a tick that is. `src/crowd/` names
none of the record: it is handed a `CrowdTiming`, which `FrameRecordTiming` in `src/telemetry/`
forwards to it.

- **A new bucket** is a constant and its `BUCKET_NAMES` entry in `src/frame_timing.gd`, its short
  name in `FrameLedger.SHORT_NAMES`, and a row in the bucket table of docs/TELEMETRY.md.
- **A `_draw()` override carries no counting code.** The per-kind `_draw()` counts the player
  asked for (jolly-trout #541) are taken by `FrameRecorder` from each counted node's `draw`
  signal. A new node that draws is added by class to `FrameRecorder._draw_kind()`, or, where the
  recorder may not name it (a node of the view, a canvas that is no class of its own), sets the
  meta `FrameTiming.DRAW_KIND_META` to its `FrameTiming.Draw` kind. A crowd agent alone counts
  itself, through `drew()` on its `CrowdTiming`.
- **A new drawn kind** is a member of `FrameTiming.Draw`, its name in `FrameLedger.COUNTER_NAMES`
  in the same order, and its column in docs/TELEMETRY.md.
- **The scenery queue's wrap is its own and is not a pattern to copy.**
  `SceneryResidency.update()` also counts its jobs by kind and times what they leave to the
  engine's deferred flush, which is what the player's question was about: the scenery queue's
  time, how far past its 2ms, and which jobs.

Nothing else about the frame record goes in a gameplay class: no reading of state, no counting, no
deferred markers, no branch that changes what the body does.

## Game logic never names the run log

A system that decides things writes its own account through the `RunTrace` it was handed
(`src/run_trace.gd`), never `Telemetry` itself: `RunSession` makes the one that writes into the
log, `main` hands it on, and a component handed none writes nowhere. A day's or a section's start
and end reach the log as `EventBus` events `RunSession` listens to (docs/TELEMETRY.md, "Who writes
it"); nothing in the run flow calls the log or the observer inline.

## Adding an entry

1. `trace.note("kind", "sentence")` where the thing happens, on the component's own trace.
2. A row in the table in `docs/TELEMETRY.md`.
3. **A kind reused from that table**, not a synonym for one.

**It has to answer a question that is open in the queue or a playtest doc.** If it does not, it
is a metric and does not belong.

## What the log is for

Reading a played minute back is how a run's behaviour is checked — see the **verify** skill, "What
each one cannot see". The `cue` entry exists because nothing in `tests/test_danger.gd` can see a
*moment*.

## Whose run is it

A log is prefixed `run-` when a person is at the controls and `rig-` for a headless boot or anything
driven by `--screenshot`, `--walk`, `--flee` or `--press`. A size-based proxy cannot tell the
difference: a `shot.sh --walk 60` is a long, busy, entirely unplayed log.
