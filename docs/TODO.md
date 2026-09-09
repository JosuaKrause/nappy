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

### Illustrated actor registration and assembly

**This is Codex's parallel track, worked beside the gameplay queue rather than ahead of it.**
*(2026-09-09: "illustrated actors is currently a sidearm for codex to work on".)* The SVG drawings
are the game's graphics until the illustrated presentation passes its visual gates, so a drawing
item in the gameplay queue is drawn as SVG.

The repair follows [ILLUSTRATED-GAMEPLAY-FIXES.md](ILLUSTRATED-GAMEPLAY-FIXES.md),
PLAYTEST-32's connected-body and legacy comparison requirements, and the M84 record in
DECISIONS.md. Keep the illustrated renderer opt-in. The supplied urban/mother illustrations
define style; `docs/reference/` supplies real-world structure and posture.

- [ ] Finish the modular source-art gate with eight complete views, clean alpha and isolated
      anatomy. The manifests identify same-facing arm/profile-leg reuse, shared diagonal walker
      edge pixels and the mustard SW facing ambiguity. Replace those source limitations while
      preserving interchangeable parts; flattened cards do not satisfy layered animation.
      Preserve PLAYTEST-44's selected transparent v3 pram. See DECISIONS.md under Illustrated
      registration audit and Limb attachment repair for the source findings and implemented fit.
- [ ] Review the registered actors at gameplay scale before expanding variants. Inspect all eight
      facings and smooth walk, run, stop, turn and reset, including the corrected resting knees.
      The static contact review in DECISIONS.md predates the resting-knee correction. Headless
      attachment and displacement checks do not establish motion quality or visual acceptance.
      Keep the legacy drawings at their fixed horizontal comparison offset.
- [ ] Resolve [PLAYTEST-45](PLAYTEST-45.md)'s directional posture and pram-quality findings within
      the connected-body repair: mustard and red legs slant during east/west travel and spread
      outward during north/south travel. Review knee bend, ground stride, projected lift and
      source rest axes independently; matching endpoints alone is insufficient. Fit per-facing
      mother-to-handle spacing to natural arm reach, preserving the selected v3 pram and logical
      collision. Trace the pixelated pram to the actual visible binding, source alpha, complete
      assembly scale and inherited filtering before choosing a repair. Confirm the illustrated
      player loads in the actual test checkout after imports. Use the repeatable procedure in
      the illustrated-png skill; see DECISIONS.md under Texture integration process.
- [ ] Resolve [PLAYTEST-42](PLAYTEST-42.md)'s additional anatomy and pram compositing defects.
      Inspect the preserved timed PNG sequence: each leg must read as one hip–knee–ankle chain,
      without a painted bend plus a second solver bend. The baby must sit within the seat and
      its facing-specific occlusion, not appear pasted over the stroller. Reconcile these with
      PLAYTEST-45's existing natural-reach and directional-gait repair; keep both reports intact.
- [ ] Implement and review [PLAYTEST-42](PLAYTEST-42.md)'s higher-resolution rendering of the
      **current view**, preserving visible world extent, actor size, HUD size and physical window.
      Render more pixels and downsample them; do not zoom out or merely enlarge logical coordinates.
      Compare actual render-target dimensions and the same scene framing, input mapping, resize
      behavior and screenshot/burst capture. Inspect filtering and retained detail without declaring
      anatomy or animation fixed by resolution. The wider-view interpretation is rejected; its
      history is in DECISIONS.md under Animation anatomy and camera experiment. The debug
      `--illustrated-render-scale 2` experiment is in the tree and unverified; its open checks are
      in HANDOFF.md. Preserve legacy presentation and the illustrated opt-in while it is reviewed.
- [ ] Review whole-actor sorting in live overlaps and integrate roof reveal, then a representative
      illustrated live street.
      Preserve current joystick/tap choice and the event and crowd silhouette halos, including
      their attributed contribution and easing. Connect crowd halos to the animated PNG assembly;
      the current callback traces the offset legacy comparison. Extend vehicles, authored events,
      environment and screens only
      after their prerequisite visual gates.

### Gameplay queue

Prioritised on 2026-09-09, in the player's words where a sentence decided a place.

1. **M62** — checkpoints that divide the map into regions. *("M62 should be next.")* M45's three
   items are folded into it, since a perimeter of permanent structure and a door that points are
   what M45 asked for and M62 specifies. It carries the reachability-grid confirmation the small
   items used to hold.
