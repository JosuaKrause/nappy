## M49 — A city that says what it is · `feature/run-and-it-backs-off`

Playtest 14, taken **before** M47 because four of its six are small and two of them are things a
player has now asked for twice. See **[docs/playtests/PLAYTEST-14.md](../playtests/PLAYTEST-14.md)**.

**The one sentence: nothing here is about balance — five of the six are the city failing to say
what it is**, and the sixth is a mechanic that was answering a question about geometry when the
player was asking one about themselves.

**Merged to `main` unfinished, deliberately, and this is the third time** — see M43 and M47. What
is merged is the first round of playtest 14, finished and green: the dog, the border built to its
brief, the moving spine, calm areas that are not diagonal, and calm areas she has not visited
staying clean. What is **not** started is the whole second round, recorded below under *"Recorded
and not started"* — the traffic lights, the calm-ground multipliers, the fence drawn from the
camera's angle, and the four faults on the borders.

The reason to merge rather than hold: the first round contains the process fix in `CLAUDE.md` and
the design record in `docs/CITY.md`, and both of those are rules the *next* piece of work has to be
done under. A branch is the wrong place for a rule about how to work. The rest of M49 continues on
a branch of its own.

- [x] **The pursuing dog does not stop.** *"It's a very simple rule — when I run the dog backs down
      almost immediately."* Third report of this encounter. `PURSUIT_SHAKEN_OFF` counted seconds of
      the **gap opening**, and a run opens it at 38px/s against the day-3 dog — a fifth of a pixel
      a frame — so a corner, a kerb, a pedestrian or the 0.37s about-turn reset the timer and the
      dog chased somebody who was visibly sprinting. Confirmed off a trace first: `run  ran 1.3s,
      exc 57 -> 98`, escaped and lost the day doing it.

      It is a fact about **her** now. Measured with a rig that accelerates: **0.35s of running for
      5 points**, against 1.2s for 17 — which is also the answer to *"or make running less
      costly"*, without moving `EXCITEMENT_FROM_RUNNING`, which is the whole of why running is
      wrong against everything that does not follow her. The contract is untouched: it rests on
      the speed clauses, so walking still cannot end a chase and running always can
- [x] **The border is just black.** M41 built the ring of frontages and opened the camera onto it
      and neither put anything on the floor out there. Each outside tile clamps to the nearest tile
      *in* the map and takes its picture, so the edge continues outward and the spine's four exits
      get their road for free. `CityMap` is untouched — this paints the tilemap only
- [x] **The main road is always in the same place.** It was the middle corridor on **every seed
      ever generated**. Rolled from the city's street stream now, three corridors clear of either
      boundary so both halves are worth being in. Four places still derived it from the constant —
      the M46 defect exactly, *a fact about a city answered from an axis length*
- [ ] **Junctions are four-way where an arm dead-ends.** **Not reproduced.** Two candidates checked
      and correct: an absorbed street's T-junctions already carry no crossing on the missing arm
      (measured, two seeds), and a boundary junction's outward crossing is right rather than wrong
      — it is how somebody on the outer pavement gets over the road she is meeting. It read as a
      dead end because there was nothing beyond it, which is the item above and is fixed. **Needs a
      location from the player**, or a third candidate
- [ ] **Courtyards are still one block.** Asked for twice now. This is the M47 entry *"The 2×2
      inner courtyard — an apartment complex"* unchanged: M21's mechanism — absorb the streets
      between four blocks — with frontages around the outside instead of open ground, so it is a
      calm area you have to find a way **into**. The largest remaining piece of M47
- [x] **The 0.2s window at the lunge — offered and declined.** *"The pursuing dog is fixed now,
      the additional change you suggested is not needed."* The measured gap is real and stays
      recorded on `Tuning.pursuit_standoff`; what it no longer carries is a claim that anybody
      wants it closed. **Do not reopen without a player asking**
