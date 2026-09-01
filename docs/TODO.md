# TODO

**The queue. Open work only.** A ticked item is history the moment it is ticked, so completed
entries live in [DECISIONS.md](DECISIONS.md) with their measurements and rejected options intact —
search it for the noun before designing anything. Progress-tracking lives only there: no ticked
boxes, no "Done:" paragraphs, no branch names or status words in headings here.

Read [HANDOFF.md](HANDOFF.md) first for the state of the tree.

Each milestone is one git branch, merged to `main` with `--no-ff`. `[~]` marks an item somebody is
mid-way through.

---

## The order

1. **M54** — the robber stops at walls, and three rows that never arrive.
2. **M56** — the resistance is noticed.
3. **M59** — the chatting mother. *Position provisional: the design is the player's (2026-09-01),
   the slot in the order is not — it can move.*

M53's one remaining piece is a question for the player, not a task — see its entry.

Everything below that is unordered and reassessed on 2026-09-01.

---

## M53 — What remains is a question, not a task

The rest of M53 shipped; the record, with the measurements and the not-reproduced claims, is in
`DECISIONS.md` under M53.

- [ ] **The precinct junction — two recorded instructions are in tension, and the player decides.**
      The queue called the junction between two precinct arms a bug ("still asphalt with zebras");
      `CityGenerator._street_tile`'s own docstring defends the current behaviour as intentional —
      a driveable street crossing a precinct does so over a zebra six tiles deep. Measured: no
      `ROAD` tile is ever produced at an internal precinct junction, only `SIDEWALK`/`CROSSING`.
      The question: should a real street's carriageway survive through a precinct it merely
      crosses, or is the six-tile zebra the design and the queue's sentence the stale one?

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

## M59 — The chatting mother · asked for 2026-09-01

*(Player: "I have an idea for a new entity -- another mother with child. when getting too close one
gets caught up in a conversation that takes 5s and consumes 25% excitement. if the baby is already
sleeping it's a pure time loss if it's not it bears overstimulation risk.")* The readings taken —
"consumes 25%" means **adds 25 points to the meter when the baby is awake**, and "pure time loss"
means **asleep, the chat emits nothing at all** (a `SLEEPING_SENSITIVITY`-scaled dose could wake
the baby, which would not be pure) — are recorded in `docs/PLAYTEST-18.md` finding 4 and can be
corrected from there.

**Why it is a route decision:** the cost flips sign with the baby's state. Outbound-awake she is a
quarter of the lose meter; homebound-asleep she is only five seconds of clock, on the leg where the
clock is the resource. No other row changes meaning across the day like that. The first new
mechanic in it is **time under compulsion** — nothing else takes the controls away.

- [ ] **The row.** `event_catalogue.gd` gains `chatting_mother` (named for what she is — nothing
      in `src/` carries a narrative name): a paced pavement fixture like the yeller — `paces`
      along a short sidewalk beat, so she is *at* a place and streaming guarantees she is met —
      with a small ambient field (person-scale: intensity near the passer-by's 4.2, outer radius
      tight) so brushing past her costs a normal close pass when no conversation triggers.
      `first_day` 1 if the balance suite still passes — act I is the social act — else 2;
      `max_per_day` 2; not `hard_fail`, does not pursue
- [ ] **The trigger.** Two new `EventDef` fields, `detain_seconds` (default 0 = never) and
      `detain_radius`. `validate_event()` gains: if `detain_seconds > 0` then
      `detain_radius < inner_radius <= outer_radius`, and the row must not be `hard_fail` or
      pursue. Default `detain_radius` for the row: small enough that the far lane of a two-tile
      pavement (lanes one tile apart) can never trigger it — under 32px, start at 26. The
      counterplay is distance, exactly like everything else that is not a pursuer
- [ ] **The capture.** When the player enters `detain_radius` of an instance that has not yet
      chatted: the stroller's movement input is ignored for `detain_seconds` (velocity runs out
      through the existing friction; pause still works; the run key does nothing). The existing
      idle rules price the stop — idle drains sleepiness and freezes excitement decay — so no new
      meter rule is needed for the time cost. **One conversation per instance**: after it, she is
      spent as a detainer and departs (walks off like a `dog_walker`), so nobody is trapped twice
      by the same body
- [ ] **The meter.** While the conversation runs and the baby is **awake**, the instance emits
      25/`detain_seconds` per second (5/s at full strength inside its inner radius; the player is
      inside it by construction) — net +25, since idle decay is zero. While the baby is **asleep**
      it emits nothing: the contribution is gated on the baby's state, read, never written —
      excitement stays a pure query and `City.total_excitement_at` still adds exactly two things
- [ ] **The drawing.** One picture per row: an adult with a pram, palette-shifted so she cannot be
      mistaken for the player, with two postures — strolling and talking. The talking posture is
      the telegraph that a capture is running. **No exclamation mark** — that cue is reserved for
      danger, and she is a cost, not a threat; the cues skill governs anything drawn
- [ ] **Telemetry.** A `chat` entry when a conversation starts: position, duration, the baby's
      state, and what the meter did — it answers this milestone's own open question, which is
      whether a forced +25 reads as fair
- [ ] **The tests** (`tests/test_events.gd`, alongside the other per-row rigs): walking a rig into
      `detain_radius` locks it for `detain_seconds` (position delta near zero) and releases it;
      awake, the meter gains 25 within tolerance; asleep, excitement is unchanged and sleepiness
      stays pinned at 100; a pass outside `detain_radius` on the same pavement never triggers; a
      second approach to the same instance never re-triggers; the whole catalogue still passes
      `validate_event()`, and `tests/test_balance.gd` still passes with the row live on its
      `first_day`
- [ ] **The docs.** An `EVENTS.md` row in the catalogue table; a short "conversation" paragraph in
      `MECHANICS.md` next to the idle rules it leans on
- [ ] **Open, deliberately:** whether a chat should ever be *worth seeking out* (a rumour, a hint)
      — parked, because the meters must stay the only currencies until the player asks otherwise

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

---

## M10 — Polish

After the playtest work. There is no point polishing a loop that is about to be re-pitched.

- [ ] **Sound lines** — concentric arcs off a source on a pulse's rising edge, the visual form of a
      discrete noise. The last gap in the visual channel, and it comes **before** audio
- [ ] **Audio**, once the above is done and judged on its own: per-act beds, per-event cues, the
      baby's breathing as the diegetic version of the meters. Additive by design
- [ ] Main menu and settings; save/continue a run (`GameState` is already shaped for it, so this is
      serialisation rather than design)
- [ ] **A web build** *(asked 2026-09-01: "can we use github pages to put the game on a page?")* —
      Godot's HTML5/WASM export on the `gl_compatibility` renderer the project already uses, hosted
      as static files on GitHub Pages. Export with threads disabled (or ship the
      `coi-serviceworker` shim), because Pages cannot set the cross-origin-isolation headers a
      threaded build needs. No server: the game has no networking
- [ ] Accessibility: colourblind-safe meters, a telegraph-time multiplier, reduced motion
- [ ] Controller support
- [ ] Gate the dev flags behind a debug build, and move `_first_event_position` and friends out of
      `main.gd` into a `DevFlags` helper — the audit measured the dev-only code at roughly a third
      of `main.gd`, so the helper is worth doing before the file is next touched

---

## Open design questions

- [ ] **Does a picked-up-but-unperformed resistance instruction expire at the end of its day, or
      wait?** Left open by decision until the pairs can be walked. The code currently **waits** —
      an incomplete perform step is re-offered each subsequent day; the only expiries are the
      poster wall's `deadline_fraction` and a rider event finishing, both inside one day
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
