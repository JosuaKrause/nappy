# TODO

**The queue. Open work only.** A ticked item is history the moment it is ticked, so completed
entries live in [DECISIONS.md](DECISIONS.md) with their measurements and rejected options intact —
search it for the noun before designing anything. Progress-tracking lives only there: no ticked
boxes, no "Done:" paragraphs, no branch names or status words in headings here.

Read [HANDOFF.md](HANDOFF.md) first for the state of the tree.

Each milestone is one git branch, squash-merged to `main` through its pull request. `[~]` marks an item somebody is
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
      A crowd car is two layers today, `art/crowd/car_{view}_{body,trim}.svg`, the tintable
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

## M175 — A row states what it costs, and the cost table is checked in · asked for 2026-09-20

> "is there a better way than having four numbers to control what actually happens? we adjust
> one thing but then forget to adjust other things in lockstep the balance is off."

> "we can do option 1 and take the radius into account as well. meaning we compute numbers
> close by and at various distances. those numbers gets automatically computed/updated but
> also checked in so we can see in the diff where the balance changed"

[PLAYTEST-114](playtests/PLAYTEST-114.md) has the conversation and both options. What the
player feels near a source is its `intensity`, averaged over its pulse, scaled by
`Tuning.SLEEPING_SENSITIVITY` (0.55) when the baby sleeps, shaped by `inner_radius`,
`outer_radius` and `falloff_power`, less `Tuning.EXCITEMENT_DECAY_WALKING` — several numbers
nothing ties together, so moving one silently re-prices every row. `docs/COSTS.md` is the
generated table that shows such a move in a diff (`tools/cost-table.sh` writes it and CI checks
it); what is open is the half that stops the move from happening.

- [ ] **A row declares the net cost and its `intensity` is computed.** Option 1 as put to the
      player: a row states what the bar does while she walks beside it inside `inner_radius`
      with the baby awake, in points a second net of the walking decay, and the catalogue
      derives the gross `intensity` from that, the decay and the mean of the row's pulse when
      it builds the row. The declared costs are a few named tiers in `tuning.gd`, so a class
      of rows moves with one number. Moving the decay or the pulse then leaves every row at
      the cost it declared. A row that is meant to sit under the decay declares a net at or
      below nothing, which is its existing relationship said out loud. The first version
      reproduces today's costs, so `docs/COSTS.md` does not change in the commit that builds it.
      The measure a row declares is the orchestrator's first draft and predates the player's
      "what matters … is walking past them" ([PLAYTEST-115](playtests/PLAYTEST-115.md)): for a
      row that moves, the declared cost is the pass. **The
      tier names and values go to the player with M174's measurements beside them, before
      this is built.**

---

## M182 — A finished task is shown by the world, never by text · asked for 2026-09-20

> "yeller should just start walking offscreen -- no onscreen text for acknowledgements like this"

[PLAYTEST-117](playtests/PLAYTEST-117.md). A touched mark already shows that it was taken, and
the HUD writes nothing for any step (`DECISIONS.md`, M177, the second mark is any alley she
comes across), and the man shouting, handed the note, goes quiet and walks off screen
(`DECISIONS.md`, M182, the man shouting walks off). What is open is every other task.

- [ ] **Every other perform step gets its own visible answer**
      (`EventInstance.leave_for_a_completed_task()` is there for the ones that leave), decided with M181, the
      resistance has a reason, and a task is one day, whose list of tasks is settled: the
      van's drop, the burnt shell, the named door, the neighbor warned before the raid, the
      loudspeaker mast, the swing and the roadblock; the power station's answer is the blackout
      (M183, the power station and the blackout). Each is something that happens
      where she is looking, and none is text.

---

## M180 — Posters she notices, and loudspeakers that are somewhere · asked for 2026-09-20

> "posters need to be more obvious. the loudspeaker part was not apparent to me. since we
> don't have sound it's not clear that this is happening. loudspeakers should be placed in the
> city with a defined field. not sure about adding a floor. it just makes losing unfair because
> things that worked before don't anymore for no obvious (or visible) reason."

