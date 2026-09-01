# TODO

**The queue. Open work only.** A ticked item is history the moment it is ticked, so completed
entries live in [DECISIONS.md](DECISIONS.md) with their measurements and rejected options intact —
search it for the noun before designing anything.

Read [HANDOFF.md](HANDOFF.md) first for the state of the tree.

Status legend: `[ ]` todo · `[~]` in progress. Each milestone is one git branch, merged to `main`
with `--no-ff`.

---

## The order

1. **M40** — the docs say only what is true. *In progress.* The player's instruction is that this
   comes before any other implementation.
2. **M55's resistance half** — designed, nothing open, needs building.
3. **M53** — a junction is made of the streets that meet at it.
4. **M54** — the robber stops at walls, and three rows that never arrive.
5. **M56** — the resistance is noticed.

Everything below that is unordered and reassessed on 2026-09-01.

---

## M40 — The docs say only what is true · `feature/timeless-docs` · in progress

Two jobs. A **correctness pass** that finds sentences no longer true, and a **style pass** that puts
everything in the present tense with the history moved to `DECISIONS.md`. A stale claim survives a
rewrite perfectly well if nobody checks it against the code, so the first is not a side effect of
the second.

The test is a reader, not a diff: **somebody who opens any single file and believes every sentence
in it is wrong about nothing.**

- [x] **`docs/DECISIONS.md` exists** and is the destination for everything the restyle lifts out.
      The test is that every fact removed can be found by searching it for the symbol name
- [x] **`docs/HANDOFF.md` is the pick-up block alone**, and true. Its history tail became the
      archive in `DECISIONS.md`
- [x] **`CLAUDE.md` becomes an index** over the skills in `.claude/skills/`, holding only what
      applies to every task and the rules a hook cannot trigger on
- [x] **The rules get skills**, one per operational task, each loaded before that task rather than
      carried in context for every task that is not it. Eleven of them, with a trigger table in
      `CLAUDE.md`
- [x] **`session-cleanup` is a skill and runs at the end of every session.** This pass is short
      when it is done every time and a milestone when it is not
