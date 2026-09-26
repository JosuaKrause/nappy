## M119 — The crowd with nowhere to go leaves · built 2026-09-13

*(2026-09-12, [PLAYTEST-66](../playtests/PLAYTEST-66.md): "pedestrians with nowhere to go (all four
sides of the intersection are blocked off) should just despawn (or never spawn in the first place)
right now they're accumulating in one place and move back and forth or worth flicker (burst 3, 4,
9, and quite a few others). the same with cars (burst 10 and 11)".)* Prioritised with the round.

**A pocket is a map property, computed once a day, not a search an agent runs.** `CrowdPockets`
floods the lanes each kind travels — the carriageway for a car, the pavements for a walker, the
junction boxes for both — from the same inputs the crowd already reads (`CityMap.held_segments`,
`soft_sealed_tiles`, `closed_tiles`, driveability), takes out today's held segments except the
door and home-block carve-outs the crowd crosses anyway, and labels every connected piece that
reaches **at most one junction**. Both placement sites — the morning's `setup()` and every
`_recycle()` — refuse a spot inside one beside the room test; an agent a seal goes up around is
recycled at the first frame it is further than `Tuning.OUT_OF_SIGHT` (420px) from the camera, so
*nothing vanishes while you are looking at it* holds and in view it paces once to the far seal.
`CityMap.day_record_version` is bumped by every write to the day's holds, soft seals and closures,
and `Crowd` refreshes the flood each frame on an integer compare, so a seal placed after the
morning reaches the crowd without anybody remembering to say so.

**Three readings of "no street leads out" were weighed and the middle one taken.** *No tile of an
un-held segment* never fires, because a soft seal stands three or four tiles inside a street rather
than at its mouth, so every pocket still contains an un-held segment's tail. *Everything but the
largest piece* would empty a quarter of the map on a day whose seals cut the city in two. *At most
one junction reached* is the conservative one: a segment is what carries an agent between two
junctions, so a piece touching two has a street out by construction, and a longer cut-off stretch
is somewhere an agent can still walk about. Open to overturn: a spine-edge junction sealed on its
three inward arms counts as a pocket for a car that could leave by the tunnel — harmless, since it
would be recycled there anyway.

**Measured.** Seed 4242 day 1 has 48 of 144 junctions pocketed for walkers, about 3,200 lane
tiles and roughly a quarter of the walkable pavement, and none for cars; day 6, 46 and 4. The
playtest's own seed, 3265820891 day 1, has 50, and tile (59,87) where the mother stood in burst 3
is one of them. The test in `tests/test_crowd.gd` is non-vacuous: with the refusal disabled it
counts 11 agents placed inside the sealed junction on the morning and 13,200 agent-frames inside
it over twenty seconds; with the evacuation disabled, 10 still pacing after the view has moved
off. **The cost is density elsewhere** — the same population on a quarter less ground — and the
balance assertions pass; whether it reads right is in `REVIEW.md`.

**The flicker is one frame, and a stride is the unit that stops it.** `_divert()` re-decides from
`_look_ahead()`'s next scan, which re-scans the moment the direction changes, so a body with a seal
at each end of its ground reversed every frame (17ms); the 83ms burst frames could not show it and
the test measures it instead — before the fix 478 of 502 about-faces fell inside one stride,
quickest on the next frame; after, 35 about-faces and none too soon. `_turn_round()` now refuses
while the last reversal is unspent, for `_stride_seconds()`: a walker's gait half-cycle
(`PI / WALKER_GAIT_RATE`, about 35px, half a second) and a car's own length (52px, a third of a
second), in seconds rather than pixels because the body this is for is usually stopped nose to a
seal. Nothing was added to `Tuning`: the 0.09 gait rate was a literal and is now the named
constant `WALKER_GAIT_RATE` in the same file. A walker's `_may_stand_on()` also refuses a shut
segment now, without which the commitment buys half a second of walking into a hard seal.

**What the refusal forced.** Refusing a quarter of the ground exhausts the placement retries far
more often, and the old fallback — keep whatever the last roll was — put an agent inside a café
(`tests/test_crowd_bodies.gd` went red by one agent-frame on seed 4242 day 6). Both placement loops
now keep the first legal-but-pocketed roll and give it back only if nothing better turns up; a
roll cannot be replayed, since `_choose_lane()` draws from the agent's own stream. Silent choices,
open to overturn: the record lives in `src/crowd/` rather than `CityMap`, since it depends on kind
and on crowd-only carve-outs; the refusal sits at the placement sites rather than inside
`_stands_on_a_street()`, because folding it in would make the pocket a wall and give everyone in
one a reason to about-face every frame; the evacuation is an `elif` after the field-edge test and
a car mid-turn is untouched. No dev flag aims the camera at a tile, so the before-and-after bursts
in `evidence/m119-crowd-pockets-2026-09-13/` use the day's own closure as a spawn target rather
than the reported junction.