- [x] **The border, as briefed rather than as complained about.** Specific tiles per side: south a
      bulkhead then water and **no buildings**, east and west a fence then grass then forest, north
      scree then mountainside. The only things that cross are the **tunnel** — the carriageway
      carries on and darkens a step per tile until it is gone — and the **bridge**. M41's east and
      west road exits are deleted with it: they made sense as gaps in a ring of frontages and make
      none in a wood, and they were never on a main road anyway
- [x] **The fence is rotated the wrong way.** It is drawn running north-south now, the axis it is
      used on, and symmetric about its own centre line so one tile serves both sides
- [x] **Calm areas must not be diagonal from each other either.** *"We said they should not be next
      to each other — this includes the entire surrounding."* `_has_open_calm_neighbour` walked the
      four edges and skipped the corners, so two could meet at a crossroads. It is the whole ring
      now. This closes the M47 open question that called the diagonal case *"an accident of the
      loop bounds rather than a decision"*
- [ ] **A calm area she has never visited was already spoiled, and that can end a run a day
      early.** The most serious finding here, because it is an unwinnable-day bug. `MIN_CALM_BLOCKS`
      is derived as *an act's worth plus one* on the assumption that only **going** to an area
      burns it — which is what `_spoil_the_parks_she_used` does. But `_ensure_one_usable_park`
      protects exactly **one**, and ordinary placement can drop a busker or a market stall into any
      of the rest, so the pool falls below the derivation through no decision she made.

      **Make the guarantee match the derivation: every calm area she has not used this act stays
      clean.** Spoiling stays the answer to *returning* and nothing else. Then check what it costs
      the catalogue — parks are one of the few places several rows can go
- [ ] **Nothing guides her toward the calm, and hard/soft diversions were summarised away on day
      one.** *"I still don't feel the game guiding me to calm zones via obstacles — also tell me you
      have a note about hard and soft diversions."* The current logic is stated in `docs/CITY.md`,
      "Guiding her to the calm": the city **permits** routes to calm and **protects** them from
      becoming impossible, and never suggests one — closures are drawn at random from whatever
      keeps the two-routes invariant, so one is as likely to be behind her as across her route.

      **The design has now been given in full and is written up in `docs/CITY.md`, "Diversions —
      the design". Read it there rather than here.** In one paragraph: hard and soft mean
      **permanent** and **per-day**, not severity; hard blockers are pruned lattice edges
      (cul-de-sacs, big buildings) and soft ones are the day's placements (closures, fallen tree,
      restaurants); soft splits into **lethal**, **mild/benign**, and **road closures**, which are
      not lethal but prevent full access. **Hard and lethal form the paths; benign go on the path.**
      The main road paces the run — she exhausts her own side before she is forced across. Sealing
      a section is fine, because there is no calm in it.

      **Presentation is not the problem and must not be touched.** *"How they are presented is
      already solved. The issue is that they are not placed properly."*

      **And nothing in the invariants forbids it** — checked rather than assumed.
      `_park_is_reachable` requires **one** reachable calm area, not a connected city, so a sealed
      quarter is already legal; `ClosurePlanner`'s two-routes rule is about reaching calm, not
      about connectivity. This is a **placement** milestone end to end: no new blocker kinds, no
      new cues, no change to what a closure is.

      **All five opening questions are answered** and the answers are in `docs/CITY.md`, "How the
      corridor is built": the target is **every available calm area**, one **corridor** each, and
      the day's plan is a **tree** rooted at the doorstep; overlaps are wanted, and a **chokepoint**
      is a guaranteed placement; there is **no budget**, only the tree, and **placeholders** that
      resolve when she arrives; one-shots **bind late**. What is left is the build, in this order:

      1. **Hard blockers do not exist and have to be built first.** *"Cul-de-sacs and big buildings
         don't exist yet — but we need them to implement proper hard blockers."* This is the only
         piece that is **once per run** rather than per day, everything else is placed relative to
         what it leaves, and it has to work for every calm area the run will ever use. It is a
         `CityGenerator` change and it is the gate on the rest
      2. **The tree**, per day: doorstep to every available calm area, corridors and chokepoints
         computed and available to whatever places things
      3. **Placement by role** against the tree — walls out of hard blockers and lethal rows,
         friction inside the corridors, set pieces on candidate sets that every corridor touches
      4. **Placeholders**, so nothing is spent on ground she never reaches
      5. **The two invariant decisions** in `docs/CITY.md` — edge-disjointness versus chokepoints,
         and late binding versus the retried day. Neither is a coding problem and both block 3
