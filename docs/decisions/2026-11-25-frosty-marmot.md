# frosty-marmot — The escape's walks meet more army trucks than explosions heard · 2026-11-26

Under bag D, the escape's default bag, the city's walks met far fewer army trucks than explosions
heard: 1.25 trucks a tunnel walk against 4.25 explosions on main 60e30a341, and 0.92 a bridge walk
against 3.42. That broke the player's frequency order for the escape: trucks, then explosions, vans,
barriers, empty (minty-lemur #785). The bag and the craters' presence were kept as they are; what
changed is where a truck may come from and how it drives. Four builders worked the entry in turn on
one pull request (#1796), each building on the last.

## What was built

- **The first builder: the lane at a junction corner, and the leg through the next box.** The
  convoy's leg runs past her and on through the next junction box by the way the walk's `WayOn`
  leaves it, straight on or round the corner (`WayOn.next_leg()`), so it follows a walk that turns
  there. Measured alone, no gain.
- **The second builder: her lane from a box, the crossing street, and round the corner.** Standing
  in a junction box, on a corner or a crossing, her lane is the street along her heading
  (`EventDirector._stands_in_a_box()`). Where her lane has no room, the truck comes down the
  crossing street at the next box ahead of her, within her view (`_across_the_next_box()`), and
  turns there into her street toward where she was sited (`_round_the_corner_toward()`,
  `WayOn.leg_out_by()`), or else crosses the box in front of her. The badge check moves her along
  her own street and the place only by the part of that shift along the truck's lane. It found the
  cause the next two builders worked from: in the escape every cross street is sealed at its box, and
  each spent explosion left a crater across the whole road, which refused trucks from when it lay
  ahead of her until she was two boxes past it. With craters made passable (a probe, reverted) the
  trucks outnumbered the explosions on the three walks tried.
- **The third builder: a crater a lane wide, and trucks that drive round it** (the orchestrator's
  design call, brief trucks-3). A new row, `lane_crater` (`EventCatalogue._lane_crater()`, drawn
  with the prepared `art/props/impact_crater_1x1.svg`, solid at `point(16)`), is what
  `finale_explosion` leaves: a burst stands on a lane's centre, so the crater covers that lane's
  tile and no other. `WayOn.driven()` is the one reading of how a car drives a leg: each straight
  stretch goes round tiles of its lane that stop it by the street's other lane, out a tile before and
  back a tile after, where that lane is carriageway and free. The 2x2 `impact_crater` stays the
  seal picture.
- **The fourth builder: the refusals counted, and the two that held trucks back fixed.** A
  temporary print at every point a convoy's siting could be refused, over the same 12 seeds and both
  walks (3408 attempts to site a truck, 72 sited), gave the reasons in the next section. Two changes
  follow from them:
  - **A way out of a box is taken where the leg after it goes on too** (`WayOn._down_the_road()`,
    `looks_on`). The through roads are worked out once a walk, and the escape's walk records no body
    at dawn, so its seals stand only as they stream in: a sealed street beyond a box was a through
    road that ended at the seal, and the leg chose straight on into it ahead of the turn that went
    on. Each way out is now asked whether a leg from where it leaves the box exists, one leg further,
    and the first that has one is taken; where none has, the first that drives clear is, as before.
  - **The leg past her crosses the box behind her from short of it** (`EventDirector._short_of_her_box()`)
    where the point level with her lies in that box or past it. The badge check asks her up to a
    run's length back along her street (`_holds_while_its_badge_is_up()`); a walk that turned at
    that box has nothing straight on past it but a sealed street, and from a point inside the box a
    leg can only drive straight out of it.
  - Stale references to `WayOn.drives_clear()` (private since the third builder) in
    `ThroughRoads`'s and `leg_in_the_lane()`'s docs now name `WayOn.driven()`; `docs/COSTS.md`
    gains the `lane_crater` rows it was missing; `docs/EVENTS.md` and `docs/GRAPHICS.md` describe
    the crater a lane wide and the convoy's siting as built; `tests/test_event_manager.gd` and
    `tests/finale_rig.gd` looked for the explosion's crater as `impact_crater` and failed, and now
    look for `lane_crater` (the rig through the row the burst names, `leaves_behind()`).

## The refusals counted

Of the 3336 refused attempts on the third builder's head (684fd70b5), by the first reason each
gave (a waiting truck is asked again every second, so the share is close to a share of the time
trucks waited):

| Reason | Attempts | Share |
|---|---|---|
| Her shifted back by the badge check: no leg out of a box from where the point level with her lay (in or past the box behind her, so straight on into the sealed street, or from a tile under a seal, or with no through road) | 1117 | 33% |
| Her shifted back: the leg through the box behind her had no way on after it (a seal across the street past that box, the leg having gone straight on) | 1041 | 31% |
| Her shifted back: the path from the truck's place to the box not drivable | 463 | 14% |
| She stood off the streets (calm ground, no lane beside her) | 352 | 11% |
| A placed plan's room across the leg | 143 | 4% |
| No place out of sight in the lane | 139 | 4% |
| The same leg reasons with her shifted ahead or not at all | 81 | 2% |

Nearly every swerve refused was one tile long with the other lane blocked beside it: a seal's
crater, which stands on the line between the two lanes and covers one tile of each. None of the
third builder's suspects was what held trucks back: a crater in a junction box where the truck
turns, and a crater within a tile of a leg's end, were each under a few percent.

## Measurement

`tests/probes/escape_winnable.gd`, seeds 4242, 1, 77, 9001, 23, 5, 31337, 2024, 7, 808, 4216201080
and 11, bag D (`ESCAPE_WINNABLE_MIX='as built'`), twelve walks to each exit. Peak excitement is the
highest excitement rate any walk saw; lowest sleep the lowest sleep any walk reached.

| Walk, build | Trucks a walk | Explosions heard a walk | Walks with no truck | Got out | Ended crying | Peak excitement | Lowest sleep |
|---|---|---|---|---|---|---|---|
| tunnel, main 60e30a341 | 1.25 | 4.25 | 5 | 3 | 0 | 6.3/s | 100 |
| tunnel, box and crossing street (second builder) | 1.42 | 4.25 | 6 | 3 | 1 | 14.7/s | 96 |
| tunnel, round the corner (c46624103) | 1.67 | 4.25 | 5 | 3 | 1 | 19.0/s | 96 |
| tunnel, lane crater (684fd70b5) | 3.58 | 3.92 | 1 | 1 | 3 | 52.1/s | 79 |
| tunnel, way out that goes on, short of her box | **4.75** | 4.00 | 1 | 1 | 3 | 46.3/s | 83 |
| bridge, main 60e30a341 | 0.92 | 3.42 | 8 | 5 | 0 | 13.8/s | 96 |
| bridge, box and crossing street (second builder) | 1.33 | 3.17 | 6 | 4 | 2 | 30.9/s | 88 |
| bridge, round the corner (c46624103) | 1.83 | 3.17 | 2 | 4 | 2 | 32.2/s | 92 |
| bridge, lane crater (684fd70b5) | 2.83 | 3.17 | 0 | 4 | 2 | 32.3/s | 88 |
| bridge, way out that goes on, short of her box | **3.92** | 2.83 | 0 | 2 | 4 | 48.6/s | 79 |

The plans are the same in every row (148 explosions planned over the 12 seeds); every other walk
ended in a hard fail (`LOST_HARD_FAIL`). Explosions heard move only because walks end at another moment.
Only bag D was walked, as the brief for the last builder asked; the entry's wish for every bag still
on the Review tab is not measured here.

## What the order costs

**The trucks' noise is a difficulty the player feels, and it is reported, not tuned away** (inbox
#1278 in olive-ferret: a difficulty the player feels moves only on their word). Against main, on
the tunnel getting out fell from 3 walks of 12 to 1 and three walks ended in crying; on the bridge
getting out fell from 5 to 2 and four ended in crying. The orchestrator brings it to the player.

## Weighed and not built

- **Craters made passable to trucks** (`impact_crater` with no body): the upper bound the second
  builder measured. Rejected for the lane crater, which keeps a hole she walks round and a truck
  drives past.
- **A truck that halts at a crater behind her**: it relaxes the rule that nothing is sent on a leg
  it could not go on from (polite-tapir-tall-ibis). Not needed once the craters take one lane.
- **Fewer explosion marbles**: the bag is the player's call, and the brief kept it.
- **A truck from whichever end of her street is clear**: from behind her conflicts with "never from
  behind her" (inbox #1460 in silky-lemur).
- **A badge check that does not ask her walking back past the box behind her**: it would raise a
  badge for a truck that cannot come should she walk back into a sealed street's stub, and a badge
  never disappears before its thing is visible (minty-dolphin #852). Crossing that box from short of
  it gives the truck a leg from every place she can be instead.
- **The swerve at a leg's end and in a turn**: the count put each under a few percent, so neither
  was built.

## Seen once, not chased

On the instrumented run of the fourth builder's change one convoy's warning was withdrawn as it
was due (112 created): `EventDirector.clear_to_send()` refused its leg at creation, a placed plan's
room having come across it during the second its badge was up. That withdrawal is the existing path
for a sent row whose room went (`EventsAhead._warn_in_its_lane()`); none was seen on the run before
the change.
