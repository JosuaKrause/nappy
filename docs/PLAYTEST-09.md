# Playtest 09 — the key that did nothing, and the man who did nothing

The ninth human playtest, taken on `7a84366` (M35), and reported as four sentences in the middle of
a session rather than as a list. Two of them are bugs and two are design instructions.

---

## The one sentence

**Two things in this build had been doing nothing at all for milestones, and both of them looked
finished from the outside.**

`Esc` shipped in M33 with a screen, a key, a doc entry and a line in the debug overlay, and it never
opened once. The man shouting on the pavement shipped in M5, was given a body in M34 to close a
complaint about walking through him, and was still a fixed price on a fixed patch of ground.

Neither could have been caught by the suite or by a screenshot, and the reasons are different and
both worth keeping. Nothing in the test rig has ever *pressed a key*. And nothing in a screenshot
can show you that something did not move.

---

## The findings, as reported

| # | What the player said | Kind |
|---|---|---|
| 1 | "esc doesn't work" | bug |
| 2 | "who is the person killing me in the third try of day 1? it didn't move and it took a long time to have any effect. this is still bad." | content |
| 3 | "if it's a robber it should be more or less lethal (since being robbed is day ending). if it's the homeless person it needs to walk up and down the sidewalk" | design |
| 4 | "a robber should increase excitement on sight and getting close to them should be day ending" / "and if you get close they should start moving towards you" | design |

---

## What the trace already said

The run is `run-…seed1604768153`, and day 1 was lost four times. The third attempt is the one the
question is about, and the answer is in every line of it:

```
   0.1  near   homeless_yeller (telegraph) at (22,61), 167px
   5.2  near   homeless_yeller at (22,61), 210px
   6.5  near   homeless_yeller at (22,61), 114px
   7.1  near   homeless_yeller at (22,61),  62px
   7.4  near   homeless_yeller at (22,61),  33px
  21.6  lost   lost_crying after 21.6s | near: homeless_yeller 31px
```

**The same coordinates on every line.** `near` prints the position precisely so that three dog
walkers can be told apart; here it is printing the same man six times over twenty-one seconds,
which is the finding written down before it was reported. The attempt in between it is the same:
she doubles back four times inside the man's field, bumping into the crowd each way, and the meter
climbs to 100 without anything ever *happening*.

So: it is `homeless_yeller`, and the player's own prescription applies — *"if it's the homeless
person it needs to walk up and down the sidewalk"*.

---

## The analysis

### A. Esc (1)

`main._unhandled_input` refused to open the pause while the between-days summary was up, and asked
the question this way:

```gdscript
if _pause.is_open() or (_summary and _summary.visible):
    return
```

`_summary` is a `CanvasLayer`. **`CanvasLayer.visible` is `true` from the moment the node is added
to the tree** — what the summary shows and hides is the `Control` inside it, which is what
`is_showing()` answers. So the guard was satisfied on every frame of every day, and the key that
`README.md`, the pause screen, the debug overlay and `docs/TODO.md` all said existed had never once
been pressed successfully.

Two things follow, and the second is the one worth having:

- The guard asks `is_showing()` now, and the pause opens **over** the summary rather than refusing
  there. The original refusal had a real argument behind it — two things fighting over
  `get_tree().paused` is how a pause stops meaning anything — and the answer is to not fight:
  `PauseScreen` puts back the paused state it found. Somebody who has just lost a day and wants out
  of the game should not have to find the one screen where the key works.
- **`--press <action> <seconds>`**, so the rig can press a key. The first version of it used
  `Input.action_press()`, which sets the polled state and nothing else — fine for `--walk`, which
  the stroller reads every frame, and useless for anything answered in `_unhandled_input`. It
  produced a screenshot of the game carrying on, which looks exactly like the bug it was written to
  check. It pushes a real event through `Input.parse_input_event` now.

### B. The man who did not move (2, 3)

