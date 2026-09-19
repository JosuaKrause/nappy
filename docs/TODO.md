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
pictures to their actual runtime consumers. The crowd walkers and the event people, animals and
riders are bound, through the shared `EightDirection` selector every family below extends
(`DECISIONS.md`, M108, the crowd walkers; M108, the event people); the gunman and the mouse stay on
their single side picture by the choices recorded there. Moving families use two frames per view
(`DECISIONS.md`, M108, the walkers' stride; M108, the event strides), with three mother
poses in each of the pushing and carrying open/together/opposite-open/together cycles. The
café sitters lean and the busker strums on a timer; whether a standing guard shifts is the
player's to say, and until then he keeps one frame.
- [ ] **Cars bob on their wheels.** *(2026-09-11, [PLAYTEST-56](playtests/PLAYTEST-56.md): "cars
      could bop up and down while the wheels stay in the same place")* A moving car's body rises
      and falls about a pixel on a phase advanced by its speed, and its wheels stay on the ground.
      A crowd car is two layers today, `assets/crowd/car_{view}_{body,trim}.svg`, the tintable
      paint and one trim holding windows, tyres and lights together, so the wheels come out of the
      trim into a third layer per view, `car_{view}_wheels.svg`, SVG first and on the same canvas
      and anchor; body and the remaining trim bob together, the wheels draw fixed, and a stopped
      car sits still. The halo traces the bobbing silhouette as it does the mother's lift
      (`EntityHalo` asks each owner for its `bob()`; the crowd's answers zero today). Crowd cars
      first, with the vehicle binding below; the event vehicles that move — the police car, the
      vans, the lorry, the fire engine — the same way, and a parked one sits still
- [ ] **Verify and document each binding increment.** Update `GRAPHICS.md` from prepared to live
      only for callers actually wired. Check SVG override and illustrated fallback so an available
      cardinal PNG cannot replace a newly selected diagonal SVG or lose its state/registration.
      PNG generation stays with M109, convert the SVG catalogue to PNG. Use focused selector and
      caller tests, import/boot checks and movement evidence; keep prepared families unbound until
      their gameplay owner needs them. M56, the resistance is noticed, owns guard/riot-van states;
      M102, the finale, owns the carrying mother and interior sequence. The protester's eight
      pointing poses are bound (`DECISIONS.md`, M65).

### M109 — Convert the SVG catalogue to PNG

Follows M108, eight-direction entity graphics. Use the approved SVG-first workflow in
[VISUALS.md](VISUALS.md) and the illustrated-png skill. The supplied diagonal urban and cardinal
gameplay references define the comic drawing style; each SVG defines the subject and functional
placement. PLAYTEST-64 requires transferring the idea, with redrawn forms and expressive ink
and shadow shapes, rather than copying the primitive drawing and adding surface texture.
**Every PNG asset must have a corresponding SVG asset, authored and reviewed first.** This is
a permanent authoring requirement, not only a conversion step. Audit existing PNG-only assets
and author their source SVG before generating a replacement; never backfill an SVG from a PNG
and call that SVG-first creation.
The approval and request are recorded in PLAYTEST-51 and `DECISIONS.md` under Eight-direction
style transfer.

[PLAYTEST-62](playtests/PLAYTEST-62.md) requires consistent identity, materials and rendering across
all directions, animation frames and state variants. In particular, the mother carrying the baby
must read as the same woman pushing the stroller. Choose the generation method by visual results;
a shared direction/state grid is a suggested strategy. Update the illustrated-PNG skill with
findings supported by the conversion and review.

- [ ] Inventory every current tracked SVG, including the prepared environment graphics and the new
      directional families, into a conversion manifest with source path, PNG destination,
      dimensions, anchor, usage and review evidence. Include root application/identity SVGs;
      exclude the historical archive. Reconcile newly added SVGs before closing the item.
- [ ] Add an asset-pairing check covering every PNG asset and its source SVG, with explicit
      mappings for non-mirrored paths. Keep raw generator outputs and captures in evidence.
      Record SVG review and generation provenance so ordering is reviewable; reject PNG-only
      additions instead of accepting a later placeholder SVG.
- [ ] Transfer the remaining entity SVGs and every directional/animation/state layer. The player
      rig's generation records are in `DECISIONS.md` under Eight-direction style transfer,
      M109, the carrying mother as one family, and M109, named carrying redraws. Preserve native
      canvases and functional anchors, and keep tintable body/trim separation and authored identities.
      Preserve the redrawn silhouette and true transparency instead of restoring primitive SVG alpha.
      Save original generation outputs, exact prompts, reference roles and reproducible extraction
      and registration inputs. Inspect detail and animation consistency at gameplay scale.
- [ ] Transfer interior terrain, building tiles, remaining props, closures, checkpoint structures and whole-street
      scenes, retaining tile seams, anchors, transparent gaps, tint behavior and repeated-part
      alignment. Convert prepared assets too without prematurely binding their gameplay. The
      garbage/litter generation record is in `DECISIONS.md` under M109, litter and garbage materials.
      The outdoor ground family record is under M109, outdoor tile materials.
      The tree, bollard, ground-bed and roof-equipment record is under M109, trees and rooftop
      equipment as comic drawings. Their source mappings identify the transferred props.
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

0. **What [PLAYTEST-67](playtests/PLAYTEST-67.md) and [PLAYTEST-68](playtests/PLAYTEST-68.md)
   left open**, on the same footing as the round before it: **M125**, the test suite
   is slow again — ten suites pruned and the
   crowd suite split (`DECISIONS.md`, M125), the events and routes suites still over the
   runner's budget. M126's audit is filed,
   M127's first press is fixed, and M128's playground and busker are built; the records are in
   `DECISIONS.md`.
1. **M56**, whose one remaining item is the measurement against the nerves. *("M56 is also
   related to the other items to work on right now.")* It waits, because reaching act III waits:
   *"I wanna wait reaching act III until those things are done."*
2. **M110**, the crowd goes round a seal, is built in full: seals, walls, doors and every other
   stationary solid body now divert the crowd (`DECISIONS.md`, M110, every solid body). Whether
   diverting at every body blunts the tell a closure's own turn-away relies on — the
   recommendation the player overturned on 2026-09-12 — is a played question, in `REVIEW.md`.
3. **M96, M97, M99 and M100**, in no order between them: the teaching day, the calm areas, the
   corridor's density after the sealing, and the consolidated small work. Each was rewritten on
   2026-09-09 from an older milestone after checking which of its items the code had already
   answered; the record of what was found built is in `DECISIONS.md` under "The queue
   reprioritised". M98, pressure in the empty acts, was the fifth of them and is built
   (`DECISIONS.md`, M98); whether its return reads as pressure or punishment is in `REVIEW.md`.
4. **Reaching act III**, which M56's measurement against the nerves needs.

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
| M100 — Small, real, and nobody's | Review `chalk_mark.svg` beside `chalk_mark_touched.svg`, then bind the touched state to the acknowledgement she adds when contact counts. Keep the original mark visible and readable on the pavement. Compare `alley_draft.svg` in context before deciding whether it replaces the live alley. Bind the mouse family with the alley event and the sound arcs with their event timing; source availability does not decide either behavior. |

M102, the finale, owns the impact-crater decals and the carrying-mother set and has bound what it
needs of them behind `--start-escape`; `GRAPHICS.md` names which sources are live and which stay
prepared, and whether the interior's event layering reads is a `REVIEW.md` question.

**A milestone still holds either drawings or not**, so that ordering one never parks work that needs
no artist.

**M79 is tabled rather than queued.** It is the city seen at an angle — a presentation change with
the lattice left cardinal — and it is written down so that whoever chooses the projection does it
with the code's constraints in hand. It is not queued and it is not rejected.

**M102, the finale, is built and reached only through `--start-escape`.** It is the good ending's
last scene — out of the apartment, out of the city — and its section holds the brief, the four
answered collisions, and the one item still open: the entry from day 14's own summary, which is
what would make it a run's ending rather than a flag's. The record of what was built is in
`DECISIONS.md`.

**[PLAYTEST-50.md](playtests/PLAYTEST-50.md) carries the seal-picture review and the new-caret walk.**
Its open findings are filed under M100: the guard robber standing inside a building, and a chalk
touch that shows only a colour change at the moment it happens. The artwork
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

---

## M143 — The readout's `process` and `physics` lines say what they measure · asked for 2026-09-14

[PLAYTEST-75](playtests/PLAYTEST-75.md), the desktop stutter, and `DECISIONS.md`, M138, what
the readout's `process` and `physics` lines measure. `Performance.TIME_PROCESS` and
`TIME_PHYSICS_PROCESS` are not per-frame times: the engine keeps the longest process interval
and the longest physics interval of the running second and hands each over once a second,
and the process interval runs from the start of the frame's `_process` through the rendering
server's sync and draw. So the readout's `last` is the worst frame of the previous second,
`mean` is the mean of a number that changes once a second, and `max` is the larger of two
such numbers — three columns of which one is a measurement. Every phone reading so far read
`mean` as a per-frame cost, which is why it always outran the frame the `fps` line implied.

- [ ] **One column each, named for what it is.** `FrameCost.readout_lines()` prints
      `process  worst 24.3 ms` and `physics  worst 1.7 ms` — the engine's own number, labelled
      as the worst interval of the last second — and drops `last`, `mean` and `max`, their
      rolling windows and `sample()`'s feeding of them, unless a window still has a reader.
      The run log's `frame` line keeps its `process`/`physics` fields but `docs/TELEMETRY.md`
      says at the column's explanation and at the readout's that both are the worst interval
      of the second, that the process interval includes the render submit, and that `worst
      frame` (the observer's own longest delta) and `process` are therefore two readings of
      the same hitch from two sides. The test that drives `readout_lines()` follows the new
      shape. No evidence: a still of the readout says nothing a test does not.

---

## M152 — Cars teleport at their turns · the landing and the about-face fixed 2026-09-15, one shunt open

> "cars are super buggy now. when they turn in the final stretch the teleport a car length
> somewhere else. also in some case instead of routing a turn (or u turn) they just teleport."

[PLAYTEST-76](playtests/PLAYTEST-76.md), [PLAYTEST-77](playtests/PLAYTEST-77.md). The
**crowd-traffic** rule governs. Both shapes are fixed and recorded (`DECISIONS.md`, M152, a
turn's landing stands where its arc ended; M152, the about-face is planned and the morning is
unpacked early). The probe `tests/probes/m152_car_jumps.gd` now finds one in-view jump that is
neither: on seed 91117 day 1 a follower is moved a car's length backwards in one frame by the
queue's front-to-back resolve, at (2941, 2800) → (2878, 2800), in the before and the after run
alike.

- [ ] **A follower is shunted a car's length by the resolve, in view.**
      `Crowd._resolve_the_queues()` moves a car by its whole overlap in one frame, which is
      right for a placement nobody has seen and is the first shape the player reported when it
      happens to a follower on camera — here the follower of a landing, since
      `_land_the_turn()` leaves the arrival where its arc ended and the queue resolves whoever
      is too close behind. Find what put the follower a car's length inside its leader on that
      frame — the landing's claim, the follower's brake, or the lane key changing under it — and
      fix that where it happens; a resolve that spreads the correction over frames is a force,
      which the rule refuses. The probe's `spacing` class in view is the measurement, 0 after.
      The last resort's own residual is measured and not asked about: one reversal on the spot
      in view over seven rig days, where a stopped car outsat the wait on the landing; the PR
      review names the shape to try if it shows in play.

---

## M161 — The game pauses when it loses focus, and a rig can say not to · asked for 2026-09-19

> "can we make the game pause on focus loss? and also an override to *not* stop the game or
> pause for agents trying to take a screenshot"

[PLAYTEST-80](playtests/PLAYTEST-80.md). The **godot**, **cli-tools** and **verify** rules
govern. Nothing reads a focus notification today, so a day runs on behind another window.

- [ ] **Losing focus opens the pause screen.** On `NOTIFICATION_APPLICATION_FOCUS_OUT` (the
      window losing focus, a browser tab going to the background) and
      `NOTIFICATION_APPLICATION_PAUSED` (a phone sending the app away), a day that is being
      played pauses exactly as the `pause` action does — the same screen, the same continue
      button. It does nothing on the title, the day summary, the ending or an open pause
      screen, and getting focus back does not resume: the player continues when they are
      back. Both choices are recorded in the playtest file as open to overturn. `main.gd`'s
      node keeps processing while the tree is paused, so it is the one that hears it.
- [ ] **`--no-focus-pause` turns it off, and a screenshot run implies it.** A dev flag in
      `DevFlags`, listed wherever the flags are listed (`README.md`'s "Dev flags", the flag's
      own help text, `docs/TELEMETRY.md` where a rig's flags are described) and rejected like
      any other when misspelled. `--screenshot` implies it, since a rig's window opens without
      focus and would otherwise capture the pause screen — so `tools/shot.sh` and every
      existing capture command keep working unchanged — and the flag by itself covers
      `tools/run.sh` runs an agent drives without a screenshot. `?nofocuspause=1` on a debug
      web build if the other flags have URL forms there. The **verify** skill says, where it
      describes windowed runs, that a rig never pauses on focus and why.

---

## M162 — A game can be resumed · asked for 2026-09-19

> "we need to be able to resume a previous game. saving should be implicit (on focus loss or
> game quit) and it should bring you back to that exact state but paused. in the browser it
> should be handled via local storage so refreshing or opening again the page doesn't lose
> progress" — "there is no need for manual save state management since you can just hold
> restart to clear the game"

[PLAYTEST-80](playtests/PLAYTEST-80.md), which lists what a run holds in memory today and what
inside a day is not a function of the seed. It shares its trigger with M161, the game pauses
when it loses focus, so M161 is built first or with it.

- [ ] **Ask what *exact* has to cover before building.** The run (`GameState`) and the day's
      plan (seed and day) come back exactly for free. The moment inside a day is her, the two
      meters, the clock, every event instance's phase and position, pursuits, the errand and
      the crowd. Put to the player, with the cost of each: everything including each walker
      and car; everything but the crowd, which is re-seeded around her as at dawn; or the run
      and the day only, resuming at that day's dawn. The player's words are *"that exact
      state"*, so anything less is theirs to agree to.
- [ ] **Saving is implicit: on focus loss and on quit**, never by a button. One save, no
      slots. A save names the build that wrote it, and a save a newer build cannot read is
      dropped for a fresh title screen rather than half-loaded.
- [ ] **Opening the game resumes it, paused.** With a save present the game comes up on the
      saved moment behind the pause screen; continue goes on, and the held restart — already
      on the pause screen and the day summary — clears the save and starts over. A finished
      run (either ending) leaves no save.
- [ ] **The browser keeps it across a refresh and a reopened page.** `user://` on a web build
      is the browser's IndexedDB, which persists; confirm on the deployed page that a refresh
      and a closed tab both come back, and that a new release (files under a directory named
      for the tag) still finds the save of the one before.
- [ ] **A rig never resumes and never saves**, the way it never pauses on focus: a dev-flagged
      run (`--screenshot`, `--seed`, `--day` and the rest) starts what it was told to start.

---

## M156 — The crowd only turns at what physically stops it · asked for 2026-09-19

> "cars shouldn't avoid it. I noticed cars turning around even though the obstacle is on the
> sidewalk. only things like a fallen tree (which blocks the whole street) should prevent cars
> from entering … pedestrians should only avoid the area if they cannot reach it physically.
> right now they give up if there is an event at all when they should only give up if they
> touch an impassable wall. that leads to two changes: 1) they should still walk through a car
> accident since the sidewalk is free there 2) they should be able to spawn inside a closed
> off section but shouldn't stand in one place but instead walk until they are forced to turn
> around (by the environment)"

[PLAYTEST-78](playtests/PLAYTEST-78.md), which also says what `CrowdAgent._cannot_go_on`
treats as shut for each kind today. The **crowd-traffic** and **city** rules govern. It is the
cause under M155's complaint: a street the crowd has given up on is a free calm area, and a
street only a whole-width obstacle shuts is one the player cannot exploit either.

- [ ] **Find where a car turns for an obstacle on the sidewalk.** A car's own rule is a body
      on its own lane tile (`CityMap.is_obstructed`), a held segment, a closed tile or a
      precinct. Say which of those a sidewalk obstacle reaches — a body whose recorded tiles
      spill onto the lane, a seal held across the whole segment for a row that takes only a
      sidewalk, or something else — with the seed, day and tile, before changing anything.
- [ ] **A car is turned only by what blocks its roadway.** Whatever the first item finds
      is fixed where it happens, so a row standing on a sidewalk leaves both lanes driving and
      a row across the whole street (the fallen tree) still turns cars at the last junction.
- [ ] **A walker turns where it meets what it cannot pass, and not before.** Today a walker
      turns off at the last junction ahead of a soft seal, a held segment or a fully taken
      sidewalk. It walks up to the impassable thing and turns round there instead, and a row
      that leaves a walkable line on its sidewalk — the car accident is the named one — is
      walked past. The turn is an about-face a walker can make anywhere; say what keeps two
      walkers turning at one barrier from stacking, since the 2026-09-12 complaint was walkers
      *"accumulating in one place and move back and forth or worth flicker"*.
- [ ] **A walker goes into a street that is closed further along, from either side.**
      *(2026-09-19: "they saw that a road section was closed of and never entered it. this
      shouldn't happen. they should still go into the section until they cannot continue.
      this should also happen from inside the path since right now we have offshoots that are
      clear because nobody attempts to go in".)* A walker choosing an arm at a junction gives
      a street with a barrier somewhere along it the same weight as an open one, so a side
      street off the day's route fills as far as its barrier and a walker arriving at the
      barrier turns round and walks back out.
- [ ] **Closed-off ground has walkers in it, and they keep walking.** Placement and recycling
      put walkers on sealed-in ground the way they do on any street, and nobody stands still
      there. The walker half of `CrowdPockets` — never placing a walker on ground no street
      leads out of, and standing one still that is caught there — answered walkers pacing a
      junction whose every arm they refused to enter; with the two items above a walker there
      has each stub to walk to its end, so say whether any walker pocket is still needed and
      remove what is not. A car's pocket stays: a car is kept out by what blocks the whole
      roadway, which it cannot turn round against in a stub.

---

## M129 — A path through the city never has to cost · two routes in five still break

> "a path through the city must never hit excitement -- so all obstacles should be routable
> around … the routing should only cross the street at intersections"

[PLAYTEST-69](playtests/PLAYTEST-69.md), [PLAYTEST-71](playtests/PLAYTEST-71.md),
[PLAYTEST-75](playtests/PLAYTEST-75.md), [PLAYTEST-76](playtests/PLAYTEST-76.md). The four rules
and the leaf blower's two-part field are built and recorded (`DECISIONS.md`, M129, the four
rules; M129, the leaf blower is a wall to walk past and a busker to stay near). The probe,
`tests/probes/m129_zero_cost_line.gd`, finds a zero-cost line along 183 of 296 routes. The
guarantee is not true for the rest, and what stands in them is a route junction covered by
several rows together (69 routes), with the leaf blower in the cut on 74 of the 113. The three
placement rules refuse a candidate whose reach *together with everything already down* would
close a junction, so a crossing the probe finds under four to six rows is one that either
reached the day past the rules or is read as covered differently by the probe and the rule:

- [ ] **Which placements the three rules never see.** `_place_one`'s candidate loop is where
      the rules run. Find every other path a row reaches the day by — the calm-ground pass
      that covers a park by area, `_ensure_one_usable_park`, the seals a `SealPlanner` places
      before the scheduler runs, the region walls and doors — and say, per broken route in the
      probe, which path placed the rows in its cut and whether the probe's *covered* and the
      rule's *open* agree on it. Then either those paths ask the same three questions, or the
      record says why a route may pay there. The probe's "what broke the line" table is the
      measurement; the seals alone cost about five points (66.9% on the day's own rows against
      61.8% with them).
- [ ] **A wall is also what cannot physically be walked past, and it never stands on the
      route's own pavement.** *(2026-09-15: "on the side of the street where the path was
      chosen only obstacles that can be bypassed should be possible" — "the market stall should
      appear on the other side of the street" — "a wall is also when you physically cannot walk
      through"; offered a placement-only rule instead, the player chose this: "that seems to
      be more thorough".)* Today `EventScheduler._role_for` answers `WALL` only for a lethal
      row or one whose walk-through cost reaches `Tuning.WALL_WORTH_OF_COST` (35), so a market
      stall — a 28 px body denying 58 px of a 64 px pavement, no 28 px line past it — is
      *friction* and is weighted onto the corridor four to one (`Tuning.EVENT_CORRIDOR_WEIGHT`).
      The width rule (`_leaves_a_line_past_it`, via `_closes_the_street`) then only asks that
      *either* pavement stays walkable end to end, so the stall may close the pavement the
      tree walks while the tint (`DECISIONS.md`, M150) marks exactly that pavement. Three
      changes, the **balance** rule governing every number: (1) `_role_for` also answers `WALL`
      for a row whose body and charging disc (`_line_reach_of`) leave no four-connected line
      the stroller's width (the 28 px the probe uses) along a pavement it may be placed on —
      a passability reading beside the cost reading, decided from the row's own numbers, so
      `docs/EVENTS.md`'s role column moves for every row it catches (`cafe_tables` and
      `market_stall` at least; list them all in the record). (2) `_copies_of` reads the
      corridor per pavement, the way M150's tint does (`Corridor.depth` answers at the grain of
      a whole street today; `docs/CITY.md` where that grain is described): a wall gets its zero
      copies on the pavement the tree walks and its ordinary off-corridor copies on the *other*
      pavement of the same street, which is where the player put the stall. (3) The width rule
      reads the route's pavement, not the street: a counted row reaching onto the tree's
      pavement between two junctions is refused unless a stroller-wide line survives along that
      pavement, cumulatively with what is already down, the way the junction rule reads.
      Measure with `tests/probes/m129_zero_cost_line.gd` before and after, and with
      `_test_the_day_is_placed_by_role`'s corridor floors and the wall caps, which will move:
      the two act I rows built to force a crossing become walls across the street from the
      route, so say what day 1's corridor now carries and what forced crossings are left,
      rather than retuning floors or caps to pass. `docs/EVENTS.md` where it describes the
      roles and the three rules.
---

## M137 — The contact is whoever she hands the note to, and the trap comes to her · asked for 2026-09-13

> "not the first yeller she reaches but the first yeller she interacts with. so the task is
> always solved by going to any yeller she notices. maybe spawn the robber in pursuing mode
> offscreen when she interacts with the yeller so it runs towards her from offscreen."

[PLAYTEST-71](playtests/PLAYTEST-71.md). The **events** rule governs the robber's spawn; the
telegraph contract it names is the constraint on *off screen*.

**What is true today.** `ResistanceDirector._track_first_reached` re-points the perform step's
contact every frame onto the nearest live look-alike she is within reach of, so a yeller she
walks past and leaves is not kept; whichever one she then touches completes the step
(`DECISIONS.md`, M132). The trap is a separate rule: `_maybe_set_a_trap` stands an
`alley_robbery` at dawn inside a band around the position the day seeded, waiting, and it wakes
when she comes within its `pursues_within`; a contact she hands over anywhere else is unguarded.
*The trap guards the seeded yeller only · overturned on 2026-09-13.*

- [ ] **The rule is worded as the player said it.** `docs/NARRATIVE.md`'s *the contact is
      whichever look-alike she reaches first* becomes *whichever look-alike she hands the note
      to*, and the director's own doc comment with it. A test in `tests/test_resistance.gd`
      walks a rig within reach of one look-alike, out again, and onto a second, and asserts the
      step completes on the second — what the code already does and nothing pins.
- [ ] **The trap comes to her.** On a perform step, no robber is seeded at dawn. At the moment
      the note is handed over, `spawn_extra` puts a robber on walkable ground outside the view
      rect (`set_sight`'s own callable, or the stream radius M131 measured, says what off screen
      is) already awake and pursuing, so he runs at her from off screen. **He is his own
      catalogue row, not an `alley_robbery` woken by hand.** *(2026-09-13: "we need a version of
      the robber that is not frozen when spawned.")* `alley_robbery` is `is_waiting()` from the
      frame it spawns — `pursues_within > 0` and no notice yet — and the new row is never
      waiting: awake from its first frame, telegraph included, the same body, speed, lethal
      reach and picture as the alley robber, `hard_fail` like him, and spawned only by the
      director — never placed, budgeted or streamed by the scheduler, so `EventDef.validate()`
      and the catalogue's placement pool are told so. He obeys the row's own numbers — spawn
      distance is a new number the **balance** rule owns — and the telegraph contract: the
      screen-edge badge and the caret answer him the way they answer any pursuer, so the player
      has the reaction time the contract promises. A chalk mark's guard is unchanged: this entry
      is about the perform step's contact, which is what the player named; say so in the record
      if a chalk mark's trap should follow.

      **What an agent's reading of the code found before it was stopped, unverified by any
      rig.** The stream-in path's `EventInstance.resume(age, travelled, noticed_at)` would take
      an alley robber out of waiting, which is the by-hand wake the player refused; the new row
      says it in the definition instead. Once noticed, `_chase()` moves him at
      `pursue_speed` (130 px/s) from the first frame — the row does not set
      `still_while_telegraphing` — holding at the standoff until his 1.8 s telegraph ends, so
      `DangerEdge` already arrows any `hard_fail` row and announces him on the first closing
      frame: no cue code changes. A candidate spawn distance, to be scrutinised: 400 px clears
      the view from any bearing (the viewport's half-diagonal at zoom 2 is about 367 px, the
      argument `NOTICE_RADIUS`'s own doc makes), plus `pursue_speed × Tuning.PURSUIT_MIN_NOTICE`
      (130 × 1.5 = 195) so at least the minimum notice passes while only the badge speaks for
      him — about 600 px. The trigger belongs in the contact-completed path, gated on
      `task_event_id` being set and on `TRAP_FIRST_DAY`, with a guard on `_maybe_set_a_trap`'s
      dawn call for a perform step; `_draw_guard_position`'s rejection loop (walkable, not
      closed, not held, not the home block) is the bearing draw to reuse.
- [ ] **What a run should look at** goes to `REVIEW.md`: does a robber arriving from off screen
      after the handoff read as the price of the errand rather than as bad luck, and does the
      badge give enough warning to run.

---

## M125 — The test suite is slow again · asked for 2026-09-13

> "Also the tests are slow again, too. Tests that only restate numbers in tables etc can be
> completely removed."

[PLAYTEST-67](playtests/PLAYTEST-67.md). The rule is the **verify** skill's, from 2026-09-03:
*a test that only doubles the work of a change is deleted, not maintained* — one that reads a
design decision back to itself, where "you changed a number" is all it could ever say. What it
keeps: a guard that a sweep was not vacuous, an ordering between two constants, and anything the
skill's incident list names.

**What is true today.** Ten suites have had the pass and the crowd suite is split in two by
subject — the per-suite times before and after are in `DECISIONS.md` under M125 — and the head
of `tests/run_tests.gd` says the budget: a suite over two minutes serial is a suite to split or
cut, because the longest suite sets the floor every shard waits on. CI runs the suite as eight
shards on eight runners, planned from `tests/suite_costs.txt`, the measured per-suite times
`tools/test.sh --record-costs` refreshes (`DECISIONS.md`, M125, CI runs the shards on eight
runners); the wall time is the longest suite plus a minute of setup, so the longest suite is
the whole of what CI's time is made of. Two suites are still over it, and the recorded costs
were last taken under local contention, so `--record-costs` on a quiet machine comes first.

- [ ] **`test_events.gd` and `test_routes.gd` are the floor now.** Both run over two minutes
      serial and both had the pass already, so what is left is a split by subject, the way the
      crowd suite was split at its own seals boundary — every test function still called once,
      the check total unchanged, the split named for what each half proves — or a measured
      shorter loop where a docstring can say why. `tools/test.sh --record-costs` afterwards,
      so the plan follows; the per-suite line before and after goes to `DECISIONS.md` under
      M125. The two suites M124 and M135 added have no row in `suite_costs.txt` until then and
      CI plans them at its default.

---

## M56 — The resistance is noticed

The city gets more dangerous the further into the subquest you are. **A task may not cost a nerve**
— a nerve is a rewind, not a resource, so there is nothing to trade.

**Every hunting row is built; what is left is the measurement, and it waits until act III is
reached**, which the queue puts after M96 to M100. *(2026-09-09: "M56 is also related to the other
items to work on right now. I wanna wait reaching act III until those things are done.")* The
records are in `DECISIONS.md` under M56.

**What the remaining item is stated against**, since the machinery under it exists: a row says how
it answers to the resistance with `EventDef.heat_response` — `NONE`, `PRESSES` or `HUNTS` —
`EventCatalogue.heated()` derives that row's shape at a progress level, and every one of those
shapes is validated on boot. The ladder has three rungs a player can name and both its upper ones
are built: `police_patrol` is **denser and then interested**, and `abduction` is **hunted**, taking
a bystander of its own while she watches and coming after her instead past three of four, with
`night_raid` on the same rung from day 10 — cold it closes a block, hot it comes for her — and
`roadblock` on it from day 7 — cold it closes a street, hot its guards leave the post and come for
her. The reasoning, and what was rejected on the way, is in `DECISIONS.md` under M56.

- [ ] **Measure it against the nerves.** This makes the back half harder precisely for the player
      doing well at the optional path, and nobody has reached act III

---

## M96 — The teaching day, and the dog after it · rewritten 2026-09-09

Rewritten from M43. Two of M43's items turned out to be built when checked — the pause lesson no
longer fires while she is detained or while the tree is paused, and the run lesson's once-per-run
flag is reset on every attempt at the teaching day — and the record is in `DECISIONS.md` under "The
queue reprioritised". The dog after the lesson is built — from day 4 it waits inside its own
field and the day-3 charge sprinkles in on later days (`DECISIONS.md`, M96, the dog waits) — and
what is left is one measurement.

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

- [ ] **The gate detains but draws no guard.** Found while capturing the inspection: the boom's
      own body takes her in, and nobody on screen is the one doing it — the guards stand at the
      huts. A gap in the fiction rather than in the mechanic: either the boom's hold draws a guard
      stepping to the arm, or the boom stops being a detaining body and the huts alone are the
      toll, with the boom's picture still barring the lanes for the cars. The player's call
- [ ] **A rig cannot be spawned at a row the day's plan never holds, and cannot stand outside
      a waiting one.** `--spawn event:<id>` reads `DevRig.first_event_position()`, which
      searches the day's planned placements, so a queue-fed row (`cat_dash`, `cyclist`,
      `loose_dog`, the day-3 `charging_dog`, anything `AHEAD_OF_PLAYER` or `TOWARD_PLAYER`) is
      never found and the flag silently falls back. Found capturing M121 (`DECISIONS.md`,
      M121, what the captures could not catch); the flock is map-placed now and can be found
      (`DECISIONS.md`, M131). Either the flag refuses such a row by name, or it stands her where
      the row would first trigger; the **cli-tools** rule wants the refusal at least. And for a
      row that waits — a flock, an alley robbery — `first_event_position()` stands her *inside*
      the trigger, so no rig can photograph the silence before it; a `--spawn` that lands her
      just outside the trigger is the other half of this item
- [ ] **The balance rig's camera is overridden to physics process mode, with a warning.**
      `tests/test_balance.gd`'s `_build_rig` adds a `Camera2D` that Godot moves to physics
      process mode because physics interpolation is on, and says so on every run. The
      **godot** rule leaves no warning standing: set the process mode the engine wants, or
      turn interpolation off on the rig's camera, whichever the real camera does.
- [ ] **`Crowd.step()` and `Crowd._physics_process()` duplicate four lines in two orders.**
      `src/crowd/crowd.gd:230-237` (`step`) and `:625-638` (`_physics_process`) both open with
      `_signals.advance` → `_pockets.refresh` → `space_out_the_traffic` →
      `_hold_walkers_at_doors`, but `step()` interleaves `agent._process` (all) in between with no
      shared helper. The crowd-traffic skill already names the incident this caused once — a rig
      that walked the agents without this prologue ran a crowd in which nobody is ever held at a
      checkpoint, and nothing about that looked like a missing call — and the structure that
      allowed it is unchanged, so the next line added to `_physics_process`'s pre-player section
      is silently absent from every rig-driven suite. Fix: extract the four shared lines into
      `_advance_the_world(delta)` and have both call it, so the only difference between them is
      the agent stepping and the player half.
- [ ] **Seven hand-written spellings of "is this the main road."**
      `src/city/traffic_signals.gd:52`, `src/crowd/crowd_lanes.gd:164`,
      `src/crowd/crowd_agent.gd:461`, `:1560`, `:2387`, `:2404` and
      `src/routes/seal_planner.gd:373-374` all independently re-encode "the spine is the vertical
      corridor," and `src/city/city.gd:244` asks the same question through
      `map.street_kind_at(...) == GameEnums.StreetKind.MAIN` — a different mechanism entirely. The
      city skill's own rule is *"Which corridor is the main road is a fact about a city, so read
      it off the map"* — every site does, so today they agree, but if `main_road` ever becomes a
      per-axis pair, or the spine becomes horizontal on some seeds, six of the seven sites keep
      answering for the vertical axis with no error anywhere. Fix: `CityMap.is_main_road(vertical:
      bool, corridor: int) -> bool`, and route every site through it.
- [ ] **A hung test shard waits out the whole CI job with no message.** `tools/test.sh:212-230`'s
      "A shard that printed no count did not finish... it crashed **or hung**" branch sits after
      `wait`, so it can only ever be reached for a crash — a hung shard blocks `wait` forever and
      the comment claims a case the code cannot reach. Fix: a `timeout` around `run_one_process`
      would make the comment true.
- [ ] **`EventManager` reaches into another class's private member.**
      `src/events/event_manager.gd:321`: `plan.noticed_at = plan.live._noticed_at`.
      `EventInstance.resume(age, travelled, noticed_at)` is the public channel in the other
      direction; there is no getter for this one. Fix: a small public getter on `EventInstance`
      for `_noticed_at`

**Drawings, as SVG:**

**Vehicle collision and silhouette agreement is checked with M61, one shape per object, and
the debug view's bounding-box layer (`3`).** Skip and burnt-out-car obstructions remain circular; the moving van uses
a capsule. Shape-derived bodies do not alone establish that apparent gaps can be walked through:
the live body and picture's footprint still need comparison with the debug layers. The directional
artwork, the player's perpendicular burnt-car correction and the rendered evidence are in
`DECISIONS.md`, "SVG artwork and upcoming milestone assets".

**Whether the `INDUSTRIAL` and `CIVIC` districts read differently at a glance is a question in
`REVIEW.md`**: their roof furniture and fronts are placed per district (`DECISIONS.md`, M106), and
in the rig pictures the two are told apart by their roofs alone.

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
- [ ] **Whether a stranger arriving at the page understands what it is.** Playtests 27 onward
      have played the live address on a laptop browser and a phone, so *it boots and takes
      input* is answered, and playtest 67 answered the frame rate on a phone — *"a bit laggy"*,
      which is M124. itch.io stays the fallback host, since it sets the isolation headers a
      threaded build would need

**Open design questions**, each answered by a played run rather than by more arithmetic:

- [ ] **A touch on a chalk mark shows nothing at the moment but a colour change.** *(2026-09-09,
      playtest 50: "how do I know I stepped on the chalk", then "I walked over the chalk why
      didn't it count?" — it had.)* A touch turns the mark from chalk white to pale green
      (`Palette.CHALK` to `CHALK_DONE`) under her feet, and the `resistance ....` dots are
      performs only, so a pick-up moves none. The mark's own words now reach her on that day's
      summary whether it was won or lost, in their own larger line (`DECISIONS.md`, M132), so
      what is left open is the moment of the touch itself. The design's own rule is no quest log
      — *the first encounter comes with no hint at all* — so how much a touch may say is the
      player's call: nothing more; the mark's colour made unmistakable; or a one-line status
      change on the pick-up itself. PLAYTEST-53 requests a distinct touched-mark SVG for review:
      she adds something to the existing mark to indicate she has seen it.
      `chalk_mark_touched.svg` prepares that acknowledgement; selecting and binding the feedback
      remains here
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
- [ ] **`CrowdAgent` moves at frame rate; every rule about that movement is applied at physics
      rate.** `src/crowd/crowd_agent.gd:751` is `_process(delta)` — frame rate — while everything
      that governs it (`space_out_the_traffic()`, `_hold_walkers_at_doors()`,
      `give_way_at_junctions()`, `_strike()`, `_horn()`, `_bump()`, `_make_way()`) is in
      `src/crowd/crowd.gd:637`, `_physics_process(delta)` — the physics tick, thirty a second.
      Speeds are frame-rate independent, so this is not a speed bug; what varies with the machine
      is the **decision cadence relative to the motion** — how far a car travels between two
      applications of "nothing enters a box it cannot leave." The verify skill records the
      windowed build drawing ~110fps, so a desktop car covers roughly 3.7 movement steps per
      right-of-way pass, against 1.0 at 30fps: a headway or junction-capacity number set against
      `Crowd.step()` does not reproduce on the player's own machine at the ratio it was measured
      at. **The audit's own recommendation**: move `CrowdAgent._process` to `_physics_process`,
      which fixes the ratio at 1:1 everywhere, at the cost of re-measuring every crowd number and
      giving up frame-rate-smooth motion for the agents — against leaving it as it is. That cost
      is no longer frame-rate-smooth against a fixed sixty either: with the tick at thirty, moving
      the agents onto it would draw the whole crowd at thirty frames a second, not merely decide
      for it at that rate, which is a larger piece of the trade than it was. Docs/evidence/
      audit-2026-09-13/AUDIT.md, finding 3.1, has the full reasoning.

---

## M102 — The finale: out of the apartment, out of the city · asked for 2026-09-09

**The sequence exists and is reached only through `--start-escape`** *(2026-09-12: "also build the
entire escape sequence to the end but make it playable only via flag today (what is now the
apartment escape should continue)")*: the building with its events, the service exit onto the city,
the two chains through three calm areas each to the tunnel and the bridge, the explosions and their
craters, the two hint lines, the millisecond clock, the section restart and the epilogue. What it
does, what was measured and what was chosen where the design was silent is in `DECISIONS.md` under
M102, the finale built behind the flag; what only a play can settle is in `REVIEW.md`. **One item
is open**, and it is the switch that makes the sequence a run's ending rather than a flag's.

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

**What is still open:**

- [ ] **The entry from day 14's summary rather than from the flag** — the one item held back on
      2026-09-12 *("make it playable only via flag today")*: the good ending's last won day hands
      over to the hallway instead of the ending screen. Everything the sequence itself needs is
      built behind `--start-escape`, so this is the one switch left: it waits on the player saying
      the finale is a run's ending rather than a flag's

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