- [ ] **Restate the main-road pacing question, which was not understood.** *(Asked badly the first
      time: "what paces the main-road crossing?")* What is meant: the design says she takes routes
      on **her side** of the spine until they are exhausted and is only then forced across. The
      question is **what makes that happen** — is it simply that calm areas exist on both sides and
      `_spoil_the_parks_she_used` burns the near ones over an act, so the far side becomes the only
      thing left? Or does something have to actively withhold the far side early on, and steer her
      across late? The first needs no new code and falls out of what exists; the second is a
      mechanism nobody has designed. **The answer decides whether the arc is emergent or authored**
- [ ] **Day 3 carries act I's whole payload, and the run lesson is the thing it crowds out.**
      *(Raised by the player: "does the fire truck conflict with the run tutorial? Should we move
      the run tutorial one day earlier to disentangle?")* **It conflicts, and it is three rows
      rather than two.** Everything in act I that is not day 1 or 2 arrives at once on day 3:

      | row | what it is | |
      |---|---|---|
      | `fire_truck` | `first_day = 3, last_day = 3` — the **only one-shot in act I**, and a set piece | mobile 190px/s, 340px radius, leaves a `burning_building` for the rest of the day |
      | `charging_dog` | `first_day = RUN_TAUGHT_DAY` — **the run lesson** | `hard_fail`, `AHEAD_OF_PLAYER`, pursues |
      | `reversing_lorry` | new that day as well | `hard_fail` |

      So the last day of act I introduces **two new lethal rows and the only set piece**, on the
      day it also teaches a key the game has spent two days punishing. And the two headline
      encounters teach **opposite answers**: the dog is the one thing in the game running beats,
      the fire engine is a thing to be off the road for. A player who learns "run" from day 3 has
      learnt it next to the one row where it is least relevant.

      **Day 2 is not empty, and the premise for moving there was that it is.** *("Day 2 might be a
      good option since it doesn't introduce anything else I think?")* Measured off the catalogue,
      **day 2 is the busiest introduction day in act I**: `busker`, `construction`, `cyclist` and
      `ice_cream_van` — four rows, and `cyclist` is **lethal**. Day 3 introduces three. So moving
      the lesson to day 2 does not give it a quiet day; it gives it a day with four other new
      things and an existing lethal row on it.

      That does not sink the move — **the argument was never about counts**. It is that day 3's two
      headline rows teach opposite answers, and that a set piece needs room. But it changes what
      the options are, so all three are worth having:

      | | | |
      |---|---|---|
      | **A. run lesson → day 2** | act I reads walk → run → set piece | day 2 gains a 5th new row and a 2nd lethal one; `cyclist` already teaches *fast things kill* |
      | **B. `reversing_lorry` → day 4** | day 3 keeps the lesson and the set piece, minus one lethal row | the two opposite lessons still share a day |
      | **C. `fire_truck` → day 2** | day 3 becomes purely the run lesson; the set piece gets its own day | act I loses its day-3 finale, which is where a one-shot naturally wants to be |

      **Decided: A.** *("Let's do A", 2026-08-31, taken with the corrected premise in front of
      it — day 2 is the busiest day in act I, not an empty one.)* It is the only option that
      separates the two opposite lessons *and* leaves the set piece where a finale belongs, and
      `cyclist` on day 2 is arguably the right neighbour for a running lesson rather than the wrong
      one. **Not implemented** — the change is `Tuning.RUN_TAUGHT_DAY` 3 → 2 plus the docs that
      state it, and it is the one code change queued out of this whole conversation.

      Three things to check rather than assume when it is made, because this is the most-reported
      encounter in the project and playtest 08 explicitly liked where it sits (*"I like the running
      tutorial on day 3"*):
      - `RUN_TAUGHT_DAY` gates **everything that pursues**, so moving it moves the robber's first
        possible day too — check act I is not made harder by a constant that was only meant to move
        a tutorial
      - `charging_dog` is `first_day = RUN_TAUGHT_DAY` **by reference**, so it follows for free;
        `reversing_lorry` is a literal `3` and would then be the only new lethal row on day 3
      - the day-2 difficulty was tuned without a `hard_fail` row on it

      And `docs/MECHANICS.md`, `docs/EVENTS.md` and `CLAUDE.md` all state *"day 1 teaches the arrow
      keys and day 3 teaches the run"* in prose. All three move with the constant, in the same
      commit, or the docs start lying about the day the game teaches its second verb

### Recorded and not started — the second round of playtest 14

Written down before anything is built, on the player's instruction (*"write those down — no fixes
yet"*) and under the `CLAUDE.md` rule the first round produced.

- [ ] **Traffic lights stand against the building instead of the kerb.** *"The traffic lights go to
      the side of the road not the building — they always stay close to the road."* A head belongs
      on the carriageway side of the footway and should stay there whatever the pavement is doing.
      M41 built them on the principle that *where it stands is what says which road it is talking
      about*, so a head against a shopfront has stopped pointing at anything
- [ ] **Calm ground is worth more, and a small calm area worth more still.** *"x1.5 the sleepiness
      effect of calm zones and double it for 1x1 calm zones."*
      `Tuning.SLEEPINESS_CALM_ZONE_MULTIPLIER` is 12. **Two readings, and they differ for the
      multi-block case** — (A) 18 for a zone and 24 for a single block, or (B) 18 and 36. A unless
      corrected. The design is the good part either way: a four-block zone is more than one lap
      wide and a single block is not, so the small ones have always been the weaker choice for
      reasons unrelated to what they are for. Re-check `docs/MECHANICS.md`'s "more than one lap"
      margin afterwards — M38's entry warns this is the constant that decides whether a day is
      winnable once the park is reached
- [ ] **The fence is drawn in elevation and turned on its side.** *"It just looks like a fence from
      the front but rotated sideways, which doesn't make sense."* Both attempts have been a side
      view — palings with a rail across them. The game looks straight down, where a fence is a thin
      line with post-heads and a shadow. Rotating an elevation does not make it a top-down drawing
- [ ] **The eastern border, four faults in one screenshot.** Seed 3225216943, day 2,
      tile (152,103):
      **a)** a calm area sits directly against the border, although M47 shipped *"calm ground is
      never at the edge"* — check `_zone_fits` and the single-block calm placement separately,
      they are different code paths;
      **b)** a road runs into the border and stops in the grass instead of teeing into the boundary
      corridor;
      **c)** people walk out onto the border as if it were pavement and vanish there — *"nobody
      should be walking there since it is not a walkable area, they need to turn like the cars on a
      t-junction"*, and the player is right: **`CrowdAgent._blocked_ahead` returns `false` for a
      tile out of bounds**, so the one wall that should stop them is the one it reports as clear.
      Every agent already runs the divert (`_process` calls it for walkers and cars alike), so the
      fix is likely to be *out of bounds is blocked* and nothing else — which would take **b)**
      with it. Check it against the **spine exits**, which are the one place a car is meant to
      leave the map. The first note here blamed M46 growing the crowd's box; that is how far they
      get, not why they are out there;
      **d)** the fence again
- [ ] **The same faults on the north and south borders.** *"Same issue with other borders."*
      Whatever fixes the east has to be stated over **a border** rather than over one side of the
      map: the first border pass wrote four sides four times, which is one bug per side waiting to
      happen, and this is it happening