2. **Alongside it, each on its own branch**, because none of the three touches the city's shape:
   - **M64** — the eight seal pictures, drawn as SVG. *("M64 we can do in parallel — svg is the
     main graphics for now.")*
   - **M56**'s build item, the other rows that hunt. *("M56 is also related to the other items to
     work on right now.")* Its measurement against the nerves waits, because reaching act III
     waits: *"I wanna wait reaching act III until those things are done."*
3. **M61** — a field is the Minkowski sum of the body and a kernel. *("M61 is kind of important
   but not the immediate next item.")*
4. **M65** — the protester who points, revisited once M62 has landed. *("M65 we need to revisit
   after M62.")* Revisited rather than built as written: a walled city with checkpoints may change
   what finding a mark is like, and the entry is re-read against that before its pose is drawn.
5. **M96 to M100**, in no order between them: the teaching day, the calm areas, the empty acts,
   the corridor's density after the sealing, and the consolidated small work. Each was rewritten on
   2026-09-09 from an older milestone after checking which of its items the code had already
   answered; the record of what was found built is in `DECISIONS.md` under "The queue
   reprioritised".
6. **Reaching act III**, which M56's measurement against the nerves needs.
7. **M101**, the fire found before the engine. *("M101 can go after the Act III stuff.")*

**Nothing in this queue is held back for being a drawing.** *(2026-09-07: "let's remove the note
about not working on graphics because it causes much confusion.")* Every item is ordered on what it
does to the route decision, the same as everything else. **M64** and **M65** are each a milestone of
only its drawings, and each is ordinary open work.

**A milestone still holds either drawings or not**, so that ordering one never parks work that needs
no artist.

**M79 is tabled rather than queued.** It is the city seen at an angle — a presentation change with
the lattice left cardinal — and it is written down so that whoever chooses the projection does it
with the code's constraints in hand. It is not queued and it is not rejected.

**[PLAYTEST-49.md](PLAYTEST-49.md) is the newest session and it is the prioritisation above**, plus
one bug — events spawning inside a fully blocked street — filed at the top of M100's defects,
one correction, that the non-adjacency rule does not cover parks yet, filed in M97, and one design
instruction, the fire found before the engine, filed as M101.

**[PLAYTEST-48.md](PLAYTEST-48.md) is the newest gameplay session, and its one note is built**:
the signal head north of a junction, which faces up the screen, shows its back and no lamp. The
record is in `DECISIONS.md` under M95.

**[PLAYTEST-47.md](PLAYTEST-47.md)'s two notes are built**: a car comes out of the tunnel and off
the bridge as well as going in, and `tools/run.sh` runs the import pass when a pulled checkout is
missing an imported texture. The record is in `DECISIONS.md` under M94.

**[PLAYTEST-39.md](PLAYTEST-39.md)'s one finding, the tunnel, is built.** The fade is inside the
portal's opening, the mountain stands above it, and the road into the mouth is asphalt rather than
a crossing; the record is in `DECISIONS.md` under "The tunnel swallows the road". Half of it was a
re-report of playtest 24's fifth finding.

The halo's design and playtest reasoning are in `DECISIONS.md` under M92.

**[PLAYTEST-45](PLAYTEST-45.md) covers illustrated texture integration; the connected-body
review also includes [PLAYTEST-43](PLAYTEST-43.md).** The open repairs are listed above.

**[PLAYTEST-37.md](PLAYTEST-37.md) finding 5, the caret inconsistency, is built as M93 and recorded
in `DECISIONS.md`.** Its junction
and border findings are recorded in `DECISIONS.md` under M53.

**[PLAYTEST-35.md](PLAYTEST-35.md)'s seven findings are all built.** Six of them landed inside M90
and M89 rather than being filed against them, because those milestones had not merged when the
findings were reported — **nothing merges carrying a defect that was already found**. The seventh,
the buttons that were rounded rectangles rather than circles, was parked by the player on sight and
then turned out to be a two-line fix; the record is in `DECISIONS.md` under "The disc is a circle
at whatever size the container gives it".

**[PLAYTEST-34.md](PLAYTEST-34.md)'s ten findings are all built** — seven as M90 and three as M91.
It is the played answer M88 and M87 were waiting for, and it is mostly a report of things that do
not respond: a button that never changes under a press, a stop circle at twice its drawn size, and
a joystick drag whose reference point walks away with the camera. **Two of its findings are
re-reports** — the pressed button was asked for in playtest 33 and the dog's short notice was
measured in playtest 20 — and each entry says so rather than designing it a second time.

**[PLAYTEST-33.md](PLAYTEST-33.md)'s thirteen findings are all built.** It is the report M83 asked
for: the two focal points a touch aims from were built and drawn as nothing, and the answer is that
they moved outward and downward and are drawn. Eight of the thirteen were M85, four raised and
extended M77, and the one question in it was M86; all three are recorded in `DECISIONS.md`. **What
playtest 34 says about it is that the pressed-button fix reached the colour and never reached the
draw state** — see M90's own item.

**[PLAYTEST-29.md](PLAYTEST-29.md)'s seven findings are all built.** Three of them were instructions
the project already had and had read as repealed by something else, and the file is worth reading for
that alone — two of its sentences are the player saying so. The record is in `DECISIONS.md` under
M83.

**[PLAYTEST-28.md](PLAYTEST-28.md)'s four findings are built** — the game has one control scheme
and no question about which: a press sets a direction she walks until the next press, a press on
her stops her, a double press runs, and the pause button in the top right is the only thing drawn.
The ending screen's own continue button, which meant nothing there, is gone too. The record is in
`DECISIONS.md` under M82.

**[PLAYTEST-27.md](PLAYTEST-27.md) is the second session on the released page and the first played
on both a laptop browser and a phone, and every one of its six findings is built.** The release
arrives under versioned URLs, the shared link carries an opaque card, the continue and restart
buttons are on both screens, a press acknowledges itself before the day it starts blocks the frame,
and the two findings about the controls themselves — tap mode dead on a laptop, and the drag stick
— are answered the same way M82 answers playtest 28: one scheme, chosen nowhere, that a mouse
click drives on every build. The record is in `DECISIONS.md` under M76, M80 and M82.

**[PLAYTEST-26.md](PLAYTEST-26.md) is the one before it and every finding in it is built**, across
the two halves of M76 and M82's own deletion of the title screen's two circular mode buttons.

**[PLAYTEST-25.md](PLAYTEST-25.md)'s nine findings are built** — the
first phone session on the built mobile game and the first human verdict on the sealed city. The
record is in `DECISIONS.md` under M73, M74 and M75. **What it leaves open is a played question and
a shaped one.** Played: the barrier rows are silent and the two ambient radii are tight, and nobody
has walked a city that costs what this one now costs. Shaped: **M61**, which is what the tightened
radii are a stopgap for — the player's *"that number was so big because it was a point source
before"* is the reason those numbers move again once a field takes the shape of its body.

**The instrument they are read with now exists.** The dusk map draws the walk over the plan — where
she went, where she ran, and which events actually reached her — so *did the corridor have to be
walked* and *what did a day cost* are questions a picture can answer. See `DECISIONS.md` under M66,
and `docs/TELEMETRY.md` for what the map draws. This is also the instrument playtest 20 was read
with — a full seven-day run's fourteen maps, copied into `docs/evidence/`.

**Playtest 22's findings are every one of them built** — the two
barrier-placement defects, the doorstep that could be sealed in, the winnability check that proved
reachability rather than survivability, the route that ran alongside the main road, and the seals
thinned so the guidance stops reading as guardrails. The record is in `DECISIONS.md` under M64.
**Playtest 21** is the one before it — *"the city feels way empty now"*, answered by the sealing.
Read [PLAYTEST-22.md](PLAYTEST-22.md) and [PLAYTEST-21.md](PLAYTEST-21.md) before picking M64 up:
what they asked for is built and unplayed, so the next report on it is the thing that matters.

**Playtest 20's four findings** went to M69 (a reachability gap, now built), M65 (a chalk-mark idea),
M97 (a calm-area spoiling inconsistency) and M96 (a measured lead-time gap on the post-tutorial
`charging_dog`).

**Playtest 19's nine findings are filed against the milestones that own them** — M64 and M65 are
new, the barriers went to M48 and are built, and the rest went to M49 (the north edge, the junction
paint) and the small items (the robber in a building).

Everything below is in the order the gameplay queue above gives it, and was reassessed on
2026-09-09.

---

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

**M45 is folded in here, on 2026-09-09, because its three items are this milestone's items seen
earlier.** M45 measured that *a closure cannot change a route while there are nine destinations and
a full grid* — 350 closures across ten seeds changed the best route to the nearest calm area once —
and concluded that **a closure's job is direction, not distance**. Its three items land as follows:

- **Permanent impassable structure, reusing `absent_segments`.** The dead ends and the big
  buildings already go through `absent_segments`, the set of lattice segments every route search
  treats as closed. The region perimeter is the rest of that item and is the second item above.
- **A closure that points** — *"does this stop her committing to a direction that cannot win
  today"* — is the door placement, and M45's trap is restated at full strength in the third item
  above: **a nudge that removes the decision is worse than a closure that does nothing.** The
  game's one verb is *where do I walk*.
- **A soft version, events rather than barriers, placed to say *not this way*.** Built by M64's
  `SealPlanner`, which puts an obstacle pair on every street off the day's tree; the record is in
  `DECISIONS.md` under M64.

- [ ] **Confirm the perimeter design against the reachability grid before building it.** This
      milestone was written against the block-level reachability model that no longer exists:
      reachability is now `ReachabilityGrid`, the tile map contracted into two-tile cells, and
      `ClosurePlanner` refuses a calm area's access streets outright — a filter the items above
      were written without. Read `DECISIONS.md` under M69 first, then restate *no boundary crosses
      calm ground* and *a region she has business in always has a door* as checks over cells rather
      than over block sides. M48 needs no such confirmation, since its rotation rule reads
      `CityMap.corridor_offset()`, which is geometry rather than reachability

**The draft answer to "what a region is", 2026-09-09, read off the code and put back for the
player.** The facts it rests on: the lattice is 11×11 blocks with 264 street segments and one
north–south main road, chosen between the third corridor from either edge; there is no east–west
main road. Calm areas number eight or nine a city and are never placed in the outer ring of blocks,
inside the home's clearance, or in the two block columns beside the main road. District tags
(`CIVIC`, `COMMERCIAL`, `INDUSTRIAL`) are dealt to blocks from a shuffled list and form no
contiguous areas, and the two precincts are three blocks each — so nothing the lattice already
knows about can be a region. And an alley is not a street segment, so any boundary stated over
segments alone has a hole wherever an alley or a courtyard archway joins two sides of it — the same
blind spot M69 found in block-level reachability.

- **A region is a set of street segments, not of blocks.** The walkable city *is* its streets, so
  a partition of the segments is a partition of where she can be, and a boundary is a **junction
  where two regions' segments meet**, with the barricade or checkpoint standing *across* the
  segment on one side of it — the picture the player drew, and the shape every barrier in the game
  already has. This is the key space `RouteTree.is_on_the_tree()`, `ClosurePlanner` and
  `SealPlanner` all use, so *a route crosses a boundary* is one lookup: a tree segment whose
  neighbour across the junction is another region's.
- **The main road is ordinary ground to the partition, so a boundary may cut it.** A checkpoint
  across the main road is the one place the gate over the roadway means something — cars come to a
  full stop and the signal machinery (`TrafficSignals`, `CrowdLanes`) is what obeys it — and it
  leaves *paths cross the spine and never run along it* untouched. **The alternative, named so it
  is cheap to pick:** the spine as a permanent boundary between an east and a west region, which
  gates every crossing the tree makes and collides with `docs/CITY.md`'s *she may cross wherever she
  likes*.
- **Regions are grown at generation from a fixed number of seed segments, over atoms.** An atom
  is a calm lot with all of its access segments, and any two segments an alley or an archway
  joins; regions grow by breadth-first flood over the segment graph from spread-out seeds, an atom
  at a time, so **no boundary runs along a calm area's frontage and no alley crosses one** by
  construction rather than by retry. The home street and its trunk join whichever region grows to
  it; precinct spans are one atom each. The count is one `Tuning` constant — **four is the
  recommendation**, since two is a single line and eight or nine (one per calm area) puts most of
  the 264 segments behind a wall and never lets *a region with no calm area gets no doors* fire.
- **The wall is the day's, planned beside the closures, not `absent_segments`.** A crossing is a
  checkpoint today and barricade tomorrow, and `absent_segments` is fixed for the run and merged
  into every route search unconditionally, so it cannot carry a per-day door. So M45's *reuse
  `absent_segments`* is reuse of the **category** — a segment every route search treats as closed
  — and the placement is `ClosurePlanner`'s: the boundary junctions are a fact of the map, and each
  morning every one the day's tree crosses is cut as a door and every other is walled.
- **The checks are floods over cells, not counts over segments.** With every boundary barrier
  down as blocked tiles, `ReachabilityGrid.flood()` from the doorstep must reach exactly the home
  region's streets and nothing across a boundary — that is what catches an alley or an archway a
  segment-level check cannot see; with only the day's doors open, every region that holds a calm
  area she can use is reached; and the home region has at least one door on every day. Sized like
  `tests/test_route_tree.gd` and `tests/test_seals.gd`, over several seeds and the days of each act.

**What is the player's to decide before an agent gets this**: that a region is segments rather
than blocks; that the main road may be cut by a boundary rather than be one; the count; and that
the wall is planned daily rather than being permanent structure — the last of which narrows M45's
own wording and is asked rather than assumed.

---

## M64 — Eight seal pictures · asked for 2026-09-02

**All that remains here is eight drawings.** The sealing itself is built and its record is in
`DECISIONS.md` under M64; the off-screen arrivals item this milestone also carried became M77 and is
built, recorded there too.

**Its open question is a played one** — whether a walled city reads as a route decision or as a
maze. Everything below is the reasoning the pictures are drawn against.

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

**Off the path is closed, not dear, and that overturns M50's central idea.** *(2026-09-02: "maybe
let's not make it a gradient but instead always have it fully closed everywhere off the path just
not necessarily with a full road closure like a tree or car accident.")* M50 makes the corridor the
*cheapest* ground with everything else merely dearer; under this the corridor is the *only way
through*, and **what varies is the picture rather than the price** — a fallen tree, a car accident,
a skip, not one barrier row repeated.

**The placement comes first and the pictures are independent of it.** *(2026-09-03: "how's that 8
seal pictures gonna solve the issue? the task can be solved right now — having more pictures makes it
nicer with variety but it's independent from actually placing things".)* This reverses the order this
entry carried, and the reversal is the player's own — the earlier instruction was *"we need to come
up with more things first then actually add them"* (2026-09-02), given before the pair mechanism was
worked out.

**The catalogue can seal a street today, from day 1, with nothing new drawn.** A soft seal is one
ordinary obstacle on each pavement, and the rows are already there: `construction` (Roadworks) has
`obstructs_radius` of `SIDEWALK_SPREAD_MAX` — 32px, so 64px wide, exactly a pavement band — from day
2, and `cafe_tables` (48px), `market_stall` (56px), `delivery_van` (pinned at the kerb) and
`homeless_yeller` are all available from day 1. For a hard seal, `barricade` obstructs 62px — 124px,
the whole street — and this entry already says it should be *"placed as a seal rather than rolled as
an event"*. So *empty off the path* is fixable now, and what the eight pictures buy is that no single
barrier becomes the city's signature.

**The city becomes a maze rather than a weighted grid**, and the route decision changes with it:
not *which way is cheaper* but *which of the open ways do I take*. That only remains a decision if
what stays open is the day's **route tree** rather than a single line, which is what
`RouteTree.for_day()` already grows — several strands, with the redundancy guarantee counted as a
max flow. So the policy is: the tree is open, everything off it is closed.

**Two of its three preconditions are built, and each was a precondition for a different reason. The
third is the first item below and is not.**

- **M69 put the tree on cells.** A tree made of whole block sides would have put every park crossing
  and every alley in the city off the tree, so *closed everywhere off the path* would have sealed the
  shortcuts the city is built around. `RouteTree` now grows on `ReachabilityGrid` cells, so a branch
  can cut a park corner or run down an alley.
- **M48 made a spread face its street.** A seal is a thing lying *across* a street, so its whole
  content is which way it faces, and every barrier in the game used to be drawn east–west whatever
  street it stood on. `EventInstance._spread_is_vertical()` now asks `CityMap.corridor_offset()` of
  both of a tile's coordinates and swaps the layout onto local Y on a north–south street. **It answers
  a street tile only**: a junction, a square, a park and a courtyard all keep the unrotated lay along
  local X, which is worth knowing before ~150 seals a day are placed against it.
- **A corner is refused as a site for anything that lies across a street**, which is where M48's two
  fixes both switched themselves off — a junction belongs to two streets at once and has no single
  direction to be wrong about. That was the third precondition and it is built, along with the second
  barrier defect playtest 22 named: a spread's end caps no longer draw wider than it obstructs. The
  record, with the measured cost and the screenshot that remains unexplained, is in `DECISIONS.md`
  under M64.

**The whole tree stays open, and everything off it is sealed a full block at a time.**
*(2026-09-03, answering the two questions this milestone could not be built without, and corrected
the same day by playtest 21.)* So the difficulty dial is set at its most forgiving end and the
sealing at its most complete: every calm area still worth reaching keeps its branch, both of its
routes where the map allowed a second one — a day plans **about fifteen routes to five to seven
areas** (`MIN_CALM_BLOCKS` 5 to `MAX_CALM_BLOCKS` 7, which the constant's own comment calls
*"places to go"*) — and what is closed is not merely the rim but everything the tree does not touch.
The city's day has 264 lattice streets in it, so this is most of them.

**The unit of sealing is a block, not a street.** *(2026-09-03, playtest 21: "we wanted full blocks
off-path which can be hard or one normal event on both sides of the street".)* An earlier reading of
this entry said *every street off the tree*, which is a street-level unit and leaves a block with one
side on the corridor getting its other three closed one segment at a time. A block-level unit closes
a whole block's worth of frontage, so the off-path city reads as **solid** rather than as a scatter
of blocked segments. Each sealed street is still either strength — hard, or the ordinary-event pair.

**The density on the corridor is already right, and nothing about it changes.** *(2026-09-03, the
design restated in full: "on the path there should be a normal amount of events that remain passable
— that looks like it is the case here. off the path there should be fully blocking events on every
segment — there should be no (easy) way to go off the path".)* The first clause is a **verdict on
what is built**, given after the measurement below: the corridor's event load is normal, the rows on
it stay passable, and the milestone touches none of it. `EventScheduler._copies_of` keeps offering a
friction row `EVENT_CORRIDOR_WEIGHT` (4) extra copies of a corridor tile, and `Corridor.depth()`
keeps pricing what it prices.

**So M64 is one change, not two: everything it does is off the path.** An earlier reading of this
entry had the corridor's discount as *"the other half of superseding M50"* and queued a second item
to remove it. That item is gone — it was aimed at a cause the measurement could not find, and the
design says the on-path half is already as it should be.

**What *"no (easy) way"* rules in and out.** Not *no way*: a soft seal takes both pavements and
leaves the carriageway to be risked, and an alley stays open at 3.0 excitement a second. Those are
the priced ways through and they are the point. What has to stop existing is the **free** way — an
off-path segment she can simply walk down, which today is most of them.

**Which park to walk to therefore stays exactly as open a question as it is today**, and what
changes is that the answer can no longer be reached any old way. That is the deliberate order: the
policy is the change being measured, and the strand count is a dial to turn afterwards if the whole
tree turns out to be too generous.

**Three consequences of *every street off the tree*, and each is load-bearing rather than a detail:**

- **The doorstep is exempt, and the join to the corridor is on the tree.** The home street is
  deliberately not coloured by any branch — *"a door is not a route"* — so a rule stated as *seal
  every street off the tree* would seal her in on the first frame, which is `CLAUDE.md`'s doorstep
  exemption arriving in a new place. `RouteTree._grow_the_trunk()` closes it: a BFS from the home
  street outward to the nearest cell already on the tree, so `is_on_the_tree()` is true of the join
  and the sealing's own rule covers it without an extra exemption.
- **The seals are their own placement pass with their own budget.** ~150–200 sealed streets is two
  bodies each, which is an order of magnitude past the day's event budget, and that budget exists to
  decide *variety*, not to price the city's walls. A seal is a fact about where she may walk, so it
  is planned where the day's closures are planned — beside `ClosurePlanner` — and counted separately
  from the catalogue's density. **Chosen where the design was silent, and cheap to overturn:** the
  alternative is seals drawn from the ordinary event budget, which would leave a day with either no
  walls or no events.
- **The winnability check stops being the guarantee and becomes an assertion.**
  `EventScheduler._ensure_the_city_is_still_walkable` drops the widest blocker until a park is
  reachable again; against seals placed *by construction* off a tree that is walkable by
  construction, there is nothing to repair and dropping one would open a hole in a wall. The
  guarantee moves to the placement — this is the project's own rule that closures are checked before
  they are accepted, never repaired afterwards — and the check becomes what proves it.

**Two things it collides with, neither fatal:**

- **M45's trap, restated at full strength.** *A nudge that removes the decision is worse than a
  closure that does nothing.* Sealing everything off the tree is the largest possible nudge. The
  answer taken is that the tree is left at full width so the decision survives inside it, which
  makes **the tree's own strand count the difficulty dial** — turned only once this has been walked.
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

**A seal comes in two strengths, and both were asked for.** *(2026-09-03.)* A **hard** seal spans
the street frontage to frontage and nothing gets past it — the fallen tree, the accident, the burst
main. A **soft** seal is the obstacle pair: both pavements taken, and the carriageway still there to
be risked. The distinction is real because of the cross-section — a street is sidewalk 2 tiles, road
2, sidewalk 2, and `Tile.is_walkable()` refuses only `BUILDING`, so the asphalt is walkable ground
with traffic on it. The `construction` row's own docstring is the sentence that names the
consequence: *"since a street is sidewalk|road|sidewalk, the road is always still there, so it costs
time and exposure, never the day."*

**So how closed a street is becomes a variable alongside what it looks like**, which is the answer
to M45's trap in its own terms: a soft seal removes the easy way and leaves a decision — *walk the
carriageway with the cars, or go round* — where a hard seal removes the street. Neither of them may
ever be the only thing between her and every calm area, because the tree is what guarantees that and
the tree is left at full width.

**An alley on the corridor is where this gets interesting, and it is already possible.**
*(2026-09-03: "with the granular reachability can we make alleyways part of paths, too? that might
force some interesting routes".)* It is what M69 built: the tree grows on the reachability grid, so
a branch may *"cut through a park corner or take an alley exactly where the ground allows it"*, and
`Corridor` prices such a cell as depth zero — genuinely on the corridor rather than a shortcut
beside it. M69 also rolled an alley's offset even so that a two-tile alley is exactly one cell wide
and connects end to end, which is what makes a branch able to run down one at all.

**It stays luck, and that was the decision.** *(2026-09-03: "if they already can happen naturally,
that is fine. no changes needed".)* Nothing prefers an alley — the two probes are a loop-erased
random walk and the shortest way home, and neither knows an alley from a pavement, so a one-cell
passage is entered only where the ground happens to lead there. A bias toward alleys, and a
guarantee of one a day, were both offered and both declined: the natural rate is wanted. **So do not
propose weighting the probes again without a reason that is not this one** — what would make it
worth discussing is a played day, not an argument.

**An alley is never mandatory, because an alley is always a toll.** *(2026-09-03: "since alleys are
always a toll lets not make them mandatory".)* Standing in one adds a constant
`EXCITEMENT_FROM_ALLEY` of 3.0 a second, and a cost with no alternative is a tax rather than a
decision — which is the whole verb of this game being taken away on the narrowest ground in the
city. So a day may put an alley on the corridor and may never leave her no way but through it.

**Read as a day-level guarantee, mirroring the one the city already keeps.**
`EventScheduler._ensure_the_city_is_still_walkable` promises that *some* calm is reachable rather
than that every area is, and this is the same sentence one step further in: **a day's open network
always offers a route to at least one usable calm area that uses no alley.** An individual branch
may still run down one — that is the shortcut she may choose to take at a price, which is what an
alley has always been here — and choosing it stays a choice because a park she can reach without one
exists. **Chosen as the smallest form consistent with the existing guarantee and open to overturn:**
the stricter reading is that every alley stretch on the tree has a parallel open way round it, which
constrains the seal placement far harder for a fairness the day-level version already buys.

**And no robber stands in an alley she has to walk down.** *(2026-09-03: "alley robber should not
happen on required alleys".)* `alley_robbery` — placed on `ALLEY` tiles from day 8, lethal inside
30px, with an explicit design note that *"a robbery has no telegraph you could see coming, and it
never did"* — is a risk she is meant to have chosen by entering the alley. On ground she has no way
around, a row whose only warning is the alley itself is unfair by its own description.

**The guarantee above mostly satisfies this one**, since an alley she can avoid is not a required
one. It is written down separately because it is the fallback that holds if the day-level guarantee
is ever loosened, and because it is the cheaper check of the two: **`alley_robbery` is refused on any
alley cell the day's corridor runs down** — an outright exclusion from the candidate pool rather than
a weighting, which is this project's rule that placement is checked before it is accepted and never
repaired afterwards, and the same shape M69 used to refuse a barrier beside a calm area's access
street. **Read conservatively on purpose:** every on-tree alley rather than only the provably
unavoidable ones, since the corridor touches few alleys and proving one unavoidable is a question
about the whole day's open network. Open to overturn if it turns out to cost the row too many sites.

**Whether the same exclusion should cover every lethal row rather than only this one is a question
for the build**, not a widening to assume: the instruction named the robber, and `charging_dog` and
the heated rows reach an alley by different paths.

**What alleys are for, then, is going round a wall.** *(2026-09-03: "let's use them as option to
avoid obstacles and as chalk mark carriers".)* This is the job the sealing gives them, and it falls
out of a distinction the seal rule already makes: **a seal is placed on a street, and an alley is
not a street.** An alley is `ALLEY` tiles cut through a block, not a `StreetNetwork` segment, so
*seal every street off the tree* leaves every alley in the city open by construction. That is not an
oversight to close — it is the answer. The off-path city is walled, and the alleys through it are the
doors, priced at 3.0 a second of dread.

**So the day has two kinds of ground she may walk and they read differently**: the corridor, which is
free and goes where the day wants her; and the alleys, which go through the walls and charge her for
it. An obstacle in front of her stops being *walk round the block* and becomes *take the alley or
turn back*, which is a decision on the one verb the game has.

**Which alleys stay open is the detail the instruction is silent on, and the smallest reading is
taken: an alley bypasses an obstacle rather than opening a second city.** An alley kept open is one
that rejoins the corridor — it goes round a wall and puts her back on the path — and alleys leading
away into sealed ground may themselves be sealed at the mouth. **The alternative, named so it is
cheap to pick instead:** every alley in the city stays open, which gives a complete shadow network
through the walled city and a much larger game than the corridor policy describes. Decide it against
a played day rather than in the abstract; the conservative version is the one that keeps M64's
central claim — the corridor is the way through — true.

**The sealing itself is built — `SealPlanner` places one on every real street off the day's tree —
and the record is in `DECISIONS.md` under M64.** Off-path density measured 0.330 events per street
before and **2.173** after, over 8 seeds × days 1, 5, 8, 11 and 14, with the on-tree figure unmoved.
Two facts from that build govern what is left here: **a seal candidate is data** — an id, a strength
and one or two catalogue rows — so the item below costs one appended entry each and no branch in the
placement code; and **hard seals are act IV only today**, because `barricade` is the sole catalogue
row wide enough to span a street. **Whether a walled city reads as a route decision or as a maze is
the played question**, and nobody has walked one.

- [ ] **Eight seal pictures, so that no single barrier becomes the city's signature.** Agreed
      2026-09-03. Five for act I, where a closed street has a municipal reason, and three for acts
      II–IV, where it is the city coming apart. **With every street off the tree sealed, a day places
      about 187 of these** — the lattice's 264 streets less the 76.6 the day's tree covers, measured
      — **and she walks past perhaps twenty-five**, so eight kinds is each one met three or four
      times in a day.

      **This is variety, and it is independent of the item above.** *(2026-09-03: "having more
      pictures makes it nicer with variety but it's independent from actually placing things".)* It
      is finished when the eight are drawn and added to the candidate list, and it should change no
      other code.

      Act I: **a fallen tree**, root plate at one kerb and crown over the far footway (hard); **a car
      accident**, two cars locked together with debris and onlookers on both pavements (hard); **a
      skip and scaffolding**, skip at the kerb and boards over the far footway (soft); **a burst
      water main**, a crater with water across the asphalt and municipal barriers at both kerbs
      (hard — it is the one that explains why the road is out too); **a removal lorry with its ramp
      down** (soft), which reuses `Look.LORRY`, the biggest silhouette in act I.

      Acts II–IV: **a burnt-out car** (hard), which is `Look.BURNT_SHELL`'s charred palette at
      vehicle scale; **a collapsed frontage** (hard), rubble spilled frontage to frontage, and the
      `RUBBLE` texture `_draw_spread` already uses exists; **a stacked barricade** (hard), which is
      the `barricade` row that already exists in act IV — *"whatever was on the street, stacked by
      somebody"* — placed as a seal rather than rolled as an event.

      **The first two are the player's own examples** and the rest were proposed and agreed in the
      same exchange

**Measured over 8 seeds × days 1, 5, 8, 11 and 14. Only the events on the path exist; everything else
is bare — and it is a factor of three and a half.** *(2026-09-03: "if you look at any of those
pictures it's immediately clear only the events on the path currently exist. everything else is
empty", and "they meant literally empty — nothing on the street".)* The unit is **events standing on
a street, per street, per day**, which is the question somebody walking down one is asking:

| band | streets a day | events a day | **per street** |
|---|---|---|---|
| on the tree | 76.6 | 62.8 | **0.82** |
| the rim | 94.1 | 20.9 | **0.22** |
| further out | 93.3 | 22.7 | **0.24** |
| the whole city | 264 | 106.4 | 0.40 |

A street on the day's route carries **0.82 events**; a street off it carries **0.23**, which is one
event every four streets. The corridor is **29% of the lattice** and holds **59% of everything
standing on a street**. `_copies_of` is what does it — a friction row is offered
`EVENT_CORRIDOR_WEIGHT` (4) extra copies of any tile whose corridor depth is zero — and friction is
4489 of 5633 placements, so the furniture is pulled onto the tree and the rest of the city is left
bare.

**And the run log says she was not on the tree.** *(2026-09-03: "maybe what the playtester thought
was the path was indeed something else. that would beg the question why were they able to leave the
path?")* The `path` telemetry line closes each day with the share of her street time spent on the
day's route, and playtest 20's run reads **52%, 29%, 51%, 30%, 20%, 52%, 33%, 36%, 0%, 0%, 59%** — a
mean around a third, and two days on which she never set foot on it. So she spent most of her walking
on 0.23-events-per-street ground. *Empty* is the accurate word for it.

**Neither cause playtest 21 proposed survives, and both were tested.** The rows that force a pavement
change are not priced out of the corridor: `_role_for` calls a row a wall when it is lethal or costs
`WALL_WORTH_OF_COST` (40 points of a 100-point meter) or more to walk through, and `cafe_tables`
costs 20.1, `market_stall` 27.9, `construction` 20.3 and `delivery_van` 8.3 — all friction, each
landing on the corridor about half the time. And M69's closure refusal moves almost nothing: planning
every day twice on the same seeds, with and without the calm-area exclusion, moves **45 of 280
closures** and shifts the share landing on the rim from **86.4% to 88.6%**, at an identical 2.50 a
day. The refusal takes 35 streets a day out of the pool and only 34.7% of them are rim at all.

**So the fix is the sealing, and the sealing has a size: 264 − 76.6 = about 187 segments a day.**

**This makes playtest 19's older finding a measurement rather than an impression** — *going off the
paths lets me skip events and is safer than going on the path.* Off-path is emptier, so off-path is
safer, which is the exact inversion M64 exists to fix. And *why was she able to leave* has a plain
answer: nothing stops her. M50 only makes the corridor **cheapest**, and it buys that cheapness by
putting harmless things on it.

*(`SET_PIECE` is zero in every bucket. A one-shot has no position at dawn, so this is the sweep
looking at plans before the director sites them rather than a day with no set pieces in it.)*

The probe that produced all of this is `tests/probes/m64_density.gd`, run by name with
`tools/test.sh probes/m64_density.gd`, so that *measure it again after* means running the same
thing rather than reinventing it.

---

## M56 — The resistance is noticed

The city gets more dangerous the further into the subquest you are. **A task may not cost a nerve**
— a nerve is a rewind, not a resource, so there is nothing to trade.

**Its first item is built alongside M62; its second waits until act III is reached**, which the
queue puts after M96 to M100. *(2026-09-09: "M56 is also related to the other items to work on
right now. I wanna wait reaching act III until those things are done.")*

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
      already in the catalogue are `checkpoint` (day 7, closes a street) and `night_raid`.

      **The draft, 2026-09-09, for the player to take or turn down.** What `HUNTS` does to a row
      is fixed by `EventDef.at_heat()`: at `Tuning.HEAT_HUNTS_LEVEL` (3 of the 4 performs that
      qualify) and above, the derived copy `pursues` at 130px/s, notices her within 180px, chases
      for `PURSUIT_TIME`, and is `hard_fail` — the top rung kills, by the ladder's own design. So
      the question per row is not *what happens* but *whether that shape reads as this thing*.

      - **`night_raid` fits the precedent exactly and needs no drawing.** It is a riot van
        (`Look.RIOT_VAN`), scripted for day 10 only, intensity 24 over 70/330px with a 6s pulse
        and a 44px body, cost 4 — *"a building goes in the night"*. Hunted, the van stops
        emptying a building and comes for her, which is the abduction's shape on a bigger
        vehicle. **And the calendar makes the threshold a sentence:** the performs fall on days
        5, 7, 9, 11 and 13, so on day 10 the most progress anybody can hold is 3 — the raid hunts
        *only* a player who has done every task on time, and a player one task behind meets the
        cold raid. Sharing `HEAT_HUNTS_LEVEL` with the van is what makes that true, so the
        recommendation is to share it rather than mint a third constant. Build: one
        `heat_response` line on the row, `tests/test_heat.gd` stating the raid's hot shape at
        every level (untouched below 3, pursuing and lethal at 3 and 4, population and intensity
        unmoved), and the row's docstring. The one contract the hot copy has to clear is
        `EventDef.validate()`'s rule that a lethal row's body must be reachable — its
        `obstructs_radius` plus her own 14px must fall inside `inner_radius` — and the raid's
        44 + 14 = 58 sits inside its 70, so it does; the heated shape is validated on boot like
        every other.
      - **`checkpoint` does not fit the precedent as it stands, and it is about to be renamed.**
        It is a spread — `Look.CHECKPOINT` draws a 120px band across the road through
        `_draw_spread`, intensity 13 over 52/215px — and a band does not chase. A hunting
        checkpoint is *guards leaving the hut*, which is a second posture like the robber's
        waiting/lunging pair and so a drawing, plus a rule for what the band does while its
        guards are away. M62 renames this row (the new structure takes the word), so building
        its heat first means building it under a name that is about to change. **Recommendation:
        the raid now, the checkpoint after M62 lands and with its new name**, filed then as one
        item with its posture drawing.
      - **`police_patrol` is not a third candidate.** It is the `PRESSES` rung and *"never gains
        `hard_fail`, whatever the heat"* — the player's own instruction, 2026-09-01.
- [ ] **Measure it against the nerves.** This makes the back half harder precisely for the player
      doing well at the optional path, and nobody has reached act III

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
- [ ] **A field is the Minkowski sum of the body and a disc.** *(2026-09-05: "horizontal barriers
      need a combination of rectangular and circular fields ... a rounded rectangle if you will ...
      since they are not point sources", and then the general form: "basically for every base shape
      the minkowsky sum of a circle and the shape should be the influence field".)*

      **One rule, and every shape falls out of it**: the falloff is a function of the distance to
      the **body**, not to a point. A point body gives the circle every field in the game already
      has and nothing moves; a line segment gives a capsule — the "rounded rectangle"; a rectangle
      gives a rectangle with rounded corners; any polygon gives itself offset outward.

      **And the other operand is what folds this milestone's original instruction into the same
      rule** *(2026-09-05: "that's for static objects. for moving objects one side of the sum is an
      oval")*. The field is always `body ⊕ kernel`; only the kernel changes — a **disc** standing
      still, an **ellipse** moving, eccentricity from speed. So the ellipse this milestone was
      opened for is the second half of one sum rather than a system of its own, and a capsule that
      is also eccentric is composition rather than a special case.

      **Nobody has to compute a general Minkowski sum of two convex shapes** *(2026-09-05: "but most
      moving objects are small enough to be a point")*. The two cases are disjoint in practice and
      each collapses: a static body ⊕ a disc is a capsule, and a moving point ⊕ an ellipse is just
      the ellipse. The cat, the loose dog, the cyclist, the flock and every pursuer are points. Only
      something both large and moving — a vehicle — would want the general form, and whether any row
      is worth it is a question for then rather than a reason to build it now.

      **Keep M61's own offset when the kernel is an ellipse.** The original instruction says *"the
      entity itself lives in one of the focus points"*, not at the centre, and that is load-bearing:
      a kernel centred on the body is symmetric front to back and delivers none of the rationale it
      was asked for — *"an entity moving towards you has more of an effect than if it moves away or
      orthogonal"*. The offset buys the asymmetry; eccentricity alone does not.

      The rows it changes are the ones drawn as a spread along a pavement — `cafe_tables` through
      `EventInstance._draw_cafe`, and `construction`, `market_stall`, `barricade` and `delivery_van`
      through `_draw_spread`. A café frontage currently prices somebody across the street exactly as
      it prices somebody standing at the tables, reaching far perpendicular to itself and falling
      short along its own length.

      **The bodies, so this is not sized off a guess.** A spread is drawn `obstructs_radius` either
      side of centre (`_draw_spread` and `_draw_cafe` both take `half = max(11, obstructs_radius)`),
      so the frontages are 48px for `cafe_tables`, 56px for `market_stall`, 64px for `construction`,
      44px for `delivery_van` and 124px for `barricade`.

      **Only two of those five still emit**, and they are the two this bullet is really about:
      `cafe_tables` carries 12.0 over 40/90px and `market_stall` 14.0 over 44/95px, so each is a
      short body wearing a circle a little under twice its own length. `construction`,
      `delivery_van` and `barricade` are at intensity 0 — their radii are dead numbers that price
      nothing, and giving one of them a shape means first deciding it should emit again, which is a
      separate question and one the player has already answered no to.

      **The radii change meaning, and that has to be settled before any code**: `inner_radius` and
      `outer_radius` stop meaning *distance from the centre* and start meaning *distance from the
      body*. Identical for a point, not for a spread — so **carrying a number across unchanged
      silently inflates it**: 90px kept as-is stops meaning 90px from the café's centre and starts
      meaning 90px beyond the whole 48px frontage, a wider field than the one standing there today.
      M75 tightened those radii *for* this change, and this is the way to undo its work by
      accident — the number has to be re-derived from the body, not reused.

      **Which way they should actually move is the player's own point** *(2026-09-05: "that number
      was so big because it was a point source before")*: a field computed from one point has to be
      wide enough to stand in for a thing that is not a point, so the radius was doing the body's
      job. Once the shape carries the body, that job goes away and the number comes **down** — by
      at least what the body was worth, and further wherever the reach was never justified. Every
      row with a body gets its radii **derived**, never carried over. This is not the refactor it
      looks like.

      **This overturns the bullet that used to stand here** — *"a stationary thing keeps its circle,
      by construction: eccentricity from speed means zero speed is a disc"*, and with it the
      conclusion that this milestone touches only the mobile rows. *Overturned on 2026-09-05 by the
      player, because a body's shape and a body's motion are two independent sources of shape, and
      only the second one goes to zero when the thing stands still.* Whether the two compose — a
      capsule that is also eccentric — is open, and nothing needs it answered while every capsule
      row is stationary.

      **It is M75's "close only" item seen from the other side, and that item has landed.**
      `cafe_tables` went from a 170px reach to 90 and `market_stall` from 185 to 95, on the
      reasoning that a café should bill somebody at the tables and not somebody across the street.
      That is the stopgap; this is the fix. **The stopgap is now the thing to beat**: a 90px circle
      still over-reaches perpendicular to a 48px frontage and under-reaches along it, so the number
      to derive is not a shrink of 170 but a fresh answer measured from the body. The two rows'
      catalogue docstrings say so where the numbers are, and expect both to move again when this
      lands
- [ ] **And it has to be visible.** The falloff is invisible today and that is fine because it is
      symmetric; a field that is stronger in front of a van is a routing fact the player can only
      learn by being told or by dying. Ask what draws it before deciding it is free

---

## M65 — A protester points at the objective · asked for 2026-09-03

**All that remains here is the pose, which is a drawing.** The two findings this milestone was
opened for — the first mark being announced, and a mark that was never on screen — are built; the
record is in `DECISIONS.md` under M78, and the played question it leaves is whether a mark that
follows her until seen is now findable at all.

**Revisited after M62 rather than built as written.** *(2026-09-09: "M65 we need to revisit after
M62.")* A walled city with checkpoints may change what finding a mark is like, so this entry is
re-read against that city before the pose is drawn or the density moved.

**Half of this item needs no drawing at all**, and is worth doing on its own if the mark is still
hard to find now that it follows her: raising how often a protester appears is a density
change, and the player's own reason it is cheap is that a protester obstructs nothing and pursues
nothing, so it does not compete for the catalogue's placement budget.

- [ ] **A protester points at the objective, and there are more of them.** *(2026-09-03, playtest
      20: "the chalk is currently unfindable I spent almost a full day searching for it. let's make
      the protesters point into the direction (with their arms or something) of the current
      objectives (not only chalk marks). and make the protesters more common. they're not really an
      obstacle/event anyway so they can be placed independently.")* Still the same complaint as the
      two items above it — the mark cannot be found — with a mechanism attached rather than only a
      placement fix: give the `protest` row (`EventDef.Look.PROTEST`, drawn in
      `src/events/event_instance.gd:91` from `protester.svg`) a pointing pose aimed at whatever the
      current objective is, and raise how often it appears. The player's own reason the density
      change is cheap: a protester obstructs nothing and pursues nothing, so it does not compete
      with the rest of the catalogue's placement budget the way raising an obstacle's density would.

      **Measured, the same run:** a chalk mark is rolled and guarded by a nearby robber on every one
      of the four days it becomes eligible
      (`docs/evidence/archive/session-captures/2026-09-03/run-2026-09-03T002310-seed4070543669-5d342c9.log:240`, `:364`, `:546`, `:602`),
      and the run ends *"bad on day 7 — resistance 0/4, sabotage not done"* (`:701`) — not found once
      across the whole run, on every day one existed to find

---

## M96 — The teaching day, and the dog after it · rewritten 2026-09-09

Rewritten from M43. Two of M43's items turned out to be built when checked — the pause lesson no
longer fires while she is detained or while the tree is paused, and the run lesson's once-per-run
flag is reset on every attempt at the teaching day — and the record is in `DECISIONS.md` under "The
queue reprioritised". What is left is one decision nobody implemented and one measurement.

- [ ] **The tutorial dog recurs but is not sited ahead of her after day 3.** `charging_dog` has
      `first_day = Tuning.RUN_TAUGHT_DAY` (3), `spawn_mode = AHEAD_OF_PLAYER` and no last day, so on
      every day after the lesson it is still put in front of her on her own line. **Decided, and
      confirmed 2026-09-09:** *"the tutorial dog may appear later but not as tutorial."* Day 3
      keeps the placement it has, because the lesson depends on being unavoidable; from day 4 it
      becomes a thing that is *somewhere*, placed on the map the way `alley_robbery` is, and met by
      routing into it — no siting on her heading, and no lesson line, which the HUD already
      restricts to the teaching day. The row needs a day-dependent spawn mode or a second row for the later days;
      `EventDirector._teach_the_run()`, which moves a pursuit to the head of the owed list on the
      teaching day only, is unaffected either way. A test asserts that a day-4 `charging_dog` is
      never sited on her heading.

      **Measured, playtest 20** *(2026-09-03: "for some reason pursuing dogs after the run tutorial
      have a shorter lead up time making them much harder to react to.")*: across five
      `charging_dog` encounters in one seven-day run
      (`docs/evidence/archive/session-captures/2026-09-03/run-2026-09-03T002310-seed4070543669-5d342c9.log`),
      the day 3 tutorial encounter and every encounter afterward that ended in evasion ran **1.5
      seconds** from the `chase` starting to the dog giving up. The two encounters that instead
      killed her — one on day 4, one on a day 5 retry — ran **0.8 and 0.9 seconds**, roughly half,
      with the dog closing distance far faster once its telegraph appeared: the tutorial encounter's
      telegraph closed 20px in 1.1s, the day 4 encounter's closed roughly 70px in 0.3s. The row
      carries one `inner_radius` (26px) and one `outer_radius` (150px) for every day, so nothing in
      the row itself shortens the lead time — the gap is a placement effect, and this item is the
      first thing to check before treating it as a row-tuning question. M77 has since moved every
      pursuer's siting to past the edge of the view along her heading, so re-measure on the current
      tree before assuming the gap is still there
**The run is taught on day 3, and stays there.** *Asked for as `RUN_TAUGHT_DAY` 3 → 2 · overturned
on 2026-09-09: "run taught goes to 3 not 2."* The constant gates everything that pursues, and day 3
is where act I stops being a nice neighbourhood; the options weighed when the move was first
proposed are in `DECISIONS.md` under M49, in the item "Day 3 carries act I's whole payload".

- [ ] **Dying at high excitement on a quiet street: is one contact at 90 a cliff?** A bump is about
      10.8 points, so above 89 a single one ends the day on an empty street. Two cheap checks:
      whether the pram's `EXCITEMENT_NEARLY_CRYING` cue, which the baby shows from 80 of the
      100-point meter, is drawn and actually read; and a rig walking an empty street at 90 into one
      walker, to say whether the day ends. If it does, the fix is a rule about the last ten points,
      not a density change

---

## M97 — Calm areas that hold · rewritten 2026-09-09

Rewritten from M47. Its apartment complex — a courtyard lot four blocks across with frontages
around the outside — is built as `_place_apartment_complexes`, and the non-adjacency rule covers
courtyards as well as open calm at generation. The multi-block count was re-derived for the
121-block city: `MIN_CALM_ZONES` 1 and `MAX_CALM_ZONES` 2, with the remainder single-block on
purpose so that *which* calm area to head for stays a real question. The record is in
`DECISIONS.md` under "The queue reprioritised". What is left is one measurement, one later tweak
and one re-check.

- [ ] **The non-adjacency rule does not cover parks yet.** *(2026-09-09: "non -adjacency rule
      doesn't cover parks yet -- that's something we might want to tweak later.")* Later, by the
      player's own word. What the code says, for whoever picks it up: `_has_calm_neighbour` asks the
      one-block ring around a footprint for every purpose in `_CALM_PURPOSES` — park, forest, quiet
      square and courtyard — and both zone placement and single-block calm placement refuse a
      footprint that has one. So the case the player has seen is not the ring test failing on its
      own terms, and the first task is a seed showing two parks side by side, to say whether a zone
      absorbing its inner streets, the border forest, or something after generation is what puts
      them there

- [ ] **Spoiling a returned-to calm area is not consistently effective.** *(2026-09-03, playtest 20:
      "the spoilage of a clam area is not always effective I went to the same park 4 times and only
      the last time had a high enough density of events to actually prevent me from using it. the
      previous time I could just walk at the edge of it. and the time before that didn't have any
      spoilage at all even though it was the second visit.")* `docs/PLAYTEST-02.md` records the
      intended shape — *"the scheduler biases a spoiling event toward a calm area the player settled
      in on day N−1"* — a bias toward, not a guaranteed minimum, which is consistent with a roll
      landing low enough some days to leave a walkable edge and high enough on others to deny the
      area outright. The run attached to playtest 20 does not carry the exact four-visit sequence
      the player describes — its own biased parks (`(1,1)` and `(4,8)`) were dense on every biased
      day the log shows. **First task:** reproduce a zero-density biased visit on a rig, reading the
      `roll` telemetry line that says *"in the park she used yesterday"*, before deciding whether the
      bias roll's spread is the cause or something else is. The fix follows the reproduction
**The main road is not made a soft block.** *Asked for on 2026-09-01 as a toll on crossing the
spine · overturned on 2026-09-09: "M47's toll already exists — it's timing the traffic lights. we
don't need to penalize routing through it just yet — it naturally happens that only some routes
cross it."* Waiting for a green is the crossing's price, and the route tree already puts only some
of a day's routes across the spine; nothing prices the crossing on top of that. The record is in
`DECISIONS.md` under "The queue reprioritised".

- [ ] **Re-check `MIN_CALM_BLOCKS` (5 to 7) and `MIN_HOME_TO_PARK_TILES` at the end, not the
      start** — after M62's perimeter, since a region that holds no calm area gets no door and the
      count of places to go is what the perimeter divides

---

## M98 — Pressure in the empty acts · rewritten 2026-09-09

Rewritten from M25 and M26. All of M26 is built: day 1 says how to walk, the run is taught by the
first pursuit on `RUN_TAUGHT_DAY`, with one wording on every device and no key named, and the
scripted event that requires a short run is the charging dog itself — *(2026-09-09: "this is what
became the charging dog")* — sited on her line on day 3 so the lesson is unavoidable, which is the
"safe place" playtest 02 asked for, moved to the day running becomes right. What remains is M25.

- [ ] **Patrols for acts III and IV, built around encounter cost.** The crowd table in `Tuning`
      empties the streets from act III on purpose — *"the cruellest number in the game: from act III
      the streets are quieter, because there is nobody left going out on them"* — and the return
      phase (`DayPhase.RETURNING`, entered when the day's clock runs low) was measured in playtest
      03 as a formality: 26s, five crossings, zero encounters, 42% of the day left. Pressure goes
      back into those streets as things she **meets**, not as an ambient band she cannot see. The
      mechanism to start from is M56's heated `police_patrol`, which is already denser and then
      interested as resistance progress rises; what this item adds is a return-phase shape in acts
      III and IV. Measure the return phase on a rig across the four acts — encounters per return,
      and how much of the day's clock the return actually spends — before and after

---

## M99 — The corridor's density after the sealing · rewritten 2026-09-09

Rewritten from M50. M64 superseded M50's gradient at both ends — off the path is *closed*, on it the
density is *normal* and playtest 21's verdict on it was that it is already right — so what is left
here is what the sealing did not answer.

- [ ] **The corridor's own obstacle density, measured rather than raised.** M50's *"blocking events
      all over"* asked to raise the caps on the expensive rows, which is a catalogue question.
      Under the sealed city the corridor carries 0.82 events per street a day, measured with
      `tests/probes/m64_density.gd`, and the player's sentence on it was *"on the path there should
      be a normal amount of events that remain passable — that looks like it is the case here"*. So
      the item is a re-measurement on the current tree with the same probe, and a cap moves only if
      a played day says the corridor is bare
- [ ] **`cyclist` and `loose_dog`'s caps no longer mean what they say.** Both rows carry
      `max_per_day` of 14 and 24 and arrive via the director's single queue at its 11–26s pacing
      rather than being map-placed, so a day fields far fewer than the cap reads as promising — the
      caps' meaning changed while the numbers stood still. Measure encounters per day on a rig
      across the acts; the record is in `DECISIONS.md` under M54
- [ ] **Placeholders — step 3.** The budget is a **variety ledger, not a density cap**: the count of
      sites is the density, the budget decides what fills them, and resolving late means variety is
      measured over the encounters that happen rather than over a city she never saw. Read the
      entry in `DECISIONS.md` under "The milestone log, as it stood on 2026-09-01" before starting;
      the first reading of this was wrong and the wrong reading is recorded there
- [ ] **A building type that closes all four of its streets.** Recorded, not built, and a
      **different type rather than a bigger one** — a big building joins two blocks and closes one
      street; this removes four and makes an island in the lattice, so it needs its own name, its
      own count, and its own answer to how many a city can take. The reasoning is in `DECISIONS.md`
      under M50

---

## M100 — Small, real, and nobody's · consolidated 2026-09-09

The small items, the polish list and the open design questions, consolidated into one milestone on
2026-09-09 *("consolidate into a current new milestone")*. Each was checked against the code that
day: the `burning_building` now finishes where the fire belongs rather than where the engine
stopped, and the seed-retry fact is stated in `docs/CITY.md`, so neither is here. Everything else
is still true.

**Defects, each a few lines once found:**

- [ ] **Events spawn inside a fully blocked street.** *(2026-09-09, playtest 49: "a definite bug
      is that inside fully blocked streets (eg tree) restaurants etc can still spawn which is
      silly".)* The scheduler's own rule is the right one — *"a closed street is not somewhere
      anyone can get to, so it is not somewhere an event can usefully happen"* — and it is enforced
      by refusing any candidate tile in `closed_tiles`. Two things put a café behind a fallen tree
      anyway. `CityMap.close_streets` fills `closed_tiles` with only the tiles a flood from the
      doorstep cannot reach once the barrier tiles at both mouths are down, so a closed street with
      an alley mouth or a courtyard archway opening onto its middle keeps its ground open, on
      purpose, and the scheduler then places on it. And a **hard seal** is not a closure at all: it
      is `barricade` bodies standing across the middle of the segment, placed by `SealPlanner`, so
      neither half of that street is in `closed_tiles` and the whole of it is open to the catalogue.
      **The fix is at placement, keyed on the segment rather than on the tile**: no catalogue row is
      offered a tile on a segment that carries a closure or a hard seal, with the seal's own bodies
      and the closure marker the only things allowed to stand there. A soft seal is not covered — the
      street is still walkable down the carriageway and a café on it is the price of going that way.
      A test plans several seeds and days and asserts that nothing planned stands on a closed or
      hard-sealed segment. Placed here rather than ahead of the queue by the player: *"blocked
      street can go behind actual important things"*
- [ ] **A queued car grazes a big building's footprint, and the M53 assertion was loosened to let
      it.** `tests/test_crowd.gd`'s *"nothing walks into a hard blocker"* asked for exactly zero
      agents ever standing inside one; it now tolerates one agent on under 5% of frames, measured at
      1.1% — one car on 27 of 2400 frames. The cause is a crawl-forward step in a traffic queue
      stepping one tile into a footprint, in `src/crowd/`. Fix that and the assertion goes back to
      zero, which is the only acceptable end state: a car standing inside a building is visible, and
      the test's own name is a promise
- [ ] **The robber can be placed inside a building, where he is stuck for ever.** *(2026-09-02:
      "the robber can be placed inside buildings which makes him unable to move at all.")*
      `alley_robbery` places on `ALLEY` tiles, which are walkable, and a chase step is clamped to
      walkable ground — so how he comes to stand inside a wall is not known, and **the first task is
      to reproduce it** on a rig and read where the placement put him. His lethal radius travels
      with him, which makes an invisible fatal spot inside a wall. Fix it where he is placed, not by
      letting a pursuer walk through buildings
- [ ] **The pram has no collision of its own.** `scenes/player/stroller.tscn` carries one circle
      for her, so the pram clips into walls when she hugs a corner. A second body that trails her,
      or a capsule that rotates with `facing`
- [ ] **A pursuer streamed out mid-chase comes back having forgotten it.** `EventInstance.resume()`
      restores the age and the distance travelled but not `_noticed_at`, and a fresh instance starts
      with that at `INF` — so a `pursues_within` row streamed out after it has noticed her returns
      waiting, standing where the day planted it. Not currently dangerous: `alley_robbery` has had
      it since the mechanic was built, and the heated patrol that surfaced it can never be
      `hard_fail`. `tests/test_heat.gd` pins the behaviour rather than the one the field name
      implies, so a fix fails there first. The fix is `resume()` carrying the notice, checked against
      every `pursues_within` row rather than the one that found it
- [ ] **A big building can be built over a precinct's own pavement.** Measured on seed 24757: two
      tiles inside a precinct span are not walkable, because a footprint was placed across the
      corridor the span runs down. `CityGenerator._place_hard_blockers` never reads
      `precinct_spans`, so nothing asks whether a footprint lands on one. A precinct's whole design
      is *paving frontage to frontage*, and the fix is a constraint where big buildings and calm
      zones choose their ground, not a repair pass afterwards
- [ ] **`chat` is written and undocumented.** `EventManager` logs a `chat` entry when
      `chatting_mother` starts a conversation, and the table of entry kinds in `docs/TELEMETRY.md`
      has no row for it. One row, plus the check that would have caught it: something asserting the
      two lists agree
- [ ] **What is still dev-only inside `main.gd`.** `DevFlags` took the flag parsing out; what stayed
      is the code that acts on it — `_first_event_position` and the `--spawn` target lookup, both of
      which read the live city. Worth finishing the next time the file is opened for another reason

**Drawings, as SVG:**

- [ ] **The fence is drawn in elevation and turned on its side.** The game looks straight down,
      where a fence is a thin line with post-heads and a shadow. `assets/tiles/fence.svg` runs
      north–south, which fixed playtest 14's rotation, and is still rails and palings seen from the
      side
- [ ] **Park trees clump.** `City` places them by rejection sampling inside the lot with no
      spacing test. A minimum-spacing check would spread them
- [ ] **`INDUSTRIAL` and `CIVIC` districts do not read differently at a glance**, although act II
      makes them narrative. Today only the wall heights differ — one to two tiles against three to
      four

**Polish, after the playtest work**, since there is no point polishing a loop that is about to be
re-pitched:

- [ ] **Sound lines** — concentric arcs off a source on a pulse's rising edge, the visual form of a
      discrete noise. The last gap in the visual channel, and it comes **before** audio
- [ ] **Audio**, once the above is done and judged on its own: per-act beds, per-event cues, the
      baby's breathing as the diegetic version of the meters. Additive by design
- [ ] Save and continue a run (`GameState` is already shaped for it, so this is serialisation
      rather than design); there is a title screen and no menu, on purpose
- [ ] Accessibility: colourblind-safe meters, a telegraph-time multiplier, reduced motion
- [ ] Controller support
- [ ] **The web build measured on a machine that did not build it.** Playtests 27 onward have
      played the live address on a laptop browser and a phone, so *it boots and takes input* is
      answered. What is not is frame rate at the game's scale on somebody else's machine, and
      whether a stranger arriving at the page understands what it is. itch.io stays the fallback
      host, since it sets the isolation headers a threaded build would need

**Open design questions**, each answered by a played run rather than by more arithmetic:

- [ ] **Does a picked-up-but-unperformed resistance instruction expire at the end of its day, or
      wait?** Left open by decision until the pairs can be walked. The code currently **waits** —
      an incomplete perform step is re-offered each subsequent day; the only expiries are the
      poster wall's `deadline_fraction` and a rider event finishing, both inside one day
- [ ] **Is the nerve economy right?** Five since M35, and **asked for rather than derived** — the
      thing that made three too few was a defect rather than a difficulty, so if act I now reads as
      fair, five may be generous. The other side is still open: with five attempts and a retry
      costing only time, **is a lost day a punishment at all?**
- [ ] **Is the balance right?** Needs a run and a trace. *"The arterial is for crossing"* is still a
      claim about a player rather than about a probe
- [ ] **Is 14 days the right run length?** Act I is only 3 days, which may be too little time to
      learn a city before it starts changing
- [ ] **Is the main-road arc emergent or authored?** The design says she exhausts her own side of
      the spine before being forced across. Either calm areas exist on both sides and spoiling
      burns the near ones over an act, which needs no new code, or something has to withhold the
      far side early and steer her across late, which is a mechanism nobody has designed. M62's
      regions may settle it, since a region with nothing left in it gets no door
- [ ] **Could the meter bars be turned off entirely** — deferred, not open. *(2026-09-02: "we can
      keep the bar for now and think about the diegetic face later on.")* The minimal HUD keeps the
      bars and drops the status line beside them, so what gets tested first is whether the pram
      alone can carry the baby's state on the half that was cut. **What comes back with it is a
      face**, the meter read off the baby rather than off a strip at the bottom of the screen — the
      same shape as the audio item's *breathing as the diegetic version of the meters*. Not
      designed, and it needs the playing that the status-line cut is about to produce

---

## M101 — The fire is found before the engine · asked for 2026-09-09

> "the player should encounter the burning building before the fire truck. basically the fire
> truck should spawn when the player sees the burning building not the other way around"

**Today the engine is the event and the fire is what it leaves behind.** `fire_truck` is act I's
one-shot — day 3 only, `ONE_SHOT`, a mobile row at 190px/s along a 60-tile street route with a
4-second telegraph, because a truck outruns a walk and the fairness rule wants the full 340px of
clearance — and `burning_building` is a `SCRIPTED` row that is never scheduled on its own:
`EventManager._successor_of()` creates it where the engine's run ends, and
`EventInstance._be_done()` makes an event with a `spawns_on_finish` stop where it stands rather
than drive off, so the fire is at the building and not two streets past it. The engine is the
thing she meets; the fire is a consequence she may never see.

**The instruction reverses the two, and the reason is legibility.** A fire engine bearing down a
street is a loud thing with no visible cause; a burning building she has already found is the
cause, and the engine arriving *at it* is the answer. Seen in that order the set piece reads as
one story rather than a truck and, later, a fire.

**The seen predicate exists.** `DangerEdge.is_on_screen()` answers whether a world point is inside
the view, and `ResistanceDirector.set_sight()` already takes it so a chalk mark can follow her
until it has been on screen once (M78's rule). The same callable is what the fire wants.

- [ ] **The burning building is the day's one-shot; the engine is spawned on sight of it.**
      `burning_building` takes over `fire_truck`'s `ONE_SHOT` slot — day 3, sited by the director
      the way the one-shot is sited today — placed *in* a building rather than on the road. When
      it first comes on screen, `fire_truck` is created with a route that **ends at the fire**,
      entering along the burning building's own street from off screen. The link is a field on the
      def in the opposite direction from `spawns_on_finish` — a row that names what arrives once
      this one has been seen — and `EventManager` owns the trigger, since it already owns the
      successor mechanism and the player's position. Whether `spawns_on_finish` survives on any
      other row, or goes, is a question for the build: today only the engine uses it
- [ ] **The engine's fairness contract does not change and has to be re-proven for the new
      siting.** Its telegraph is its approach, so the route's start has to be far enough up the
      street that the full 4 seconds pass before its field reaches her — M77's off-screen arrival
      rule applied to a thing driving at the building rather than at her. If she stands on that
      street between the engine's entry and the fire, she is in its path; the row's own contract
      (walk away the instant it is visible and be clear before it hurts) is what the test asserts,
      and it is asserted from the worst position on the street. The `hard_fail`-style further
      siting is not needed, since the engine is not lethal
- [ ] **The fire's own telegraph and pulse are re-read for a thing she finds rather than one that
      arrives.** `burning_building` carries a 2.2s telegraph and a 3-second pulse, both written
      for a fire that begins in front of her when the engine stops. A fire that was already burning
      when she turned the corner has no arrival to telegraph; what it keeps is the pulse, the
      obstruction (30px, five flames) and the `burnt_shell` scar. Decide whether the telegraph
      becomes zero or stays as the moment the fire is *noticed*, and say which in the row's doc
- [ ] **Day 3 is re-measured.** Day 3 carries act I's whole payload — the run lesson's dog, the
      cyclist's first day and the set piece — and the balance suite prices the day with the engine
      as the expensive row. The engine still comes, but later and only if the fire is seen, so a
      day on which she never finds the fire costs less than the day the suite describes. Run
      `tests/test_balance.gd` and the day-3 rig before and after, and record both numbers in
      `DECISIONS.md`
- [ ] **`docs/EVENTS.md` follows.** Its one-shot example is the fire truck, its route sentence says
      *a fire engine is in the world before its mark*, and its finishing-position paragraph
      describes the engine leaving the fire behind. All three move in the same commit as the rows

---

## M79 — The city seen at an angle · tabled 2026-09-06

**Tabled, and the reason is sequencing rather than doubt.** *(2026-09-06: "let's write down the
findings about the diagonal grid but table it for now".)* Nothing here is rejected; it is written
down so the graphics overhaul can decide the projection with the code's constraints in front of it
rather than after committing to art. **What would make it worth picking up**: the overhaul reaching
the point where it chooses a projection, and somebody confirming the existing rotated presentation
on a real phone — not a complaint about how the city looks today.

The reference the player gave is `docs/evidence/reference-isometric-street-2026-09-06.jpeg`: a 2:1
isometric street with buildings as tall volumes, pedestrians, cars and a pram. **Its HUD is not part
of this.** *(2026-09-06: "ignore the hud in the image".)* That picture's bottom bar carries verbs —
Feed, Soothe, Order Pizza — and this game has one verb, which is where you walk.

**The instruction is a presentation change and nothing else.** *(2026-09-06: "the logical layout
would stay the same only the presentation would rotate".)*

- [ ] **Only the world-to-screen transform changes; the lattice does not.** The tile grid stays
      cardinal `Vector2i`, so the lattice, `RouteTree`, `ClosurePlanner`, `SealPlanner`, the crowd's
      lanes and every test are untouched. **This is the whole reason a diagonal *lattice* is not
      what is being asked for**, and it is worth stating why that alternative is closed: `CityMap`'s
      layout is a modulo — its own comment, *"a coordinate's position within its period tells you
      which it is"*, over a period of `BLOCK_SIZE + STREET_WIDTH` tiles — and a 45° street has no
      period in tile coordinates. Every segment is horizontal or vertical down to the vocabulary
      (`closure.segment.horizontal`, logged as `h(7,4)` and `v(8,6)`), the crowd is built on
      `travelling_vertically()` and `make_lane_key(vertical, corridor, lane, direction)`, and
      `TrafficLight.arm_is_vertical` even picks a different sprite. A diagonal lattice is a rewrite
      of the city that buys nothing the route decision can feel — she still chooses between streets

- [ ] **The buildings are already 2.5D, which is what makes this cheap.** `Building` is *"a 2.5D
      extruded block, assembled from 32px facade and roof tiles"* — a front wall in elevation plus a
      roof, from `wall.svg`, `wall_edge_w/e.svg`, `roof.svg` and `roof_edge_n.svg`, and each one is
      its own `StaticBody2D` node in `City._spawn_buildings()`. So the facade vocabulary exists and
      is not top-down art to re-author, and per-building translucency is `modulate` on one node
      rather than a restructure

- [ ] **What rotation destroys is a guarantee, and replacing it is the actual work.** `Building`'s
      class doc: *"nothing can ever legitimately be **behind** a building, so nothing sorts against
      one."* The layout guarantees there is no walkable ground behind a building's mass, so occlusion
      never has to be solved and no real y-sorting is needed. **Rotate and that is gone** — a rotated
      lot puts its own pavement behind its own wall. So this item is: replace a layout guarantee with
      a runtime rule, and add the y-sorting nothing does today

- [ ] **Buildings in front fade or vanish, and "when necessary" is wider than the player.**
      *(2026-09-06: "buildings in front could become translucent or disappear when it becomes
      necessary".)* The standard answer is *"when it hides the character"*, and that is too narrow
      here: the route decision depends on seeing the things you route around. The must-see set is the
      player, any event carrying a mark (`EventInstance.wants_a_mark()`), anything `DangerEdge` would
      badge if it were off screen — an occluded thing is that same question in a new form — and the
      home arrow's target during the return. Cost is a per-frame test of a few dozen buildings
      against a handful of points, the same order as the event scan `CLAUDE.md` already calls free.

      Two calls inside it: **fade or vanish** — fade keeps a street legible as a street, vanishing is
      unambiguous but flickers at the threshold — and **whether a fading building is itself a cue**.
      If you learn *something is there* because a wall went translucent, the **cues** rules govern it
      and it owes the same discipline as the rest of the danger vocabulary

- [ ] **It must be a real camera transform, not faked in `_draw()`.** `TouchControls._on_tap()` maps a
      tap to a world point through `get_viewport().get_canvas_transform().affine_inverse()`, and
      `DangerEdge` and `HomeArrow` both go the other way every frame from the same transform. A real
      transform keeps all three working; a fake one breaks every one of them. Two more that follow:
      `main.gd`'s camera fit sets zoom from an axis-aligned bound and would be fitting a diamond, and
      `city.gd` draws kerbs, centre lines and zebras as axis-aligned rects off `STREET_WIDTH`

- [ ] **The gameplay cost is the keyboard, and it is the one real objection.** *(2026-09-06: "what
      would be the implication on gameplay? if down the line tap becomes the default it's fine. but
      keyboard controls become clunky in diagonal".)*

      **The collision and the physics do not change at all** — the world stays cardinal and only the
      camera turns, so pavements, lanes, bodies and every fairness contract are untouched. What
      changes is that `Stroller` reads `Input.get_vector("move_left", "move_right", "move_up",
      "move_down")`, a normalised vector **in world space**, so a key press stops pointing where she
      visibly goes. There is no arrangement that avoids this, only a choice of which way it hurts:

      - **Keys on world axes** (one key follows a street exactly, and on screen she sets off at 45°
        to the key pressed). Correct for the game — a street is the thing you walk — and it is what
        most isometric games do, but it is exactly the clunkiness named above.
      - **Keys rotated to the screen** (up walks up the screen). Reads right for one second and then
        walks her diagonally into buildings, since up-the-screen is a world diagonal and no street
        goes that way. She would slide along walls constantly.

      **And it inverts what two keys mean.** Today holding two gives a true diagonal along open
      ground. Rotated, with keys on world axes, a single key follows a street and **two keys point
      between buildings** — so the combination a player reaches for becomes the useless one.

      **The pointer scheme has none of this.** `TouchControls._on_tap()` already maps a screen point
      to a world point through `get_viewport().get_canvas_transform().affine_inverse()`, so a
      rotated camera is handled by the transform and costs the design nothing: a press already
      means *go there*, in world space, whatever the camera's own angle.

      **So the objection is the keyboard alone, now that there is one control scheme rather than a
      choice between two** (M82 deleted the drag stick and the title screen's own question). A
      fresh install has nothing to default to any more — every device gets the same pointer scheme,
      and the keyboard sits beside it as arrows/WASD always have. **Settle whether the diagonal
      clunkiness above is acceptable on a keyboard before this is scheduled**, because that is now
      the whole of what standing in the way of a rotated presentation.

- [ ] **Spike the transform alone on the existing square art before anybody draws anything** —
      proving tap-to-world, the edge cues, the zoom fit and y-sorting survive, with no new art,
      because that is what de-risks the expensive half.

      **The rotation it composes with is already one rotation**, which is what makes the spike
      worth doing rather than doomed: `ScreenOrientation` carries a single transform applied to
      every `CanvasLayer`, `main._process()` re-asks `wants_rotation()` every frame and reapplies
      only on change, and `TouchControls` no longer turns itself. **What is not settled is a sign
      error the world and the drawing could share**, which `tests/test_orientation.gd` says outright
      it cannot catch — so the spike is looked at in a portrait window with `tools/shot.sh`'s
      resolution argument, not judged from a passing suite
