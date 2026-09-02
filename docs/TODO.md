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

1. **M64** — nothing off the path. Design the rows first, then place them.
2. **M65** — the chalk mark is findable, and silent until it is found.
3. **M56** — the resistance is noticed.

**Playtest 19 is the freshest thing in this file** and its nine findings are filed against the
milestones that own them — M64 and M65 are new, and the rest went to M48 (barriers), M49 (the north
edge, the junction paint) and the small items (the robber in a building). Read it before picking
anything up.

M53's one remaining piece is specified and unordered — see its entry.

Everything below that is unordered and reassessed on 2026-09-01.

---

## M63 — It plays on a phone · asked for 2026-09-02

*(2026-09-02, of the live site: "I can't start the game on mobile — there is no space", "the title
screen requires me to press space". Asked whether that should become playable or become an honest
"needs a keyboard": **playable**.)*

**The page is published and a phone can do nothing with it.** Three screens are gated on
`ui_accept`, which is space or enter — the title, the between-days summary, and the pause — and
nothing anywhere in the game handles a touch or a click. Past them there would be no way to walk
either: movement is the four `move_*` actions and they are bound to keys alone.

- [ ] **Every screen advances on a tap.** The title, the day summary and the pause. Handle the
      touch event itself rather than adding a click, so the desktop is untouched and a stray mouse
      press cannot skip a day summary
- [ ] **A virtual stick, and it costs the game nothing.** Movement is one call —
      `Input.get_vector("move_left", "move_right", "move_up", "move_down")` in `Stroller`, already
      an analogue vector with a 0.2 deadzone — so a stick that presses those actions with a
      strength needs no gameplay change at all
- [ ] **A held run button, and never a stick threshold.** *(2026-09-02: "is it possible to have a
      separate button on mobile for running?")* Yes, and it is also the only correct answer.
      `Stroller` moves toward `input_dir * top_speed` with the **raw** vector, so a partly
      deflected stick is already a slower walk; making running the far end of that same push would
      turn the one deliberate act in the game into a gradient. Running is *"rarely worth it"* in
      the title screen's own words, day 3 exists to teach it, and every pursuit contract is stated
      over the gap between a walk and a run. A separate button held under the other thumb is what
      `Shift` already is
- [ ] **The controls appear only where they are used**, and every hint agrees with them: a screen
      that says *space to begin* on a device with no space is the same defect as the `q` that
      quit nothing
- [ ] **Landscape.** Letterboxed to 16:9 a portrait phone is a strip. The Web export preset can
      declare the orientation
- [ ] **Then measure the thing that might sink it.** `CrowdLanes` pushes the two walking lanes of a
      pavement 8px apart so there is a clear line between them worth aiming at, and it carries the
      measurement: forty seconds down an arterial lane centre costs 13.7 contacts and the midline
      costs 0.0 — **148 points of a hundred-point meter riding on those pixels**. Arrow keys hit
      that line and a thumb may not. **This is a question about whether careful-versus-careless
      survives a blunter instrument, and it is answered by playing it rather than by arguing it**

---

## M64 — Nothing off the path · asked for 2026-09-02

> "there is almost never anything when leaving a path. all events are on the path (restaurant
> yeller etc are all *for* the path they force you to switch street sides) but there is *nothing*
> off the path. we need more things for indicating the path (most events we have are for on the
> path) so we need to come up with more things first then actually add them"

> "also, there is no punishment for staying in the path"

**This is M50's gradient working as built and being the wrong shape.** The corridor is the cheapest
ground on every day by design, and the catalogue that fills it is a catalogue of *obstacles* — a
yeller, a café, a market stall, a reversing lorry — each of which is a reason to **cross the
street**, never a reason not to go somewhere. So the city can say *this way is expensive* and cannot
say *not this way at all*, and the route decision the whole game is built on has one correct answer
every day.

**The instruction is two-stage and the order is the whole of it: come up with the rows first, then
place them.** This is a catalogue design problem before it is a placement one, and playtest 19
carries the map that shows it.

