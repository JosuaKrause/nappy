# plush-marten — Day 12's park is closed by a police cordon · 2026-10-10

[azure-puffin](../playtests/2026-10-10-azure-puffin.md), inbox #666:

> the park "closing down" is not diegetic -- the material changes in front of the player. we need
> to think of a better effect there

Offered three effects, the player chose a police line, "(B) for the park with the added danger that
you can get trapped inside (which would end the day). the policemen must come from offscreen", and
then, asked how it closes, "Cordon closes round the edge (Recommended)".

**The ground stays grass; officers tape the park shut.** When she touches day 12's swing,
`take_the_park()` (`src/resistance/happenings.gd`) still requisitions the park and takes it from calm,
and starts a `ParkCordon` (`src/resistance/park_cordon.gd`) where the mud rings were; no tile changes.
Two officers are placed on the sidewalk on the side of the park opposite the last gap, wholly out of
the camera's view, and walk in at `PARK_CLOSING_OFFICER_SPEED` (80px/s). They tape its edge about a
tile at a time, one each way round, so the open edge is always one gap. **The gap is checked before
it is accepted** (the city skill): of the stretches whose outside ground still reaches home with the
park's ground blocked, under the director's own `_reach_blocked` (`EventScheduler.blocked_by()`, which
the director now hands to `take_the_park()`), and which stand clear of every body's obstruction and
her whole shape and of any field a body carries, the one nearest where she stood at the touch; when
none qualifies, the best is used and the run log says so. Each officer paces himself, corners
included, to a deadline solved at set-out (`ParkCordon._time_the_close()`): no sooner than
`Tuning.PARK_CLOSING_SECONDS` (12s) after the touch, and no sooner than the walk from where she stood
to the gap plus `Tuning.PARK_CLOSING_WARNING` (2s) after the first officer comes into the camera's
view of where she stood; a stretch never takes less than `PARK_CLOSING_STRETCH_MIN` (0.3s). **If she is inside when the last
gap closes, the day ends** (`park_cordon`, "They taped the park shut with you inside."). Up to
`PARK_CLOSING_ESCORTS` (2) more officers walk the park's people out: a way out is planned at
set-out, through the last gap and over the ground outside it to the nearest place out of her sight,
by sidewalk where it gets there; each escort comes in along it, sends his person off down it
(`EventInstance.leave_along()`, which past the way's end plans on from there to where she could not
be watching and ends only there) and walks out behind them, and is gone once out of her sight.
Anyone in the park already leaving on their own is turned onto the way too. Anything planned in the
park that has not appeared yet is taken off the day. Afterwards the tapers walk off by the same kind
of way, out of sight.

The tape is `art/closures/cordon_tape_across.svg`, `cordon_tape_along.svg` and `cordon_post.svg`, in
police blue and white, on the late park's fence line; each taped stretch is a static body
(`src/resistance/cordon_tape.gd`) and its edge tiles are obstructed, and an officer waits while any of
her collision shape could reach the stretch he is about to tape — the pram's circle whichever way she
faces (`HER_REACH`, 28px from her centre, since her facing follows the input) — or one of the park's
people or their escorts could; the last gap also waits until everyone being walked out is through
it. The officers (`src/resistance/cordon_officer.gd`) are the
sandy-ferret policeman's standing pose with a walking bob, no field, no badge, catching nobody.
`docs/NARRATIVE.md`'s day 12, `docs/CITY.md` and `docs/GRAPHICS.md` say so; `City.close_ground()` has
no caller in the game and stays for `tests/test_scenery_residency.gd`.

**The review of PR #677 found four things one small park could not show**, measured there over seeds
1 to 40: the last gap, placed by geometry alone, opened onto ground cut off from home on seeds 10 and
13 and into a car crash's field or beside a barricade on seeds 2, 28, 32 and 35; on the 704px calm
zones the first officer came into her view of the swing 2.5s before the gap closed, with the gap up to
3.2s away on foot; the tape went down through the pram's circle with her 20 to 26px from the line,
since the officer waited only on her centre; and the park's people left in a straight line away from
her, through the tape, with their escort walking a fixed 840px through whatever stood that way. Each
is fixed as described above.

