# Playtest 77 — 2026-09-15

A desktop run on `v0.10.7-107-gc7dfc4ed`, the `main` that carries M152's landing fix, seed
3126506586, day 1, three minutes after the queue's other pull requests of the day were
merged. One finding, with a burst the player asked for.

## Cars are still jumping around

> "2026-09-15/run-202436-seed3126506586-v0.10.7-107-gc7dfc4ed/asked/burst-25017518-001 that
> shows that cars are still jumping around"

Said on 2026-09-15 after the M152 jump probe on this build had come back identical to the
filed after-the-fix run (no landing retreats in view). The run folder is copied whole to
`docs/evidence/m152-about-face-2026-09-15/run-202436-seed3126506586-v0.10.7-107-gc7dfc4ed/`;
the burst is 36 frames over 3.0 s at 12 fps, `burst.json` carries the capture times.

What the frames show. She stands at tile (97,103) on a pavement; the north-south street one
junction east of her is sealed about five tiles south of the junction by a burst water main.
A car stopped on the zebra just south of that junction, at about tile (99,102), keeps its
position along the street for the whole burst and slides sideways between the two lane
centres, about 62 px peak to peak with a period near 0.7 s — its tail lights measured at 753,
768, 783, 795, 779, 765, 750, 734 px and back, frame by frame. At frame 15 its picture flips
from facing south to facing north in one frame and then holds north while the sliding goes
on. Southbound cars queue behind it in the west lane and overlap each other (frames 25 to
27). So the second shape playtest 76 reported — a car that reverses on the spot instead of
routing a U-turn — is this: the reversal repeats once a stride on a stopped car at a seal, and
each one carries the car toward the other lane until the next. Answered on the same day's branch:
`DECISIONS.md`, M152, the about-face is planned and the morning is unpacked early.

## The day summary says when the day ended

> "can you show the time of the day when dieing/completing a day (not the total like on the
> game over / win screen). ...fell asleep after xx:xx or something like that"

Said on 2026-09-15. The day summary — `DaySummary.show_day()`, the screen after every day —
carries the day number, the reason a lost day ended, the nerves and the resistance tally, and
no clock. The ending screen carries the run's whole length to the millisecond, and that is not
what is asked for: the ask is the day's own clock at the moment the day ended, on the summary
of that day, in the shape *fell asleep after 1:24*. Filed as M154 in `TODO.md`.

## The hint curbstones are on the obstacle's side of the street

> "I think the hint curbstones are still wrong [a still] why would it be on this side of the
> street where the obstacle is and not the other side?" — "where no obstacle is"

Said on 2026-09-15 of a desktop debug still, build v0.10.7-110-g6f467bc1 (the M152 branch
under test), seed 3095532833, day 2, her on the carriageway at tile 64,73 of an east-west
street with the readout on: a market stall stands on the upper pavement by the traffic light,
and the yellow cast is on that pavement's kerb, not on the lower pavement's, which is clear.
The still arrived in the conversation rather than as a file; the seed and tile reproduce the
city. The cause is read from the code. The tint follows the pavement the route tree walks
(`DECISIONS.md`, M150), and the tree picks that pavement at dawn before any event is placed;
the scheduler then weights friction rows onto the corridor on purpose
(`Tuning.EVENT_CORRIDOR_WEIGHT`, 4, *"benign blockers go on the route"*), and the width rule
only asks that *some* pavement of a route street stays walkable end to end — here the lower
one. So the free line and the tinted line are on opposite pavements, and a walk that follows
the tint meets the stall.

> "how is market stall a friction? you can't walk through it. the market stall should appear on
> the other side of the street where for some reason no event was chosen -- on the side of the
> street where the path was chosen only obstacles that can be bypassed should be possible."

Said a minute later, answering the two ways out that were offered (refuse the row on the
route's pavement, or move the tint to the free pavement). The decision is the first, and it
comes with a reading of *friction* the code does not have: `EventScheduler._role_for` calls a
row a wall only when it is lethal or its walk-through cost reaches `Tuning.WALL_WORTH_OF_COST`
(35 on the meter), and a market stall's cost is under that, so it is friction by cost — while
its 28 px body and 58 px denial on a 64 px pavement leave no line a 28 px stroller fits
through. Whether a row can be bypassed is a question about the pavement it stands on, not
about its cost.

> "a wall is also when you physically cannot walk through"

Said next, and read two ways when asked: change what the code calls a wall, or leave the
roles alone and add one placement rule. The placement rule was recommended and taken first,
then overturned within the minute: *(2026-09-15: "actually let's do the other option" — "that
seems to be more thorough")*. So the role itself changes: a row is a wall when it is lethal,
when it costs a wall's worth, **or when its body and its charging disc leave no line a
stroller fits through on the pavement it stands on** — and a wall stands across the street
from the route's pavement or off the route, never on the pavement the tree walks. The café
tables and the market stall, act I's two rows built to force a crossing, become walls by this
reading, which the entry names as the balance consequence to measure. Filed under M129 in
`TODO.md`.
