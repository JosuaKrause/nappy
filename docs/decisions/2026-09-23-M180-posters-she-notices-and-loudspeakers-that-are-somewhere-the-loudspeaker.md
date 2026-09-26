## M180 — Posters she notices, and loudspeakers that are somewhere: the loudspeaker masts · built 2026-09-23

*([PLAYTEST-117](../playtests/PLAYTEST-117.md); [PLAYTEST-122](../playtests/PLAYTEST-122.md)
statement 5, "there should be a visible indicator about when a mast is active / has a
broadcast"; [PLAYTEST-123](../playtests/PLAYTEST-123.md) statements 23 and 34, "mast in 292 is
weird. it's in the middle of the road", then "mast looks fine now, too".)* One agent on
`feature/loudspeaker-masts`, in two phases around M181's slice one; reviewed here.

**What was built.** `MastSites.compute(map)` farthest-point-samples `Tuning.MAST_COUNT` (6) sites
from junction corners, squares and main-road points, each snapped to the nearest sidewalk or
square tile, never the home street (`MAST_HOME_STREET_MARGIN`) or a calm interior
(`MAST_CALM_INTERIOR_MARGIN`); `EventScheduler._place_masts()` plants a `loudspeaker` plan at each
from `Tuning.MAST_FIRST_DAY` (day 5), the same sites every day, skipping a site on a day whose
closures, wall or huts hold that tile. The field is `homeless_yeller`'s geometry (45/210px) at
intensity 20 on the old 22s pulse with a 3s telegraph: walking past costs 40.0 in
`docs/COSTS.md`, the man shouting's own figure. The picture is `art/events/mast.svg` with a lamp
overlay — unlit when silenced, amber through the telegraph, green with `sound_pulse.svg`'s arcs
while it speaks — on one broadcast clock for all masts. On day 6 a co-located, invisible
`curfew_announce` plan (intensity 30, 26s, ramp 0.2) is the masts carrying the curfew.
`EventManager.silence_mast(id)`, `silence_all_masts()` and `mast_foot(id)` are there for day 11
and day 14; a silenced mast still stands. **`EventDef.city_wide` is gone** with every reader: the
HUD's "nowhere is quiet" line, `EventBus.city_wide_changed`, the `silence_city_wide()` forwarder;
day 14's sabotage calls `silence_all_masts()`. A mast is halo'd, badged, careted, drawn in the
debug layers and logged like any placed row.

**Found and fixed on the branch.** Silencing did not invalidate the contribution cache, so a
silenced mast kept its pre-silence figure for the rest of the tick. A fixed site could stand on a
day's held ground (a closure, wall or hut). The first siting used raw box centres, so a mast stood
in the road — the player's catch; every site now snaps to sidewalk or square, with a test.

**Open to overturn, chosen where the design was silent.** Six masts. The field equal to the man
shouting's. Every square counts as a commercial square. A junction corner is the sidewalk tile
nearest a box corner. The home-street and calm margins. A 6px pole body. The curfew as a second
invisible plan stacked on the broadcast rather than replacing it. **A mast whose site is held on a
day, or reaches a door the siting-time refusal missed (an alley door, since that refusal is stated
over every boundary segment's own street door and not the private detection an alley crossing
needs), does not stand that day** rather than moving, a narrow gap in "the same places every day".
Run-long silencing belongs to M181's day 11.

**The items as the queue held them when this was built:**

- [ ] **A loudspeaker is a mast on a street with a field around it.** Placed from day 5 where
      the fiction puts them — junctions, squares, the main road — drawn, with a field that
      pulses when it speaks and falls away with distance like any other row's, so a route can
      go round one. It is in `docs/COSTS.md` like any row. **A mast shows when it is live and when it
      broadcasts** ([PLAYTEST-122](../playtests/PLAYTEST-122.md): "there should be a visible
      indicator about when a mast is active / has a broadcast"): a live mast looks different from a
      silenced one, and each broadcast is telegraphed before it starts, without sound.
- [ ] **The city-wide floor goes.** *Decided by the player on 2026-09-20: "Remove it"*, asked
      with keeping it near masts only and keeping it as it is as the alternatives. A cost with
      no place cannot be routed round, and the game's one verb is where she walks. No row is
      `city_wide`: what replaces the loudspeaker's pressure is the masts' own fields, and
      `curfew_announce` becomes something the masts do. The day-14 reward, that the sabotage
      silences the city, is the masts going quiet.
