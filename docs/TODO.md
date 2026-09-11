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

### M108 — Eight-direction entity graphics

The SVG-only authoring and subsequent integration requests are recorded in [PLAYTEST-53](playtests/PLAYTEST-53.md).
Drafts rejected only internally by an assistant stay outside the repository; retain artwork
suggested for human review or rejected by a human.

This graphics track runs beside the gameplay queue. [PLAYTEST-51](playtests/PLAYTEST-51.md)
approves the SVG-to-PNG workflow and requests eight-direction movement graphics for all entities
before catalogue-wide conversion. See `DECISIONS.md` under Eight-direction style transfer.
Use the reviewed N, NE, E, SE, S, SW, W, NW source coverage and existing animation/state variants.
Preserve native scale, ground anchors, actor identity and gameplay. Follow the documented mirror
symmetry; choose an authored projection rather than rotating an upright picture.

The prepared source families and their complete facing/state matrices are in `GRAPHICS.md` and
its linked people, vehicle/animal and environment inventories. The source-art record is in
`DECISIONS.md` under SVG completion and selective rejection retention. Work below binds those
pictures to their actual runtime consumers.
- [ ] **Bind crowd walkers first.** Add a shared eight-sector heading selector and explicit
      family tables for source paths, mirrors, canvases and anchors. Reuse the stroller's stable
      sector-selection behavior where appropriate: retain facing at rest, avoid chatter at sector
      boundaries, reset cleanly on placement/recycle. Drive walking facing from applied travel,
      keeping authored action aim separate. Bind matching walker body/trim views with one transform
      and preserve tint, gait timing, sorting and foot registration. Verify all eight headings,
      boundary crossings, stops, blocked movement and recycle with a focused rig and rendered
      native-size movement evidence.
- [ ] **Bind live event people, animals and riders.** Extend the same selector to each actual
      drawing path in `EventInstance`, including composed actors, leads, prams, held tools and
      weapons. Keep idle/moving, waiting/lunging, talking/walking and wing/gait phases distinct;
      an action's target supplies its aim even when its actor is stationary. Preserve event
      identity, timing, collision, cues and halo silhouettes. Exercise state transitions as well
      as every facing; a source sheet alone does not verify the runtime composite.
- [ ] **Bind vehicle views.** Use each family's explicit front/back/side/diagonal table, including
      its documented side-facing convention, rather than assuming every side source faces east.
      Keep crowd car body/trim and police overlays registered together. Straight-moving event
      vehicles use their existing travel heading. Crowd cars consume the continuous turn heading
      supplied by M111, cars follow their turns; changing the picture alone does not close that
      item. Preserve native scale, contact point, sorting and per-view halo geometry. Keep
      `GroundShape` as the independent ground datum; changing sprite view must not resize the
      shape or lethal strike box. Orient shape-derived shadows with the continuous travel heading.
- [ ] **Verify and document each binding increment.** Update `GRAPHICS.md` from prepared to live
      only for callers actually wired. Check SVG override and illustrated fallback so an available
      cardinal PNG cannot replace a newly selected diagonal SVG or lose its state/registration.
      PNG generation stays with M109, convert the SVG catalogue to PNG. Use focused selector and
      caller tests, import/boot checks and movement evidence; keep prepared families unbound until
      their gameplay owner needs them. M56, the resistance is noticed, owns guard/riot-van states;
      M102, the finale, owns the carrying mother and interior sequence. The protester's eight
      pointing poses are bound (`DECISIONS.md`, M65).

### M111 — Cars follow their turns

[PLAYTEST-53](playtests/PLAYTEST-53.md) asks for proper turns and turnarounds using diagonal
sprites. This is the motion work needed alongside M108, eight-direction entity graphics.
`CrowdAgent._divert()` immediately swaps the travel axis and lane, and `_turn_round()` immediately
reverses direction before steering to the opposite lane. The heading exposed to drawing remains
cardinal. A continuous turn must change the travelled path and the body facing together.