- [x] **The path-triggered rules are a hook, not an instruction.** *(2026-09-01: "if they are
      triggered by files then make them rules that trigger on those files.")* A skill somebody has
      to remember to load is not a rule. `.claude/hooks/project-rules.sh` fires on every
      `Edit`/`Write`, maps the path to the skills that govern it, and injects them **before the edit
      is made** — once per area per session, keyed on the session id, so the same rules are not
      repeated on every subsequent edit to the same place. The three that have no file to trigger on
      — `feedback`, `committing`, `session-cleanup` — stay invoked by hand, because they are about a
      *moment* rather than a place
- [x] **`docs/TODO.md` is a queue again** — open work only, with every completed entry archived
      whole in `DECISIONS.md`
*(2026-09-01: "also scan the whole codebase to update for the timeless style — not only documents
but also code docs/comments.")* Done. The method is in the `godot` skill under "Comments are written
in the present tense": **keep the reason a thing is the way it is and the trap that makes it easy to
get wrong; drop the milestone number, the former value, and the narration of the fix.**

- [x] **The docstrings.** Every `.gd` file in `src/` is at zero, checked with
      `grep -rcE '(M[0-9]{1,2}\b|playtest|Playtest)' src --include='*.gd'` — the four hits left are
      in `main.gd` and are all the ordinary word, in the function that decides whether a run's log
      is a playtest.

      **The rewrite that works** is turning a narrated fix into the mistake a reader could still
      make: *a contract in seconds cannot describe a pursuit played out in distances*, *never guard
      on a `CanvasLayer`'s `visible`*, *a category in an enum is a list waiting to happen*. Where a
      paragraph did not survive that test it was history and went to `DECISIONS.md`.

      **The pass found five stale claims and one dead field**, which is the argument for doing both
      passes at once holding for the code as well as for the docs: the mark docstring's "fifteen of
      the eighteen rows" (the catalogue has thirty-one, six of them lethal) and its "no lethal
      events in acts I and II" (the cyclist is day 2), `street_network`'s "64 junctions and 112
      segments" (144 and 264), `main`'s "eighteen kinds" and its list of "four things a picture
      cannot carry" that names three, two crowd sizes quoted as four and five hundred against a cap
      of 200, and `EventDef.act_tag`, which is set on eleven rows and read by nothing
- [x] **The design docs** — `EVENTS`, `CITY`, `MECHANICS`, `TELEMETRY`, `ARCHITECTURE`, `DESIGN`,
      `NARRATIVE`, `README` are all at **zero** history references, one commit each. Done before
      the docstrings because a reader reaches them first.

      **The style pass found nine stale claims, which is the argument for doing both passes at
      once**: `AHEAD_OF_PLAYER` "is the cat" (it is three rows), the pre-per-block event budget
      formula, `construction` as "the only act I event in the way", `cat_dash`'s duration, an 8×8
      junction lattice and 112 streets, "nineteen of a hundred" signalled junctions, `PARK`'s
      sleepiness and decay multipliers, a 104×104 city, and a car population of thirty.
      **`charging_dog` had no row in the catalogue table at all.** Two obsolete measured tables
      moved to `DECISIONS.md` rather than being restyled in place
### ← Next step: re-audit the numbers, separately from the restyle

- [ ] **A stale claim survives a rewrite perfectly well if nobody checks it against the code.** The
      two restyle passes caught fourteen between them, and only because rewriting a sentence forces
      you to read what it says — a pass that goes looking will find more. Any number a doc or a
      docstring quotes is a candidate: radii, costs, counts, densities, timings.

      Two known shapes to look for. **A number stated per something that has since been resized** —
      the lattice is 11×11 and every count over blocks, junctions or streets moves with it; two of
      the fourteen were exactly this. And **a measured table that was a before-and-after**: those
      are history, and they belong in `DECISIONS.md` with their date rather than being restyled into
      the present tense.

      Where a number is load-bearing but fragile, the fix is usually to **state the relationship
      instead of the figure** — "only the spine's junctions are signalled" rather than "nineteen of
      a hundred" — and to leave the figure to the code

---

## M55 — The resistance is a place you reach · designed, not built

Everything else in M55 is done. The design has nothing open; `DECISIONS.md` carries the calendar,
the guard arithmetic and the six drafts with the one that was not taken.

- [ ] **The hold goes; touching a mark completes it.** `E` comes out of `project.godot`,
      `contact_point.gd`, `tests/test_resistance.gd`, `docs/MECHANICS.md` and
      `docs/ARCHITECTURE.md`. With it go `hold_seconds`, `progress`, `DECAY_RATE`,
      `resistance_hold_changed`, the HUD's `holding N%`, and the patrol hold-reset
      (`SEEN_RADIUS`, `_patrol_is_watching`, `was_seen`, `resistance_seen`)
- [ ] **A task is two steps** — pick up the instruction, perform it the next day. The first mark
      moves to day 4; the calendar is exact through day 14. `RESISTANCE_GOAL` counts the perform
      half only, so 4-of-5 is untouched
- [ ] **The day brief carries the resistance's own words**, which is now the mechanism rather than
      a courtesy: miss the mark and there is no task tomorrow. The first encounter keeps its
      absolute no-hint exemption, which is free — `day_summary.gd` already gates on
      `has_joined_resistance()`
- [ ] **The shared plumbing**: a contact that rides on an `EventInstance` rather than on a tile,
      with several candidates. Every task needs it and nothing else is common to them
- [ ] **Five tasks** — the yeller, the package carried home, the checkpoint, the poster crew's
      wall, the protest
- [ ] **Every mark is guarded.** `TRAP_FIRST_DAY` goes to the first step's day, the
      `_step.district >= 0` exemption comes out, and `TRAP_CHANCE` becomes a **distance** in the
      66–176px band the robber's own radii fix. Which side she approaches from decides whether he
      wakes
- [ ] **Open, deliberately:** whether a picked-up-but-unperformed instruction expires at the end of
      its day or waits. `deadline_fraction` is the machinery for the first. Left until the pairs
      can be walked

---

## M53 — A junction is made of the streets that meet at it

**The lattice draws a full crossroads wherever two corridors cross, whether or not the arms are
streets.** `CityMap.absent_segments`, `built_over` and the map edge already say which arms exist —
nothing that draws a junction asks.

- [ ] **A junction whose arm is not a street has three arms, not four.** The shore, a park, a calm
      zone's absorbed corridor, a dead end's plug
- [ ] **No crossing onto a wall** — a zebra with a traffic light beside it is painted onto
      `built_over` tiles. A crossing marks *where to cross to*; the paint is the promise, so this is
      worth doing even if the full three-armed junction is not
- [ ] **A junction between two precinct arms is still asphalt with zebras on it.** A precinct is
      laid `SIDEWALK` frontage to frontage by `CityGenerator._street_tile`; the junction between two
      of them was never included
- [ ] **Cars and people still go off the map.** Two candidate causes wanting different fixes: the
      agent is recycled on screen, or the junction should not be there
- [ ] **Only cars go over the bridge.** The overrun permission was narrowed to a car on the spine
      and the **lane** was not, so a walker's lanes still run the length of a corridor that at the
      boundary is a bridge. The bridge is **not** to be made safe
- [ ] **The crowd has to agree with the drawing.** A T-junction the paint knows about and
      `CrowdAgent._divert` does not is the same bug in the other direction

---

## M54 — The robber stops at walls, and three rows that never arrive

Its resistance bullet is absorbed into M55.

- [ ] **The robber runs through walls.** A pursuing `EventInstance` moves by setting its own
      position and nothing in the event system has ever collided with the city — harmless while
      every mobile row travelled a route the scheduler had checked, and not harmless the moment
      something steers at the player
- [ ] **The bike, the loose dog and the cat never have an impact.** Three rows whose whole content
      is a moving thing meeting her. `cyclist` and `loose_dog` are `MAP` rows sited at dawn, so the
      day chose where they go before it knew where she goes; `cat_dash` is `AHEAD_OF_PLAYER` and
      aimed **late**, crossing behind her because the lead is measured from where she is rather
      than where she will be.

      The design: place them when she gets close, the biker on the pavement she is walking on
      coming toward her, so she has to answer by changing side or turning. **What it collides
      with:** a bike she answers by *planning a turn* is neither `MAP` nor `AHEAD_OF_PLAYER`, so
      this may want a **third spawn mode**
- [ ] **The run hint belongs to the lesson, not the mechanic.** Once the run is taught, a line
      telling her to hold shift explains something she has already been made to do

---

## M56 — The resistance is noticed

The city gets more dangerous the further into the subquest you are. **A task may not cost a nerve**
— a nerve is a rewind, not a resource, so there is nothing to trade.

- [ ] **Danger scales with `GameState.resistance_progress`.** What it may move is open. The
      constraint is that a role is read off the def, so heat must not become a per-row switch
- [ ] **The patrol is the non-lethal rung; the van is the lethal one.** `police_patrol` today is
      mobile at 74px/s, intensity 10, radii 44/185, up to 12 a day, from day 4, and not `hard_fail`
      — which the instruction keeps. The axes an escalation could move are intensity, radius,
      population, and whether it investigates rather than patrols: **draft and put back**
- [ ] **The abduction van takes somebody, and then it takes you.** `abduction` today does neither —
      a static idling van, 250px field, `hard_fail` inside 54px. **"Normally just abduct people" is
      the first authored event with a victim**; nothing in the catalogue has ever acted on the
      crowd. And a hunting van inherits `pursue_speed` under `RUN_SPEED`, so it creeps at a fast
      walk — a screenshot question, not an arithmetic one
- [ ] **A lethal field that follows her** is neither M28's clearance rule nor M50's off-corridor
      exemption. Either the rule gains a third case for pursuers — which `charging_dog` and
      `alley_robbery` have quietly needed without anybody writing it down — or a hunting van is not
      a `hard_fail`
- [ ] **"And other dangers like this"** — drafted and put back, after the vans, because the vans
      are where the precedent gets set
- [ ] **Measure it against the nerves.** This makes the back half harder precisely for the player
      doing well at the optional path, and nobody has reached act III

---

## M50 — What the corridor still owes

- [ ] **"Blocking events all over" is a catalogue question, not a placement one.** The gradient is
      built and measured, and the corridor is the cheapest ground on every day. What is not true is
      the density: raising the caps on the expensive rows is a real balance change and wants its own
      measurement
- [ ] **Placeholders — step 3.** The budget is a **variety ledger, not a density cap**: the count of
      sites is the density, the budget decides what fills them, and resolving late means variety is
      measured over the encounters that happen rather than over a city she never saw. Read the
      entry in `DECISIONS.md` before starting; the first reading of this was wrong and the wrong
      reading is recorded there
- [ ] **A building type that closes all four of its streets.** Recorded, not built, and a
      **different type rather than a bigger one** — it makes an island, so it needs its own name,
      its own count, and its own answer to how many a city can take

---

## M47 — Calm areas that are places

- [ ] **The 2×2 inner courtyard — an apartment complex.** Asked for three times. M21's mechanism —
      absorb the streets between four blocks — with frontages around the outside instead of open
      ground, so it is a calm area you have to find a way *into*. The largest remaining piece
- [ ] **No two calm areas directly adjacent, including courtyards.** Half true today:
      `_has_open_calm_neighbour` tests open calm only and `_cut_courtyards` runs after it, so **two
      courtyards may sit across a street from each other** and nothing can see it. Two things to
      decide while fixing: whether a courtyard counts as calm for spreading at all, and whether
      diagonal counts — the four-edge walk skips corners today by accident rather than by decision
- [ ] **More of them multi-block, and not all of them.** `MIN_CALM_ZONES` / `MAX_CALM_ZONES` were
      sized for a 49-block city; re-derive against 121. Keep single-block calm in the mix — *which*
      calm area to head for stays a real question only while a small square close by competes with
      a big park further out
- [ ] **The main road as a soft block.** Make it genuinely expensive to cross and the city splits
      into two halves with a toll between them — M45's "not a full grid" without removing a
      walkable tile. **Build it before the cul-de-sacs**, because it costs no geometry
- [ ] **Re-check `MIN_CALM_BLOCKS` and `MIN_HOME_TO_PARK_TILES` at the end, not the start**

---

## M45 — A grid with fewer ways through

**A closure cannot change a route while there are nine destinations and a full grid** — measured:
350 closures across ten seeds changed the best route to the nearest calm area *once*. No margin,
filter or run length fixes that; the answer is that the question was wrong. **A closure's job is
direction, not distance.**

- [ ] **Permanent impassable structure**, reusing `absent_segments` rather than reinventing it
- [ ] **A closure that points**: not *"does this lengthen the best route"* but *"does this stop her
      committing to a direction that cannot win today"*. **The trap, and it is the whole difficulty:
      a nudge that removes the decision is worse than a closure that does nothing.** The game's one
      verb is *where do I walk*
- [ ] **And a soft version — events rather than barriers.** Everything exists except the *intent*:
      nothing in `EventScheduler` has ever placed events to say *not this way*

---

## M48 — Things drawn where they stand

- [ ] **A body on a pavement has to fit on the pavement.** `construction` obstructs 34, so it draws
      68px wide on a 64px sidewalk from a tile centre 16px from one edge — **it overhangs by 18px
      whichever lane it lands in.** Every `_draw_spread` row can break the same way. Wants a test
      over the catalogue
- [ ] **A spread is always drawn east–west, whatever street it is on.** Nothing rotates an
      `EventInstance`. **A barrier's entire content is which way it faces**
- [ ] **And it does not say what it is.** Blue-grey with no hazard marking. One-picture-per-row
      passes and the row still says nothing, which is that rule's own limit — municipal barriers are
      red-and-white for a reason

---

## M43 — Two that need a played run

- [ ] **The tutorial dog is not a tutorial after day 3.** `charging_dog` is `first_day 3`,
      `AHEAD_OF_PLAYER`, no last day, so it is still sited in front of her on day 4. **Decided: it
      recurs but is not sited ahead of her** — it becomes a thing that is *somewhere*, like
      `alley_robbery`. Day 3 keeps the placement it has, because the lesson depends on being
      unavoidable
- [ ] **Dying at high excitement on a quiet street.** The crowd half closed into M46. Two cheap
      checks remain: whether the pram's `EXCITEMENT_NEARLY_CRYING` cue is shown and not read, and
      whether **one contact at 90 is a cliff** — a bump is ~10.8 points, so above 89 a single one
      ends the day on an empty street
- [ ] **`RUN_TAUGHT_DAY` 3 → 2**, decided and not implemented. It gates **everything that pursues**,
      so check act I is not made harder by a constant meant only to move a tutorial; day 2 was tuned
      without a `hard_fail` row on it. `docs/MECHANICS.md`, `docs/EVENTS.md` and the skills all
      state "day 3 teaches the run" in prose and move in the same commit

---

## M49 — Borders and drawings

- [ ] **The fence is drawn in elevation and turned on its side.** The game looks straight down,
      where a fence is a thin line with post-heads and a shadow. Rotating an elevation does not make
      it a top-down drawing
- [ ] **People walk out onto the border and vanish there.**
      **`CrowdAgent._blocked_ahead` returns `false` for a tile out of bounds**, so the one wall that
      should stop them reports as clear. Likely *out of bounds is blocked* and nothing else — check
      against the **spine exits**, the one place a car is meant to leave the map. Overlaps M53
- [ ] **Whatever fixes one border has to be stated over *a border*.** The first pass wrote four
      sides four times, which is one bug per side waiting to happen
- [ ] **Junctions are four-way where an arm dead-ends** — **not reproduced.** Two candidates checked
      and correct. Needs a location from the player, or a third candidate
- [ ] **Restate the main-road pacing question.** The design says she exhausts her own side of the
      spine before being forced across. **Is that emergent** — calm areas exist on both sides and
      spoiling burns the near ones over an act — **or does something have to withhold the far side
      early and steer her across late?** The first needs no new code; the second is a mechanism
      nobody has designed. The answer decides whether the arc is emergent or authored

---

## M25 — Patrols for the empty acts

- [ ] Pressure back into the streets acts III and IV deliberately emptied, built around **encounter
      cost** rather than ambient emission, and specifically the shape of the return phase — which
      playtest 03 measured as a formality: 26s, five crossings, zero encounters, 42% of the day
      left. *Its stated prerequisite — a mechanic running escapes, with a contract over `RUN_SPEED`
      — shipped in M33, so this is unblocked and has been since.*

## M26 — Teaching the two controls that remain

- [ ] Arrows/WASD at the start of day 1, then shift, then a day-1-only event requiring a short run
      after the first block. *Its first half (deleting the interact key) is M55's.* **Comes after
      M25 for correctness, not scheduling:** forcing a run before running is ever the right answer
      teaches a move that is never correct again

---

## Reassessed on 2026-09-01, and still wanted

Small, real, nobody's milestone. Each has sat since the milestone that deferred it.

- [ ] **The `burning_building` spawns in the road** rather than in a building — it spawns exactly
      where the engine stopped. A few lines to nudge it to the nearest `BUILDING` tile
- [ ] **The pram has no collision of its own**, so it clips into walls when she hugs a corner. A
      second body that trails her, or a capsule that rotates with `facing`
- [ ] **Park trees clump** — placed by rejection sampling. A minimum-spacing check would spread them
- [ ] **`INDUSTRIAL` and `CIVIC` districts do not read differently at a glance**, although act II
      makes them narrative
- [ ] **`generate()` retries with `seed + 1`**, so a run's city is the first nearby seed that
      passes rather than `run_seed` itself. Not a bug; worth remembering when reproducing from a
      seed

## Reassessed on 2026-09-01, and closed

- **The pending calm-ground multiplier is planned against a stale base** — *done.*
  `SLEEPINESS_CALM_ZONE_MULTIPLIER` is 21, which is the 1.5× taken on the correct base, and the
  correction travelled with it
- **A bug closed inside a design finding was never closed out** — *done.*
  `CrowdLanes.PRECINCT_OFFSETS` is six lanes across the whole width. The shape is worth watching:
  **a finding with two halves gets closed when the louder half is done**
- **M41's eight open boxes** — the milestone is merged and its work shipped; the boxes were never
  ticked. What genuinely remains is in M53 (T-junctions at the edge) and M49 (judged by eye)
- **M27's "nobody has played it"** — superseded. Seven playtests have happened since
- **M20's overtaking, eight-way driving and the crash event** — **parked with the player's
  agreement**, as *a conversation that is owed*, not as a thing nobody wanted
- **M17, the route map** — **backlogged by the player's decision.** The gap it closes is real and
  `docs/CITY.md` states it as a gap rather than papering over it
- **M52's "should more junctions be signalled?"** — parked, unasked-for, and it would repeal *"a
  property of the street rather than a scattering of them"*

---

## M10 — Polish

After the playtest work. There is no point polishing a loop that is about to be re-pitched.

- [ ] **Sound lines** — concentric arcs off a source on a pulse's rising edge, the visual form of a
      discrete noise. The last gap in the visual channel, and it comes **before** audio
- [ ] **Audio**, once the above is done and judged on its own: per-act beds, per-event cues, the
      baby's breathing as the diegetic version of the meters. Additive by design
- [ ] Main menu and settings; save/continue a run (`GameState` is already shaped for it, so this is
      serialisation rather than design)
- [ ] Accessibility: colourblind-safe meters, a telegraph-time multiplier, reduced motion
- [ ] Controller support
- [ ] Gate the dev flags behind a debug build, and move `_first_event_position` and friends out of
      `main.gd` into a `DevFlags` helper

---

## Open design questions

- [ ] **Is the nerve economy right?** Five since M35, and **asked for rather than derived** — the
      thing that made three too few was a defect rather than a difficulty, so if act I now reads as
      fair, five may be generous. The other side is still open: with five attempts and a retry
      costing only time, **is a lost day a punishment at all?**
- [ ] **Is the balance right?** Needs a run and a trace, not more arithmetic. *"The arterial is for
      crossing"* is still a claim about a player rather than about a probe
- [ ] **Is 14 days the right run length?** Act I is only 3 days, which may be too little time to
      learn a city before it starts changing
- [ ] **Could the meter bars be turned off entirely**, now that the pram carries four states of the
      baby? A question for somebody playing with them hidden rather than for more code