`EventDef.paces`: walks its route and turns round at the ends, for ever. The difference between a
**journey** and a **beat**, and it is the difference between two kinds of event — a dog walker is
going somewhere and is gone at the end of thirty tiles; a man shouting is *at* a place, and until
now the only way to say that was to make him stationary.

It is a design change rather than a polish one. A fixed source on a fixed patch of pavement is a
line you draw once and never think about again. A man walking up and down two hundred and fifty
pixels of footway is a *timing* problem on top of a routing one, which is the same thing his yell
pulse already asks for at a smaller scale.

The cost is his body: **anything mobile is exempt from "solid things are solid"**, because a moving
wall on a two-tile pavement pins her against a building. That is M19's `dog_walker` decision and it
has not changed, so M34's `PERSON_BODY` comes straight back off. What stops you walking through him
is the meter — and *"it took a long time to have any effect"* is 10 intensity, which is 14 now.

### C. The robber (4)

The player's three sentences are three numbers, and the row had none of them. It was a 42px field
with a 30px kill inside it: a thing that does nothing at all until it does everything, avoidable for
ever by walking two tiles wide of it. That is playtest 07's whole complaint about the catalogue,
arriving at the one row where the consequence is the day.

`EventDef.pursues_within` is the mechanic, and it is the second shape a pursuit can have. M33's dog
is a **moment** — sited in front of her by the director, and the chase is all of it. A robbery is a
**place** that becomes a moment. Three states rather than two, and both of the new ones needed
saying out loud:

- **The clock starts when it notices her**, not when the day put it there. A robbery whose telegraph
  ran at dawn, four streets away, would arrive with no notice in it at all.
- **Its notice does not damp what it is emitting.** `TELEGRAPH_INTENSITY_FRACTION` means *this has
  not started yet*, and a man who has been standing in that alley since she came round the corner
  has started. What has not started is the lunge.

---

## What was done

All four, as **M36**.

- **1** — `is_showing()`, the pause opening over the summary with the paused state put back, and
  `--press` so that a rig can press a key. `tests/test_pause.gd` holds the two halves a unit test
  can hold, including the trap itself: *a fresh summary is not showing, and its own `visible` is
  true anyway*.
- **2, 3** — `EventDef.paces`, and `homeless_yeller` walks eight tiles of pavement at 30px/s, turning
  round at each end, at intensity 14 with no body. Cost table: +17.7 → **+31.2**.
- **4** — `EventDef.pursues_within`, and `alley_robbery` is 16 over 200px, lethal inside 30px, and
  comes at her at 130px/s from 140px. Measured: standing, walking past and walking *away* all end
  the day; running shakes him off in about a second and a half, for 21 points.
- **And a bug the change exposed.** `_ensure_one_usable_park` could erase a **scar**. It found the
  calm block with the fewest spoilers on it and stripped them, and a burnt-out shell that had been on
  that corner since day 3 was one of them — so it vanished for a day and came back the next.
  `tests/test_acts.gd` caught it by luck (day 9 of one seed) rather than by design. Scars are exempt
  now, for the same reason ambient events are: a permanent feature of the map is not today's noise.

### Measured

| | before | after |
|---|---:|---:|
| `homeless_yeller`, walked through | +17.7 | +31.2 |
| `homeless_yeller`, paces | — | 256px, ~4 turns a minute |
| `alley_robbery`, field | 42px | 200px |
| robberies placed, day 8 | 3.4 | 3.4 |
| events placed, day 1 / 8 / 14 | 40.0 / 58.8 / 78.6 | 39.8 / 58.8 / 78.6 |

The density is untouched, which is the number that had to not move: a wider lethal field means the
"nothing else happens inside it" rule has more to satisfy, and it turned out to have room.

### Not done

Playtest 07's list, unchanged: three act I events sharing one `person.svg` — which is now *two* of
the three complaints in this playtest pointing at the same missing artwork — a café with no people
at it, the cat crossing the wrong axis, a four-block concrete plaza, a car turning with no diagonal,
the warning indicators rendering below roofs, and the zzz stepped aside from the pram.