[PLAYTEST-117](playtests/PLAYTEST-117.md). **The masts are built** (`DECISIONS.md`, M180,
the loudspeaker masts): six from day 5, on sidewalks, with a field, a lamp that says when they
speak, and nothing city-wide left. What is open is the posters.

- [ ] **Posters are seen at all.** *"I have not seen a single poster in any playthrough -- I
      don't know what you're referring to here -- it needs to be way more obvious"*: the run
      behind PLAYTEST-116 placed ten poster crews on day 4 and the player noticed none. The crew's
      walls, and what they leave behind, read at walking distance as the city changing: size,
      contrast and how many, against the act's palette. A visual attempt comes back to the
      player early rather than polished.

      **Why none is seen, read from that run's log and the row itself.** A crew is placed at
      dawn anywhere in the city (`poster_crew` has the default `MAP` spawn mode, and the day's
      corridor only weighs four to one against every other block), so over the whole run she
      came within a crew's 110px field once, and within none of day 4's ten. A crew leaves nothing behind: the row has no
      `scar_id`, never finishes (`duration` 0) and paints nothing on the wall, so the city
      does not accumulate posters. The poster itself is a 9x13px sheet of paper held at head
      height inside a 30x44 figure, about 18x26 on screen at the camera's 2x zoom, on a worker
      drawn in the street's own olive-grey with no second frame. And it costs nothing to
      pass (`docs/COSTS.md`: walking through nets a gain, scenery on purpose), so the meter never
      points at one either. Nothing can draw over it; buildings sit under the entity layer.

      **The fix, in the order of what the log blames:** crews work on walls along the way she
      walks, the way day 3's fire is sited (`DECISIONS.md`, M179, the fire is on her way), rather
      than anywhere; a wall a crew has worked keeps its posters for the rest of the run, drawn
      on the building face and large enough to read at walking distance, so each day's walls
      add to the last; and the crew is seen pasting. The row's cost stays what it is: making a
      poster crew charge the meter is a change to what the row is for, and is the player's.
- [ ] **There are four kinds of poster, and they are on the walls** ([PLAYTEST-119](playtests/PLAYTEST-119.md)).
      *The leader's portrait*, a nondescript face with no name; *the rules*, a pale printed
      notice with a heavy header bar, gray lines and a red stamp, joined from day 6 by a curfew
      sheet with a clock face; *the darker uniform sheets* under one plain geometric emblem
      that resembles nothing real, covering a wall edge to edge in act III; and *the wanted
      notice* in act IV, rows of faces, some crossed out in red, drawn in a different style
      from the leader's. No sheet carries readable words (`docs/NARRATIVE.md`, tone rule 1:
      nobody explains the politics). A poster takes up about 60 to 80% of a tile, "big enough
      to be recognizable as posters". They are on walls from the first day poster crews appear,
      day 4, and **some are already up that first morning**; they are **sparse at first and
      denser towards the end of the run**, each day's walls adding to the last. The
      progression, proposed by the orchestrator from the acts and the player's to move:

      | From | New on the walls | How much |
      | --- | --- | --- |
      | Day 4 | The rules and the leader's portrait, some already up that morning | Sparse: a wall here and there, one or two sheets on it |
      | Day 6 | The curfew sheet with its clock face, among the rules | A few more walls |
      | Day 8, act III | The dark uniform sheets under the emblem, pasted over the older ones | Whole walls, edge to edge, on the streets she uses most |
      | Day 12, act IV | The wanted notice | Dense: most walls on a main street carry something; the portrait is everywhere |

      **One face on the wanted notice is the neighbor's** ([PLAYTEST-121](playtests/PLAYTEST-121.md):
      "I like the idea with the crossed out face if 10 is failed"): the neighbor she is sent to
      warn on day 10 (M181, the resistance has a reason, and a task is one day) is among the
      faces from day 12, drawn to match the figure she met or missed, and **crossed out in red
      if day 10's task was not done on the day she won**. Never explained. It is the posters'
      one tie to the story: "other than that we can keep this mechanic separate with no story
      tie in", so tearing stays a gimmick that counts for nothing.

      A kind that has arrived stays in the mix; nothing is taken down except by her.

      **The pictures are drawn and accepted** (`DECISIONS.md`, M180, the poster art): the six
      intact sheets and three tear masks under `art/events/posters/`, prepared and not yet bound,
      with the neighbor's slot on the wanted notice and the compositing recipe in
      `docs/GRAPHICS.md`'s Posters section. **What is open is putting them on the walls**: only on
      blank ground-floor wall, never over a window (M185, a ground floor is blank wall or shops),
      one row to a wall, following the progression above. Where a sheet is pasted over an
      older one, the offset is large enough that the older sheet plainly shows, never a sliver that
      reads as a glitch ([PLAYTEST-123](playtests/PLAYTEST-123.md), statement 31); **most** new sheets
      cover the old one exactly and replace it, and only some show the one beneath (statements 32
      and 33: "if it's visibly over pasted for all of them then it will look weird"). PNGs are Codex's, later.