**And then it stopped being a gradient at all.** *(2026-09-02: "maybe let's not make it a gradient
but instead always have it fully closed everywhere off the path just not necessarily with a full
road closure like a tree or car accident.")* **This overturns M50's central idea**, which is that
the corridor is the *cheapest* ground and everything else is merely dearer. Off the path is now
**closed**, and what varies is the picture rather than the price — a fallen tree, a car accident, a
skip, not one barrier row repeated.

**The city becomes a maze rather than a weighted grid**, and the route decision changes with it:
not *which way is cheaper* but *which of the open ways do I take*. That only remains a decision if
what stays open is the day's **route tree** rather than a single line, which is what
`RouteTree.for_day()` already grows — several strands, with the redundancy guarantee counted as a
max flow. So the policy is: the tree is open, everything off it is closed.

**Four things it collides with, none of them fatal and all of them to be answered before building:**

- **M45's trap, restated at full strength.** *A nudge that removes the decision is worse than a
  closure that does nothing.* Sealing everything off the tree is the largest possible nudge, so the
  number of strands the tree keeps open **is** the difficulty dial, and it stops being a placement
  detail.
- **The doorstep exemption.** The home is a notch with one exit; that street can never be sealed.
- **The winnability check becomes load-bearing.** `EventScheduler._ensure_the_city_is_still_walkable`
  already reasons over the **whole set** of blockers at once rather than one at a time — it asks
  `_park_is_reachable` with all of them standing and drops the widest until it is — so a pair that
  seals a street between them is seen today. What is new is how much weight that check will carry
  once sealing is the intent rather than the accident.
- **A fixed city is knowledge you earn.** The lattice does not move, so what a player learns still
  pays; what changes daily is which ways through are open. Worth checking that it still *feels* like
  earned knowledge rather than a new maze each morning.

**Two obstacles facing each other are already a closure, and that is the cheap way to build this.**
*(2026-09-02: "placing an obstacle that would force you to switch sides on both sides (eg restaurant
on one side and yeller on the other) is effectively a full closure and can be used to demarkate
paths.")* Every obstacle in the catalogue is *walk around it at a price*, and the price is paid by
crossing to the other side — so **two of them, one per side, leave no line to walk**. No new row is
needed for the mechanism; the catalogue already contains the wall, split in half and never yet
placed as one.

- [ ] **Decide how many ways through the tree keeps open**, because under a policy of *closed
      everywhere off the path* that number is the difficulty of the whole game and not a placement
      detail. It is also M45's trap in its sharpest form
- [ ] **The pictures, which are the part that needs inventing.** The mechanism is a pair of
      ordinary obstacles facing each other; what is missing is enough *kinds* of them that a sealed
      street does not read as the same barrier every time. A fallen tree and a car accident are the
      player's own two examples, and neither exists
- [ ] **Then place them off the tree**, and check the winnability guarantee still holds when sealing
      is the intent rather than the accident
- [ ] **Nothing arrives from off screen, and everything should.** *(2026-09-02: "the charging dog
      doesn't have an offscreen indication it should start further away and appear first as
      offscreen indicator", and "bikers / unleashed dogs all pop in in front of the player instead
      of starting off screen".)* One defect across every director-sited row: a thing that
      materialises inside the view has no approach, so the warning it owes is spent before the
      player can watch it being spent. `DangerEdge` already draws the screen-edge badge for anything
      off screen worth one, so the second half may be a consequence of the first — a dog sited
      inside the view has no offscreen phase to be announced in.

      **The care needed is the day-3 lesson.** `charging_dog` is deliberately unavoidable on the day
      it teaches running, and a dog that starts further away is a dog with more room to be walked
      around — which is the thing that placement was chosen to prevent

---

## M53 — The precinct is for walking

A precinct is paving frontage to frontage with nothing driving on it, on either axis, and a street
that meets one ends at its edge. What remains is that the ending is not *drawn* as anything.

- [ ] **Nothing draws a bollard, and the street just stops.** Six comments across the city and the
      crowd explain a precinct by saying a driver *"meeting a bollarded street"* diverts, and
      `docs/CITY.md` says a span stops short of the crossroads at either end *"which is where the
      bollards are"*. **There is no bollard anywhere in the game** — no sprite, no tile, no prop. The
      carriageway simply ends flush against the paving, which reads as the road running out rather
      than as a street that was closed on purpose. It is the same gap M48 names for the barrier that
      is blue-grey with no hazard marking: one picture per row passes and the picture still says
      nothing. What it wants is the smallest thing that says *this was done deliberately* — a line
      of posts across the mouth is the real-world answer and it is also the cheapest drawing in the
      list

---

## M65 — The chalk mark is findable, and silent until it is found · asked for 2026-09-02

Two findings from playtest 19, and they are halves of one thing: the first mark is announced when it
should not be, and it cannot be found when it should be.

- [ ] **The first chalk mark is named in the status line.** *(2026-09-02: "the first chalk mark is
      written in the status when it should not be.")* Seen in the screenshot as
      `resistance ....   somewhere out there: a chalk mark`, before the player had found anything.
      **This is the no-hint rule leaking**, and that rule is in `CLAUDE.md` under things
      deliberately not done: *the **first** encounter comes with no hint at all, because finding the
      difficulty dial is meant to be the player's own doing. After that the resistance speaks.* The
      HUD line is fed by `resistance_contact_available`, which does not distinguish the first mark
      from the rest
- [ ] **A mark that was never on screen was never placed.** *(2026-09-02: "it's hard to find the
      chalk mark remember it should be dynamically placed on the path where the player can see it.
      if it was placed but never on screen it should count as not placed and be placed on the next
      alley the player comes close to.")* *"Remember"* is right — placing it on the path is already
      the design; what is new is the **re-placement rule**, and it is a shape nothing in the game
      has: `ClosurePlanner` and `EventScheduler` both decide at dawn and stand, and this follows the
      player through the day.

      It is also what makes finding 1's silence fair: a first encounter with no hint is only
      reasonable if the thing can actually be come across

---

## M56 — The resistance is noticed

The city gets more dangerous the further into the subquest you are. **A task may not cost a nerve**
— a nerve is a rewind, not a resource, so there is nothing to trade.

**What the remaining items are stated against**, since the machinery under them exists: a row says
how it answers to the resistance with `EventDef.heat_response` — `NONE`, `PRESSES` or `HUNTS` —
`EventCatalogue.heated()` derives that row's shape at a progress level, and every one of those
shapes is validated on boot. The ladder has three rungs a player can name and both its upper ones
are built: `police_patrol` is **denser and then interested**, and `abduction` is **hunted**, taking
a bystander of its own while she watches and coming after her instead past three of four. The
reasoning, and what was rejected on the way, is in `DECISIONS.md` under M56.

- [ ] **"And other dangers like this"** — drafted and put back, and the vans have now set the
      precedent it was waiting on: a `HUNTS` row keeps `hard_fail`, moves neither population nor
      intensity, and gains its own threshold rather than sharing the patrol's. The candidates
      already in the catalogue are `checkpoint` (day 7, closes a street) and `night_raid`
- [ ] **Measure it against the nerves.** This makes the back half harder precisely for the player
      doing well at the optional path, and nobody has reached act III

---

## M60 — Ready for a GitHub Pages launch · asked for 2026-09-01

The game becomes a folder of static files a browser runs. Godot's HTML5/WASM export on the
`gl_compatibility` renderer the project already uses; **threads disabled**, so no
cross-origin-isolation headers are needed and GitHub Pages serves it as-is. No server: the game has
no networking. What Pages needs is preparation, not architecture:

**The site exists and it has an address.** *(2026-09-02: "I set up the website for the gh-page —
needs to be deployed via CI / gh-action — it's https://nappy.josuakrause.com/".)* So the two things
a workflow file could never do for itself are done: Pages is on for the repository and the custom
domain is set. **What is left is a build and a deploy**, and the address is a fact the rest of this
milestone now has to hold — a custom domain is stored as a repository setting rather than in the
artifact, so the deploy must not overwrite it and nothing in the export may assume a `/nappy/`
path prefix.

**What is built, so what is left has a floor.** Every dev flag and the snapshot key answer "not
given" outside a debug build, with the parsing in `DevFlags` rather than woven through `main.gd`;
the day's HUD is the clock, the two bars and the optional goal, with the header and status line
behind the same gate; `export_presets.cfg` is tracked with one Web preset on `gl_compatibility` and
threads off; `tools/export-web.sh` builds into `build/web/`; the run log is silent on a web build;
and `.github/workflows/deploy.yml` gates, exports and publishes on a push to `main`. The record is
in `DECISIONS.md` under M60.

**The site is live and the workflow built it.** The push to `main` that finished the build chain
also ran it end to end — gate, export, upload, publish — and `https://nappy.josuakrause.com/` serves
the game. The export had never completed anywhere before that run.

**What the first play of it changed.** The developer's readout is gated with the rest of the
furniture, `Q` is not offered where quitting does nothing, and the window letterboxes so every
player sees the same 640×360 of world. All three are in `DECISIONS.md` under M60.

- [ ] **A pause a thumb can reach.** `pause` is bound to a key alone, so on a touch-only device the
      pause screen arrives only when the between-days summary brings it. Every screen takes a tap
      now; what is missing is something on screen to tap for it
- [ ] **Landscape is declared where nothing reads it.** `export_presets.cfg` carries
      `progressive_web_app/orientation=1`, and the manifest that would carry it is not written
      unless the full PWA export is enabled — a larger change with unset icon paths. So an ordinary
      browser tab ignores it and a phone can still be held in portrait, where a 16:9 letterbox is a
      strip
- [ ] **The home arrow can land under a thumb.** `HomeArrow` hugs within 74px of a screen edge while
      pointing home, and the stick and the run button sit at that height on both sides — so during
      the return phase the one cue that says *this way home* can be under the finger steering her
- [ ] **A browser smoke pass** once it is deployed, at the real address: boots, keyboard input
      works, holds frame rate at the game's scale, and the title screen reads as the front door of a
      public page. itch.io stays the fallback host (it sets the isolation headers, so a threaded
      build would also work there)

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

**The regions are decided when the city is generated, and a region edge can never affect a path.**
*(2026-09-02: "what the regions are is determined at initial city creation and paths planning and
boundary placement are 100% orthogonal. a region edge can never affect a path — note this implies
the region boundaries cannot be through calm zones etc.")*

**This is the constraint the rest of the milestone hangs off, and it is stronger than it looks.**
The two systems never negotiate: `RouteTree` grows a day's routes knowing nothing about regions, and
the boundaries were drawn before any of them existed. There is no ordering problem, no feedback
loop, and no case where a wall makes a route worse — a boundary is laid where a wall changes nothing
about where anybody can get to, and the doors are then cut wherever the day's paths happen to cross
it.

**And it decides where a boundary may run.** A boundary through a park would wall off half of a
destination, which is a region edge affecting a path — so **no boundary crosses calm ground**, and
every calm area belongs wholly to one region. That is also what makes *"the region contains an
accessible calm zone"* a question with an answer: nothing is ever half in. The same reasoning
applies to anything else a route has to be able to reach or use as a whole, and the home is the
sharpest case — it is a notch with one exit, so a boundary anywhere near it is the doorstep problem
by another route.

The honest form of the rule is therefore a **generation guarantee, checked like the other ones**:
a boundary runs on ground where sealing it removes no destination and shortens no route. That is a
test over many seeds, not an argument.

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
- **"Contains a calm zone" is settled at generation; "accessible today" is not.** No boundary
  crosses calm ground, so which region a calm area is in is a permanent fact and a region with none
  at all is sealed for the whole run — a district she learns once and never has reason to enter.
  What is left open is the softer case: a region whose calm areas are all *spoiled* today has
  nothing in it today either. Sealing on that is the day's steering rather than the city's shape, so
  it belongs with the door placement and is answered there, not here.

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

      **No ordering problem, because the two are orthogonal by decree** — see the constraint above.
      The tree is grown knowing nothing about regions, the boundary was drawn before it, and the
      doors go wherever the two happen to meet. What is *not* in the tree is what a door costs:
      `RouteTree` has never priced an edge, so a route through three checkpoints and one through
      none look identical to it. That is a real gap and it is M45's open item — whether the tree
      can express "passable, at a price" at all
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

**M64 supersedes the gradient this milestone built.** *(2026-09-02: "let's not make it a gradient
but instead always have it fully closed everywhere off the path.")* Read M64 before picking up
anything here — the corridor being *cheapest* is the thing that is being replaced by the corridor
being *the only way through*, and an item below that tunes the gradient may be tuning something
about to be removed.

- [ ] **"Blocking events all over" is a catalogue question, not a placement one.** The gradient is
      built and measured, and the corridor is the cheapest ground on every day. What is not true is
      the density: raising the caps on the expensive rows is a real balance change and wants its own
      measurement. **Check this against M64 first** — under a closed-off-path policy the question
      changes shape
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
      **Reported from play on 2026-09-02** (playtest 19, with a screenshot): *"they're all placed
      with an offset that makes them clip into other things — the only barrier that is consistently
      correct is the full street closure."* That last clause is the sharpest thing said about this
      yet: **the closure is right because it spans the whole street**, so neither its offset nor its
      rotation can be wrong. Every other placement is a body narrower than the ground it sits on,
      which is the only case where either defect can show
- [ ] **A spread is always drawn east–west, whatever street it is on.** Nothing rotates an
      `EventInstance`. **A barrier's entire content is which way it faces**, and playtest 19 reports
      it from play: *"they're always horizontal even when they should be vertical."* The fix is a
      rule rather than a field — **a spread's rotation is a property of the street it stands on**,
      which the map can already answer
- [ ] **And it does not say what it is.** Blue-grey with no hazard marking. One-picture-per-row
      passes and the row still says nothing, which is that rule's own limit — municipal barriers are
      red-and-white for a reason

---

## M43 — Two that need a played run

- [ ] **The pause lesson fires while she is being held.** *(2026-09-02, from play: "the pause
      tutorial comes up when being detained (since you're not moving).")* `_teach_the_pause()`
      decides she has stopped by asking `Stroller.is_idle()`, which is velocity under 12px/s, so a
      `chatting_mother` conversation — which locks her movement input — reads as her choosing to
      stand still, and three seconds later the HUD offers her the pause key.

      **Wrong in the function's own terms**: it already teaches the pause at *"the first time she
      stops of her own accord"* and already excludes somebody who has not started. Being held is
      the third case in that list and the sharpest, since it offers her a key at the moment her
      controls were taken away.

      **And it has a second instance, so the rule is stated over the class.** The HUD has no
      `process_mode` of its own and inherits `ALWAYS` from `Main`, so it keeps counting while the
      tree is paused — behind the day summary, the pause screen and the title. The rule is *idle
      **and** nothing is holding her still*: not detained, and the tree not paused
- [ ] **The run lesson does not show, and it must.** *(2026-09-02, from play: "the run lesson
      doesn't show at all anymore — it should always show for the day 3 lesson.")*

      **The cause, given by the player and confirmed by reading the retry path:** *"when I die the
      next time it won't show — you need to reset the flag when the player dies on day 3."*
      `_taught_run` in the HUD is once per **run**, and a lost day is not a new run: losing a nerve
      calls `_start_day()` again on the same HUD instance, which is never rebuilt. `_teach_the_day()`
      already resets the line, its timer and the walked-today state on every day start, and
      deliberately does not reset the once-per-run flags — so the second attempt at day 3 is the
      first one that has already spent its lesson.

      **The fix is that the flag belongs to the attempt, not to the run**, which is the game's own
      rule about nerves arriving in the HUD: a nerve is a rewind, and a rewound day should not
      remember what it taught. Reset it whenever the day being started is `Tuning.RUN_TAUGHT_DAY`,
      so the lesson fires on every attempt at that day including the first.

      **And the neighbouring case is a question, not part of the fix.** `_taught_pause` — the *"Esc
      to pause"* line, also once per run — has the same shape but is not tied to a day at all: it
      fires the first time she stops of her own accord. Whether a rewind should erase that too is
      the player's call, and nothing should reset it unasked
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
- [ ] **People walk out onto the border and vanish there.** Reported again from play on 2026-09-02
      — *"the north edge still has people and cars walking into the mountain and disappearing"* —
      so it is people **and cars**, and the north edge is where it was seen.
      **`CrowdAgent._blocked_ahead` returns `false` for a tile out of bounds**, so the one wall that
      should stop them reports as clear. Likely *out of bounds is blocked* and nothing else — check
      against the **spine exits**, the one place a car is meant to leave the map. Overlaps M53
- [ ] **Whatever fixes one border has to be stated over *a border*.** The first pass wrote four
      sides four times, which is one bug per side waiting to happen
- [ ] **Junctions are four-way where an arm dead-ends — reproduced, with a picture.**
      *(2026-09-02, from play: "the intersections are not t intersections", of the **north edge**.)*
      **Seed 2927659514, day 1, standing at tile (80,1)** —
      `docs/evidence/run-2026-09-02T181431-seed2927659514-ffa2830-061s-asked.png`. The zebras on the
      north–south streets run all the way to the border and a crossing box is painted on an arm with
      nothing beyond it. Three earlier candidates were checked and were correct, which is why this
      sat as *not reproduced* for so long: the map's own border is the one place an arm genuinely
      dead-ends. **The same frame shows a car and two pedestrians standing on the out-of-bounds
      ground above the top pavement**, so this and the vanishing-walkers entry above are one cause
      seen twice — whatever decides what is beyond the last tile is answering *street* in both.

      **It is every side, not the north one.** The same seed at tile (5,88) is the **west** border
      with the identical painted crossings running into it —
      `run-2026-09-02T181431-seed2927659514-ffa2830-045s-asked.png`. Whatever fixes this is stated
      over *a border*, which is the item two above this one.

      **And there is a working case to copy, in one frame with a broken one** —
      `run-2026-09-02T181431-seed2927659514-ffa2830-030s-asked.png`, tile (13,87). *(2026-09-02:
      "here is an example of a proper closed off side of the intersection (towards the right to the
      park) and an improperly closed off side (towards the south it should be closed off but
      isn't).")* The arm running **east into the park** is terminated correctly — the carriageway
      stops and the pavement carries on across it — while the arm running **south**, with nothing
      beyond it either, is drawn as though the street continued.

      **That is the most useful thing anybody has said about this**, because it makes the question
      *what is different between those two arms* rather than *where is the bug*. `docs/TODO.md`'s
      own M49 wording already guesses at the answer — *"where the arm beyond is not a street at all
      — a park, a calm zone's absorbed corridor, the shore"* — so the case that works is the one the
      generator was told about explicitly, and the fix is to state it over *anything* that is not a
      street rather than over the list of things somebody remembered
- [ ] **A main road's junction is four dotted crossings, not two.** *(2026-09-02: "minor issue — for
      a main street intersection all four crossings should be lines instead of zebra crossing since
      all four are controlled by the traffic light".)* `GroundTiles._crossing_variant` already draws
      the dotted pair rather than a zebra for a **main road's** crossing, with the reason recorded in
      `CityGenerator._street_tile`: traffic on a main road obeys the light rather than giving way, so
      the crossing is a *timing* problem and a zebra there is paint promising a gap-hunting one. The
      player's point is that the property belongs to **the junction rather than the arm** — where the
      spine crosses an ordinary street, one light governs all four crossings, so the two on the side
      street are currently painted as a promise the traffic does not make
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

- [ ] **The robber can be placed inside a building, where he is stuck for ever.** *(2026-09-02:
      "the robber can be placed inside buildings which makes him unable to move at all.")*
      `alley_robbery` places on `ALLEY` tiles and pursues, and `EventInstance._walkable_step` clamps
      a chase to walkable ground — so a robber who begins inside a building is not merely oddly
      sited, **every step he tries is refused**. His lethal radius still travels with him, which
      makes an invisible fatal spot inside a wall. Fix it where he is placed, not by letting a
      pursuer walk through buildings
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
- [ ] **A pursuer streamed out mid-chase comes back having forgotten it.** `EventInstance.resume()`
      restores the age and the distance travelled but not `_noticed_at`, and a fresh instance starts
      with that at `INF` — so a `pursues_within` row streamed out after it has noticed her returns
      `is_waiting()`, standing where the day planted it. It is not new and it is not currently
      dangerous: `alley_robbery` has had it since the mechanic was built, and the heated patrol that
      surfaced it can never be `hard_fail`. **`tests/test_heat.gd` pins the behaviour rather than the
      one the field name implies**, so a fix fails there first. The fix is `resume()` carrying the
      notice, and it has to be checked against every `pursues_within` row rather than the one that
      found it
- [ ] **A big building can be built over a precinct's own pavement.** Measured on **seed 24757**:
      two tiles inside a precinct span are not walkable, because something with a footprint was
      placed across the corridor the span runs down. A precinct is the best ground in the city to
      bring a meter down on and its whole design is *paving frontage to frontage* — a hole in it is
      the one place that sentence stops being true. Nothing in the placement rules asks whether a
      footprint lands on a precinct span; the fix is a constraint where big buildings and calm zones
      choose their ground, not a repair pass afterwards
- [ ] **`chat` is written and undocumented.** `EventManager` logs a `chat` entry when
      `chatting_mother` starts a conversation, and the table of entry kinds in `docs/TELEMETRY.md`
      has no row for it — so a reader of a run log meets a kind the documentation does not admit
      exists. One row, and the check that would have caught it is whether anything asserts the two
      lists agree
- [ ] **The dusk map draws the route she actually walked.** *(2026-09-02: "the dusk picture should
      contain the entire route a player took.")* Two maps are written per day — one at dawn and one
      at dusk — and today they differ only in which resistance marks are opaque. **Nothing anywhere
      records where she went**: `TelemetryMap.render()` takes the map, the closures, the day's route
      tree and the event plans, and the log holds positions only at the moments something happened
      (a tile, a road crossing, a contact). So the one picture that could answer *what did she
      actually do* shows the same city as the one drawn before she left the house.

      **Where it goes is decided by the telemetry rules**: a per-frame read belongs in
      `TelemetryObserver`, which already holds the player and looks at her position every frame, and
      **nothing about this may touch gameplay** — no RNG, no consumed values, no gameplay class
      learning that it is being watched. Sample by **distance rather than by frame** so the trail is
      bounded and framerate-independent: at one point per tile a 180-second day is a few hundred
      points.

      Three things to get right rather than discover. The **dawn** map keeps drawing nothing, since
      there is no route yet and a picture that lies about which one it is would be worse than no
      picture. A **lost day** restarts the trail, because a rewound day was not walked. And the
      trail has to read *against* the corridor the map already draws — the whole value is seeing
      where she went versus where the day expected her to
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
- [ ] **What is still dev-only inside `main.gd`.** `DevFlags` took the flag *parsing* out; what
      stayed is the code that acts on it — `_first_event_position` and the `--spawn` target lookup,
      both of which read the live city and would have made the move a rewrite rather than a
      relocation. Worth finishing the next time the file is opened for another reason

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
- [ ] **Could the meter bars be turned off entirely** — deferred, not open. *(2026-09-02: "we can
      keep the bar for now and think about the diegetic face later on.")* The minimal HUD keeps the
      bars and drops the status line beside them, so what gets tested first is whether the pram
      alone can carry the baby's state on the half that was cut.

      **What comes back with it is a face**, which is a bigger idea than hiding a bar: the same
      shape M10 already records for audio, where the baby's breathing is *"the diegetic version of
      the meters"*. A face would be that in the visual channel — the meter read off the baby rather
      than off a strip at the bottom of the screen. Not designed, and it needs the playing that the
      status-line cut is about to produce
