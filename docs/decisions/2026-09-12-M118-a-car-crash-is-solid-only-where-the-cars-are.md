## M118 — A car crash is solid only where the cars are · built 2026-09-12

*(2026-09-12, [PLAYTEST-63](../playtests/PLAYTEST-63.md): "a car crash right now has a full bounding
box even though there are gaps in the sprite. the bounding box should only be the crashed cars but
it should emanate an excitement field that prevents the player from walking past it", with "this
round's feedbacks should all be prioritized since I'm actively testing the changes as they come
in".)*

**Overturned: *a closure is silent* · overturned for the `car_accident` seal on 2026-09-12, because
a body that matches the picture leaves gaps, and the player asked for those gaps to be closed by a
field rather than by a wall nobody can see.** Narrowly: a `RoadClosure` still contributes nothing to
the meter, `CRASH` included, and the seven other seal pictures keep `intensity = 0.0` — the
exception is one catalogue row, and a seal was always an `EventDef`, so nothing was added to
`City.total_excitement_at`'s two summands. The fallen tree (one trunk kerb to kerb) and the burst
main (a crater between two barriers) were not named by the player and leave no gaps to close;
whether they follow is the player's question.

**The parts machinery.** `EventDef.solid_parts` is a list of `SolidPart` — an offset along the
scene's own spread axis and a `GroundShape` — and `EventInstance` builds one `CollisionShape2D`, one
shadow patch and one entry of a per-tile record per piece, from `EventDef.parts()`, which answers
one piece at the origin carrying `shape` for every row that declares none. So exactly one row in the
catalogue is several bodies and `tests/test_events.gd` asserts that count.

**Two offsets per part, because a wide scene has two authored pictures.** `_wide_scene_texture`
picks a composition per street axis rather than rotating one, so where the cars sit across the
street is a fact about the picture in use. On `car_accident.svg` (200×50, a north-south street) the
cars are drawn end-on at x 63–91 and 92–120 and `car_accident_shadow.svg` puts their ground contacts
at 77 and 106 — the two agree, because an end-on car stands directly above its own patch of road. On
`car_accident_vertical.svg` (50×200, an east-west street) the cars are side views drawn *above* the
road they stand on, so only `car_accident_vertical_shadow.svg` says where that is: contacts at y 88
and 110. At the 192/200 scale `_draw_wide_scene` fits each picture to the street, those are **−22.1
and +5.8** (north-south) and **−11.5 and +9.6** (east-west) from the scene's centre. **14px of radius
apiece**: a car is drawn 28px wide, 26.9px of ground at that scale, and the round number is what
makes the two bodies meet rather than leaving a one-pixel slot that reads as a way through and is
not one. Everything else in the scene — the debris, the two onlookers — carries no body, because
being the gaps is what they are for.

**Two readings of a body came apart, for one row.** `obstructs_radius` stays 96 — the whole street,
the disc every planner clears, spaces and refuses ground with, and what the picture is fitted to —
while `EventDef.solid_reach()` (36.1) is how far the row is actually solid. Only one caller takes the
second: `validate()`'s check that a lethal radius is reachable past its own body, which is about
where her centre comes to rest and would otherwise refuse an arrangement that in fact lets the kill
fire. `detain_distance()` stays on `obstructs_radius`; no row that detains is solid in parts, and the
two numbers are equal for every row but this one. `validate()` refuses a part reaching past the row's
own `shape`, which is what keeps the planners' disc an upper bound — and is the direction argument
for item C: removing obstruction inside a disc the day already cleared can only add reachable ground,
so `ClosurePlanner`'s route guarantee and `CityMap.held_segments` needed no change at all.

**What the gap costs, measured.** `tests/probes/m118_crash_gap.gd` walks every line through the
picture's open ground at `WALK_SPEED`, over six seeds and both street axes, and reports the
**cheapest** — a guarantee about a price is a guarantee about the price she can get. Her centre has
open lanes at −82..−52 and +34..+82 on a north-south street and −82..−40 and +38..+82 on an east-west
one (px from the scene centre, the street spanning ±96); the cars are drawn locked together, so there
is no passable slot between them and the two gaps are the pavements. At `CAR_ACCIDENT_INTENSITY`
40.0 the cheapest pass cost **48.5** and the dearest 49.2 — under the `METER_MAX / 2` line
`tests/test_crowd.gd` draws between expensive and fatal, so the number went to **45.0**, where the
cheapest is **56.3** and the dearest 57.0. The field is `inner_radius` `GroundShape.BAND_RADIUS`
(24, the band's own surface, since a segment's field is priced from its spine) with a 72px shoulder
to `outer_radius` 96; that keeps the required telegraph at 0.78s, under the row's existing 0.9, so
the fairness contract did not have to move to pay for this. `tests/test_seals.gd` now walks that
same measurement as an assertion rather than asserting the constant back to itself.

**The fork the entry left open, built the recommended way.** *Prevents* means **costs more than she
can carry**, not lethal: the pram's nearly-crying cue is the turn-back signal and a fresh meter can
still force the pass at the price of the day. The other reading is one line away and off —
`Tuning.CAR_ACCIDENT_GAPS_ARE_LETHAL`, which takes the row to `hard_fail` with
`CAR_ACCIDENT_LETHAL_INNER_RADIUS` 56 (clear of the cars' 36.1 plus her 14, so the kill can actually
fire) and the doubled hard-fail telegraph. The expensive reading was built because a wall that kills
has no price to weigh, and the verb of this game is *where do I walk*.

**The running rule flips for this row, and it is arithmetic rather than taste.** Running is a fixed
`EXCITEMENT_FROM_RUNNING` (14/s) plus a collapsed decay against a saving that is only the shorter
exposure, so it beats walking on any field whose mean emission along the line clears about 24/s — and
no field short enough to be *felt walking up to it* rather than from down the street can charge fifty
points without clearing that. Sprinting past a crash costs **54.0** where walking costs **63.1**.
Rather than retune the geometry the entry specified, `tests/test_events.gd` names the row in
`_RUNNING_IS_CHEAPER`, asserts the exemption is still true, and asserts there is exactly one of them.
**Open to overturn**: the alternative is a wider, quieter field, and its cost is a sealed street
announcing itself half a block away.

**The defect the bounding-box layer found, which the suite was green through.** The first still of a
placed crash drew one stadium kerb to kerb. `SealPlanner.sealed_variant` builds every seal from
`EventDef.duplicate()`, and `Resource.duplicate()` copies only properties with storage usage —
which `solid_parts` does not have, being a plain `var` holding `RefCounted`s, exactly like `shape`
beside it, which that function already carried across by hand. So the row reached its only placement
path with no parts and fell back to one body spanning the street: no error, no failing check, the
milestone silently undone. `EventDef.at_heat()` duplicates the same way and got the same line, and
`tests/test_seals.gd` now asserts a placed crash keeps its car bodies across six seeds and every day.
**A green suite says nothing about the copy the day actually places.**

**Silent choices, every one open to overturn**: the 72px shoulder and the inner radius at the band's
edge (the entry said "short"; 96 is what keeps the telegraph contract still); 45.0 rather than the
~41.5 that would just clear half the meter, for margin over a measurement taken on one falloff shape;
a disc per car rather than a capsule, which gives each body 28px of ground depth along the street
where the old band had 48; the cars' bodies touching, so the "debris gap" is not a way through and
the two gaps are the pavements; `detain_distance()` left on `obstructs_radius`; and the accident
keeping its authored contact-shadow art, with the per-part shadow path built for whatever row is
solid in parts next.

**Evidence**: `docs/evidence/m118-crash-bodies-2026-09-12/` — `bodies-north-south.png`, a
`--layers 3` still of a placed crash (seed 4222) with two circles meeting under the two cars and both
pavements open; `gap-walk-burst/`, five frames and the timing record of her walking out of the field
and back into the south gap of an east-west crash (seed 4333), where the same two circles sit under
the stacked side views and the readout reads `incoming 45.00/s` against `decay 3.50/s` with the meter
passing 42; and `gap-walk-east-west.png`, the end of that run, which is a cry — two passes through
one crash is the whole meter.

**Merged with M110's per-tile solid record, and the join is one loop.**
`EventManager.obstructed_footprint()` rasterises `EventDef.parts()` rather than the one `shape`,
each piece at its own offset along the spread axis — so a one-piece row records exactly the tiles it
recorded before (`tests/test_crowd_bodies.gd` pins that against `shape.tiles_under()` directly) and
a crash records its two cars and leaves the debris and both pavements open. **It changes nothing on
a played day today, and that is worth writing down rather than discovering**: a crash is a hard
seal, `SealPlanner.plan_day` marks every hard seal's segment in `CityMap.held_segments`, and the
record deliberately skips a body on held ground because the whole street is already shut to walkers
and cars. So the crowd stays off the crash's street the way it always did; what M118 opened is the
*player's* way through, and she is stopped by the pieces' own collision shapes, not by that record.
The loop is what makes the two milestones agree the first time a partly-solid body stands anywhere
the crowd can reach.