- [ ] **She tears a poster down by pushing against its wall**, a diagonal heading included;
      no button, and more than walking past. *The orchestrator recommended running along the
      wall · the player chose pushing on 2026-09-20*, because a push can happen by accident,
      which is how it is discovered. It is a gimmick to be judged by feel and holds nothing
      else up. Open to overturn, set by the orchestrator: her heading has to press into the
      postered wall for about 0.4 seconds, so brushing past does not tear; a torn poster stays
      torn until a crew pastes that wall again; tearing costs nothing on the meter and counts
      for nothing. **A tear has a small chance of a pursuer**: a `police_patrol` sent toward
      her from off screen under the lead its row already owes, starting at one tear in ten, and
      never on the first tear of a run. **Whether a tear brings one is drawn from a marble bag**
      ([PLAYTEST-125](playtests/PLAYTEST-125.md)): a bag holding a fixed set of marbles in the
      desired proportion, one drawn at random and removed per tear, refilled with the same set
      when empty, so every bag's share is exact ("it has the desired probability but feels
      fair"). A first, pre-bag holds only "no pursuit" marbles, one per tear guaranteed safe.
      The bag is the queue's numbers (statement 5): a pre-bag of one safe tear, then one
      pursuit in every ten. Only poster tears use a marble bag.

---

## M183 — The power station and the blackout · asked for 2026-09-20

> "so we need to design a power station building that is guaranteed to spawn on the map" ·
> "just wait until a certain distance away -- then everything is off at once" · "yes all lights
> should go out. that actually applies also to the escape sequence"

[PLAYTEST-119](playtests/PLAYTEST-119.md). **The station itself is built** (`DECISIONS.md`, M183,
slice one, the power station): one on every seed, across a region door from home, with its own
look and a front door that day 14's route always reaches. What is open is the blackout and the
dark escape, and the red arrow of M181, the resistance has a reason, and a task is one day, which
points at the door (`CityMap.power_station_door_position()`).

- [ ] **The blackout is everything at once.** After she has touched the front door, once she
      is a set distance from the station, every lit window goes dark, every traffic light goes
      off and every loudspeaker mast stops, in one frame. *The orchestrator recommended the
      touch of the door, rolling outward · the player chose distance and all at once on
      2026-09-20*: a rolling blackout cannot be seen from the street, and the moment is "very
      visible and linked to her action". The distance is the orchestrator's and open to
      overturn: far enough that the station is off screen. **Dead traffic lights are part
      of the challenge of coming home after the sabotage** (the player, 2026-09-20): the roads
      are harder that night on purpose. What stays owed is the **crowd-traffic** rules'
      fairness contract for a lethal road — a car she can see coming — and the brief says how
      a crosswalk with no light keeps it.
      **The station's own hall goes dark with the city**: its clerestory windows
      (`art/buildings/power_station_clerestory.svg`) are drawn unlit today and need a dim lit
      state for the night of day 14, so the hall is seen to go out.
