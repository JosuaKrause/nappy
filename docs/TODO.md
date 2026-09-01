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

1. **M56** — the resistance is noticed.
2. **M60** — ready for a GitHub Pages launch. *(2026-09-01: "can we use github pages to put the
   game on a page?" and "add a step for preparing for github pages launch.")*

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

## M56 — The resistance is noticed

The city gets more dangerous the further into the subquest you are. **A task may not cost a nerve**
— a nerve is a rewind, not a resource, so there is nothing to trade.

**The three forks were put back and answered on 2026-09-02.** What they settled:

- **Heat is a declarative field on `EventDef`**, not a per-row switch and not extra days. A row
  states *that* it answers to heat and `Tuning` holds what each answer costs, so it is read off the
  def exactly the way the blocking role is (`EventScheduler._role_for` derives the role from the def
  rather than anyone setting it per placement). *Rejected: adding progress to the day number — it
  reuses `budget_for` for free but also moves `first_day`, so act III vans reach act II and the
  calendar in `docs/EVENTS.md` stops meaning what it says.*
- **The patrol's escalation moves population, intensity and whether it investigates.** Not its outer
  radius: widening the 185px field also widens what the telegraph has to buy, since
  `Tuning.required_telegraph_time` is stated over the gap between the two radii.
- **A pursuer is exempt from the clearance rule**, and the exemption is the third case rather than
  the van losing `hard_fail`.

- [ ] **Danger scales with `GameState.resistance_progress`.** `EventDef` gains a `heat_response` —
      `NONE`, `PRESSES`, `HUNTS` — and the catalogue derives a **heated copy** of a row per progress
      level, so nothing downstream of the day's plan has to know heat exists. Progress is an integer
      0..`RESISTANCE_GOAL`, so the set of shapes is **finite and every one of them is validated on
      boot** — which is the answer to the load-time contract problem: `Tuning.validate_event` and
      `validate_pursuit` check the catalogue in the shape it booted in, so a def that changed
      mid-run would be validated only in its harmless shape
- [ ] **The patrol presses.** `police_patrol` today is mobile at 74px/s along roads and crossings,
      intensity 10, radii 44/185, up to 12 a day, from day 4, and not `hard_fail` — which the
      instruction keeps. Heated it is more numerous, costs more to stand near, and past a threshold
      **investigates**: it runs its route until she comes close, then turns and follows.
      **A pursuer that has a route runs it until it notices her** — derived from `pursues and mobile
      and is_waiting()`, so investigating needs no field of its own. The contract to watch is that
      every clause of `Tuning.validate_pursuit` is written about a *lethal* chase ("running opens
      more than the radius that ends the day"), and this is the first pursuer that never kills
- [ ] **The abduction van takes somebody, and then it takes you.** `abduction` today does neither —
      a static idling van, 250px field, `hard_fail` inside 54px. **"Normally just abduct people" is
      the first authored event with a victim**; nothing in the catalogue has ever acted on the
      crowd. And a hunting van inherits `pursue_speed` under `RUN_SPEED`, so it creeps at a fast
      walk — a screenshot question, not an arithmetic one
- [ ] **Write the pursuer exemption down.** M28's rule is that nothing else happens inside a lethal
      event's field, and M50 exempts only the off-corridor `WALL` role. The clearance rule is about
      *places*, and a pursuer has no place — which is already true and unwritten of `charging_dog`
      (day 3, sited in front of her) and `alley_robbery` (day 8, lethal inside 30px, chases at
      130px/s), both of which carry a lethal radius around with them today with nothing checking
      their clearance
- [ ] **"And other dangers like this"** — drafted and put back, after the vans, because the vans
      are where the precedent gets set. The candidates already in the catalogue are `checkpoint`
      (day 7, closes a street) and `night_raid`
- [ ] **Measure it against the nerves.** This makes the back half harder precisely for the player
      doing well at the optional path, and nobody has reached act III

---

## M60 — Ready for a GitHub Pages launch · asked for 2026-09-01

The game becomes a folder of static files a browser runs. Godot's HTML5/WASM export on the
`gl_compatibility` renderer the project already uses; **threads disabled**, so no
cross-origin-isolation headers are needed and GitHub Pages serves it as-is. No server: the game has
no networking. What Pages needs is preparation, not architecture:

- [ ] **Gate the dev flags first — this is the prerequisite, not a polish item.** `--seed`,
      `--day`, `--spawn`, `--ending` and the rest ship in the build today (M10 records the debug
      gate as owed). A public build guards every dev flag and the snapshot key behind
      `OS.is_debug_build()`, and the M10 item to move them into a `DevFlags` helper is naturally
      the same work
- [ ] **A tracked Web export preset.** `export_presets.cfg` is gitignored because presets often
      carry credentials — a Web preset carries none, so track it (adjust the ignore with a comment
      saying why), configured for threads off. Decide the viewport/canvas policy (the game renders
      640×360 and scales)
- [ ] **`tools/export-web.sh`** — headless export (`--headless --export-release Web`) into
      `build/web/` (already gitignored), with the missing-export-templates failure caught the way
      the other tools catch a missing Godot binary
- [ ] **Telemetry on the web is off.** *(2026-09-02: "the github pages version should not emit
      telemetry".)* `user://` maps to browser storage in a web build: nobody collects those logs and
      the folder can grow unbounded on a stranger's machine. Off for web exports, by an OS
      feature-tag check
- [ ] **The day's HUD loses everything that is not the day.** *(2026-09-02: "the on-screen info
      should be minimal (only timer + bars + status line) but even status line I think we should be
      able to drop — the status is visible on the entity. only maybe the current optional goal
      should be visible. the day / nerve / etc info should not be there — it is already shown
      between days — during the day this info is just noise and the player can pause to see it.")*

      What the HUD shows today, so the cut has a floor: a **header** reading
      `day N / 14   act N   nerves ***`, the **clock**, the two **meter bars**, a **status line**
      (the baby's state, why she is not settling, and a city-wide source when one is running), and
      a **resistance line** (`resistance *...` plus the current step's title). Kept: the clock, the
      bars, and the optional goal. Cut: the header. **The status line is the interesting one** —
      it goes because the pram already carries four states of the baby, which is the same claim as
      the open question about turning the meter bars off entirely, and the two should be answered
      together. What has no home once it goes: `stall_reason()`'s *"not settling: …"* and the
      *"nowhere is quiet"* note for a city-wide source, neither of which the pram draws.

      **The scope is a question and it is not answered here.** The instruction was given about the
      Pages build, and its reason — *during the day this info is noise* — is about the game rather
      than about the host. Ask before building it web-only, because two HUDs is a maintenance cost
      taken on a guess
- [ ] **The deploy workflow** — GitHub Actions on push to `main`: install Godot + export
      templates, run the export, publish `build/web/` to Pages (`upload-pages-artifact` +
      `deploy-pages`). **Blocked on a decision only the player can take: the repo has no GitHub
      remote today**, and publishing it is theirs to do; the workflow file can sit ready in the
      repo before the remote exists
- [ ] **A browser smoke pass** once an export exists: boots, keyboard input works, holds frame
      rate at the game's scale, and the title screen reads as the front door of a public page.
      itch.io stays the fallback host (it sets the isolation headers, so a threaded build would
      also work there)

---

## M61 — A field is an ellipse · asked for 2026-09-02

> "fields should be ellipses, not circles. the excentricity should be determined by movement speed.
> the rationale is that an entity moving towards you has more of an effect than if it moves away or
> orthogonal. the entity itself lives in one of the focus points"

**A change to the emission model itself, and it is the first one since the falloff shape.** Today
every field is a disc: `Tuning.falloff(distance, intensity, inner, outer)` prices being near a thing
by distance alone, so a fire engine bearing down on her and one that has just gone past cost exactly
the same at the same range. The instruction says the direction of travel is part of the price, and
gives the geometry to say it with — an ellipse whose eccentricity is a function of speed, with the
entity standing at a focus rather than at the centre, so the field reaches further ahead of a moving
thing than behind it.

- [ ] **Where the shape lives.** `contribution_at()` on `EventInstance` is one function and the
      falloff is one function in `Tuning`, so the arithmetic has one home. What has more than one
      home is everything that *reasons* about a radius — the telegraph contract
      (`Tuning.required_telegraph_time`, stated over the gap between the inner and outer radii),
      the placement spacing (`EVENT_SPACING_ANY` / `EVENT_SPACING_SAME`), the clearance a lethal
      row keeps, the streaming radius, and the denial radius a park spoiler is measured by. **Each
      of those is a question about "how far", and an ellipse has two answers.** Decide per rule
      whether it takes the long axis (safe, and it widens every clearance in the game) or the short
      one, before writing any of it
- [ ] **The contract has to be restated over the worst direction.** A player who starts walking away
      the instant an event becomes visible must get clear before it hurts. Against an ellipse
      pointed at her that is a different sum, and a version stated over the mean radius would pass
      while the encounter it describes is unfair — the same failure `Tuning.pursuit_standoff()`
      exists to stop, one system over
- [ ] **A stationary thing keeps its circle**, by construction: eccentricity from speed means zero
      speed is a disc. So the change is *only* about the mobile rows, which is a much smaller blast
      radius than it first reads as — and the pursuers are where it will be felt
- [ ] **And it has to be visible.** The falloff is invisible today and that is fine because it is
      symmetric; a field that is stronger in front of a van is a routing fact the player can only
      learn by being told or by dying. Ask what draws it before deciding it is free

## M62 — Checkpoints that divide the map · asked for 2026-09-02

> "checkpoints in the later acts should divide the map into segments/areas. that is the player
> should be forced to cross checkpoints to reach parts of the map and the checkpoints live alongside
> the full perimeter of each region. checkpoints can reuse the other woman with baby logic. the cost
> can be time (and a bit of excitement) while being detained until released"

**This is M45's answer arriving from the other side.** M45 measured that a closure cannot change a
route while there are nine destinations and a full grid — 350 closures across ten seeds moved the
best route once — and concluded that a closure's job is direction rather than distance. A checkpoint
ring is the version that *does* change distance, because it is not one barrier on one street: it is
the whole perimeter of a region, so there is no way round, only a way through at a price. It is also
M47's "main road as a soft block" generalised from one street to a boundary.

- [ ] **The regions are a city-generation question, not an event-placement one.** `checkpoint`
      today is a recurring row rolled onto `ROAD`/`CROSSING` tiles up to six times a day from day 7.
      A perimeter is a decision about the map, so what needs designing first is what a region *is*
      — the quadrants either side of the spine, a growth from the home block, or something the
      lattice already knows about
- [ ] **The cost is a detention, and the mechanism already exists.** *"Reuse the other woman with
      baby logic"* is `chatting_mother`: `EventDef.detain_seconds` locks her movement on first
      contact inside `detain_radius`, and `Stroller.detain()` runs the lock out through the ordinary
      friction rather than stopping her dead. **`EventDef.validate()` currently refuses `detain` on
      anything `hard_fail` or that `pursues`** — a conversation is a cost, never a threat — which a
      checkpoint satisfies, since being held up is exactly a cost
- [ ] **"A bit of excitement" is the second half and it is not the detention.** A detained player
      is standing still, and standing still is where `EXCITEMENT_DECAY_IDLE` pays back nothing —
      so a checkpoint charges her twice over unless the intensity is set knowing that
- [ ] **The winnability guarantee has to survive it.** Every day must leave a route to a calm area,
      and a ring of checkpoints around the region the home is in is the exact shape of sealing her
      in. It is the doorstep exemption's problem at city scale

## M50 — What the corridor still owes

- [ ] **"Blocking events all over" is a catalogue question, not a placement one.** The gradient is
      built and measured, and the corridor is the cheapest ground on every day. What is not true is
      the density: raising the caps on the expensive rows is a real balance change and wants its own
      measurement
- [ ] **`cyclist` and `loose_dog`'s caps no longer mean what they say.** Both rows now arrive via
      the director's single queue and its 11–26s pacing rather than being map-placed, so a day
      fields far fewer than `max_per_day` (14 and 24) reads as promising — the caps' meaning
      changed while the numbers stood still. Whether the encounter rate is right is a measurement,
      not an inference; the record is in `DECISIONS.md` under M54
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
- [ ] **The log says when she is stuck** *(asked 2026-09-01: "put a note in the telemetry when the
      player doesn't move even though they press something")*. A throttled `blocked` entry from
      `TelemetryObserver` — movement input held for about a second while displacement stays near
      zero → one entry with position, direction and duration, throttled like the bump entries, not
      per frame. It makes an immobile rig visible in its own log (a `--walk` run that never left
      the doorstep currently reads as a run) and gives a human pressing into an invisible blocker
      a trace. Observer-only; gameplay untouched

---

## M10 — Polish

After the playtest work. There is no point polishing a loop that is about to be re-pitched.

- [ ] **Sound lines** — concentric arcs off a source on a pulse's rising edge, the visual form of a
      discrete noise. The last gap in the visual channel, and it comes **before** audio
- [ ] **Audio**, once the above is done and judged on its own: per-act beds, per-event cues, the
      baby's breathing as the diegetic version of the meters. Additive by design
- [ ] Main menu and settings; save/continue a run (`GameState` is already shaped for it, so this is
      serialisation rather than design)
- [ ] **A web build** — grew into its own milestone: M60, "Ready for a GitHub Pages launch"
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
