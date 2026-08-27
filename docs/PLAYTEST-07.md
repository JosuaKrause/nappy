# Playtest 07 — the street is the crowd, and everything else is scenery

The seventh human playtest, taken on `c80ba39` (M32), and the first one reported as a running
commentary rather than as a list at the end. Nineteen things, of which one is praise, one is a
question with "you can't" for an answer, and the other seventeen are defects.

It is also the first playtest that can be **read back off a trace** for most of its claims, and
two of the things it says are visible in the logs the player left behind. Those are quoted below
where they are, because a finding a trace can confirm is a different kind of finding from one
that needs a person.

---

## The one sentence

**Every cost in the game is paid on contact, and almost nothing else in it is real.**

Sixteen of the nineteen findings are that sentence from one side or another. The crowd is the only
system whose cost lands — it lands *hard*, on touch, and it sticks — while the events, which are
the authored content, are fields so steep that three quarters of every radius is free. Solid
objects are not solid. A stationary danger can be walked over. The spoiler that is supposed to
deny a park does not cover it. And standing still, which touches nothing, was the strongest
counterplay in the game.

The player said it in two lines:

> currently the only thing that really kills my runs are just pedestrians

> the actual dangers are not really dangerous since they don't have an effect at all

---

## The findings, as reported

| # | What the player said | Kind |
|---|---|---|
| 1 | "the cat sometimes runs alongside the street and then disappears instead of orthogonal" | geometry |
| 2 | "there was a person right on the home block but walking up to them didn't do anything — not sure what that person was supposed to be — it had a red triangle" | cue / art |
| 3 | "not walking at all shouldn't reduce excitement either — otherwise I can just stop in the middle of the street and wait until everything is good. Is that info captured in the telemetry as well?" | balance / telemetry |
| 4 | "the warning indicators render below ceilings" | drawing |
| 5 | "bumping into a person should resolve more — right now you can get trapped and stick to the other person which basically leads to instant death" | physics |
| 6 | "cars turning is just a jump from one lane to the other — it should have a diagonal graphic and transition between each direction" | art / motion |
| 7 | "there is also a car obstacle on the road that is basically a still car standing on the road doing nothing" | content |
| 8 | "there is a big plaza which is four tiles which has a concrete floor but trees? is that supposed to be a courtyard? if so it needs to be surrounded by building on the block" | city |
| 9 | "birds just disappear if I get close and do nothing" | content |
| 10 | "the robber on the courtyard doesn't prevent me at all from using it again" + "blocking a park etc should have multiple robbers so the entire area is dangerous or a full block party or other things that completely block out the space" | design |
| 11 | "restaurants don't have people so it's not immediately clear why they would be a problem for the baby" | art |
| 12 | "how can I pause the game?" | missing |
| 13 | "I can walk over the robber and he doesn't do anything" | correctness |
| 14 | "the zzz when walking up are not above the stroller" | cue |
| 15 | "the backing out lorry does not connect to the building making it hard to visually read" | art |
| 16 | "none of the non-moving obstacles do anything" / "I can freely walk over them" | correctness |
| 17 | "currently the only thing that really kills my runs are just pedestrians" / "the actual dangers are not really dangerous since they don't have an effect at all" | balance |
| 18 | "the radius of excitement for obstacles needs to be bigger" / "with most obstacles — dogs, robbers, etc — the excitement should go substantially up from relatively far away. I shouldn't have to get actual contact to get penalized" | balance |
| 19 | "walking in a restaurant correctly gets excitement up" | **works** |

---

## What the traces already said

Two runs were left behind in `user://telemetry/`. They are worth reading because they confirm
three of the findings without a person having to be asked twice.

**Finding 17, in full.** `run-…seed3684693132` loses day 2 three times in a row and burns the whole
run out on it:

```
 14.6  lost  lost_crying after 14.6s | exc 100, in 25.8/s (crowd 25.8, events 0.0)
 23.1  lost  lost_crying after 23.1s | exc 100, in 23.0/s (crowd 18.8, events 4.2)
 27.8  lost  lost_crying after 27.8s | exc 100, in 17.8/s (crowd 17.8, events 0.0)
 27.8  ending  bad on day 2 — resistance 0/4, sabotage not done
```

Three attempts, three deaths inside half a minute, and the crowd supplies between 82% and 100% of
the excitement in each. `events 0.0` is the finding: the authored content is not in the fight.

**Finding 18, with a number on it.** From the same run and the other one, every `near` entry
written at an event's own outer radius reads `events 0.0`:

```
  8.8  near  cafe_tables at (29,93), 170px, in 18.7/s (crowd 18.4, events 0.0)
 21.8  near  dog_walker  at (46,76), 104px, in  4.4/s (crowd  4.4, events 0.0)
```

That is not a bug in the events, it is the **falloff shape**. `Tuning.falloff` was quadratic —
`(1−t)²` between the inner and outer radius — so at the halfway point a source emits a quarter of
its intensity and at three quarters of the way out it emits six percent. A café at 12/s is under
the 3.5/s walking decay for the entire outer 60% of its own field. The player has to touch it
before the game charges for it, which is exactly what they said.