- [ ] **The escape is in the dark too.** The hallways and the basement are gloomy, and the
      stairs have emergency lighting, "maybe … (red?)", the player's to judge on a picture.
- [ ] **`docs/NARRATIVE.md` says what the last night is.** Its good ending has the
      loudspeakers cutting out as the sabotage itself and the walk home after it as "the
      easiest conditions in the game, and that is the reward". With this built the masts stop
      because the power does — their fields, since M180, posters she notices, and loudspeakers
      that are somewhere, leaves no city-wide floor to silence — and **neither the walk home nor
      the escape is easy** ([PLAYTEST-121](playtests/PLAYTEST-121.md): "the escape shouldn't be
      easy!"). The "Good" ending, Act IV's day 14 and tone rule 3's "the reward is quiet" are
      rewritten with the build, and `docs/MECHANICS.md`'s account of the good ending with them.

---

## M185 — A ground floor is blank wall or shops · asked for 2026-09-23

> "Yes, the home block should have fixed visuals. That way we can craft a convincing house that
> also matches with the interiors of the escape."

The rule itself is built (`DECISIONS.md`, M185, a ground floor is blank wall or shops): shops or
blank wall on every multi-story ground floor, one entrance door on a front with no other way in,
the storefronts redrawn, and her home block keeping its ground-floor windows
([PLAYTEST-124](playtests/PLAYTEST-124.md)). What is open is her house.

- [ ] **The home block has fixed visuals** ([PLAYTEST-124](playtests/PLAYTEST-124.md),
      statement 6): its buildings look the same on every seed — window style, which windows are
      lit, heights, front and roof furniture — rather than being rolled like any other block, so
      it can be crafted into a convincing house that matches the interiors of the escape (M102,
      the finale: out of the apartment, out of the city, whose stairwell, hallways and basement are
      in `art/interior/`). The block's size and shape still come from the seed's lattice; what is
      fixed is how it is drawn. The crafted look is drawn SVG first and goes to the player as
      pictures before it is installed, beside the escape's interiors.

---

## M184 — A rig walks the route · asked for 2026-09-23

> "we should have a test-rig mode where she just follows the edges of a path that way we can test
> paths properly and do those timing checks without having to guess the right inputs"

[PLAYTEST-122](playtests/PLAYTEST-122.md). The rig is built (`DECISIONS.md`, M184, a rig walks
the route): `--route mark,task,calm,home` walks her along a real path's edges, at walking pace,
through the ordinary game, and `tests/probes/m184_route_timing.gd` times days 6 to 13 with it.
What is open is where it gives up, which is what keeps M181's late days from being fully timed;
the legs that find no path are the game's (M188, a resistance target can always be reached).

- [ ] **The rig gets through chokepoints.** In 14 of the 24 measured runs a leg ends "stuck
      fast", wedged more often than its budget of three stuck episodes a leg. Waiting three
      seconds before forcing a way out gets none of them through (`DECISIONS.md`, M184, the rig
      waits before it forces), and day 10's calm leg on seed 90210, reached in 30.5 seconds
      before, now sticks too, unexplained. What the first look found, on day 6's mark on seed
      1234567, built and then taken out again: she stalls flush against a van's body, because
      `CityMap.obstructed_tiles` marks only the tile a body's centre falls in (right for the
      crowd, which keeps to a lane) and a van overhangs the next tile's centre by about 6px, so
      the plan itself walks her into it. A keep-clear margin from `EventDef.solid_reach()`, the
      way the rig already keeps clear of a hazard's `lethal_reach()`, moved the stall a few tiles
      on; trying the unstick directions in the order that points away from the body, rather
      than always starting up, cleared each maneuver first time; but the recovery re-plan rings
      her own position rather than the body that caught her, so she went straight back to the
      same pinch. The narrowest gap there measured about 2px short of her body plus the van's
      reach: whether a player hugging the far edge gets through, or the van is sited without
      leaving a walkable width, is to be checked before calling it the rig's fault. Whether the
      stalls on day 8's home leg on seed 1234567 and day 12's on 4242 are the crowd rather than a
      body is not yet checked.