**Its second review found one more of each kind**, all fixed: a person walked out ended at the way's
last point, because the private `EventInstance._trail` the cordon wrote is walked by `_walk_back()`,
which ends where it runs out, so on seed 4242, with her walking the same way out from 4 or 8s after
the touch and stopping at its end, the busker vanished beside her; the logged close and
`first_in_view` were read before the 0.3s-a-stretch floor, so a large park logged 12.0s and closed at
14.0s, and a taper lost the rest of a frame's step at every stretch's end, about half a second over a
large park; and someone already leaving on their own, or an escort sent back alone from inside the
park, was not counted by the gap's wait. Merging main's bouncy-egret (#674), whose `_reach_blocked`
also carries the soft seals' bands, moved seed 13's last gap off one, to an edge the officers reach
her view of later, so that park now closes at 26.3s rather than 14.0s.

**Its third review found the walk past the way's end standing still in her view**: it steered
straight away from her and, where that was off the walkable ground, slid along the wall by the part
of the step square to it, which against the city's edge met nearly square-on is next to nothing. On
seed 4242, with her stopped at the way's end, the busker walked 304px west to the city's edge and
stood there, in her view for 42s after the way was walked; turning along the open axis at full
pace was the other fix offered, and was not taken because steering on "away from her" also turns
back and forth in a dead end. With the rest planned by the search he is in her view 6.8s after the
way and never under half his pace in it, and `tests/test_park_cordon.gd` bounds both.

**Its fourth review found that search walking him back into the park**: the park's grass is
walkable and the tape is a body, not a tile, so the nearest ground out of her sight was often across
the park. With her stopped 60px past the way's end, the busker walked back in through the last gap
88px from her on seed 10, back into the park in her view on seed 40, and across tape that was up on
seed 34. `leave_along()` now takes the tiles the rest must not enter, and the cordon passes its
park's; the planned rest also left a second call's new way followed by the old rest, and is cleared
with it.

**Measured** (`tests/probes/plush_marten_cordon.gd`, seeds 1 to 40 and 90210, her at the swing and the
camera on her; 41 swing parks, 35 of them 256 by 256px and 6 of them 704 by 704px): every last gap's
outside reaches home and the day's other calm ground with the park blocked, and stands clear of the
day's bodies and fields. The walk from the swing to the gap is 60 to 538px, 0.7 to 5.8s (the 538px on
seed 10, whose nearer edges open onto ground cut off from home). On the small parks an officer is in
view within 0.5s and the gap closes 12.0s after the touch; on the large ones the first officer
comes into view 1.1 to 22.7s after it and the gap closes at 13.4 to 13.5s, and at 26.3s on seed 13 and
27.9s on seed 40, where the officers come into her view only late in their round. First sight comes
2.0 to 11.2s before the close beyond the walk, and setting off at a walk a second after it gets her
out on every one; the close and first sight are within a quarter of a second of what the cordon set
out to (`deadline`, `first_in_view`). `tests/test_park_cordon_seeds.gd` holds that sweep against the
map and the clock, and walks a busker out of each park with her stopped 60px past the way's end,
holding that he never walks back into it nor across tape; `tests/test_park_cordon.gd` holds the
cordon on one city, the pram at 20 to 26px either side of the line, and a busker walked out through
the gap.
The pictures, from day 12's swing scene on the whole city without `--invincible`, are [plush-marten-park-cordon-2026-10-11](../evidence/plush-marten-park-cordon-2026-10-11/): the tape
and officers, a sheet and a clip of the cordon closing, the last gap and the day lost to it, and her
outside the closed park; and [plush-marten-walked-out-2026-10-11](../evidence/plush-marten-walked-out-2026-10-11/):
a busker walked out through the last gap with his escort behind him.

*Proposed at filing and built, open to the player's correction:* the tape is solid; the officers are
the existing policeman; walking out from the swing by the nearest open edge succeeds; they catch
nobody, and their arrival is the warning. *Chosen where the entry was silent:* officers walk just
outside the tape; the gap's place is fixed at the touch; no screen-edge badge, since they come at
nobody, the deadline instead leaving her the walk and two seconds after first sight; the officer's
reach is taken whichever way she faces rather than read off her facing, since the facing can swing
the pram into the line after the tape is up; standing in the last
gap keeps the park from closing; the tape stands only on day 12, and from day 13 the park is like any
other spent park; a park person with no departure of their own walks out at
`PARK_CLOSING_LEAVE_SPEED` (50px/s), the pace `leave_along()` is handed; past the way's end, since
that may be where she now stands, `leave_along()` plans the rest from where she is
(`EventInstance._way_on_out_of_sight()`, a breadth-first search over the tiles
`CityMap.is_walkable()` admits, off the park's, to the nearest one more than `Tuning.OUT_OF_SIGHT`
and a tile from her, again each time one runs out while she could still be watching) and walks it
at the same pace, stepping straight away from her only where the search finds nothing; the cordon's
search for the way out (`ParkCordon._route_away()`) is a breadth-first search of its own, over
walkable ground off the park and off the day's blocked set, roads only when the sidewalk does not
get there. The art's open points: the tape at thigh height, blue and white rather than yellow and
black, the end-on runs reading as posts.

*Open for the player:* whether the tape should stand on days 13 and 14, a physical closure that meets
[M129, one late park is fenced](2026-09-26-M129-regular-spent-parks-are-spoiled-one-late-park-is-fenced-corrected.md);
whether being shut in only by staying twelve seconds on most parks, and up to about 28 on the
largest — the swing's robber usually runs her out within a couple — is the danger meant; and whether
a large park's later close should instead come from bringing the officers into her view sooner.
[snowy-trout](2026-10-07-snowy-trout.md), day 12's return softlock, does not reproduce
with the cordon: the route rig, run headless (`--fixed-fps 60`) with `--no-focus-pause --no-title`
(without the two it did not move her) and `--invincible`, walks `mark,task,calm,home` on day 12 of seeds 4242, 11 and 13 (13's
park a large one), touches the swing, settles the baby elsewhere while the park is cordoned off with
her outside, and walks home with the baby asleep to a won day each time, with no error. The rig
stops at the win, so the summary and the next morning after it are not exercised.
