# Playtest 57 — 2026-09-11

A desktop debug run on `main` at the invincible-mode merge, day 7, seed 2199579682, played with
`--invincible` as `docs/REVIEW.md` suggests. The run folder is
`docs/evidence/playtest-57-2026-09-11/run-215244-seed2199579682-v0.8.2-630-g7517fe3/`; the five
asked pictures are its `asked/` folder. Seven pictures were asked for at the held clock and three
survived, the defect playtest 56 filed the same evening.

## The stroller's own body, rejected

The first three pictures — `042s-attempt1-asked.png`, `090s-attempt1-asked.png` and
`144s-attempt1-asked-1.png` — are her standing north of a roadblock band across the mouth of an
alley between two lots, as close as she can get to it, with the pram's bounding box (the debug
view's layer `3`) a clear gap short of the band's:

> this is the closest I can get to the wall. the stroller hitbox doesn't even touch it.

`144s-attempt1-asked-2.png` is the same thing at the region wall across a road, three bands wide,
she on the carriageway above it:

> here again, the bounding box isn't even close to the other bounding box but I can't move further
> down than this.

And the verdict on the pram's body itself, built under M100 the day before as *the pram's own
collision* and listed in `REVIEW.md` for exactly this judgement:

> I don't like the stroller having a hitbox. it makes navigation clunky, I cannot get close to
> walls anymore, and I get constantly stuck.

So the pram's collision body goes: *asked for on 2026-09-10 · overturned on 2026-09-11*. The gap
in the pictures is bigger than the pram alone explains — the band's body stops her a pram's length
short of the band's drawn box — so the wall's own body is to be measured against its picture too.

## Roofs

On the same pictures:

> also allow going in a little bit for northern edges of roofs.

> roofs also should be drawn over objects. the barrier looks on top of the roof in those pictures.

The band across the alley is drawn wider than the alley and lies over the roof edges of the lots on
either side, reading as a barrier standing on a roof. A roof is above everything on the street, so
what stands on the street draws under it; and the northern edge of a roof — the top of the wall in
this projection — is ground she should be able to step a little way into, rather than a wall she
stops a tile short of.

## A chalk mark behind a barrier

`144s-attempt1-asked-1.png` also shows the resistance's chalk mark on the alley's paving behind the
band:

> a blocked off alley must not have a chalk mark.

## The keyboard against the last click

> arrow keys should reset any mouse click position. when pressing awsd or arrow keys right now the
> last pressed mouse position is still active resulting in incorrect / drifting movement.

## The checkpoint, as played

`144s-attempt1-asked-3.png` is a checkpoint on the road below a region wall: two huts on the
pavements, a boom across the carriageway drawn at the height of the road's upper kerb, cars in the
lanes below it.

> the gate for the cars is too high up. it needs to be further down

> the checkpoint should activate when I get close. with the new stroller hitbox I cannot reach the
> checkpoint entrance.

And the `REVIEW.md` item for M113, the inspection reads as one — *both she and the guard vanish for
two seconds, the camera eases onto the hut and back* — answered:

> the camera makes a huge jump from somewhere to the checkpoint. the checkpoint house disappears.
> the camera doesn't move at all after the 2s. also, if I don't move I get sent back afterwards.
> all this is incorrect.

The run log shows the hold once, at the clock's end: `checkpoint_hut at (111,89), 2.0s, released on
the east side`, followed by `near` entries for the same hut at 65px, which is her standing where she
was released and being detained again.

## Streets with trees

> can we make only some streets have trees? it should be continuous segments of 3/4/5 blocks
> randomly placed on the map in both directions. fallen trees should only be possible on streets
> with trees and one spot should be empty (the fallen tree's spot)

Today every street fronted by a residential or commercial block carries pits at a fixed spacing,
and a fallen tree merely prefers a street with trees.

## Invincible, as played

> when invincible the timer should never go down and excitement should never go up. this is just
> noisy flashing of alarms and the day gets dark.

The flag as built the same evening keeps the day running and lets everything else stay real, which
was the entry's own choice; played, the real meters mean the baby cries at once and stays crying,
the alert flashes for the rest of the run, and the clock runs the light down to dusk. *Asked for as
everything else real · overturned on 2026-09-11*: under the flag the clock does not move and
excitement does not rise.