---

## M181 — The resistance has a reason, and a task is one day · slice one built 2026-09-23

> "when doing the mark it doesn't really feel that we would need to resist against anything
> since nothing really has visibly deterioated yet" · "we could do 1) chalk 2) it immediately
> shows the task 3) you have to do the task on the same day" · "add more different tasks" ·
> "a red arrow (like the blue home arrow but red) to point to tasks where we need to go to a
> specific location" · "we should also start with doors later since tasks should come first" ·
> "9-11 need some extra memorable content in addition to the tasks"

[PLAYTEST-117](playtests/PLAYTEST-117.md) to [PLAYTEST-122](playtests/PLAYTEST-122.md). **Slice
one is built** (`DECISIONS.md`, M181, slice one, which also holds every decision the entry
carried): a task is one day, announced at its mark and done that day; the first mark on day 6;
six of the eight tasks (days 6, 7, 8, 9, 12 and 13) with the red arrow for the one-place ones;
the goal of five; the doors from day 9; the day brief's own line for each day; and the story
in `docs/NARRATIVE.md`, "What the tasks are for". **What is open is slice two**, below, and the
two tasks that wait on other milestones: **day 11's mast on M180**, posters she notices, and
loudspeakers that are somewhere, and **day 14's front door on M183**, the power station and the
blackout; until then day 14 keeps the last night's district contact.

**The calendar, decided by the player:**

| Day | Task | What happens once |
| --- | --- | --- |
| 6 | A note for the man shouting — any of them · built | |
| 7 | The package at a van's drop · arrow · built | |
| 8 | Leave something at the burnt shell · arrow · built | |
| 9 | Cross a named door · arrow · built | The doors arrive · built |
| 10 | Warn the neighbor, out in the city, before the raid · arrow, deadline | The raid on her own street, at her own building. |
| 11 | Silence a loudspeaker mast · arrow | The market is gone. |
| 12 | The swing in one park · arrow · built | That park is taken once she has reached the swing. |
| 13 | Walk into a roadblock's band — any of them · built | A column on the main road. |
| 14 | The power station's front door · arrow | The blackout. |

- [ ] **Day 10: warn the neighbor before the raid.** The neighbor lives in her own building;
      the red arrow points at them out in the city, and the deadline is the neighbor walking home
      into the vans (*the orchestrator's reading · taken by the player on 2026-09-21*,
      [PLAYTEST-121](playtests/PLAYTEST-121.md)). Warned, the neighbor runs; not warned, they are
      taken, and theirs is the face crossed out on day 12's wanted notice (M180). **The raid is vans
      in the street at her building with a patrol, and the doorstep stays reachable**
      ([PLAYTEST-122](playtests/PLAYTEST-122.md): "we will have to see how that one feels", so it
      goes to `REVIEW.md` once built). The neighbor's door is sealed the next morning either way.
- [ ] **Day 11: silence a mast**, which stays quiet for the rest of the run: she reaches its
      foot, as a mark is touched, and its field makes the approach cost while it broadcasts
      ([PLAYTEST-122](playtests/PLAYTEST-122.md)). Waits on M180's masts, which expose each
      mast's stable id and foot.
- [ ] **The once-only happenings of days 10 to 13**, each leaving something permanent and each
      sited from where she is walking as the fire is (`DECISIONS.md`, M179), except the raid,
      which is at her own building and is what she comes home to: the raid, whose door is
      boarded the next morning; the market is gone; the park taken once she has reached the
      swing; and a column on the main road. **The convoys start on day 13** with the column:
      `military_convoy`'s `first_day` moves from 12 ([PLAYTEST-122](playtests/PLAYTEST-122.md)).
