# Playtest 54 — 2026-09-10

## The stair references, ingested properly

Said after PR 78, the prepared SVG graphics, had merged with the two supplied stair illustrations
committed as raw JPEGs under an evidence folder:

> re graphics: can we properly ingest the reference images with proper names instead of who made it.

Done the same day: both went through `tools/reference.sh` and live in `docs/reference/` as
`stairwell-switchback-interior-01.jpg` and `fire-escape-switchback-exterior-01.jpg`; the evidence
folder and its generator-named originals are gone.

## The inner stairs have to be walkable tiles

> also I like the fire escape stairs but the inner stairs don't work. I think the misunderstanding
> here is that the inner stairs need to work as tiles and need to be walkable so they need to be
> actually 2.5D and be separated in handrail and stair tiles and landings.

The prepared `assets/interior/stair_down.svg` is one 64×64 picture of a whole switchback; it is
superseded by a tile kit — flight tiles, landing tiles and handrail overlays — that the interior
map lays down and she walks on. Filed as M112, the escape scene, walkable.

## Build the escape scene as a test entry, now

> as a good exercise we could build out the escape scene (three floors over ground floor -- top
> floor is her apartment -- entrance -- basement -- double staircase left and right) without any
> events just as a special game entry ./tools/run.sh --start-escape or similar to test out the
> walking and screen transitions and stair walking. graphics are her holding the baby

> can you do that right now

> also create the svg needed for this

Filed as M112 and started the same day.

## M111 as written

On the review of PR 78, which had suggested a smaller reading of M111, cars follow their turns —
an arc through the junction with the sprite on the tangent, leaving the swept-footprint model as a
fork:

> I like the overcommit

> also note that the car turn overcommittment that you flagged is good and we should do that

So M111 stands as written: the swept vehicle footprint validated against the road space and turn
space reserved before a car commits, not only the picture. It pulls three of M102's items forward — the interior
map, the stair binding and the carrying rig — and builds them without events, behind a debug
flag, so walking, floor transitions and stair walking can be judged before the finale's pressure
is put on top of them.