**Finding 3, as a hole in the log.** `run-…seed1190600081`, day 2:

```
  30.6  crowd  walked into somebody at (50,29)
  83.1  cross  stepped into the road at (45,28), at a zebra
```

and later

```
 100.0  near   homeless_yeller at (40,62), 209px
 174.2  cross  stepped into the road at (39,45), mid-block
```

Fifty-two seconds and then seventy-four seconds with **no entry at all**, out of a hundred and
eighty second day. Standing still emits nothing — no crossing, no turn, no contact, nothing
coming near — so the strongest move in the game appeared in the trace as a *gap*, and a gap is
what a reader skips. The player asked whether it was captured. It was not.

**Finding 10, confirmed.** Day 1 settles in calm block (1,3). Day 2 correctly rolls a spoiler for
it — `roll  homeless_yeller in the park she used yesterday, (1,3)` — and day 2 settles in (1,3)
anyway, at 36.1s. One event with a 210px reach in a lot 704px across denies about a tenth of it.

---

## The analysis

### A. The cost model is inverted (17, 18, 5, 3, 19)

Four systems can move the excitement meter and they are wildly out of proportion:

| source | what it costs | where it costs it |
|---|---|---|
| walking into a pedestrian | ~26/s jolt + 4.2/s body | on contact, 14px |
| a car's horn | ~8/s | in the carriageway |
| an event | 6% of intensity at ¾ radius | on contact |
| standing still | **−6/s** | anywhere |

The middle two columns are the finding. An event is authored, placed, telegraphed, spaced and
validated — and then charged for at a radius the player has to walk into. A pedestrian is
generated traffic and costs six times more. So the route, which is the only verb in the game, is
not what the meter is about; bumping is.

Three changes, and they are one change:

1. **The falloff gets a shoulder.** `(1−t)²` → `1−t²`. Full intensity at the inner edge, three
   quarters of it at the midpoint, zero only at the outer edge. Every field in the catalogue now
   bites from a distance without a single radius moving, which is finding 18 answered at the one
   place that fixes it for every row at once. The fairness contract is untouched: it is stated
   over *distance*, and the distances did not move.
2. **Contact stops compounding.** `touching` had no hysteresis, so a contact resolved to exactly
   `BUMP_RADIUS` flickers in and out of range and re-fires a fresh 26/s jolt every couple of
   frames. That is the "instant death" — and a walker whose lane centre is where she is standing
   walks straight back into her, so it never ends. It releases at a wider radius now, the
   separation resolves past the contact radius rather than to it, and **the person she walked into
   steps aside** for a moment instead of steering back into her.
3. **Standing still settles nothing.** `EXCITEMENT_DECAY_IDLE` was 6.0, the *fastest* of the three
   rates. What settles a baby is being pushed, so the ordering is motion-shaped now: walking 3.5,
   running 0.5, standing 0.0. And there is an `idle` telemetry span, so the next trace can see it.

### B. Solid things are not solid (16, 13, 7, 15)

`obstructs_radius` was set on five rows of thirty. A delivery van, an ice cream van, a reversing
lorry, a burnt-out shell and an abduction van are all large, visibly solid, stationary objects
with no collision body at all. A probe rig confirms `cafe_tables` blocks correctly, so this was
never a physics bug — it is a table with holes in it.

Finding 13 is the same hole with teeth: `alley_robbery` has an `inner_radius` of 22px, which is
smaller than the player's own collision circle, so "walk over the robber" is a thing that can
happen without ever entering the lethal radius.

### C. A cue that marks everything says nothing — again (2, 4, 14)

`wants_a_mark()` returns true for any event with a `pulse_period`, and six of the ten rows
available on day 1 have one. So the caret is over most of an ordinary street, on things that are
not going anywhere and will not do anything, which is the ring's own mistake in the shape M22
invented to replace it. The player walked up to one to find out what it meant and the answer was
"nothing".

### D. The rest

- **1** — the cat crosses perpendicular to *her heading*, which is right on a pavement and is a
  run down the middle of the carriageway when she is crossing a road. And it ends its run in the
  open, so it vanishes in plain sight.
- **6** — a turn swaps the axes in one frame. The along-motion is instantly full speed on the new
  axis and the sprite snaps from side-on to end-on. There is no diagonal art in the project.
- **8** — a four-block calm zone rolls its purpose uniformly from park, forest and **quiet
  square**, so one city in three has a 22-tile-square concrete plaza with thirty trees scattered
  over it. A quiet square is a *small* thing; it should not be able to be the big one.
- **9** — pigeons are an `AHEAD_OF_PLAYER` event with a 2.4s duration sited 2s of walking ahead,
  so they expire as she arrives, and `_draw_birds` holds them in the air and then deletes them.
- **10** — see above. The spoiler has to cover the lot, not stand in it.
- **11** — `cafe_tables` draws tables and no people, so the thing that makes it loud is invisible.
- **12** — there is no pause. `Esc` quits outright.

---

## What was done

See **M33** in [TODO.md](TODO.md).
