---
name: telemetry
description: Rules for the run log — the one invariant it must never break, where a per-frame check belongs, and how to add an entry. Load this BEFORE touching src/telemetry/, Telemetry.note, TelemetryObserver, or adding any logging to a gameplay class.
---

# Telemetry

The run log is an **ordered log, not a metrics dump** — what happened, in what order, readable top
to bottom with no tool. It records what the code **cannot recompute**, above all the random outcomes
that branch a run: a one-shot that fired, a block arc that advanced. Those depend on run history, so
no seed reproduces them.

**Anything derivable from the seed, `Tuning` or the catalogue stays out.**

Read a run back with `./tools/telemetry.sh`. The table of entry kinds is `docs/TELEMETRY.md`.

## Telemetry never touches gameplay

**No RNG. No `day_rng()` stream. Nothing that changes a placement or a roll.**

Where a system logs a random outcome it **hoists the existing roll into a variable** to print it; it
never adds one. `EventScheduler`'s one-shot roll is the model:

```gdscript
# Hoisted out of the comparison purely so it can be written down.
var roll := rng.randf()
var threshold := 1.0 / float(remaining)
if roll > threshold:
    Telemetry.note("roll", "one-shot %s: %.2f > %.2f — not today" % [def.id, roll, threshold])
    continue
```

That hoist is a one-line edit with a way to be **catastrophically wrong**: consume one extra value
from a day's RNG and every event placed after it moves, and the determinism invariant takes every
other guarantee in the game down with it.

`tests/test_telemetry.gd` plans every day of the run (`Tuning.RUN_LENGTH_DAYS`) with the log off and
again with it on and requires the plans to be **identical event for event**.

## Per-frame checks go in the observer

Anything needing a per-frame check goes in `TelemetryObserver`, **not** in the gameplay class. The
telemetry stays out of the files that decide things, which is what makes the rule easy to keep.

**The one exception is the per-system frame record's timing wrap** (`FrameRecord`, docs/TELEMETRY.md,
"Per-system frame records"). *(2026-10-03, inbox #510: "let's focus on recording what cause
spillover in the regular 2ms ... it seems that stuttering happens with a lot of objects on screen
so influence calculation, pathing, drawing, etc. can all be the culprit".)* A phone has no
profiler, so the only way to know what a system cost in a frame is to time it where it runs, and
an observer cannot do that from outside. The wrap is a single branch in front of an unchanged
body, and it takes one of two shapes by how often it runs, because what it costs with the record
off is paid by every player.

A system timed **once a frame** (the crowd's and the event manager's physics steps, the sweep, the
halo, the edge) reads `FrameRecord.on` and moves its body into a private function of its own:

```gdscript
func _physics_process(delta: float) -> void:
	if FrameRecord.on:
		var outer := FrameRecord.enter(FrameRecord.CROWD)
		_tick_the_crowd(delta)
		FrameRecord.leave(outer)
	else:
		_tick_the_crowd(delta)
```

A thing timed **once per body per frame** (a crowd agent, a live event) copies the switch when it
is made and keeps its body where it is, so off it pays one member read: a static read and a second
call on each of a couple of hundred bodies cost about 0.15ms a frame on a desktop
(docs/evidence/m159-frame-record-2026-10-04/). It is made per day, after the recorder has started:

```gdscript
var _timed := FrameRecord.on
var _timing := false

func _process(delta: float) -> void:
	if _timed and not _timing and FrameRecord.on:
		var outer := FrameRecord.enter(FrameRecord.CROWD)
		_timing = true
		_process(delta)
		_timing = false
		FrameRecord.leave(outer)
		return
	# the body, unchanged
```

Nothing else about the frame record goes in a gameplay class — no reading of state, no counting
beyond the scenery queue's own jobs, no branch that changes what the body does — and a new timed
system takes one of these two shapes, with its bucket added to `FrameRecord` and the table in
docs/TELEMETRY.md.

## Adding an entry

1. `Telemetry.note("kind", "sentence")` where the thing happens.
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
