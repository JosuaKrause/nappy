## M47 — A city with places in it · `feature/a-city-with-places`

Not started. Playtest 13's finding 2 and the second half of finding 7, **plus the whole of M45**,
which is absorbed here because it is the same machinery. See **[docs/playtests/PLAYTEST-13.md](../playtests/PLAYTEST-13.md)**
and the M45 entry above, which is still the design for the closure half.

**The one sentence: the count of calm areas is right and their density is not, and the answer is
area rather than count.** The city went 7×7 → 11×11 across M42 and M41 — 49 blocks to 121 — while
the calm areas stayed at eight. The equation playtest 12 asked to keep was about *count*; what a
player experiences is *density*, and the two came apart when the map grew.

The decision taken on the finding, quoted, because it is not what the analysis expected:

> *"make more calm areas take up multiple blocks — I said a long time ago that an inner courtyard
> (surrounded by buildings) should have a footprint of 2x2 blocks (apartment complex) — this never
> got implemented. not all calm areas have to take up multiple blocks but add more that do. also,
> add calm varieties that take up 2x1 non-square shapes"*

- [x] **Calm ground is never at the edge of the map and never beside the main road** — the second
      lever on density, taken in the same session and **cheaper than everything below it**, because
      it is a placement rule rather than new geometry. *"Another way to get density is to make a
      rule to not have a calm area at the edge of the map or next to the main road."*

      **Today a single calm block has neither rule.** `_assign_purposes` constrains it three ways
      — unclaimed, no open-calm neighbour across a street, `_too_near_the_home` — so a quiet square
      can sit in the outermost block column against the boundary wall, or directly across the road
      from the spine. A 2×2 zone has half of one: `_zone_fits` refuses a footprint that would
      **absorb** a stretch of the arterial, which is about swallowing the street rather than about
      being beside it.

      **Measured on the lattice, for a single calm area, with the home clearance already applied:**

      | eligible blocks | count |
      |---|---:|
      | today (121 minus the 5×5 home clearance) | **96** |
      | + no calm in the outer ring of blocks | 56 |
      | + no calm in the two block-columns beside the spine | **48** |

      So it halves the field for the same 5–7 open calm areas, and **the count the player asked to
      keep does not move**. Two things about that table are worth carrying:

      - **The two halves are wildly unequal and the density argument is almost all the edge rule.**
        The outer ring is 40 blocks; the spine's two columns add only **8** on top, because the
        main road runs down the middle where `_too_near_the_home` has already taken a 5×5 out. So
        *"not beside the main road"* has to be justified on **design** rather than on density —
        where it is stronger: `decay_multiplier` is 0.6 on the spine, so a park you can hear it
        from is not calm ground, and if calm never sits beside it then **crossing it always leads
        somewhere worth crossing for**, which is what makes it a soft block rather than a wall.
      - **It recovers half the loss, not all of it.** At 7×7 the eligible field was ~24 blocks for
        the same 5–7 areas. This lever and the bigger calm areas below are complementary — one
        shrinks the field, the other enlarges each destination — and neither is sufficient alone.

      Three things to get right when building it. State both rules over a **footprint**, like
      `_too_near_the_home` and `_zone_fits` already do, so single blocks and zones obey one rule
      rather than two that drift. State the spine rule over **`map.main_road`**, never over
      `CrowdLanes.arterial_index` — `_zone_fits` currently uses the latter and so carries the same
      M41 defect as `CrowdLanes.busyness()` (see M46), protecting a horizontal arterial the city no
      longer has; adding a third copy of a fact that already has two, one of them wrong, is the
      `DangerEdge` mistake M37 found. And **decide courtyards separately**: a courtyard is *hidden*
      calm you have to know about, it is cut from `remaining` with only the neighbour rule on it,
      and an argument can be made either way for one against the boundary.

      Then **measure the room before committing**, because this is where it goes quietly wrong:
      48 blocks must hold 5–7 non-adjacent calm areas, 1–2 four-block zones needing a wholly
      unclaimed 2×2, and up to 3 courtyards — and `generate()` retries with `seed + 1`, so a rule
      that is too tight shows up as a slower generator rather than as an error.

      **The spine half is expendable and that is a decision, not a fallback.** *"The not next to
      main road rule is not that important, you can remove it if it loses too much freedom."* So
      the edge rule is the one that must land; if the measurement above says the field is too
      tight, the spine rule is what comes out, and it comes out **before** `MIN_CALM_BLOCKS` or the
      non-adjacency rule are touched — those two are what the player asked for by name

      **Built in M52 as one question over a footprint** — `CityGenerator._calm_may_sit_here`, asked
      by all three placement paths (the zone pass, the single-block pass and `_cut_courtyards`),
      which is what this entry asked for and is why the home clearance now reaches a courtyard too.
      **The field was measured before committing and the room is there:** 40 seeds, calm areas at
      the edge **4.42 per city → 0**, beside the spine **1.50 → 0**, areas per city 8.85 → 8.43
      (courtyards 3.00 → 2.55, open calm inside its 5–7 band throughout), and generation retries per
      city **0.50 → 0.00** — the courtyard beside the front door that used to fail the home-distance
      guarantee is refused at placement instead. The spine rule did not have to come out.

      **And the east-west guard came out with it.** `_zone_fits` refused a footprint that would
      absorb the middle east-west corridor, tested against `CrowdLanes.arterial_index` — the phantom
      arterial of M46, protecting a street that stopped being anything when playtest 14 deleted the
      east and west city exits. `tests/test_generator.gd` asserted the same phantom, and now asserts
      the sentence that is load-bearing: no zone swallows a stretch of the **main road**, which the
      new spine clause makes true by construction. Recorded rather than merely deleted, because it is
      a rule nobody took being removed rather than one somebody asked for