- [ ] **Day 12's park is forced open whatever its state**, as decided
      ([PLAYTEST-119](playtests/PLAYTEST-119.md)). Slice one sends her to a park that is already
      open, since forcing one needs `ClosurePlanner` and the scheduler's arcs, which were outside
      its fence; that is a narrower guarantee than the decision, not an overturn of it. **And
      the day guarantees a second open park she can reach from the swing**, checked when the day
      is planned ([PLAYTEST-122](playtests/PLAYTEST-122.md)).
- [ ] **The neighbor is seen from day 1**: on days 1 to 9, a figure in work clothes leaves her
      building each morning as she does and walks off, and nothing points at them; from day 11
      they are gone. The same figure is who day 10's arrow finds and day 12's wanted notice draws
      ([PLAYTEST-122](playtests/PLAYTEST-122.md)).
- [ ] **Two marks are reworded** ([PLAYTEST-122](playtests/PLAYTEST-122.md)). Day 8: "Something
      was left in the stroller in the night. Take it to the burnt building." Day 13: "Walk up to
      the roadblock. See how close they let you come."
- [ ] **Day 14's task is the station's front door, by the red arrow**, and the blackout follows
      (M183). Waits on M183's first slice, which gives the door a point other code can ask for.
- [ ] **The late days are timed** — the mark, the task, the happening and the walk home, day
      12's swing-then-second-park first — with M184, a rig that walks the route, before anything
      is cut ([PLAYTEST-122](playtests/PLAYTEST-122.md)). The figures go here, into slice two's
      brief. **Measured so far** (`--route mark,task,calm,home --invincible`, days 6 to 13 on seeds
      4242, 90210 and 1234567; the table is in `DECISIONS.md`, M184): every day she walked home
      from had at least 22 seconds left, most 50 to 120; on day 12 the second open park was
      reached a tenth of a second after the swing on the one seed whose swing the rig reached;
      days 10 and 11 have no mark or task until slice two builds them, so they are timed then. The
      rig gave up a leg in half the runs (M184), so the late days are not fully measured yet. **Each late day's happening arrives differently** — waiting at home, found gone,
      closing in front of her, coming on her way — and slice two keeps that variety.

---

## M159 — A slow frame names the frame that was slow · asked for 2026-09-19

> "we did some analysis of performance and lag frames / stutter. have astra look at the recorded
> numbers and the codebase and think about how we could improve performance and reduce stutter"

**On the desktop the player feels the stutter gone with v0.14.0's baked atlases**
([PLAYTEST-112](playtests/PLAYTEST-112.md): "I feel like the stuttering is gone (so it was
always what I predicted -- a proper atlas implementation solved it)"). The open items below are
reassessed against that: what remains is confirming it in the recorded numbers, and the phone.

**The deliverable is an optimization, with measurement retained as evidence.**
[PLAYTEST-86](playtests/PLAYTEST-86.md) clarifies: "well the point was to actually do some
optimizations. measurement is nice and make sure it's fully recorded but the core is to make
things faster". Instrumentation alone does not complete this item. Reduce a demonstrated cost
without changing gameplay, retain controlled repeated before/after distributions over equal
active-play windows, and verify identical behavior. A measured reduction in a named work metric
must be distinguished from whole-frame improvement and perceived smoothness. The existing noisy
toggle trials establish neither a causal toggle cost nor a shipping pacing choice.

