# lilac-marten — The escape's bag has one empty marble, and four measured bags can be played · 2026-11-25

lilac-marten's `fuller-escape.md`. The player: "the escape is basically empty now" (curly-moose #803).
Whether the empty share may stay off the player's order (empty rarest) is the player's to answer
(inbox #1278 in olive-ferret; downy-tapir-2 and polite-tapir-coral-badger kept nine empty marbles on
the orchestrator's reading). The orchestrator picked the default, the player's review item asks it,
and `--escape-bag A|B|C|D` (or `?debug=1&escapebag=X`) plays each measured bag.

**Built.** `DaySpec.ESCAPE_BAGS` names four bags (marbles trucks, explosions, vans, roadblocks,
empty) and `DaySpec.DEFAULT_ESCAPE_BAG` is `D`. `DaySpec.for_section()` takes the bag's name and a
section draws `ESCAPE_MARBLES_A_STREET` marbles a street (`MarbleDraw`'s `marbles_a_unit` replaces
its one-marble flag, `DaySpec.marbles_a_street()` the spec's yes-or-no `stands_one_event_a_street()`):

| Bag | Trucks | Explosions | Vans | Roadblocks | Empty | Marbles a street |
|---|---|---|---|---|---|---|
| A, what shipped | 10 | 8 | 3 | 2 | 9 | 1 |
| B, the player's order, the freed marbles spread in proportion | 13 | 11 | 4 | 3 | 1 | 1 |
| C, A drawn twice a street (downy-tapir-2's option) | 10 | 8 | 3 | 2 | 9 | 2 |
| D, the default: vans and roadblocks as shipped, the freed marbles to trucks and explosions | 14 | 12 | 3 | 2 | 1 | 1 |

**C keeps the open-sidewalk guarantee.** `WalkGround` keeps every plan it is shown, and a unit with
two marbles shows it trial layouts (a row laid again when a larger row is drawn after it). Those
plans stay standing as phantoms, and the ground only gains bodies, so every plan it accepts is
accepted against a superset of what finally stands: the walk stays open past the final plans too, at
the cost of the room the unused trials hold. `tests/finale_rig.gd`'s street-of-vans case plays C
over three seeds (1, 8, 39) and reaches both exits past every body and reach. C stands a van on about
every street and a roadblock on about two thirds as many (69 roadblocks beside 98 vans over the three
seeds), so about a third of the streets stand a van alone and the rest a van and a roadblock. The case guards that the roadblocks were placed
(more than a third as many as the vans), so it fails if C's roadblock marbles were refused.

**What was measured** (`tests/probes/escape_winnable.gd`, twelve seeds 4242, 1, 77, 9001, 23, 5,
31337, 2024, 7, 808, 4216201080, 11, both exits, the game's own walker, on main after snowy-goose
#1761 and misty-plover #1750, **before lilac-marten-lilac-squirrel #1762's charger timing** (every
charger warns for 1.75 s and notices her from a quarter farther, the escape's roadblock guards from
225px instead of 180px), which moves the "Out" rows and the excitement figures; trucks are counted from the run log as she meets them, not from the
plan table, which reads a truck's street as empty; a second pass reproduced every figure). Tunnel,
twelve walks each:

| | A | B | C | D |
|---|---|---|---|---|
| Streets held something | 54% | 68% | 76% | 69% |
| Of those, a van or a roadblock | 17% | 25% | 36% | 18% |
| Per walk: trucks / vans / guards | 2.92 / 1.42 / 0.58 | 0.83 / 0.92 / 0.92 | 0.33 / 1.17 / 0.92 | 1.25 / 0.92 / 0.75 |
| Explosions heard per walk | 3.1 | 3.6 | 4.3 | 4.5 |
| Walks that meet no truck | 3 | 7 | 9 | 5 |
| Out (hard fail) | 5 (7) | 1 (11) | 1 (11) | 4 (8) |
| Mean walk seconds | 53 | 35 | 32 | 48 |
| Lowest sleep / highest excitement | 96 / 21.7 | 100 / 3.9 | 100 / 7.5 | 100 / 6.2 |

Bridge, twelve walks each:

| | A | B | C | D |
|---|---|---|---|---|
| Streets held something | 46% | 59% | 77% | 54% |
| Of those, a van or a roadblock | 13% | 21% | 35% | 15% |
| Per walk: trucks / vans / guards | 0.83 / 0.58 / 0.67 | 1.08 / 1.08 / 0.67 | 0.08 / 1.83 / 2.00 | 1.08 / 0.58 / 0.58 |
| Explosions heard per walk | 2.8 | 3.6 | 4.3 | 3.9 |
| Walks that meet no truck | 9 | 7 | 11 | 7 |
| Out (hard fail, timeout) | 4 (8) | 5 (7) | 2 (9, 1) | 6 (6) |
| Mean walk seconds | 41 | 37 | 41 | 40 |
| Lowest sleep / highest excitement | 100 / 4.1 | 96 / 19.6 | 100 / 7.2 | 96 / 14.2 |

**Reading.** On the bridge walk the lanes ahead of her hold craters a truck cannot pass and the cross
streets are sealed, so trucks barely reach it (0.08 to 1.08 a walk in every bag): more truck marbles
do almost nothing there, and only placed vans, roadblocks and explosions fill its streets. The
walker loses about 60% of walks even on A and plays no lure, so wins at twelve walks are noisy
(tunnel: A 5, B 1, D 4) and the van-and-roadblock share is the steadier comparison; meetings per walk
are cut short by early losses; sleep barely moves, so what a walk costs shows as excitement, not as
crying. D fills about as many streets as B at A's share of vans and roadblocks and about A's wins; B
fills them with more of what takes her; C is the fullest city and the hardest, and its win rate
(1 and 2 of 12) is the least trustworthy figure. Rerun on the merged head (after #1762) for D alone: on these twelve
seeds the tunnel gives 3 out (the table: 4) and the bridge 5 out (6); over 24 seeds, streets held
something 66% (tunnel) and 57% (bridge) of the time, a van or a roadblock 16% and 16%, so the tables
stand as the comparison between bags and D's own rows are a walk or two off. **Open to the player:** whether empty may be one
marble, and which bag. The probe's `ESCAPE_WINNABLE_BAG` plans and walks a named bag.

