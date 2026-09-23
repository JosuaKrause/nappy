# M181 — the red arrow on a one-place task

Runtime evidence for one item of M181, "the resistance has a reason, and a task is one day": the
red arrow pointing at a one-place task's own contact, from the moment its mark is touched.

## What was recorded

```sh
tools/shot.sh out.png 16 --seed 4242 --day 7 --walk 2s10@75@14s --invincible
```

Day 7 of seed 4242 is the van's own task — one place, red arrow, `ResistanceSteps` index 4. The
walk leaves the doorstep south for two seconds (the home's only open side), then holds a bearing
of 75° for the rest of the run; day 7's own mark, unseen, relocates to an alley she comes near
along the way (`ResistanceDirector._track_sight_and_reposition()`), and she walks through it,
which activates the van perform the same day (`ResistanceDirector._on_contact_completed()`).

## What it shows

`red-arrow-day7.png` — the red chevron over her own head, reading "2 m", pointing at the van
(`nearest: delivery_van active age=16.0/1.3 99px`, in the debug readout at the right); the HUD's
status line reads "resistance ..... somewhere out there: a van, waiting" — the perform step's own
header, named the instant the mark activated it.
