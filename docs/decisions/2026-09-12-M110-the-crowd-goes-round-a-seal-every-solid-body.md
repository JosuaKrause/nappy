## M110 — The crowd goes round a seal · every solid body, built 2026-09-12

*(2026-09-12, asked whether every other solid body diverts the crowd too: "yes every solid body
should do that -- not necessarily force a turn around but at least avoid the solid".)* The
milestone's last open item — a café, a construction band, a kerbed van, a stall, a skip, a
burnt-out car were all still walked and driven through. Three agent commits on
`feature/crowd-avoids-solid-bodies`, reviewed here. This closes M110; nothing of it is left in
`TODO.md`.

**The shape.** `CityMap.obstructed_tiles` is a per-tile count, the same shape
`soft_sealed_tiles` already has and for the same reason: two bodies can share a tile, and the
first to leave must not open ground the second is still standing on. It is filled from the day's
whole `Planned` list rather than from the live `EventInstance`s, because the crowd is steered
across the entire map while an instance only exists within `Tuning.EVENT_STREAM_RADIUS` of the
player — a café two streets away is still a café — and every instance also keeps its own copy for
a body placed later in the day (a burnt-out shell where a fire finished, the resistance's own
guard) with no plan behind it; both give their copy back on every way a body's stay ends.
`GroundShape.tiles_under()` rasterises the placement and axis `EventInstance`'s own statics
already compute — exact on a cardinal axis, conservative rather than wrong on a diagonal, since a
bounding box can only add tiles and adding tiles can only give a body more room. Three kinds are
left out because somebody else already answers for them: mobile rows, by the catalogue's own
*solid things are solid* rule; a body on a segment `held_segments` already holds (a hard seal, a
region wall); and a door body, which `WalkerDoorHold` and the boom already hold.

A **walker** whose own lane is obstructed ahead steers into whichever lane of the same footway has
the most open road in front of it, `Tuning.WALKER_BODY_SIDESTEP_TILES` (4 tiles, 128px) before it
draws level, and steers back once it is past — the same sidestep a bump already gives it, aimed at
a lane instead of away from a person. Only a body across **every** lane of one footway shuts that
footway to the walker, the way a soft seal does, so it turns at the last junction instead — the
other footway and the carriageway stay open, which is the whole difference between a body and a
seal. A **car** has one lane per direction and the oncoming lane is not an option, so a body on its
own lane is a wall to it: it turns at the last junction through the machinery a closure's turn
already uses, and a car already in the street with no junction left before the body stops behind
it the way it stops behind a queue — the M111 about-face is the last resort it already is. Nothing
forces a turn-round the existing closure logic does not; *avoid* was the instruction throughout.

**Three things went wrong on the way, each worth the next reader's time.** The sidestep was first
stated over the tile the walker was standing on: the detour had already carried it off its own
lane, so the next scan found the clear lane it had just moved into, dropped the detour, and steered
it straight back into the body — a two-frame oscillation that put walkers inside bodies for tens of
frames a day. Stating it over `_lane` instead — "where the walker belongs" against "how far off it
currently is" — is stable while the detour is being acted on, and ties going to `_lane` is what
makes "steps back after" happen at all. Second, a turn has no runway: a walker rounds a corner
wherever its old along coordinate left it, sometimes a few pixels from the next street's first
tile, and crossing a footway takes half a second — so `CrowdAgent.BODY_TURN_CLEARANCE_TILES` (3
tiles) refuses a *voluntary* turn onto a lane with less room than that to cross before the body
starts; an unmade turn is invisible, a walker clipping a café's tables is not. A turn forced by a
blockage still happens regardless, and falls back to the nearest pavement. Third, tuning the brake
and the sidestep could never have finished the job, because both are approaches that aim at a
point and arrive a frame late — a car easing toward a blockage overshoots by the last frame's
speed, a walker is still half way across when it draws level with the first table.
`CrowdAgent._keep_out_of_a_body()` holds the step inside the tile the agent started the frame on,
the same shape `nudge_back()` already has for the backward direction, and gives up the cross half
of the refusal before the along half: refusing both at once wedges a walker beside a body for
good, since its steering target never moves and the identical step is refused every frame after.

**A vacuous check almost shipped a fourth time.** The occupancy assertion was checked against the
code being deleted, twice, since a crowd predicate here has passed vacuously for eleven
milestones before: with `CityMap.is_obstructed` answering false outright, five of the new checks
still failed to catch it; only with the record left honest and just the crowd's *use* of it
disabled did fourteen catch it.

**Measured with `tests/probes/m110_bodies.gd`** (three seeds, three days each, walked twice per
day — once with `obstructed_tiles` as the day filled it and once emptied, so the stopped-car share
reads as a difference rather than a level): zero walker-frames and zero car-frames inside a body,
against 80 to 748 before; 0.4% to 5.5% of walker-frames stepping round one; and the stopped-car
share 18.1% against 19.8% with the record emptied, so turning cars away from bodies does not park
them — the M111 failure this was watched for throughout. `tests/test_crowd_bodies.gd` holds the
occupancy, the footway-shut and the car-turn behaviour as assertions, in its own suite since
`test_crowd.gd` is already the longest file on disk and these all want the same bare-city rig with
nothing standing on it but the body the test placed.

**Chosen where the entry was silent, every one open to overturn.** The sidestep is held rather
than timed, because what ends it is being past the body and no number of seconds knows that. A
precinct is stepped round across all six of its lanes and is never shut, since it has no far side
and one stall would empty the busiest pavement in the city; a walker carrying a precinct lane onto
an ordinary street is measured against the nearest sidewalk instead, so the same move that takes
it round a body takes it off the road. `BODY_TURN_CLEARANCE_TILES` is 3 tiles and
`WALKER_BODY_SIDESTEP_TILES` is 4 tiles (128px), both picked to fit the geometry above rather than
measured against a nerve.