**The full model below is wanted as written**, swept footprint and reserved turn space included —
a review had offered the smaller reading of an arc with the sprite on its tangent, and the player
kept this one *(2026-09-10, playtest 54: "the car turn overcommittment that you flagged is good
and we should do that")*. `CrowdAgent.velocity()` and `EventInstance.travel_velocity()`, built
under M61, are the actual-motion velocities the third item asks for.

Coordinate implementation with M110, the crowd goes round a seal: it supplies which lanes and
segments are blocked to each crowd kind; this item supplies how a car physically follows the
chosen diversion. Preserve its distinction between hard seals and passable soft-seal carriageways,
and keep its open question about ordinary solid obstacles with that item's owner.

- [ ] **Plan a continuous path before entering a turn.** Cover left/right junction diversions
      and 180-degree returns at dead ends, closures and precinct boundaries from both road axes.
      Join the incoming and correct outgoing lane with continuous position and heading; the car
      follows the curve and its sprite follows the tangent through diagonal sectors. No instant
      reversal, lateral lane jump, rotation of an upright side sprite or cosmetic diagonal frame
      over unchanged right-angle movement. Keep current route choices and straight-through travel.
- [ ] **Fit the manoeuvre to legal road space.** Validate the swept vehicle footprint against
      pavement, closures, walls and other cars before committing. Check destination room and
      reserve conflicting turn space, including same-frame claims. If a turnaround cannot fit,
      stop safely before the obstruction and choose a feasible earlier turning place; never drive
      through a barrier or use separation to repair a knowingly invalid turn. Document any space
      constraint that needs a different manoeuvre before broadening the driving behavior.
- [ ] **Keep traffic rules coherent throughout the curve.** Adapt lane indexing, box occupancy,
      following gaps and conflict tests that currently assume a cardinal axis. Keep a turning
      car claimed until its tail clears; do not enter a junction without room to leave. Preserve
      signal/amber clearance, zebra stopping, right-of-way, horn warning and lethal carriageway
      contracts. Derive velocity from actual motion for collision and approach calculations.
      Measure any required turn-speed/radius choices under the balance rules; do not retune
      population, light timing or cruise speeds as an incidental graphics change.
- [ ] **Prove movement and presentation together.** Step the whole crowd with `Crowd.step()` in
      focused traffic rigs: left/right turns and U-turns from every approach, a blocked exit,
      simultaneous arrivals, queues, signals, zebras and boundary closures. Assert continuous
      travel, legal swept space, correct exit lanes, no overlaps/deadlock and finite completion
      when the path is free. Capture native-scale turns showing intermediate diagonal views,
      including body/trim and police markings, and inspect grounding and heading at entry/apex/exit.
      Update traffic documentation and `GRAPHICS.md` with the resulting motion/binding contract.

### M109 — Convert the SVG catalogue to PNG

Follows M108, eight-direction entity graphics. Use the approved SVG-first workflow in
[VISUALS.md](VISUALS.md) and the illustrated-png skill. The supplied diagonal urban and cardinal
gameplay references define style only; each SVG defines content, geometry and placement.
**Every PNG asset must have a corresponding SVG asset, authored and reviewed first.** This is
a permanent authoring requirement, not only a conversion step. Audit existing PNG-only assets
and author their source SVG before generating a replacement; never backfill an SVG from a PNG
and call that SVG-first creation.
The approval and request are recorded in PLAYTEST-51 and `DECISIONS.md` under Eight-direction
style transfer.

- [ ] Inventory every current tracked SVG, including the prepared environment graphics and the new
      directional families, into a conversion manifest with source path, PNG destination,
      dimensions, anchor, usage and review evidence. Include root application/identity SVGs;
      exclude the historical archive. Reconcile newly added SVGs before closing the item.
- [ ] Add an asset-pairing check covering every PNG asset and its source SVG, with explicit
      mappings for non-mirrored paths. Keep raw generator outputs and captures in evidence.
      Record SVG review and generation provenance so ordering is reviewable; reject PNG-only
      additions instead of accepting a later placeholder SVG.
- [ ] Transfer all entity SVGs and every directional/animation/state layer. Preserve native
      canvases and exact SVG alpha, and keep tintable body/trim separation and authored identities.
      Save original generation outputs, exact prompts, reference roles and reproducible extraction
      and registration inputs. Inspect detail and animation consistency at gameplay scale.
- [ ] Transfer terrain, building tiles, props, closures, checkpoint structures and whole-street
      scenes, retaining tile seams, anchors, transparent gaps, tint behavior and repeated-part
      alignment. Convert prepared assets too without prematurely binding their gameplay.
- [ ] Convert UI, cue and identity SVGs while preserving their symbols, text, legibility and
      exact geometry. Keep code-drawn graphics and shader behavior under their current owners.
- [ ] Audit all loading paths: shared drawing helpers, direct textures, TileSets, scenes/resources,
      UI buttons, the application icon and identity/export consumers. Provide registered PNG
      bindings for every live SVG without altering draw transforms; verify both flag states and
      missing/mismatched fallback. The SVG override remains the comparison control during review.
- [ ] Review catalogue completeness, native-size quality, alpha, seams, tinting, cues, all eight
      facings and moving-state consistency. Publish SVG/PNG comparisons and purposeful gameplay
      evidence in the PR; document actual bindings and make SVG-first followed by transfer the
      graphics authoring procedure. Archive outputs suggested for human review or rejected by a
      human; keep drafts rejected only internally by an assistant outside the repo. Keep import
      metadata only outside folders excluded by `.gdignore`.

### Gameplay queue

**Upcoming SVG parts are listed with their owning milestones below:** the lunging guard,
directional pointing poses, district accents and discrete sound arcs. Reuse the available
assets when implementing those systems; their placement, timing and gameplay decisions remain
open. DECISIONS.md, "SVG artwork and upcoming milestone assets", records the visual review.

Prioritised on 2026-09-09, in the player's words where a sentence decided a place.

1. **M56**'s build item, the other rows that hunt. *("M56 is also related to the other items to
   work on right now.")* Its measurement against the nerves waits, because reaching act III
   waits: *"I wanna wait reaching act III until those things are done."*
2. **M113** — the inspection reads as one: a two-second hold at a checkpoint during which she and
   the guard are gone and the camera eases onto the hut. *(2026-09-10, playtest 55.)* Placed here
   by the orchestrator because it is the first thing act III shows and it was seen once; open to
   the player moving it.
3. **M110** — the crowd goes round a seal. *(2026-09-10, playtest 52: "objects like fallen trees
   don't stop/redirect traffic or pedestrians.")* Placed here by the orchestrator because a sealed
   street the crowd walks through is the sealing's own legibility failing — open to the player
   moving it.
4. **M96 to M100**, in no order between them: the teaching day, the calm areas, the empty acts,
   the corridor's density after the sealing, and the consolidated small work. Each was rewritten on
   2026-09-09 from an older milestone after checking which of its items the code had already
   answered; the record of what was found built is in `DECISIONS.md` under "The queue
   reprioritised". **M105, the city degrades, M106, roofs, fronts and street trees, and M107, the run
   clock, sit in this batch provisionally** — they were asked for on 2026-09-10 and not placed,
   so this is the orchestrator's guess at where work that needs no route decision belongs, open
   to the player moving it.
5. **Reaching act III**, which M56's measurement against the nerves needs.

**The regions, their walls and their checkpoints are built and nobody has walked through one.**
The record, with its measurements and the choices open to overturn, is in `DECISIONS.md` under
M62. What only a played day answers: whether a wall at a street's mouth reads as a district edge
or as one more closure, whether being held six seconds at a hut and let out the far side reads as
a toll or as a bug, and whether the day's doors leave the route decision standing — two doors is
a choice, one door is a corridor with a toll booth.

**Nothing in this queue is held back for being a drawing.** *(2026-09-07: "let's remove the note
about not working on graphics because it causes much confusion.")* Every item is ordered on what it
does to the route decision, the same as everything else. Prepared drawings remain available
while their owning milestones settle placement and behavior.

Use [GRAPHICS.md](GRAPHICS.md) for the asset catalogue, current runtime bindings and prepared
parts. The assignments below name the assets each graphics-dependent milestone should use.

**Bind prepared environment art with its existing gameplay owner.** These are integration
checks within those milestones, not separate implementations of the same feature. Source canvases,
anchors and review sheets belong to `GRAPHICS.md`; runtime use must be verified in the caller.

| Owner | Integration work and acceptance |
|---|---|
| M56 — The resistance is noticed | Bind the riot van's directional family and standing/lunging guard poses to the actual waiting, departing and pursuit states. Preserve the waiting silhouette and telegraph; use M108's heading selector rather than a second direction table. |
| M100 — Small, real, and nobody's | Review `chalk_mark.svg` beside `chalk_mark_touched.svg`, then bind the touched state to the acknowledgement she adds when contact counts. Keep the original mark visible and readable on the pavement. Compare `alley_draft.svg` in context before deciding whether it replaces the live alley. Bind the mouse family with the alley event and the sound arcs with their event timing; source availability does not decide either behavior. |
| M102 — The finale: out of the apartment, out of the city | Build the interior TileSet/map binding for hallway, stairwell and basement floors/edges/walls. Register doors, barricade, chandelier and puddle separately; retain the south hallway's implied door thresholds. Bind normal/flash windows to explosion timing, steam to its pulse, and carrying-mother facing/gait to actual movement. Reuse mouse, guards, vehicles and crater sources. Decide whether the optional `explosion_preview.svg` is needed; the off-screen explosion brief does not require a visible burst. Check room transitions, foot anchors, layering and state changes in runtime evidence. |
| M105 — The city degrades | Register the three crack levels and two patterns for each road/sidewalk/alley base in the TileSet, preserving markings, kerbs, seams and tile semantics. Place the five flat litter decals under actors; place single/piled sacks with the milestone's obstruction decision. Select matching `storefront_{a,b,c,d}_shuttered.svg` variants through M106's frontage binding. Compare a fixed seed across acts. |
| M106 — Roofs, fronts and street trees | Bind roof units and both vent phases in `Building`, preserving the fixed housing while the rotor changes. Assemble straight/corner ducts with matching joins; keep furniture inside roofs. Bind each storefront's plain/awning/shuttered states without moving its door, place fire escapes over existing walls/windows, and select tall/shuttered window pairs. Centre `tree_pit.svg` beneath the existing standing tree. Verify tint, depth, overhang and registration in district comparisons. |

The impact-crater decals `assets/props/impact_crater_1x1.svg`,
`impact_crater_2x2.svg` and `impact_crater_3x3.svg` (32×32, 64×64 and 96×96 footprints) are the
finale's: the marks its off-screen explosions leave on the street. M102 also owns the prepared `assets/rig/mother_carrying_{front,back,side,front_diagonal,back_diagonal}_{a,b}.svg`
set, documented in GRAPHICS.md; nothing binds it until that milestone is built.

**A milestone still holds either drawings or not**, so that ordering one never parks work that needs
no artist.

**M79 is tabled rather than queued.** It is the city seen at an angle — a presentation change with
the lattice left cardinal — and it is written down so that whoever chooses the projection does it
with the code's constraints in hand. It is not queued and it is not rejected.

**M102, the finale, is planned and not queued.** *(2026-09-09: "this is just a plan for now — we
probably won't actually implement it for a while (there are a lot of milestones before that)".)* It
is the good ending's last scene — out of the apartment, out of the city — written down in full so
that the milestones before it can be built knowing what they are building towards. Its four
collisions with the good ending as written today were asked and answered the same day, and the
entry records the answers in the player's words.

**[PLAYTEST-50.md](playtests/PLAYTEST-50.md) carries the seal-picture review and the new-caret walk.**
Its open findings are filed under M100: the guard robber standing inside a building, and a chalk
touch that shows only a colour change and no confirmation on a lost day's summary. The artwork
review and the player's directional corrections are recorded in `DECISIONS.md`.

**[PLAYTEST-49.md](playtests/PLAYTEST-49.md) is the session before it and it is the prioritisation above**, plus
one bug — events spawning inside a fully blocked street — filed at the top of M100's defects,
one correction, that the non-adjacency rule does not cover parks yet, filed in M97, and one design
instruction, the fire found before the engine, built (`DECISIONS.md`, M101).

**[PLAYTEST-48.md](playtests/PLAYTEST-48.md) is the newest gameplay session, and its one note is built**:
the signal head north of a junction, which faces up the screen, shows its back and no lamp. The
record is in `DECISIONS.md` under M95.

**[PLAYTEST-47.md](playtests/PLAYTEST-47.md)'s two notes are built**: a car comes out of the tunnel and off
the bridge as well as going in, and `tools/run.sh` runs the import pass when a pulled checkout is
missing an imported texture. The record is in `DECISIONS.md` under M94.

**[PLAYTEST-39.md](playtests/PLAYTEST-39.md)'s one finding, the tunnel, is built.** The fade is inside the
portal's opening, the mountain stands above it, and the road into the mouth is asphalt rather than
a crossing; the record is in `DECISIONS.md` under "The tunnel swallows the road". Half of it was a
re-report of playtest 24's fifth finding.

The halo's design and playtest reasoning are in `DECISIONS.md` under M92.

**[PLAYTEST-37.md](playtests/PLAYTEST-37.md) finding 5, the caret inconsistency, is built as M93 and recorded
in `DECISIONS.md`.** Its junction
and border findings are recorded in `DECISIONS.md` under M53.

**[PLAYTEST-35.md](playtests/PLAYTEST-35.md)'s seven findings are all built.** Six of them landed inside M90
and M89 rather than being filed against them, because those milestones had not merged when the
findings were reported — **nothing merges carrying a defect that was already found**. The seventh,
the buttons that were rounded rectangles rather than circles, was parked by the player on sight and
then turned out to be a two-line fix; the record is in `DECISIONS.md` under "The disc is a circle
at whatever size the container gives it".

**[PLAYTEST-34.md](playtests/PLAYTEST-34.md)'s ten findings are all built** — seven as M90 and three as M91.
It is the played answer M88 and M87 were waiting for, and it is mostly a report of things that do
not respond: a button that never changes under a press, a stop circle at twice its drawn size, and
a joystick drag whose reference point walks away with the camera. **Two of its findings are
re-reports** — the pressed button was asked for in playtest 33 and the dog's short notice was
measured in playtest 20 — and each entry says so rather than designing it a second time.

**[PLAYTEST-33.md](playtests/PLAYTEST-33.md)'s thirteen findings are all built.** It is the report M83 asked
for: the two focal points a touch aims from were built and drawn as nothing, and the answer is that
they moved outward and downward and are drawn. Eight of the thirteen were M85, four raised and
extended M77, and the one question in it was M86; all three are recorded in `DECISIONS.md`. **What
playtest 34 says about it is that the pressed-button fix reached the colour and never reached the
draw state** — see M90's own item.

**[PLAYTEST-29.md](playtests/PLAYTEST-29.md)'s seven findings are all built.** Three of them were instructions
the project already had and had read as repealed by something else, and the file is worth reading for
that alone — two of its sentences are the player saying so. The record is in `DECISIONS.md` under
M83.

**[PLAYTEST-28.md](playtests/PLAYTEST-28.md)'s four findings are built** — the game has one control scheme
and no question about which: a press sets a direction she walks until the next press, a press on
her stops her, a double press runs, and the pause button in the top right is the only thing drawn.
The ending screen's own continue button, which meant nothing there, is gone too. The record is in
`DECISIONS.md` under M82.

**[PLAYTEST-27.md](playtests/PLAYTEST-27.md) is the second session on the released page and the first played
on both a laptop browser and a phone, and every one of its six findings is built.** The release
arrives under versioned URLs, the shared link carries an opaque card, the continue and restart
buttons are on both screens, a press acknowledges itself before the day it starts blocks the frame,
and the two findings about the controls themselves — tap mode dead on a laptop, and the drag stick
— are answered the same way M82 answers playtest 28: one scheme, chosen nowhere, that a mouse
click drives on every build. The record is in `DECISIONS.md` under M76, M80 and M82.

**[PLAYTEST-26.md](playtests/PLAYTEST-26.md) is the one before it and every finding in it is built**, across
the two halves of M76 and M82's own deletion of the title screen's two circular mode buttons.

**[PLAYTEST-25.md](playtests/PLAYTEST-25.md)'s nine findings are built** — the
first phone session on the built mobile game and the first human verdict on the sealed city. The
record is in `DECISIONS.md` under M73, M74 and M75. **What it leaves open is a played question.**
The barrier rows are silent, the café and the market stall now bill from their own body to the
middle of the carriageway and no further (derived under M61, the field — the player's *"that
number was so big because it was a point source before"*), and nobody has walked a city that
costs what this one now costs.

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
Read [PLAYTEST-22.md](playtests/PLAYTEST-22.md) and [PLAYTEST-21.md](playtests/PLAYTEST-21.md) before changing the
sealing: what they asked for is built and unplayed, so the next report on it is the thing that
matters.

**Playtest 20's four findings** went to M69 (a reachability gap, built), M65 (the pointing
protesters, built — `DECISIONS.md`, M65), M97 (a calm-area spoiling inconsistency) and M96 (a
measured lead-time gap on the post-tutorial `charging_dog`).

**Playtest 19's graphics and placement findings have separate owners.** The protester objective
work is built (`DECISIONS.md`, M65). The seal and barrier records are in
`DECISIONS.md` under M64, eight seal pictures, and M48, the barriers; the remaining north-edge,
junction-paint and robber-placement records are filed there under M49 and the small items.

Everything below is in the order the gameplay queue above gives it, and was reassessed on
2026-09-09.

---


## M56 — The resistance is noticed

The city gets more dangerous the further into the subquest you are. **A task may not cost a nerve**
— a nerve is a rewind, not a resource, so there is nothing to trade.

**The raid hunts; what is left of "and other dangers like this" is the roadblock, which needs a
drawing, and the measurement waits until act III is reached**, which the queue puts after M96 to
M100. *(2026-09-09: "M56 is also related to the other items to work on right now. I wanna wait
reaching act III until those things are done.")* The raid's record is in `DECISIONS.md` under M56.

**What the remaining items are stated against**, since the machinery under them exists: a row says
how it answers to the resistance with `EventDef.heat_response` — `NONE`, `PRESSES` or `HUNTS` —
`EventCatalogue.heated()` derives that row's shape at a progress level, and every one of those
shapes is validated on boot. The ladder has three rungs a player can name and both its upper ones
are built: `police_patrol` is **denser and then interested**, and `abduction` is **hunted**, taking
a bystander of its own while she watches and coming after her instead past three of four, with
`night_raid` on the same rung from day 10 — cold it closes a block, hot it comes for her. The
reasoning, and what was rejected on the way, is in `DECISIONS.md` under M56.

**Guard artwork is available for the hut interaction:** `assets/checkpoints/guard_standing.svg`
and `guard_lunging.svg` share the person's scale and keep their ground anchors in the SVG comments.
The lunging pose faces east and can be mirrored for west. These are the stationary and departing
poses for the drawing discussed below; the heat-response decision and runtime binding remain here.
Use `assets/events/riot_van.svg` for the existing night-raid vehicle;
use the guard pair for a guard departure if that proposed response is accepted.

- [ ] **The roadblock's guards leave their post.** The other half of *"and other dangers like
      this"*, filed after the raid on the draft's own recommendation — *the raid now, the roadblock
      later* — because it is a drawing where the raid was one line. What `HUNTS` does to a row is
      fixed by `EventDef.at_heat()`: at `Tuning.HEAT_HUNTS_LEVEL` (3 of the 4 performs that
      qualify) and above, the derived copy `pursues` at 130px/s, notices her within 180px, chases
      for `PURSUIT_TIME`, and is `hard_fail`. `roadblock` cannot simply switch that on: it is a
      spread — `Look.ROADBLOCK` draws a 120px band across the road through `_draw_spread`,
      intensity 13 over 52/215px, from day 7 — and a band does not chase. A hunting roadblock is
      *guards leaving their post*, a second posture like the robber's waiting/lunging pair, so the
      item is the drawing (the prepared `guard_standing.svg` / `guard_lunging.svg` pair above is
      the candidate), the `heat_response` line, a rule for what the band does while its guards
      are away, and the same named test the raid has in `tests/test_heat.gd`. The region
      checkpoints (`checkpoint_hut`, `checkpoint_gate`, `checkpoint_post`) are a separate thing
      and are never rolled by the scheduler, so they are not candidates; neither is
      `police_patrol`, the `PRESSES` rung that *"never gains `hard_fail`, whatever the heat"* —
      the player's own instruction, 2026-09-01
- [ ] **Bind the riot van's end and diagonal views.** `Look.RIOT_VAN` uses one side view, so
      a hunting raid van chasing north or south is drawn side-on. Select the prepared
      `riot_van_{front,back,front_diagonal,back_diagonal}.svg` family through M108's heading
      binding; `riot_van_end.svg` is available for the side/end caller during integration.
      Preserve the waiting-to-hunting state change and the van's native ground registration.
- [ ] **Measure it against the nerves.** This makes the back half harder precisely for the player
      doing well at the optional path, and nobody has reached act III

---

## M113 — The inspection reads as one · asked for 2026-09-10

> "the checkpoint itself, 2s should be enough -- both the guard and the player should disappear
> during the inspection, the camera should center on the hut (use a smooth ease in out for non
> player caused camera movement if possible) after the inspection the player and the guard should
> reappear"

**Today a checkpoint hold is six seconds of standing still.** `checkpoint_hut` and
`checkpoint_post` detain through `chatting_mother`'s mechanism — `Tuning.CHECKPOINT_DETAIN_SECONDS`
6.0 over a 48px `detain_radius`, `redetains` so a second approach holds again — and while she is
held nothing else happens: she stands where she was caught, the guard stands where he was drawn,
the camera stays on her. The record of the regions and their doors is in `DECISIONS.md` under M62.

- [ ] **Two seconds, and both of them gone.** `CHECKPOINT_DETAIN_SECONDS` 6.0 → 2.0. For the
      hold's duration neither she nor the guard is drawn — they have gone inside — and both
      reappear when it ends, her on the far side of the hut so being let out reads as being let
      through, the guard at his post. The pram's cue and the danger caret over her are hidden with
      her; the meters keep running, since the baby is still there. `EventDef.detain_seconds` and
      the release margin (`CHECKPOINT_RELEASE_MARGIN`, 8px) are the two numbers to re-check against
      the shorter hold so she is not re-detained on release; `tests/test_checkpoints.gd` covers it
- [ ] **The camera eases onto the hut and back.** During the hold the camera centres on the hut
      rather than on her, and every camera move that is not her walking — this one, and any later
      one — eases in and out (a smooth-step over a short, tuned duration) rather than cutting or
      using the walk's own `position_smoothing`. Today the camera is `Camera2D` on
      `scenes/player/stroller.tscn` with `position_smoothing_speed` 6, plus `main.gd`'s follow
      camera for rigs; the ease is a small focus-target on the player's camera, not a second camera.
      A test drives a hold and asserts the camera's target and its return
- [ ] **Walk it on day 7.** One capture of a hold in progress and one of the release, on the seed
      playtest 55 was played on (3045005721), in `docs/evidence/`

---

## M110 — The crowd goes round a seal · asked for 2026-09-10

> "also I noticed that objects like fallen trees don't stop/redirect traffic or pedestrians"

**The crowd knows about closures and about nothing else that stands in a street.** A walker or a
car looks `LOOKAHEAD_TILES` ahead along its lane and turns off at the last junction when
`CrowdAgent._cannot_go_on()` says the way is shut — and that predicate knows three things: a tile
outside the map, a tile that is not street (or not driveable, for a car), and a tile in
`CityMap.closed_tiles`. That set holds only what `ClosurePlanner` closes: `close_streets` floods
the day's ground from the doorstep with the closure barriers down and files whatever a closed
street's own ground the flood never reaches. **A seal is not a closure.** A hard seal — the fallen
tree, the car accident, the burst main, the burnt-out car, the collapsed frontage, the stacked
barricade — is `SealPlanner._place_hard` standing one row's bodies across the middle of a segment,
spaced so their shapes cover it kerb to kerb; a soft seal is `_place_soft` standing one body on
each pavement with the carriageway left open, and the thinning pass drops one body of some pairs.
None of it touches `closed_tiles`, so every seal stands on ground the crowd reads as open, and
walkers and cars pass through the bodies because an agent has no physics against an event body at
all. The `delivery_van` row's docstring says as much of every solid body: on the carriageway it
stands *"in a traffic lane the crowd knows nothing about and drives straight through"*.

**Why it matters more for a seal than for a café**: traffic going round a closure is half of what
makes one legible — `_divert()`'s own docstring: *"the street with nobody on it is the street that
is shut, which reads from a block away — further than the barrier itself does."* A hard seal is
meant to read as a closed street and gets none of that tell; worse, a stream of walkers passing
through a fallen tree says the street is open when it is not.

- [ ] **The region walls, their checkpoints and the roadblock are driven through too.**
      *(2026-09-10, playtest 55, day 7: "also cars go through the barriers and checkpoints".)*
      The same cause as the seals — none of it writes `closed_tiles` — and a wider set of bodies:
      `RegionPlanner`'s wall segments, its door segments with `checkpoint_hut`, `checkpoint_gate`
      and `checkpoint_post` standing on them, and the `roadblock` band. A wall segment is shut to
      the crowd the way a hard seal is. **A door lets cars through, one at a time, and the gate
      moves** — decided by the player the same day: *"at checkpoints cars should slow down halt
      then the bar should lift then the car drives through then it closes again"*. So a car
      approaching a `checkpoint_gate` brakes to a halt at a stop line before the bar, the way it
      stops for a zebra or a red (`CrowdAgent`'s zebra commit rule and braking distance are the
      model); the gate's `RegionPlanner.GateState` raises (`boom_gate_*_raised.svg` exists beside
      the lowered picture) after a short hold, the car drives through, and the bar lowers behind
      it; a queue forms behind the first car the way one forms at a light, and nothing enters the
      gate's own box it cannot leave. Walkers pass the hut as she does. **A raised bar is not a
      way past for her**: stepping into the gate while it is up for a car starts an ordinary
      inspection, exactly as if it were down — *(2026-09-10: "attempting to do that should just
      start a regular checkpoint inspection")* — so the gate's `detain_radius` holds whatever the
      bar is doing, and a test drives her at a raised gate and asserts the hold
- [ ] **A hard seal shuts its street to the crowd the way a closure does.** The map carries a
      second, crowd-facing record of the day's sealed ground — the cross-section tiles of every
      segment `SealPlanner` sealed hard, at the seal's position — and `_cannot_go_on()` treats them
      as shut, so the look-ahead sees the seal from seven tiles off and both walkers and cars turn
      off at the last junction. Not `closed_tiles` itself: that set is computed by flood and is read
      by the scheduler's placement and by the reachability picture, and a seal's ground is still
      walkable for her (the guarantee the seal body already respects). Keyed on the segment rather
      than the tile, because M100's *"events spawn inside a fully blocked street"* defect wants the
      same fact — no catalogue row placed on a hard-sealed segment — and one record should serve
      both. A test in `tests/test_crowd.gd` in the shape of *"nothing walks into a hard blocker"*:
      on a day with hard seals, no agent stands inside a hard seal body's footprint on any frame,
      and the sealed segment carries no through traffic
- [ ] **A soft seal takes both pavements from the walkers and leaves the carriageway to the cars.**
      The tiles under each soft body are shut to walkers only; a car on the road passes. A thinned
      pair leaves its open pavement open, and the walkers still using it become the tell that the
      wrong turn is takeable — which is the thinning's whole point *(playtest 22: "this makes the
      actual path the player takes feel more organic, self-chosen, and earned")*, now visible from a
      block away rather than only on arrival
- [ ] **Open question, the player's: does every other solid body divert the crowd too?** A café, a
      construction band, a kerbed van are walked through the same way. Diverting the crowd at every
      pavement obstacle spends the tell closures rely on — every obstructed street would read as
      shut — and a walker stepping *round* a body within its pavement is a behaviour the lanes do
      not have (`CrowdLanes` gives a walker one of four fixed lanes per corridor). The
      recommendation is seals only in this milestone, with ordinary bodies asked about against a
      played day; the alternative, treating any body that covers a whole lane as shut for that lane,
      is one predicate more and is cheap to add if the player wants it

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
      restricts to the teaching day. **Half of this is built and the half is not the decision**
      (`DECISIONS.md`, M96): from day 4 the director sites the dog off her heading — a bearing
      50–110° to one side, past the edge of the view — so it is never in front of her on her own
      line, and a test holds that; but it is still sited *near her* by the director, not placed on
      the map and met by routing. The agent stopped there because the map placement needs a
      day-dependent `spawn_mode` on the def (`event_def.gd`, then the scheduler reading it), and a
      second row is blocked by the one-picture-per-row check. **What remains**: the def gains a
      spawn mode for the days after `first_day` — the smallest shape is a second `spawn_mode` field
      that applies from `RUN_TAUGHT_DAY + 1`, read where the scheduler decides how a row is sited —
      `charging_dog` takes `ALLEY`-style map placement from day 4 exactly as `alley_robbery` does,
      the off-heading siting goes, and `_teach_the_run()` stays untouched. The lead-time gap
      playtest 20 measured (1.5s to evade against 0.8–0.9s on the days it killed her) is closed by
      M77 already: re-measured on the current tree, the notice and the evasion window are identical
      on every heading; the figures are in `DECISIONS.md` under M96
**The run is taught on day 3, and stays there.** *Asked for as `RUN_TAUGHT_DAY` 3 → 2 · overturned
on 2026-09-09: "run taught goes to 3 not 2."* The constant gates everything that pursues, and day 3
is where act I stops being a nice neighbourhood; the options weighed when the move was first
proposed are in `DECISIONS.md` under M49, in the item "Day 3 carries act I's whole payload".

- [ ] **One contact at 89 is a cliff, measured; the rule about the last ten points is the
      player's to give.** A bump is about 10.8 points, and a rig confirmed it on 2026-09-11
      (`DECISIONS.md`, M96): one walker's startle against the baby at 90 and at 89 both end at 100
      and crying; at 85 it ends at 96.8 and awake. The pram's nearly-crying cue is drawn from 80 of
      the 100-point meter, by code rather than by eye — whether it is *read* is a played question.
      The entry's own rule stands: the fix is a rule about the last ten points, not a density
      change — a floor on what one contact may add near the top, a grace window after the cue, or
      nothing, if a walker at 89 on an empty street is meant to be the risk it is. Decide, then it
      is one constant and a test beside `tests/test_meters.gd`'s pinned measurement

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
      spoilage at all even though it was the second visit.")* `docs/playtests/PLAYTEST-02.md` records the
      intended shape — *"the scheduler biases a spoiling event toward a calm area the player settled
      in on day N−1"* — a bias toward, not a guaranteed minimum, which is consistent with a roll
      landing low enough some days to leave a walkable edge and high enough on others to deny the
      area outright. The run attached to playtest 20 does not carry the exact four-visit sequence
      the player describes — its own biased parks (`(1,1)` and `(4,8)`) were dense on every biased
      day the log shows. **The zero-density visit does not reproduce on the current tree**, measured
      2026-09-11 with `tests/probes/m97_spoilage.gd` over every calm block on eight seeds — the
      record, with the distribution, is in `DECISIONS.md` under M97. What the probe found instead
      is a rare tail: a biased visit whose weighted roll draws one low-reach row for a large lot and
      leaves most of it walkable, and a bias that is mostly backstopped by the day's ordinary fill
      landing in the used park rather than by the spoil roll itself. So this waits for a played
      recurrence: if a second visit to the same park reads unspoiled again, the probe is the
      instrument and the low-reach-row draw is the suspect, and the fix is a floor on the spoil
      roll's reach for a lot that size, not a density change
**The main road is not made a soft block.** *Asked for on 2026-09-01 as a toll on crossing the
spine · overturned on 2026-09-09: "M47's toll already exists — it's timing the traffic lights. we
don't need to penalize routing through it just yet — it naturally happens that only some routes
cross it."* Waiting for a green is the crossing's price, and the route tree already puts only some
of a day's routes across the spine; nothing prices the crossing on top of that. The record is in
`DECISIONS.md` under "The queue reprioritised".

- [ ] **Re-check `MIN_CALM_BLOCKS` (5 to 7) and `MIN_HOME_TO_PARK_TILES` at the end, not the
      start** — now that the region walls stand from day 7, since a region that holds no calm
      area gets no door and the count of places to go is what the wall divides

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
      and how much of the day's clock the return actually spends — before and after. **The shape
      is not designed yet, and the measurement comes first** *(2026-09-11: "measure now, design
      after")*: the before-figures are in hand, taken with `tests/probes/m98_return_phase.gd` and
      recorded in `DECISIONS.md` under M98 — a return leg that spends a fifth to a third of the
      day and meets the director's queue once or twice, zero on one leg in five — and the shape,
      how many, where, at what cost, is the player's question now

---

## M99 — The corridor's density after the sealing · rewritten 2026-09-09

Rewritten from M50. M64 superseded M50's gradient at both ends — off the path is *closed*, on it the
density is *normal* and playtest 21's verdict on it was that it is already right — so what is left
here is what the sealing did not answer. **The corridor's own obstacle density is measured, not
raised**: M50's *"blocking events all over"* asked to raise the caps on the expensive rows, the
player's sentence on the sealed corridor was *"on the path there should be a normal amount of
events that remain passable — that looks like it is the case here"*, and the re-measurement on the
current tree with `tests/probes/m64_density.gd` is in `DECISIONS.md` under M99. A cap moves only if
a played day says the corridor is bare.

- [ ] **`cyclist` and `loose_dog`'s caps bind nowhere, and the number should say what it does.**
      Both rows carry `max_per_day` of 14 and 24 and arrive via the director's single queue at its
      11–26s pacing rather than being map-placed; measured 2026-09-11 with
      `tests/probes/m99_caps.gd` across the acts (`DECISIONS.md`, M99), a day meets the cyclist
      under once and the dog under three times on average, and never within an order of magnitude
      of either cap. The caps' meaning changed while the numbers stood still. **The player's
      choice**: either the cap is dropped from queue-fed rows, since the director's pacing is the
      cap and a number nothing reaches is a false promise — the recommendation — or it is lowered
      to the pacing's own ceiling so it reads true, with the row's doc saying which of the two
      decides the count. The record of the caps' history is in `DECISIONS.md` under M54
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

- [ ] **A roadblock band is a row of blocks, not a barrier.** *(2026-09-10, playtest 55: "the
      barrier itself also doesn't read as a continuous element. is it using the texture of the
      other orientation and concatenating that one?")* No: `Look.ROADBLOCK` is drawn by
      `_draw_spread(CHECKPOINT_BLOCK)`, which repeats `assets/events/checkpoint_block.svg` — one
      22×30 concrete block with its own frame and hazard panel — along the band with no end cap and
      no orientation sibling, so the band is identical blocks side by side. `roadworks` already
      draws as `_draw_spread(BARRIER_SEGMENT, BARRIER_END)`, a rail with caps that reads as one
      thing; the roadblock wants the same construction — a continuous held-street barrier picture
      that repeats seamlessly, with an end piece — drawn under the svg-art rules and bound in
      `_draw_body`'s `ROADBLOCK` case
- [ ] **A car's strike box sits half a car behind its picture going north, half a car ahead going
      south.** *(2026-09-10, playtest 55, read off the debug view: "the dead zone of a car is
      trailing the car instead of leading the car?")* `CrowdAgent._draw_body` draws a car with
      `Sprites.draw_standing` — bottom-centre at the node's position, so the end-on picture stands
      north of the node — while `Crowd._strike()`'s box, `will_be_lethal()`'s test, the car's
      `GroundShape` shadow and its field are all centred on the node. For a vehicle seen end-on the
      ground footprint is its whole length, so the standing anchor is the wrong one: draw the
      end-on car with its footprint centred on the position (the side view already is, along its
      length), or move the node to the picture's footprint centre — one of the two, chosen so
      the box, the shadow, the field and the picture agree in the debug view, and asserted by a
      test that samples the drawn footprint against the strike box
- [ ] **A queued car grazes a big building's footprint, and the M53 assertion was loosened to let
      it.** `tests/test_crowd.gd`'s *"nothing walks into a hard blocker"* asked for exactly zero
      agents ever standing inside one; it now tolerates one agent on under 5% of frames, measured at
      1.1% — one car on 27 of 2400 frames. The cause is a crawl-forward step in a traffic queue
      stepping one tile into a footprint, in `src/crowd/`. Fix that and the assertion goes back to
      zero, which is the only acceptable end state: a car standing inside a building is visible, and
      the test's own name is a promise
- [ ] **The pram has no collision of its own.** `scenes/player/stroller.tscn` carries one circle
      for her, so the pram clips into walls when she hugs a corner. A second body that trails her,
      or a capsule that rotates with `facing`
- [ ] **A pursuer streamed out mid-chase comes back having forgotten it.** `EventInstance.resume()`
      restores the age and the distance travelled but not `_noticed_at`, and a fresh instance starts
      with that at `INF` — so a `pursues_within` row streamed out after it has noticed her returns
      waiting, standing where the day planted it. Not currently dangerous: `alley_robbery` has had
      it since the mechanic was built, and the heated patrol that surfaced it can never be
      `hard_fail`. **Half built** (`DECISIONS.md`, M100): `resume()` now takes the notice as a
      third, defaulted argument and restores it, and `tests/test_heat.gd` holds that for every
      `pursues_within` row. **What remains is the caller**: `EventManager._stream_in()` never
      captures a streamed-out instance's notice, because `EventScheduler.Planned` has no field for
      it — so the argument is always its default and the behaviour is unchanged in play. The fix
      is the field on `Planned`, written when an instance streams out and passed on `resume()`,
      with a test that streams a noticed pursuer out and back through `EventManager` itself
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
- [ ] **`--spawn event:<id>` stands the rig in the carriageway on an east–west street.** The
      offset `main.gd` applies to the found event's position is along local X whatever the street's
      orientation, so beside a spread that faces an east–west street she is put on the road rather
      than the pavement, and a screenshot rig can lose the day before the frame is taken. Found while
      photographing the seal pictures; the fix is to offset across the street's own axis, which
      `EventInstance._spread_is_vertical()` already answers
- [ ] **What is still dev-only inside `main.gd`.** `DevFlags` took the flag parsing out; what stayed
      is the code that acts on it — `_first_event_position` and the `--spawn` target lookup, both of
      which read the live city. Worth finishing the next time the file is opened for another reason

**Drawings, as SVG:**

**Vehicle collision and silhouette agreement is checked with M61, one shape per object, and
the debug view's bounding-box layer (`3`).** Skip and burnt-out-car obstructions remain circular; the moving van uses
a capsule. Shape-derived bodies do not alone establish that apparent gaps can be walked through:
the live body and picture's footprint still need comparison with the debug layers. The directional
artwork, the player's perpendicular burnt-car correction and the rendered evidence are in
`DECISIONS.md`, "SVG artwork and upcoming milestone assets".

- [ ] **A mouse in the alley.** *(2026-09-10: "we can reuse the mouse for alleyways as well.")* A
      new catalogue row placed on `ALLEY` tiles: a mouse that darts across the alley when she comes
      near, the `cat_dash` shape — a short pulse, no body, nothing lethal — at a lower intensity,
      since it is a startle rather than a threat, and the alley's own `+3.0` a second of dread is
      already the row's setting. The picture is `assets/events/mouse.svg`, shared with
      M102, the finale, and its prepared directional family. Which acts it appears in and its cap are the build's
      to derive from the cat's, and its dash is aimed across the alley's short axis so it crosses
      her path rather than running down it
- [ ] **Park trees clump.** `City` places them by rejection sampling inside the lot with no
      spacing test. Add a minimum-spacing check while retaining `assets/props/tree_a.svg` and
      `tree_b.svg`, the two existing variants drawn by `Prop`.
**The `INDUSTRIAL` and `CIVIC` districts reading differently moved to M106 on 2026-09-10**, where
the roof furniture and the fronts are placed per district; the prepared `industrial_vent.svg` and
`civic_portico.svg` are its first two pieces.

**Polish, after the playtest work**, since there is no point polishing a loop that is about to be
re-pitched:

- [ ] **Sound lines** — concentric arcs off a source on a pulse's rising edge, the visual form of a
      discrete noise. `assets/events/sound_pulse.svg` supplies three open arcs in a 48×32 canvas,
      anchored at (24, 32); pulse timing, orientation and runtime binding remain. The last gap in
      the visual channel comes **before** audio.
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

- [ ] **A touch on a chalk mark shows nothing at the moment but a colour change, and nothing at
      all if the day is then lost.** *(2026-09-09, playtest 50: "how do I know I stepped on the
      chalk", then "I walked over the chalk why didn't it count?" — it had.)* A touch turns the
      mark from chalk white to pale green (`Palette.CHALK` to `CHALK_DONE`) under her feet; the
      `resistance ....` dots are performs only, so a pick-up moves none; and the mark's own words
      (`GameState.pending_resistance_brief`) are appended by `DaySummary._resistance_line()` on
      the **won** branch of the summary only, so a mark touched on a day she then loses says
      nothing until the end of the next won day, while the touch itself survives the nerve. The
      design's own rule is no quest log — *the first encounter comes with no hint at all* — so how
      much a touch may say is the player's call: nothing more; the mark's colour made
      unmistakable; the brief shown on a lost day's summary too; or a one-line status change on
      the pick-up itself. PLAYTEST-53 requests a distinct touched-mark SVG for review: she adds
      something to the existing mark to indicate she has seen it. `chalk_mark_touched.svg`
      prepares that acknowledgement; selecting and binding the feedback remains here
- [ ] **Three cues on one screen needed asking about, and an alley read as a roof.** *(2026-09-09,
      playtest 50: "what is shown here?", and "the robber is stuck inside the roof" of a robber
      standing beside an alley.)* The baby's unsettled cue over the pram, the alert over her and a
      honking car's halo were all up at once on `asked/016s-attempt1-asked.png` of playtest 50's
      run, and none of them named itself; the two-tile alley behind a building read as its roof.
      Whether each mark is told apart on sight is not a rig question; the alley's own tile picture
      is a drawing item if the reading persists

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
      far side early and steer her across late, which is a mechanism nobody has designed. The
      regions may settle it, since a region with nothing left in it gets no door unless the
      day's route passes through it
- [ ] **Could the meter bars be turned off entirely** — deferred, not open. *(2026-09-02: "we can
      keep the bar for now and think about the diegetic face later on.")* The minimal HUD keeps the
      bars and drops the status line beside them, so what gets tested first is whether the pram
      alone can carry the baby's state on the half that was cut. **What comes back with it is a
      face**, the meter read off the baby rather than off a strip at the bottom of the screen — the
      same shape as the audio item's *breathing as the diegetic version of the meters*. Not
      designed, and it needs the playing that the status-line cut is about to produce

---

## M107 — The run clock · asked for 2026-09-10

> "can you add an in-game timer that counts up during gameplay (and stops when paused or between
> days). for now let's keep it hidden and only show it on the win screen"
> "all endings show the game timer -- with millisecond precision"

**One number per run: seconds actually played.** Not the day's countdown, which `HUD` already shows
as `%d:%02d` off `DAY_LENGTH_SECONDS` and which resets every day, and not wall time: the sum over
the run of the time the world was moving. It runs while a day is `WALKING` or `RETURNING` and the
tree is not paused, and stops for everything else — the pause screen (`get_tree().paused`), the day
summary, the title screen, a lost day's restart, and the moment `main.gd` pauses the tree at a
day's end. So a retried day's first attempt still counts (it was played), and a minute spent on the
summary does not.

- [ ] **`GameState.play_seconds`**, reset in `start_run()` with the rest of the run, and advanced
      by one owner — the same `_process` in `main.gd` that already knows the phase and the pause
      state — rather than by the HUD or the day loop, so there is one place it can be wrong. It
      is run state, so it goes with the run into a save the day M100's save item is built
- [ ] **Hidden during play, shown on every ending, to the millisecond.** *"for now let's keep it
      hidden"*, then *(2026-09-10: "all endings show the game timer -- with millisecond
      precision")*: no HUD, no pause screen, no day summary. `DaySummary.show_ending()` appends
      one line for every `GameEnums.Ending` — bad, neutral and good alike — the time played as
      `%d:%02d.%03d`, under the ending's body. The millisecond format is the one M102's finale
      clock uses, so the two share a formatter rather than each carrying a string
- [ ] **A test that the clock only moves when the world does.** Drive `main` through a walking
      frame, a paused frame, a summary frame and a title-screen frame with a fixed delta and
      assert which ones advanced it; and that `start_run()` zeroes it. One `run.log` line at the
      run's end carries the total, since the run's own record is the place a number like this is
      read from later

---

## M105 — The city degrades · asked for 2026-09-10

> "we need cracked street/sidewalk tiles to be able to deteriorate the city. we need loose garbage
> (eg eaten apple, newspaper, etc) that can be spread around throughout the city to show basic
> services failing towards the later acts (it can be defined by a density factor for placement
> which can increase with the days starting at day 4 or 5). we need garbage sacks that can be
> placed in alleyways at first and at the side of buildings later on as the city degrades."
> "floor tiles of the city need different levels of cracks"

**What the street looks like is the act, told without a word.** The acts are already narrative —
the crowd thins from act III because *"there is nobody left going out on them"*, blocks go
`BOARDED_UP` and `BURNT_OUT` — and the ground under her feet says none of it. This milestone gives
the city a visible decline that rises with the day: cracks in the road, litter on the pavement,
sacks in the alleys and then against the buildings. **None of it changes what a route costs**, on
purpose: it is presentation, and the one exception — a sack pile that stands in the way — is stated
below rather than smuggled in. The prepared pictures are catalogued in `GRAPHICS.md`; this
milestone places them.

- [ ] **One degradation curve, in `Tuning`.** A density per tile that is zero through the early
      days and rises from `DEGRADATION_FIRST_DAY` — *"day 4 or 5"*, the player's range, and the
      build picks one and says why — to the last day, the way `budget_for(day)` rises. Everything
      below reads that one number, so the city degrades as one thing rather than as three
      unrelated ones; a per-block factor can sit on top of it later (a `BURNT_OUT` block is
      further gone than a residential one) but is not the first version
- [ ] **Cracked ground, by level — variety and gradient.** *("different levels of cracks … so we
      can add variety and gradient.")* `GroundTiles` chooses a tile's crack level from the curve
      and a per-tile hash, so the same tile shows the same crack every day and more tiles show
      worse cracks as the run goes on: hairline first, cracked, then broken. That is the gradient
      in time; the gradient across the map — a block further gone than its neighbour, the
      industrial edge worse than the residential middle — is the per-block factor the first item
      leaves for later, and the levels are what make it expressible. The patterns within a level
      are the variety, picked by the same hash. Pavement before road, since it is what she walks
      on and what she sees. A crack changes nothing about the tile — not its type, not its cost,
      not the crowd's lanes
- [ ] **Loose litter, spread by the curve.** Small ground decals placed at generation each day from
      the curve and a seeded roll, on pavements, alleys and squares, never on the road's lanes
      (where a decal under a car reads as a bug) and never inside a calm area (a park with litter
      in it is a spoiled park, and spoiling has its own mechanism). Decals only: no body, no
      field, no y-sort — they lie under everything
- [ ] **Garbage sacks, alleys first.** Sacks stand in alleys from the first degraded day and beside
      building fronts later, the second threshold another day or two on: *"in alleyways at first
      and at the side of buildings later on"*. A single sack is decoration with a `GroundShape`
      and no body; **a pile may carry a body** — an alley narrowed by rubbish is the one place this
      milestone could touch a route, and whether it should is decided when a pile is seen in an
      alley she has to use, not before. The mouse in the alley (M100) is placed by preference
      beside a pile once both exist
- [ ] **The storefronts shutter.** M106's `storefront_{a,b,c,d}_shuttered.svg` replaces a block's storefronts
      when the block goes `BOARDED_UP`, and from a later point on the curve for any commercial
      block, so the degrading city and the block purposes tell one story rather than two
- [ ] **A rig picture per act.** Four screenshots of the same seed on days 1, 5, 9 and 13 from the
      same doorstep, so the curve is judged as a sequence; the record goes to `DECISIONS.md`

---

## M106 — Roofs, fronts and street trees · asked for 2026-09-10

> "we need stuff on top of roofs -- we have an air duckt already -- it needs to be animated. but we
> need other things on roofs as well (there are reference photos to draw ideas from). we need more
> varied building fronts. storefronts, fire escapes."
> "we could also add trees that can be placed in the street. right now the fallen tree doesn't make
> that much sense"

**The buildings are the same wall and roof repeated, and the districts are told apart by nothing
but height.** `Building` composes every facade from `wall.svg`, `wall_base.svg`, the two window
tiles and the edge tiles, and every roof from `roof.svg` and its edges; `INDUSTRIAL` and `CIVIC`
differ only in storeys. The prepared pictures are catalogued in `GRAPHICS.md`; this
milestone places them so a street reads as a place, and a district as a district, at a glance.

- [ ] **Roof furniture, placed per building at generation.** A seeded pick from the roof units by
      district — vents, ducts and HVAC boxes on `INDUSTRIAL`, skylights on `CIVIC`, water tanks and
      the odd vent on `RESIDENTIAL` and `COMMERCIAL` — sited on the roof's interior cells so
      nothing overhangs an edge, a count that scales with the footprint, and a duct run laid as a
      straight-and-corner chain. The vent animates by alternating its two frames on the building's
      own timer, and nothing else on a roof moves. Drawn by `Building` above its roof tiles, so a
      roof unit is never y-sorted against anything on the street
- [ ] **Fronts, per district and block purpose.** `COMMERCIAL` ground floors take storefronts, with
      an awning on a seeded share of them; `CIVIC` takes `civic_portico.svg` at its entrance; fire
      escapes go on `RESIDENTIAL` facades at a seeded share, two cells tall over the existing
      windows. A storefront is a `wall_base` replacement and a fire escape is an overlay, so
      `Building`'s composition changes in two places and the tint rules stay. The awning is the
      one piece that leaves the facade plane, and it stays out of the pavement's walkable band.
      Fire-escape flights run sideways parallel to the facade and reverse direction at landings;
      retain their transparent treads and rail gaps over windows. Use PLAYTEST-53's exterior
      reference for that construction, with the prepared SVG's native placement contract.
- [ ] **Street trees.** Trees on the pavement, in pits, along `RESIDENTIAL` and `COMMERCIAL`
      streets at a seeded spacing — never on a crossing, never within a tile of a door or a
      checkpoint, and never on the main road's pavements where the crowd's lanes are densest. A
      street tree is a `Prop` like a park tree, feet-anchored so she passes behind its canopy, and
      it carries a `GroundShape` with a small body, since a trunk is something you walk around.
      **This is what makes the fallen tree make sense**: a street with trees on it can have one
      down across it. `fallen_tree`'s own placement then prefers a street that has standing trees,
      and the closure marker's picture is checked against the standing drawing so the two read as
      the same tree
- [ ] **The district comparison.** One rig screenshot per district at gameplay scale, side by
      side, so *reads differently at a glance* is judged by a person rather than by the count of
      units placed; the record goes to `DECISIONS.md`

---

## M102 — The finale: out of the apartment, out of the city · asked for 2026-09-09

**Planned and not queued.** *("this is just a plan for now — we probably won't actually implement
it for a while (there are a lot of milestones before that).")* Written down now so that M62
(checkpoints that divide the map), M56 (the resistance is noticed) and M100's sound lines are
built knowing they are also the finale's parts, as M101 (the fire found before the engine) was.

**The brief, in the player's words:**

> "for the good ending. after completing all tasks. after the last day ends the next scene is the
> hallway in front of the apartment at night with the player holding the sleeping baby (sleep bar
> is full) the goal is to escape. masked men are trying to capture the player, army trucks are
> driving on the streets, explosions happen off screen (but loud enough to cause excitement)
> leaving craters on the street. burnt cars, blockades, craters, etc. block paths through the city.
> but before reaching the city we need to get out of the house. elevator is non-functioning so we
> need to take the staircase down a few floors (not excessively many). the main entrance of the
> building is barricaded so we need to go to the basement walk through the basement corridors to
> the service entrance. we can keep the events inside the house relatively minimal. maybe some
> mice. some masked pursuers that run up the stairs that can be avoided by going into a corridor
> and letting them pass. there might be a fire on one staircase forcing us to use the other
> staircase (all buildings have two egresses). maybe some steam in the basement etc. once back on
> the street grid (emerging from the service exit on the side of the main building). no regular
> cars or regular people on the street. there is a single path through the city that crosses three
> parks (the player can use them to calm down or get the baby back to sleep if it wakes up) ending
> at the tunnel or bridge (or maybe one path for each and the player can choose). this is the
> climax of the story with lots of lethal and dangerous events. help messages show "escape the
> apartment" and "exit the city" in the appropriate places (only in the beginning of each section
> like normal tutorial hints). the timer shows milli second precision for dramatic effect (instead
> of the regular second precision of the main game)"

**What it is, in the game's own terms.** A fifteenth walk that is not a day: no route to a calm
area and home, but one way out, played in two sections that each open with one hint line and share
one clock. The verb is unchanged — *where do I walk* — and the pressure is the same two meters: the
baby starts asleep with sleepiness full, and everything on the way is a reason for her to wake.

**Section one — the apartment.** *"escape the apartment"*, said once at the start, the way the
HUD's `_say()` teaches tapping and running on day 1 and then never again. The building is the
home lot's own block, seen from inside for the first and only time in the run: the hallway outside
the door at night, a dead lift, and two stairwells: one at the building's left side and one at its
right side. Within each stairwell, flights zigzag sideways across the view with landings between
them, as in the two stair references in `docs/reference/` (`stairwell-switchback-interior-01.jpg`,
`fire-escape-switchback-exterior-01.jpg`). They do not recede front-to-back.
The two egresses (*"all buildings have two egresses"*) lead down a few
floors — three or four, *"not excessively many"*. The main entrance is barricaded, so the way out
is down past the ground floor into the basement, along its corridors to the service entrance on
the side of the building. Events here are *"relatively minimal"*: mice; masked pursuers who run up
a staircase and can be let past by stepping into a corridor, a moving wall she avoids by not being
on its line; a fire on one staircase that closes it and forces the other; steam in the basement.
Each is the existing vocabulary indoors — a pursuer is a mobile row on a path, a fire is
`burning_building`'s flame at a stairwell, steam is a stationary field on a corridor — and the
section wants at most one of each.

**Section two — the city.** *"exit the city"*, said once at the service exit. The city she knows,
with nobody in it: `CROWD_PEDESTRIANS_PER_ACT` and `CROWD_CARS_PER_ACT` give act IV 70 walkers and
16 cars, and this scene has zero of both — *"no regular cars or regular people on the street"*. In
their place, army trucks on the carriageways, masked men on foot and in vans trying to take her,
and explosions off screen, loud enough to reach the meter, each leaving a crater on a street. Off
the one open route everything is sealed with the finale's own pictures — burnt cars, blockades,
craters — which is `SealPlanner`'s existing job with a different candidate list: it already seals
every street off the day's tree. **But the finale's route is not a tree.** *(2026-09-09: "the
finale route is *not* a tree any more. it's a single path going to the first park, then the second,
then the third, then the exit. no overlapping routes".)* A day grows several strands to several
calm areas and counts two distinct routes to each as a max flow; the finale has one ordered chain
— service exit, first park, second park, third park, edge — with no branch, no second way to any
of them, and everything off the chain sealed. The parks are the only calm on the way and are for
*"calm down or get the baby back to sleep if it wakes up"*; the edge is the tunnel at the north
end of the main road or the bridge at its south end, the two exits `CityEdge` already draws and
already lets her walk into.
*"Lots of lethal and dangerous events"*: this is the climax, and the density rules that keep a day
fair (`_room_around`, the telegraph contract, off-corridor exemption) still hold — lethal things
are dense, not unfair.

**The clock shows milliseconds** — `HUD._on_day_time_changed()` formats `%d:%02d` today and the
finale formats `%d:%02d.%03d` — *"for dramatic effect"*, and nothing else about it changes.

**The parts that already exist, so nobody draws or builds them twice.** The impact craters at
three sizes, `assets/props/impact_crater_1x1.svg`, `_2x2` and `_3x3` (32, 64 and 96px, ground-centred,
catalogued in `GRAPHICS.md` as prepared with no owner), are the explosions' marks and this
milestone is their owner. `burnt_out_car.svg` with its vertical sibling, `barricade_pile.svg` and
`checkpoint_block.svg` are the finale's seals and are already seal candidates or barrier rows.
`army_truck.svg` and `army_truck_end.svg` are the trucks; `unmarked_van.svg`, `unmarked_van_end.svg`
and the `abduction` row are the masked men in vans; `guard_standing.svg` and `guard_lunging.svg`
are masked men on foot; `flame.svg` is the staircase fire; `sound_pulse.svg` is the arc an
off-screen explosion draws, once M100's sound lines bind it. The player herself is drawn:
`assets/rig/mother_carrying_{front,back,side,front_diagonal,back_diagonal}_{a,b}.svg` are the mother's ten sources with
the baby in her arms and no pram, on the same canvases and feet anchors as the walking set, so
`Stroller` can swap them in facing for facing. Prepared drawings, each listed with its contract in
`GRAPHICS.md`: the hallway with its flashing windows and its floor edge that implies the apartment doors,
the stairwell with its mechanical floor and its door seen only from inside, the entrance and the
furniture heaped against it, a chandelier, the basement's gloomy floor, brick walls and puddles, the
emergency exit, a dead lift door, mice, steam, and an explosion row's own picture if one is wanted
beyond the arc and the crater. The original room list is preserved in `DECISIONS.md` under
M103, the drawings the queue owes.

**What is genuinely new, and the order to build it in:**

- [ ] **The building is built and empty** — M112, the escape scene, walkable, in `DECISIONS.md`:
      one map with three hallways, two switchback stairwells, the lobby and the basement, doors
      that fade and teleport, her carrying the baby, all behind `--start-escape`. What this
      milestone adds inside it: the entry from day 14's summary
      rather than from a flag, the exit through the service door onto the city map at the home
      lot's side, the hallway windows that **flash** when an off-screen explosion goes off (the
      explosion row's cue indoors, one or two frames of `hallway_wall_window_flash.svg`), the
      chandelier as the hallway's light, and the events — mice, the pursuers on the stairs, the
      fire on one stairwell, the steam
- [ ] **A finale plan for the city map.** An ordered chain, not a `RouteTree`: service exit to
      first park to second to third to the edge, one street-walk between each pair and nothing
      else open. `RouteTree.for_day` and its redundancy guarantee (two distinct routes to each calm
      area, counted as a max flow) are exactly what the finale must *not* do, so the chain is its
      own small planner that reuses the reachability grid and hands `SealPlanner` the set of open
      cells — a route *out* must never count as a route to a calm area, which is the rule
      `CityEdge` and `tests/test_blocks.gd` already keep. Crowd at zero, and a scheduler budget of
      army trucks, abductions and explosions rather than the act's ordinary catalogue
- [ ] **An explosion row.** Off screen, a short burst of intensity high enough to reach her from
      out of view, a sound arc when M100's sound lines exist, and a crater left behind as a scar
      the way `barricade` leaves one — `spawns_on_finish` naming a crater row whose picture is one
      of the three prepared sizes, obstructing at the size it is drawn
- [ ] **The two hint lines, the millisecond clock and the section restart**, each a small change
      to `HUD` and `DayController`: the clock formats milliseconds, and the day-lost path restarts
      the section rather than ending a day
- [ ] **The summary after it**, which is the good ending's epilogue: the tunnel or the bridge
      behind her, and nothing triumphant

**Four things the brief collided with in the finale as `docs/NARRATIVE.md` writes it today, each
asked and each answered by the player on 2026-09-09:**

1. **The sabotage stays, and the escape is what it causes.** *("yes, the sabotage is the cause of
   the brutal crackdown.")* Today the good ending is `RESISTANCE_GOAL` reached *and* the day-14
   step "The last night" touched (`ResistanceSteps._finale`, a civic-district contact that sets
   `sabotage_done`), and its reward is mechanical quiet: every `city_wide` source is silenced and
   she walks home on the easiest ground in the run. That stands. The quiet walk home is the breath
   before the climax; the hallway scene follows it the same night, and the trucks and the masked
   men are the regime's answer to what she did. *"No triumphalism"* still governs what is shown
   after the tunnel.
2. **Losing the finale restarts the section, at no Nerve cost.** *("sounds good at that point you
   earned it.")* A day lost costs one Nerve and the day is over; the finale has no next day, and
   the run is already won on paper. Capture, the meter reaching 100, or the clock running out each
   put her back at the start of the section she was in — the hallway, or the service exit — with
   Nerves untouched. A fourteen-day run is never thrown by one wrong turn in the last minutes.
3. **The clock is a day's clock with milliseconds on it, and zero loses.** *("the timer for the
   sequence is the same length and running out loses (the bridge/tunnel collapses or something
   like that). the only change is that in addition to minutes and seconds the timer also shows
   milliseconds. this makes the timer appear faster than just the seconds alone which adds
   additional tension.")* So: one clock for the whole sequence, `DAY_LENGTH_SECONDS` (180s) long
   like any day, counting down through both sections; at zero the way out is gone — the bridge or
   the tunnel collapses, or something of that shape — and the section restarts as in 2. The only
   change to the clock itself is the format, `%d:%02d.%03d` in place of `%d:%02d`, because
   milliseconds ticking make the same countdown read as faster.
4. **Two paths.** *("two paths it is.")* Two chains of the shape above, one ending at the tunnel
   at the north end of the main road and one at the bridge at its south end, each through its own
   three parks. They part at the service exit, or as near it as the lattice allows, and do not
   overlap after that — *"no overlapping routes"* — so the choice is made once, at the door, and
   is the game's verb; the home lot sits between the two ends of the main road so neither exit is
   trivially nearer.

**And what the finale is not.** No fighting, no button — the tone rules stand: the danger is
noise, the men are the same masked men as act III's abductions, and the baby is never threatened by
anything but being woken.

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
