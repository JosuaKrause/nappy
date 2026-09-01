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
- [ ] **The abduction van takes somebody, and then it takes you.** *(2026-09-01: "we need abduction
      vans that normally just abduct people but start trying to abduct the player if she is part of
      the resistance.")* `abduction` today does neither: an unmarked van that **idles**, static,
      250px field, `hard_fail` inside 54px, a 4.6s telegraph, `first_day` 8, up to four a day. It
      never moves and nothing is ever taken — the abduction is entirely in the name and in what
      happens to *her*.

      **The second half is the small one.** `heat_response = HUNTS` and the van gains `pursues`,
      which the machinery already supports; it keeps `hard_fail`, since a pursuer is exempt from
      the clearance rule. Two things are not arithmetic. A van cannot chase at van speed —
      `Tuning.validate_pursuit` allows 112 to 148px/s against a 168px/s run, so a hunting van
      creeps after her at about a fast walk, and whether that reads as menacing or as comic is a
      **screenshot question**. And at *what* progress it starts hunting is a separate number from
      the patrol's `HEAT_INVESTIGATES_LEVEL` (2) and should not be assumed to be the same one.

      **The first half is the one with a precedent in it, and the crowd's shape constrains it.**
      Nothing in the catalogue has ever acted on the crowd: events never push, the world sums
      `contribution_at()`, and the one existing coupling is a *modifier* rather than a command —
      `CrowdAgent.startle()`, which a bump or a car horn uses to raise what that body emits. And
      the crowd is a population of **the field around the player** rather than of the city, spawned
      and recycled as she moves, so a pedestrian is not a persistent individual and an abduction
      can never be a lasting fact about the world. It is a **scene**, and it only means anything
      where she can see it happen.

      **Decided on 2026-09-02: the van draws its own victim** — a scripted figure belonging to the
      event, with no crowd coupling at all. It reads identically from the street, it works on an
      empty one (act III's streets are deliberately empty), it is testable headless, and it leaves
      untouched the rule that events never push at the world. *Rejected: taking a real `CrowdAgent`
      and removing it. It is closer to the instruction's own words — the crowd would be the thing
      in danger, and she is one of the crowd — but it would be the first event in the game to delete
      a body, it needs an answer for the street with nobody on it, and no headless test could rely
      on a walker being there to take.* The cost taken with it is that the victim is scenery, and
      scenery cannot also be you.

      **And it hunts from 3 of 4.** *(2026-09-02: "after the patrol but still early enough to
      happen more than just once".)* So the ladder has three steps a player can name — denser, then
      interested, then hunted — with the last one arriving on its own rung rather than alongside
      the patrol's, and with days left to be met in more than once.
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

- [ ] **Gate the developer's furniture first — this is the prerequisite, not a polish item.**
      `--seed`, `--day`, `--spawn`, `--ending` and the rest ship in the build today (M10 records the
      debug gate as owed). A public build guards every dev flag and the snapshot key behind
      `OS.is_debug_build()`, and the M10 item to move them into a `DevFlags` helper is naturally the
      same work. **The HUD's header and status line are the same category** and go behind the same
      gate — see the entry below
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

      **The scope is answered, and it is not "two HUDs".** *(2026-09-02: "the current HUD is for
      debugging — for the real game (the web version) it must be minimal.")* The header, the status
      line and everything else being cut is **debug output that has been shipping as if it were the
      game**, so this is the same work as gating the dev flags: the minimal HUD is the game, and
      what is left goes behind `OS.is_debug_build()` with the rest of the developer's furniture.
      That also decides where it lives — beside the `DevFlags` helper, not in a web-only branch
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

> "checkpoints are not the same as closures. closures are eg construction sites where the road is
> fully closed. a checkpoint is a barrier across the street where there are guards on the side-walks
> with a hut and a gate over the roadway to let cars through (cars need to slow down to a full stop
> before the gate opens and they can go ahead again). the player walks to a hut gets detained inside
> and then spawns on the other side afterwards. it works in both directions with the same cost each
> time"

**A checkpoint is not a closure and the difference is the whole design.** A closure — roadworks, a
construction site — takes a street away, and `docs/CITY.md`'s `absent_segments` is how the city says
so. **A checkpoint never removes a route; it prices one, and the price is the same every time in
both directions.** It is a crossing you can always make and never make for free, which is a thing
the game does not have yet: every other cost in it is either avoidable by routing or fatal.

**Both survive, and they are two different things.** *(2026-09-02: "let's keep both the checkpoint
and a barrier around.")* The existing row — a recurring event rolled onto `ROAD`/`CROSSING` tiles up
to six times a day from day 7, whose own docstring calls it *"the first event that takes a route
away rather than making it expensive"* — is **the barrier**, and it keeps doing exactly that. The
new structure is **the checkpoint**, and it never takes a route away. Having both is what makes
either legible: a street held by soldiers that you cannot pass, and a street held by soldiers that
you can pass at a price, are only a decision when the city contains both.

- [ ] **The barrier needs its own name, because the new thing has taken `checkpoint`.** Two rows
      that draw armed men across a street and mean opposite things about whether you can get
      through, sharing a word, is the *one picture per row* rule failing at the name instead of at
      the drawing. `barricade` already exists in act IV and is something else — whatever was
      stacked there by somebody — so this is a third name, not a merge. Its picture stays: poured
      concrete and a hazard stripe is a street being **held**, which is still true of it

**Its anatomy, in the player's words, and each part lands on a different system:**

- **A barrier across the street**, with **guards on the sidewalks** and a **hut**. So it is not one
  body on one tile — it spans the full width of a street, footway to footway, which nothing in the
  catalogue does. `EventDef.obstructs_radius` is a *circle* whose radius is half a silhouette, and
  half a street is not a silhouette.
- **A gate over the roadway.** Cars come to a **full stop**, the gate opens, they go on. The
  machinery for making traffic stop and start at a place already exists and is not in the crowd —
  `src/city/traffic_signals.gd` and `traffic_light.gd` hold the cycle, `src/crowd/crowd_lanes.gd`
  and `crowd.gd` are what obeys it. A gate is a signal with a different rule and a different
  drawing, which is a much smaller thing to build than it sounds.
- **She walks to the hut, is detained inside, and comes out the other side.** A **teleport**, and
  nothing in this game has ever moved the player. It is also the answer to the question a barrier
  spanning a street would otherwise raise — how does a pram get past a thing with no gap in it —
  and it means the crossing is never a matter of finding a way through the geometry.
- **Both directions, the same cost each time.** So it is a toll rather than a puzzle: nothing about
  it is learnable except that it is there, which is what makes it a *routing* fact.

**How the two are placed, and it is one rule for both.** *(2026-09-02: "for the barricade and
checkpoint placement divide the map into regions and create barricades along the full perimeters —
add checkpoints instead of barricades only where the paths cross the region boundaries.")*

**The perimeter is a wall with doors in it.** Barricade every tile of a region's boundary; wherever
a walkable route crosses that boundary, put a checkpoint there instead. So the wall is complete —
there is no gap to find and no way round — and every way through is a toll. That is what makes both
rows mean something: the barricade is what you cannot pass, the checkpoint is the only place you
can, and neither reads as anything without the other beside it.

It also answers, by construction, the thing that would otherwise sink the idea. A ring of
impassable structure is exactly the shape of sealing her in, and *the doors are placed at every
crossing rather than at a chosen few*, so a region she has business in can never become unreachable
however the lattice came out. The winnability check stops being an argument about placement and
becomes a count.

**The regions partition the map.** *(2026-09-02: "regions should be a partition of the map.")* Every
tile belongs to exactly one, with no gap between two of them and no tile in both. It is worth
stating because the alternative — regions as a few marked-off districts in an otherwise open city —
is what a first implementation drifts into, and it quietly gives back the way round that the
perimeter exists to remove.

**A region with nothing in it for her gets no doors at all.** *(2026-09-02: "a region that contains
no accessible calm zone should have no checkpoints / gates. this might sound counter-intuitive from
a realworld point of view since such a region wouldn't ordinarily make sense but from the game
perspective there is no reason to ever enter the region so we shouldn't even provide the option —
the player won't notice the difference.")* Its perimeter is barricade the whole way round and she
can never enter it.

**This is the game's own rule beating the simulation's**, and it is the same principle as the one
that keeps a quest marker out of this game: offer a choice only where there is a choice. A door
into ground with no calm area behind it is a route the player can spend a day's clock discovering
is worthless, and the discovery teaches nothing, because *there was never anything there* is not a
fact about the city she can carry to tomorrow. Sealing it costs her nothing she would have wanted
and removes a way to lose a day to no purpose.

Two things it forces, and neither is optional:

- **The region she starts in always has doors.** If her own region holds no calm area and is sealed,
  the day is unwinnable from the first frame. This is the doorstep exemption's shape at city scale —
  the home is a notch with one exit, so sealing that street seals her in — and it lands the same
  way: the rule is stated over *a region*, and then the one she is standing in is exempt from it.
- **"Accessible calm zone" is asked of the city or of the day, and which one is open.** A region's
  *boundary* stands for the run; its *doors* are re-cut daily off the day's paths (see below). So
  the sealing rule could be a permanent fact — this region never has anything in it, wall it for the
  whole run — or a daily one, where a region whose calm areas are all spoiled today gets no doors
  today. The first makes a sealed district a landmark she learns once; the second makes the sealing
  part of the day's steering, and puts it in the same hands as the door placement. Answer it with
  the door placement rather than separately, because they are the same decision asked twice.

- [ ] **The regions are a city-generation question, not an event-placement one.** A perimeter is a
      decision about the map, so what needs designing first is what a region *is* — the quadrants
      either side of the spine, a growth from the home block, or something the lattice already
      knows about. This is the largest piece and everything else waits on it
- [ ] **The barricade is structure; the checkpoint is placed by the day.** Neither is a recurring
      event rolled onto a tile by weight. A perimeter is a fact about the city, generated with it
      and standing for the run, and M45's first item is **permanent impassable structure, reusing
      `absent_segments` rather than reinventing it** — that is this, so build them together or build
      that one first. The doors are the day's, and the thing that already places per-day openings
      and closings on a fixed map is `ClosurePlanner`, which is where their planning belongs rather
      than in the event scheduler
- [ ] **The wall stands for the run and the doors are re-cut every morning.** *(2026-09-02: "it is
      okay to move checkpoints on a daily basis — reassess where to put them depending on the paths
      of the current day.")* So the boundary is permanent and *which* of its crossings are gated is
      a decision the day takes, off `RouteTree.for_day(map, day)` — the day's corridor, a pure
      function of the city's seed and the day number. A crossing that is a checkpoint today is
      barricade tomorrow.

      **This makes the gate the sharpest routing instrument in the game, and it is M45's open item
      arriving with a mechanism.** M45 wants *"a closure that points"* — not *does this lengthen
      the route* but *does this stop her committing to a direction that cannot win today* — and
      records the trap beside it: **a nudge that removes the decision is worse than a closure that
      does nothing.** Choosing which doors are open is exactly that instrument, and it is exactly
      that trap, at full strength. Two doors is a choice; one door is a corridor with a toll booth

      **Ordering, because it can go circular.** The tree is grown first and the day is planned
      against it, so gates sited where the tree crosses a boundary are consistent by construction —
      the routes go through the doors because the doors were put where the routes went. What is
      *not* in the tree is what a door costs: `RouteTree` has never priced an edge, so a route
      through three checkpoints and one through none look identical to it. See the M45 item on
      whether the tree can express "passable, at a price" at all
- [ ] **The detention is `chatting_mother`'s mechanism.** *"Reuse the other woman with baby logic"*:
      `EventDef.detain_seconds` locks her movement on first contact inside `detain_radius`, and
      `Stroller.detain()` runs the lock out through the ordinary friction rather than stopping her
      dead. **`EventDef.validate()` currently refuses `detain` on anything `hard_fail` or that
      `pursues`** — a conversation is a cost, never a threat — which a checkpoint satisfies, since
      being held up is exactly a cost. What it does not cover is the teleport at the end of the
      lock, which is new
- [ ] **"A bit of excitement" is the second half, and it is not the detention.** A detained player
      is standing still, and standing still is where `EXCITEMENT_DECAY_IDLE` pays back nothing — so
      a checkpoint charges her twice over unless the intensity is set knowing that
- [ ] **What the doors cannot fix is the toll on every park.** Reachability is settled by placing a
      checkpoint at every crossing of a region worth entering, and that is not the same as winnable:
      a region whose calm areas all sit behind a detention is a day priced differently from one that
      does not, and the difference is a real number. Measure it against a day's clock, do not argue
      it. **The check the tests carry is not "every boundary has a door"** — it is that every region
      holding a calm area she can use has one, and that the region she starts in always does
- [ ] **What it does to the corridor.** `RouteTree` grows the day's routes and `Corridor` answers
      *is this tile on one*. A toll is a cost on an edge, and the route tree has never had one —
      check whether it can express "passable, at a price" before assuming it can

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