- [ ] **And no two calm areas are directly next to each other — including courtyards.** *"Also
      don't place calm areas directly next to each other."* Half of this is already true and half
      of it is a real gap, which is why it is its own item.

      `_has_open_calm_neighbour` tests `_OPEN_CALM` only — park, forest, quiet square — and
      `_cut_courtyards` runs **after** the open calm is placed. So a courtyard is correctly refused
      beside a park, and **two courtyards may sit directly across a street from each other**, with
      nothing in the generator able to see it: the open-calm pass cannot, because no courtyard
      exists yet, and the courtyard pass does not look for its own kind. The trace's day 1 planned
      **three** courtyards, so this is reachable rather than theoretical.

      Two things to decide while fixing it, and neither is obvious. **Whether a courtyard counts as
      calm for spreading purposes at all** — it is *hidden* calm, cut into a residential block, and
      the argument that two of them across a street are one awkward area is weaker than for two
      parks. And **whether diagonal counts**: `_has_open_calm_neighbour` walks the four edges and
      skips the corners, so two calm blocks meeting at a junction are legal today. That is
      probably right — they are a junction apart rather than a street apart — but it is currently
      an accident of the loop bounds rather than a decision, and it should become one either way
- [ ] **The 2×2 inner courtyard — an apartment complex.** Asked for *"a long time ago"* and never
      built. What exists is `COURTYARD_SIZE_TILES`, a 4-tile court carved inside **one**
      residential block. What is wanted is four blocks of buildings with a shared court in the
      middle of them, which is neither that nor M21's open four-block zone. **The mechanism is
      M21's** — absorb the streets between four blocks — with frontages around the outside
      instead of open ground, so it is a calm area you have to find a way *into*
- [x] **Calm areas that are not square.** `CALM_ZONE_BLOCKS` is one integer and everything
      downstream is that integer squared — the tile rect, which segments are absorbed, which
      junctions survive. It becomes a `Vector2i`, and `CityMap.anchor_of()` and `lot_rect()` are
      where it is felt. A 2×1 is the case to build first because it is the one that breaks every
      piece of arithmetic that assumed a square

      **Built in M52 as `Tuning.CALM_ZONE_SHAPES` — 2×2, 2×1, 1×2 — with the square placed first.**
      That ordering is the whole of how the variety arrived without repealing anything: M21's
      guarantee is not *multi-block calm*, it is that every city has somewhere with a **route**
      through it rather than a lap round it, and a shape rolled for the first zone would have made
      that a matter of luck. `validate()` asks the city for a square rather than trusting the
      ordering, because the ordering is the kind of thing a later change moves quietly.

      **`CALM_ZONE_BLOCKS` stayed**, as the square's side — it is what the sleepiness curve is
      normalised against and what every relationship test is pitched at. What moved is that counts
      are stated over the **footprint**: a `w × h` zone absorbs `w(h−1) + h(w−1)` streets (four for
      the square, **one** for a rectangle), has `2(w + h)` streets round it, and contains
      `(w−1)(h−1)` junctions, which is **none** for a rectangle. `tests/test_routes.gd` asserted
      all three as the square's answers, which agreed with the general ones for exactly as long as
      every zone was a square.

      Three things the shape actually broke, and only one of them was in the generator:

      - **`_inset_rect` rolled both offsets against `lot.size.x`**, which is the same number on both
        axes only while every lot is square. A playground in a 22×8 lot would have gone up to
        fourteen tiles south of a lot eight deep.
      - **`--spawn zone` could not photograph one.** It takes `zone:<n>` now, the way
        `closure:<n>` does, because `keys()[0]` is always the square and so the one thing the
        milestone added had no way to be looked at.
      - **The rate curve needed nothing at all**, which is what M52's item 2 bought: a 2×1 fills in
        8.0s and pays for about one traverse of its long side, exactly as the square pays for one
        diagonal. `tests/test_generator.gd` asserts the rectangle sits between the other two rather
        than restating the number
- [ ] **More of them are multi-block, and not all of them.** *"Not all calm areas have to take up
      multiple blocks but add more that do."* `MIN_CALM_ZONES` / `MAX_CALM_ZONES` are 1 and 2 and
      were sized for a 49-block city. Re-derive against 121, and keep single-block calm in the
      mix — *which* calm area to head for stays a real question only while a small quiet square
      close by competes with a big park further out
- [ ] **The main road as a soft block.** Finding 7's second half: *"think of the main road as a
      soft block to guide the player — they will avoid crossing it until it becomes necessary."*
      This is M45's *"a city that is not a full grid, permanently"* achieved without removing a
      walkable tile: the spine is already a line down the middle of the map with a hierarchy and a
      picture, and making it genuinely expensive to cross splits the city into two halves with a
      toll between them. **Build it before the cul-de-sacs**, because it costs no geometry and
      nothing downstream has to be re-proved
- [ ] **Then the rest of M45** — permanent impassable blocks, and closures placed to say *not this
      way today*. The design is in the M45 entry above and is unchanged. The trap it names is the
      one to keep in front of you: **a nudge that removes the decision is worse than a closure
      that does nothing**, because the game's one verb is *where do I walk*
- [ ] **Re-check `MIN_CALM_BLOCKS` and `MIN_HOME_TO_PARK_TILES` at the end, not the start.** Both
      are stated in a lattice that is about to change what a calm area *is*. `calm_areas_needed()`
      derives the floor from the act lengths and must go on doing so