`CrowdAgent.contribution_at()` skips velocity and ellipse work outside a conservative bound
that includes the current jolt and the maximum forward stretch. The exact-parity checks and
repeated before/after measurement are in [DECISIONS.md](DECISIONS.md), M159, cheaper crowd
contribution sweeps; the raw evidence is
[the contribution measurement record](evidence/m159-crowd-rejection-2026-09-19/README.md).
This establishes a reduction in query cost, while the remaining long-frame cause and phone
behavior still require the work below. `--frame-trace` supplies bounded raw callback intervals
and atlas CPU spans; its semantics and limits are in [TELEMETRY.md](TELEMETRY.md#raw-frame-traces).

- [ ] **Attribute the remaining slow intervals before another optimization.** Use the raw traces
      to select a reproducible expensive call or span, reduce that work, and retain controlled
      before/after evidence with identical-behavior checks. Establish repeatable full active-play
      windows before ranking modest readout, graph, telemetry or pacing costs. Keep rejected short
      trials visible. CPU callbacks do not measure physical display presentation, and unchanged
      counters do not rule out unobserved script work. M143, readout labels and windows, separately
      owns the engine's previous-second `process` and `physics` maxima. A pacing switch remains
      diagnostic, not a shipping decision.
- [ ] **Profile the current phone build only after that baseline.** Divide CPU time between the
      baby's every-physics-tick crowd contribution sweep, the halo's rendered-frame contribution
      sweep, event streaming/director work, crowd movement/traffic and debug presentation. Do not
      use `--invincible`: it skips the baby's source sweep and suppresses the meter behavior being
      measured. Measure the conservative contribution rejection on that device, including its
      effect on the baby and halo callers, before considering caching or lower tick rates.
- [ ] **Measure what the baked pages cost, on the run log's own lines.** A page writes one
      `texture` line when it is read — `atlas page '<group>' loaded in the <moment>: <ms> ms,
      <W> x <H>`, the moment being `startup`, `day brief`, `escape` or `OUTSIDE` — and one when
      its last reference goes, `atlas page '<group>' released after <s> s: <W> x <H>`; the boot
      prints how many pages it holds from startup and in how long. Collect those on the
      threadless web export and on the phone as well as the desktop, with the page sizes as the
      memory figure, and compare against the baseline retained from the runtime packer
      (`DECISIONS.md`, M159 and M171). Distinguish the CPU read from GPU completion where the
      platform allows it. No result here is assumed to explain the older laptop hitch, which
      predates every atlas path, and the native-host evidence supports neither worker jobs nor
      larger pages.

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

## M129 — A path through the city never has to cost · one route in eight still breaks

> "a path through the city must never hit excitement -- so all obstacles should be routable
> around … the routing should only cross the street at intersections"

[PLAYTEST-69](playtests/PLAYTEST-69.md), [PLAYTEST-71](playtests/PLAYTEST-71.md),
[PLAYTEST-75](playtests/PLAYTEST-75.md), [PLAYTEST-76](playtests/PLAYTEST-76.md),
[PLAYTEST-77](playtests/PLAYTEST-77.md). The four rules, the leaf blower's two-part field and
the wall reading are built and recorded (`DECISIONS.md`, M129, the four rules; M129, the leaf
blower is a wall to walk past and a busker to stay near; M129, a wall is also what cannot be
walked past). The probe, `tests/probes/m129_zero_cost_line.gd`, finds a zero-cost line along
261 of 296 routes. No body closes a walked sidewalk (`DECISIONS.md`, M129, no body closes the
walked sidewalk, which also holds the rim decision and the square's poster crew). The guarantee
is not true
for the rest, and what stands in them is almost all one shape: a route junction taken by several
rows together, with `leaf_blower`, `homeless_yeller`, `roadblock` and `delivery_van` in the
cuts; the probe's own table names them per run. No sidewalk rule reaches a `roadblock` on a carriageway or a wall's wide field reaching
over a crossing from one street out. The three placement rules refuse a candidate whose reach
*together with everything already down* would close a junction, so a crossing the probe finds
covered is one that either reached the day past the rules or is read as covered differently by
the probe and the rule:

- [ ] **Which placements the three rules never see.** `_place_one`'s candidate loop is where
      the rules run. Find every other path a row reaches the day by — the calm-ground pass
      that covers a park by area, `_ensure_one_usable_park`, the seals a `SealPlanner` places
      before the scheduler runs, the region walls and doors — and say, per broken route in the
      probe, which path placed the rows in its cut and whether the probe's *covered* and the
      rule's *open* agree on it. Then either those paths ask the same three questions, or the
      record says why a route may pay there. The probe's "what broke the line" table is the
      measurement; the seals and the region wall cost about four points (92.2% on the day's
      own rows against 88.5% with them).

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

- [ ] **`--spawn contact` asks for the contact before one exists.** On a dev-flagged boot
      `DevRig.spawn_position()` runs before `ResistanceDirector.start_day()` has placed the
      day's contact, so the flag cannot put a rig beside a chalk mark and no capture of one is
      cheap. Found in M177; the order of the two calls in `main`'s first-day boot is the fix.
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
      discrete noise. `art/events/sound_pulse.svg` supplies three open arcs in a 48×32 canvas,
      anchored at (24, 32); pulse timing, orientation and runtime binding remain. The last gap in
      the visual channel comes **before** audio.
- [ ] **Audio**, once the above is done and judged on its own: per-act beds, per-event cues, the
      baby's breathing as the diegetic version of the meters. Additive by design
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
      what is left open is the moment of the touch itself. The first mark is hinted at by day 6's brief
      ([PLAYTEST-122](playtests/PLAYTEST-122.md)), and how much a touch may say is the
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

**The sequence is the run's ending**: a won day 14 with every task complete goes on to it, and
`--start-escape` reaches it directly. It is the building with its events, the service exit onto the city,
the two chains through three calm areas each to the tunnel and the bridge, the explosions and their
craters, the two hint lines, the millisecond clock, the section restart and the epilogue. What it
does, what was measured and what was chosen where the design was silent is in `DECISIONS.md` under
M102, the finale built behind the flag, and M102, the finale is the run's ending; what only a
play can settle is in `REVIEW.md`. **One item is open**, what the audit of a day against a
section found and could not wire.

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

- [ ] **The building shows what the city shows, and the escape is in the run log as a day is**
      ([PLAYTEST-115](playtests/PLAYTEST-115.md): "The escape shouldn't behave any different
      than the rest of the game"). The screen-edge badge, the excitement halo and the debug
      view's layers are built for the city section only, because each reads a `City`'s own
      `EventManager` and crowd, and the building's `InteriorEvents` is not shaped like one; and
      neither section has the telemetry observer a day has, which is built around a day's
      `City`, route tree and corridor. Each needs an adapter or an observer of its own rather
      than wiring.

**Four things the brief collided with in the finale as `docs/NARRATIVE.md` writes it today, each
asked and each answered by the player on 2026-09-09:**

1. **The sabotage stays, and the escape is what it causes.** *("yes, the sabotage is the cause of
   the brutal crackdown.")* Today the good ending is `RESISTANCE_GOAL` reached *and* the day-14
   step "The last night" touched (`ResistanceSteps._finale`, a civic-district contact that sets
   `sabotage_done`), and what it changes is mechanical quiet: every loudspeaker mast is
   silenced (`EventManager.silence_all_masts()`). **Neither the walk home after it nor the escape is easy**
   ([PLAYTEST-121](playtests/PLAYTEST-121.md): "the escape shouldn't be easy!"): M183, the power
   station and the blackout, takes the traffic lights with the power, so the roads are harder
   that night on purpose. The hallway scene follows the same night, and the trucks and the
   masked men are the regime's answer to what she did. *"No triumphalism"* still governs what is shown
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
   additional tension.")* *Asked for one clock counting down through both sections · overturned
   by the player on 2026-09-20 to "180s per section"
   ([PLAYTEST-113](playtests/PLAYTEST-113.md)), because each section is its own day and a shared
   clock could leave the city's checkpoint unwinnable.* So: each section's clock is
   `DAY_LENGTH_SECONDS` (180s) long like any day; at zero the way out is gone — the bridge or
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
