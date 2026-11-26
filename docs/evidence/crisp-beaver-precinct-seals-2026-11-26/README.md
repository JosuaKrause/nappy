# crisp-beaver — seals on a pedestrian street, 2026-11-26

**Claim.** On a pedestrian street (a precinct) every seal closes the street frontage to
frontage, and no soft seal stands there; before the change most seals on a precinct left a way
through. **Limits.** The counts are the seal planner's dawn placements on the seal rng
`tests/test_seals.gd` uses, not a game's own day rng, so a played day's pictures differ while
the rule holds the same; the two stills are one build, seed and moment each.

## The measurement

`tests/probes/crisp_beaver_precinct_seals.gd`, run as
`tools/test.sh probes/crisp_beaver_precinct_seals.gd`, on seeds 67, 1 to 20, 24757 and 71717,
days 1 to 14 each. Before is `main` at `3c73ed774` with the probe added; after is this
branch's code. For each seal on a precinct it asks the walker lanes left open three tiles either
side of it (no body footprint, no soft-sealed tile) and the widest band her centre passes.

| | seals on precincts | soft | leave a lane or a band open |
|---|---|---|---|
| seed 67, before | 47 | 32 | 36 |
| seed 67, after | 47 | 0 | 0 |
| all 23 seeds, before | 1060 | 655 | 761 |
| all 23 seeds, after | 1060 | 0 | 0 |

Before, by picture over all 23 seeds (count, what was left open):

| picture | seals | lanes open | her band |
|---|---|---|---|
| cafe tables (soft) | 103 | 2-3 (93), four lanes when thinned (10) | 54px, 110px thinned |
| market stall (soft) | 126 | 2-3 (108), four when thinned (18) | 46px, 106px |
| delivery van (soft) | 104 | 2-3 (90), four when thinned (14) | 26px, 96px |
| moving van (soft) | 102 | 2-3 (95), four when thinned (7) | 22px, 94px |
| construction (soft) | 95 | 2-3 (85), four when thinned (10) | 38px, 102px |
| skip and scaffolding (soft) | 125 | 2-3 (114), four when thinned (11) | 32px, 96-102px |
| car accident (hard, solid only at its two cars) | 106 | 0, 1, 4 and 5 | 46-50px |
| burst water main, burnt-out car, collapsed frontage, barricade (hard) | 121, 77, 82, 19 | none | none |

After: burst water main 509, burnt-out car 251, collapsed frontage 248, barricade 52, each
leaving no lane and no band open. The same streets are sealed: only the picture changes.

## The stills

Taken with `tools/shot.sh <out>.png 4 --seed 67 --day <d> --spawn event:<row> --invincible`
from this branch's working tree before its first commit (the code as committed), one with
`--day 12 --spawn event:barricade` and one with `--day 8 --spawn event:collapsed_frontage`;
on both days that row's first planned body stands on the precinct the spawn finds.

- `seed67-day12-barricade-across-a-precinct.png`: the barricade's carts across the paved
  precinct, wall to wall.
- `seed67-day8-collapsed-frontage-across-a-precinct.png`: the collapsed frontage's rubble across
  the same precinct.

A third still of the same run, a collapsed frontage on an ordinary street, was left out as not
about a precinct.
