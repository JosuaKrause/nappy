# frosty-marmot — The escape's walks meet more army trucks than explosions heard · 2026-11-26

Under bag D, the escape's default bag, the city's walks met far fewer army trucks than explosions
heard: 1.25 trucks a tunnel walk against 4.25 explosions on main 60e30a341, and 0.92 a bridge walk
against 3.42. That broke the player's frequency order for the escape: trucks, then explosions, vans,
barriers, empty (minty-lemur #785). The bag and the craters' presence were kept as they are; what
changed is where a truck may come from and how it drives. Five builders worked the entry in turn on
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
- **The fifth builder: the Opus review's findings, and the convoy set off further up its lane.**
  The review (on #1796, against 44936c045) found eight things; what each led to:
  - **A truck could come from behind her** (blocking). Where her lane had no room, the crossing
    street was asked at the next box, the box she stood in included, and a truck that could not turn
    the corner crossed the box straight on into the street's far arm, where her walk may have
    turned while its badge was up. Now the crossing street is asked only at the first box wholly
    ahead of her (`JunctionBoxes.past()`), and a lane that crosses her street sends a truck only
    round the corner toward her (`EventDirector._crosses_her_street()`,
    `_round_the_corner_toward()`); the straight crossing is gone.
  - **The badge check did not ask the crossing lane.** A truck's place in the crossing street moves
    with her as she crosses her own street during the badge's second, which the check never asked.
    It now shifts her along the crossing lane too (`_holds_while_its_badge_is_up()`), and the turn
    sets off at least a tile short of the box, since that place can lie in the box.
  - **The withdrawn warning** is this pull request's, and is fixed by the badge check above (the
    section "The withdrawn warning").
  - **The box arithmetic was worked out in several places.** `JunctionBoxes`
    (`src/events/simulation/junction_boxes.gd`, static lattice arithmetic like `CityMap.period()`)
    is the one reading of where a street's boxes lie, asked by the director and by `WayOn`; a box
    test in `_round_the_corner_toward()` that could never be taken went with it.
  - **What losing the straight crossing cost**: bag D's tunnel walks met 4.17 trucks against 4.17
    explosions heard on 1c44f0ce9, level rather than ahead. Six walks with temporary prints
    (removed) showed the commonest refusal of the stretch from the truck's place down her street was
    a lane crater at the place or within a tile of it, where the swerve has no room to pull out
    (`WayOn.SWERVE`, a tile before the hole), and the next commonest a crater with the other lane
    blocked beside it. **The convoy now sets off a tile or two further up its lane where its leg
    cannot be driven from its place** (`EventDirector.SETS_OFF_BACK`,
    `_past_her_through_the_next_box()`): still out of sight, still in her street ahead of her,
    driving at her. That put the trucks ahead again (the measurement below).
  - **Pictures** of a lane crater, a truck swerving round it and a truck turning the corner are in
    `docs/evidence/frosty-marmot-escape-trucks-2026-11-26/`.
  - **Days 13 and 14**: the box, crossing-street, corner, swerve and set-off changes apply to the
    convoy the director sends on ordinary days too, measured below.
  - The bag D figures of the fourth builder came from an uncommitted tree; they are labelled so
    below, and bag D was run again on the committed heads. `docs/EVENTS.md`'s `military_convoy`
    row says, as the convoy bullet does, that the truck crosses the next box by the first way out
    that goes on, and the escape section says the order holds under the default bag.

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
| tunnel, way out that goes on, short of her box (684fd70b5's tree with that change uncommitted) | 4.75 | 4.00 | 1 | 1 | 3 | 46.3/s | 83 |
| tunnel, never from behind her, badge along both streets (1c44f0ce9) | 4.17 | 4.17 | 0 | 3 | 0 | 22.6/s | 100 |
| tunnel, sets off further up its lane (dde7cc2a4) | **4.67** | 4.00 | 0 | 3 | 1 | 28.2/s | 92 |
| bridge, main 60e30a341 | 0.92 | 3.42 | 8 | 5 | 0 | 13.8/s | 96 |
| bridge, box and crossing street (second builder) | 1.33 | 3.17 | 6 | 4 | 2 | 30.9/s | 88 |
| bridge, round the corner (c46624103) | 1.83 | 3.17 | 2 | 4 | 2 | 32.2/s | 92 |
| bridge, lane crater (684fd70b5) | 2.83 | 3.17 | 0 | 4 | 2 | 32.3/s | 88 |
| bridge, way out that goes on, short of her box (684fd70b5's tree with that change uncommitted) | 3.92 | 2.83 | 0 | 2 | 4 | 48.6/s | 79 |
| bridge, never from behind her, badge along both streets (1c44f0ce9) | 3.25 | 3.17 | 2 | 3 | 2 | 32.4/s | 88 |
| bridge, sets off further up its lane (dde7cc2a4) | **3.33** | 3.17 | 1 | 3 | 2 | 33.2/s | 88 |

The plans are the same in every row (148 explosions planned over the 12 seeds); every other walk
ended in a hard fail (`LOST_HARD_FAIL`). The dde7cc2a4 rows were run twice with the same figures:
on the tree that commit holds, before it was committed, and on 39f0a2e32, whose `src/` and
`tests/` are dde7cc2a4's and whose only uncommitted edits were under `docs/`, which the game does
not load. The other bags' dde7cc2a4 rows ran on 39f0a2e32 with nothing uncommitted. Explosions heard move only because walks end at another moment.
### The other bags

The same seeds, probe and walks under the other bags still on the Review tab (`ESCAPE_WINNABLE_BAG`),
on 3577d40d9 (the branch's merge base, which holds the same escape code as main 60e30a341), on
the fourth builder's head 6b928d6ad and on the fifth builder's dde7cc2a4. Bag C is bag A's marbles (`DaySpec.ESCAPE_BAGS` has `"C": _BAG_A`), so
its walks are bag A's and it was not run again.

| Bag, walk, build | Trucks a walk | Explosions heard a walk | Walks with no truck | Got out | Ended crying | Peak excitement | Lowest sleep |
|---|---|---|---|---|---|---|---|
| A (and C), tunnel, main | 2.92 | 3.08 | 3 | 5 | 0 | 21.7/s | 96 |
| A (and C), tunnel, 6b928d6ad | 3.83 | 2.50 | 2 | 0 | 8 | 71.8/s | 67 |
| A (and C), tunnel, dde7cc2a4 | 4.00 | 2.58 | 2 | 0 | 6 | 60.2/s | 75 |
| A (and C), bridge, main | 0.83 | 2.75 | 9 | 4 | 0 | 3.8/s | 100 |
| A (and C), bridge, 6b928d6ad | 3.33 | 2.42 | 2 | 1 | 5 | 56.4/s | 75 |
| A (and C), bridge, dde7cc2a4 | 4.17 | 2.67 | 3 | 4 | 1 | 22.8/s | 96 |
| B, tunnel, main | 0.83 | 3.17 | 7 | 1 | 0 | 4.0/s | 100 |
| B, tunnel, 6b928d6ad | 2.83 | 2.92 | 4 | 0 | 2 | 38.0/s | 83 |
| B, tunnel, dde7cc2a4 | 3.08 | 3.08 | 3 | 1 | 1 | 20.7/s | 96 |
| B, bridge, main | 0.92 | 3.17 | 8 | 4 | 0 | 16.2/s | 96 |
| B, bridge, 6b928d6ad | 3.33 | 2.75 | 1 | 0 | 5 | 49.3/s | 79 |
| B, bridge, dde7cc2a4 | 2.67 | 2.92 | 2 | 1 | 3 | 37.8/s | 88 |

On dde7cc2a4, under bag A the trucks pass the explosions on both walks; **under bag B they do not**:
level on the tunnel (3.08 against 3.08) and short on the bridge (2.67 against 2.92). Bag A's tunnel
gets out 0 walks of 12 (main 5) and 6 end crying; bag A's bridge gets out 4 (main 4) and 1 ends
crying; bag B gets out 1 on each walk (main 1 and 4). Every walk not out or crying ended in a hard
fail.

### Days 13 and 14

The convoy the director sends on ordinary days goes through the same siting, so every change here
reaches days 13 and 14 too. `RouteRig` walks (`--day <13|14> --seed <s> --route calm,home`) on the
merge base 3577d40d9 and on dde7cc2a4, seeds 4242, 23, 7, 1, 77, 9001, 5 and 808, one walk each,
counted in each run log: a convoy's screen-edge badge, a convoy the director sent down the road at
her, and a withdrawn convoy warning.

| Day, build | Walks | Convoy badges | Sent at her by the director | Warnings withdrawn | Won |
|---|---|---|---|---|---|
| 13, merge base | 8 | 2 | 0 | 0 | 6 |
| 13, dde7cc2a4 | 8 | 2 | 0 | 0 | 6 |
| 14, merge base | 8 | 1 | 1 | 0 | 6 |
| 14, dde7cc2a4 | 8 | 2 | 2 | 0 | 6 |

Day 13's two badges are its placed column's, the same on both builds; day 14 met one sent truck
more (seed 4242, after 32s), with the same outcome and the same end time on every walk. A walk of
this rig ends when the day is won or lost, 15s to 50s in, so it is a small sample of what a
day's walk meets.

## What the order costs

**The trucks' noise is a difficulty the player feels, and it is reported, not tuned away** (inbox
#1278 in olive-ferret: a difficulty the player feels moves only on their word). Under bag D on
dde7cc2a4 against main, the tunnel gets out 3 walks of 12 as main does and one walk ends in
crying; the bridge gets out 3 (main 5) and two end in crying; the highest excitement any walk saw
rose from 6.3/s and 13.8/s to 28.2/s and 33.2/s. The orchestrator brings it to the player.

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

## The withdrawn warning

On the instrumented run of the fourth builder's change one convoy's warning was withdrawn as it
was due: `EventDirector.clear_to_send()` refused its leg at creation, so its badge came down with
no truck behind it, which a badge must never do (minty-dolphin #852). **It was this pull request's
own.** Clean runs of 6b928d6ad withdrew convoy warnings too, two of them just after she stepped into
the road at a zebra, crossing her own street while the badge was up: a truck in the crossing street
is placed at creation level with her along its lane, so her crossing moved its place, and the badge
check never asked that move. The merge base's 24 clean walks withdrew none. The badge check now
asks her shifted along the crossing lane as well (the fifth builder, above), and no convoy warning
was withdrawn in the 24 walks on 1c44f0ce9 or the 24 on dde7cc2a4.
