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
Two officers are placed on the sidewalk on the park's far side from her, wholly out of the camera's
view, and walk in at `PARK_CLOSING_OFFICER_SPEED` (80px/s). They tape its edge about a tile at a time,
one each way round, so the open edge is always one gap, and it closes at the point nearest where she
stood at the touch. Each officer paces himself, corners included, so the last gap closes
`Tuning.PARK_CLOSING_SECONDS` (12s) after the touch; a stretch never takes less than
`PARK_CLOSING_STRETCH_MIN` (0.3s), so a very large park closes later. **If she is inside when the last
gap closes, the day ends** (`park_cordon`, "They taped the park shut with you inside."). Up to
`PARK_CLOSING_ESCORTS` (2) more officers walk the park's people out, and anything planned in the park
that has not appeared yet is taken off the day. Afterwards the officers walk off out of sight.

The tape is `art/closures/cordon_tape_across.svg`, `cordon_tape_along.svg` and `cordon_post.svg`, in
police blue and white, on the late park's fence line; each taped stretch is a static body
(`src/resistance/cordon_tape.gd`) and its edge tiles are obstructed, and an officer waits while she
stands in the stretch he is about to tape. The officers (`src/resistance/cordon_officer.gd`) are the
sandy-ferret policeman's standing pose with a walking bob, no field, no badge, catching nobody.
`docs/NARRATIVE.md`'s day 12, `docs/CITY.md` and `docs/GRAPHICS.md` say so; `City.close_ground()` has
no caller in the game and stays for `tests/test_scenery_residency.gd`.

**Measured** (`tests/probes/plush_marten_cordon.gd`, five seeds): the swing is 60 to 164px from where
the last gap closes, 0.7 to 1.8s of walking; standing still, the last gap closes at 12.2s, 14.0s on
seed 90210's large park; setting off walking as late as 11.5s still gets her out. `tests/test_park_cordon.gd`
holds the cordon. The pictures, from day 12's swing scene on the whole city without `--invincible`,
are [plush-marten-park-cordon-2026-10-11](../evidence/plush-marten-park-cordon-2026-10-11/): the tape
and officers, a sheet and a clip of the cordon closing, the last gap and the day lost to it, and her
outside the closed park.

*Proposed at filing and built, open to the player's correction:* the tape is solid; the officers are
the existing policeman; walking out from the swing by the nearest open edge succeeds; they catch
nobody, and their arrival is the warning. *Chosen where the entry was silent:* officers walk just
outside the tape; the gap's place is fixed at the touch; no screen-edge badge, since they come at
nobody (on a park taller than the view she may first see them already taping); standing in the last
gap keeps the park from closing; the tape stands only on day 12, and from day 13 the park is like any
other spent park; `ParkCordon._send_off()` walks a park person off on a copy of their own row with
`departs_at` set, a stopgap for a leave-on-foot hook on `EventInstance`. The art's open points: the
tape at thigh height, blue and white rather than yellow and black, the end-on runs reading as posts.

*Open for the player:* whether the tape should stand on days 13 and 14, a physical closure that meets
[M129, one late park is fenced](2026-09-26-M129-regular-spent-parks-are-spoiled-one-late-park-is-fenced-corrected.md);
and whether being shut in only by staying about ten seconds — the swing's robber usually runs her out
within a couple — is the danger meant. [snowy-trout](../todo/2026-10-07-snowy-trout/README.md), day 12's
return softlock, could not be rechecked: the route rig did not move her on day 11 either.
