## M64 — Off the path is closed · sealing built 2026-09-03

The design, the eight pictures and the two barrier-placement defects stay in `docs/TODO.md` under
M64; this records the sealing pass, which is the change the milestone existed for.

**What it replaced.** M50 made the corridor the *cheapest* ground and everything else merely dearer,
and the catalogue that filled it is a catalogue of obstacles — a yeller, a café, a market stall, a
reversing lorry — each of which is a reason to cross the street and none a reason not to go
somewhere. So the city could say *this way is expensive* and could not say *not this way at all*, and
the route decision the whole game is built on had one correct answer every day. It was also the wrong
one: off-path was measurably emptier, therefore safer, which is playtest 19's *"going off the paths
lets me skip events and is safer than going on the path"* as a number rather than an impression.

**The measurement, 8 seeds × days 1, 5, 8, 11 and 14, taken with and without the pass in the same run
so the two halves are comparable:**

| band | streets a day | before | after |
|---|---|---|---|
| on the tree | 76.6 | 0.578 | 0.578 |
| the rim | 85.0 | 0.344 | 2.320 |
| further out | 102.4 | 0.319 | 2.050 |
| **off the path** | **187.4** | **0.330** | **2.173** |

Off-path ground now carries nearly four times what the corridor does. **The on-tree figure does not
move at all**, which is the check that nothing touched route ground.

**The earlier 0.23-versus-0.82 figures do not reproduce**, and the discrepancy is recorded rather
than reconciled: the same method now reads 0.330 and 0.578. It is consistent with route-tree and
generation changes landing since, not with the sealing, and nobody chased it down.

**The architecture is the requirement, not a nicety.** *(2026-09-03: "code should be that updating
the list of candidates is enough and no other code changes need to happen to go to 8 seal
pictures".)* A `SealPlanner.Candidate` is an id, a strength (`HARD` or `SOFT`) and one or two
catalogue row ids. Adding a ninth is one appended entry: the per-segment loop, the eligibility pick,
the hard-coverage arithmetic, the pavement pair and the alley-mouth choice are all generic over the
list. A hard seal repeats its row across the street's whole width, the copy count derived from the
row's own `obstructs_radius` rather than hand-tuned, so coverage is edge to edge.

**Two things found in the building that nobody had written down.**

- **`barricade` carries a `scar_id`,** which marks a block `MILITARY` and scars it for the rest of
  the run the first time it is seen — because *that* barricade is the aftermath of something that
  happened. Placed as a seal it would have sealed streets permanently regardless of tomorrow's tree,
  which is a closure no `RouteTree` decided on. `_sealed_variant` duplicates every candidate's def
  and strips `scar_id` and `spawns_on_finish` unconditionally, so a ninth candidate gets that
  protection without anybody remembering to ask for it.
- **`homeless_yeller` cannot seal a pavement.** M64's own text listed it as day-1 seal material and
  it has no `obstructs_radius` at all, so it obstructs nothing. It was dropped from the candidate
  list.

**The winnability guarantee moved from repair to construction**, which was the point.
`EventScheduler._ensure_the_city_is_still_walkable` drops the widest blocker until a park is
reachable; against seals placed by construction off a tree that is walkable by construction, dropping
one would open a hole in a wall. `tests/test_seals.gd` asserts over 6 seeds × 14 days that a calm
area is still reachable with every seal *and* every closure standing.

**Chosen where the design was silent, and each is cheap to overturn:**

- **Hard seals are act IV only.** `barricade` is the only catalogue row wide enough to span a street
  and its only day signal is `act_tag = 4`, so that was read as *hard seals start in act IV* rather
  than a day being invented for it. Days 1–11 seal soft — both pavements taken, the carriageway still
  there to be risked. The three act-I hard pictures close this at no code cost.
- **The alley-mouth rule is the smallest reading**, exactly as the design named it: an alley touching
  the tree at either end stays fully open, and one touching it nowhere is sealed at both mouths. The
  stricter alternative — a parallel open way round every on-tree alley stretch — was named and
  declined in the design itself.

**Composition, same sampling: about 368.8 seal placements a day** — 328.9 soft, 15.3 hard, 24.6 alley
mouths. Soft is two bodies per street, which is why the placement count is twice the street count.

**What is unfelt.** A rig walking blindly south from the doorstep on seed 2102613802, day 6 is walled
at the second street, stands unable to move for thirteen seconds, and loses the day at 17.6s with
excitement at 100 — from `crowd 28.0/s, events 0.0/s`. The seals themselves cost nothing; being
stopped dead while the crowd keeps shoving is what ends it. A player who routes would not stand
there, so this may be the wall doing its job — but it is the first time the wrong direction is a
losing move inside twenty seconds, and nothing telegraphs that.
