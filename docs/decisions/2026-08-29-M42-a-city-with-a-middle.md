## M42 — A city with a middle · `feature/a-city-with-a-middle`

Playtest 11, finding 4, asked as a question in playtest 10 and as an instruction now: *"let's make
the home be the center (with an odd number of rows/cols blocks) mandatory. I spawn too often at the
edge leaving only a few ways into the rest of the city."*

**The diagnosis is that two existing rules compete for the same thing.** The city is already odd at
7×7 and `_place_home` already sorts candidate blocks by distance to the centre; what walks the home
outward is `MIN_HOME_TO_PARK_TILES` = 30, and the centre of a 7×7 city is rarely 30 tiles from every
park. Both rules are about the same thing — the walk out has to be long enough to matter — and at
7×7 they cannot both hold.

- [x] **9×9.** Odd, and large enough that a central home is still a long walk from calm ground.
      Acceptance test: `MIN_HOME_TO_PARK_TILES` satisfied from a block within one of the centre, over
      200 seeds
- [x] **Re-measure every density number in `docs/playtests/PLAYTEST-04.md`.** 65% more blocks, one event per
      block since M28, and a crowd that is a field around the player since M27 — so placed per day,
      live inside the stream radius, on screen at once, and met on a route all move, and the budget
      with them. This is why it is a milestone and not a constant
- [ ] **And check what a wheel does to the return phase**, which playtest 03 already called a
      formality. Four ways out is four ways back

**Measured, ten seeds** — and this is the only copy of the table, since `docs/CITY.md` keeps the
rule rather than the 7×7-versus-9×9 comparison. Home offset from centre
1.97 blocks → **0.00**, central in 4/10 → **10/10**, calm areas lying in 2.9 of 4 directions → **3.7
of 4**, and directions with real city behind them 3.4 of 4 → **4.0 of 4**. The 30-tile guarantee got
*better* rather than worse — 32.0 tiles at 9/10 seeds → 39.4 at 10/10 — because the clearance rule
replaced the walk-outward rule. Events per block on day 1: 0.97 → **0.94**, which is the number that
had to not move, and `budget_for()` is stated per block now so it cannot drift on the next resize.

**One thing this changed and did not measure**, recorded in `docs/CITY.md`: the crowd is a field of
fixed population in a fixed-size box clamped to the city, so a doorstep at the boundary had the same
agents spread over fewer streets. A central doorstep should therefore be *thinner* per street, which
is the opposite direction from the open difficulty question — and it wants the crowd milestone's own
measurements rather than an assumption.
