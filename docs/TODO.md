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
their single side picture by the choices recorded there. Every living thing that moves strides,
two frames per view (`DECISIONS.md`, M108, the walkers' stride; M108, the event strides), the
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

### M111 — Cars follow their turns

The motion is built — a car plans one arc tangent to both lanes and follows it, its heading the
tangent throughout, nothing committed before the swept strike box has been checked against the
ground — and the record, with its measurements and the turn geometry's own reasoning, is in
`DECISIONS.md` under M111. The diagonal *pictures* on the curve are M108's vehicle item, which
reads `CrowdAgent.heading()`, the unit vector along actual travel. What stands here is what the
build could not decide alone.

- [ ] **Open question, the player's: the street about-face crosses a kerb, or the traffic gets a
      reverse gear.** A half turn between two lanes 32px apart is a 16px arc, and a car's corners
      then reach 40px from its centre against 32px to the kerb, so a car turning round *in a
      street* — only where a barrier leaves it no junction to reach — overhangs open pavement by
      8px, every hard blocker still refused. Refusing that too was measured: 33 of 34 cars at a
      standstill inside ninety seconds, because one nose-to-wall car holds its junction and the
      street behind it queues. The manoeuvre it really wants is a three-point turn, and the
      traffic has no reverse gear. The overhang cannot kill her — a strike counts only on a road
      tile, the same kerb read from her side — so the question is whether the picture is
      acceptable, or whether reversing is worth building. **And one instant reversal survives**
      as the last resort for a car already stopped with less than a half turn's room in front of
      it, reachable only by a placement or a barrier that arrived after the car did; the
      alternative was a car that never moves again

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
- [ ] Correct the carrying mother's A/B gait frames in every direction: PLAYTEST-65 clarifies
      that the pictures differ but do not depict walking. The north view comes closest, yet
      still fails to swap the left/right leg behind. Preserve each direction's head, torso,
      arms and baby; alternate which anatomical leg leads and trails, and which overlaps the
      other in each view. Sideways movement also needs spread and closed legs: use open,
      passing, opposite open, passing, with three distinct source poses and a four-phase cycle.
      Author and review each new passing-pose SVG before its PNG. Check readable leg motion at
      native scale. Keep versions
      A–D available for comparison; name the corrected family E, clear strides. Inspect all
      five view cycles and west mirrors, and verify animation in the running game.
- [ ] Bring the stroller drawing closer so the mother's hands meet its handle, as requested
      in PLAYTEST-65. Inspect both gait frames and all eight directions, including turns;
      change visual placement and its dependent shadow/cue placement together. Preserve
      collision positions, navigation, steering and gameplay costs. Compare PNG and SVG modes.
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

0. **M117**, excitement decays visibly on quiet ground, and **M118**, a car crash is solid only
   where the cars are — *(2026-09-12: "prioritize this fix"; "this round's feedbacks should all
   be prioritized since I'm actively testing the changes as they come in")* — ahead of
   everything, by the player's own word.
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
| M102 — The finale: out of the apartment, out of the city | Extend the playable interior and its carrying-mother rig into the finale. Bind normal/flash windows to explosion timing and steam to its pulse. Reuse mouse, guards, vehicles and crater sources. Decide whether the optional `explosion_preview.svg` is needed; the off-screen explosion brief does not require a visible burst. Check event state changes and their layering in the interior at runtime. |

The impact-crater decals `assets/props/impact_crater_1x1.svg`,
`impact_crater_2x2.svg` and `impact_crater_3x3.svg` (32×32, 64×64 and 96×96 footprints) are the
finale's: the marks its off-screen explosions leave on the street. M102 also owns the prepared `assets/rig/mother_carrying_{front,back,side,front_diagonal,back_diagonal}_{a,b}.svg`
set, documented in GRAPHICS.md and bound by the playable apartment's carrying rig.

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

## M117 — Excitement decays visibly on quiet ground · asked for 2026-09-12

> "the decay for excitement is too low anywhere -- except for the main street and maybe alleys
> there excitement should go visibly down when no excitement source is around -- prioritize this
> fix"

[PLAYTEST-63](playtests/PLAYTEST-63.md). Placed first by the player's own word.

**What is true today.** Walking decays excitement at `EXCITEMENT_DECAY_WALKING`, 3.5 a second,
times what the ground does: calm ground 2.2, a precinct 1.5, an ordinary street 1.0, the main
road 0.6 (`City.decay_multiplier()`; an alley has no multiplier of its own and decays as an
ordinary street, while standing in one adds `EXCITEMENT_FROM_ALLEY`, 3.0 a second, so an alley
is already net-slower than a street). Standing still decays nothing and running 0.5. The crowd
on an ordinary pavement charges about 1.4 to 2.2 a second over a forty-second walk, so a quiet
street nets only 1.3 to 2.1 a second downward — thirty points take fifteen to twenty seconds
to leave the bar, which is the "too low" the player sees. **Every crowd number is pitched
against the walking decay**: one person at arm's length is 4.2, just over it, so a close pass
costs; one car 5.4; the arterial's floor between one and three times it; `tests/test_crowd.gd`
and `tests/test_meters.gd` assert those relationships, and the calm-zone admission distance in
`EventScheduler._denial_radius()` is the walking decay times the calm multiplier, 7.7 a second.

- [ ] **Raise the walking decay on every ground but the main road, and hold the main road where
      it is.** The target is a **net** rate on an ordinary pavement, with the day's own crowd on
      it and nothing authored in range, that the bar shows: measure it first on a rig over
      several seeds and forty-second walks (the `tests/test_crowd.gd` floor probes are the
      instrument), then set `EXCITEMENT_DECAY_WALKING` so the net comes out around 4 a second
      or better — a full meter in about twenty-five seconds of quiet walking — and reduce
      `EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER` in the same step so the main road's **absolute**
      rate stays at today's 2.1 a second. Keep the ordering calm > precinct > street > main road
      and re-measure the calm and precinct rates after; if the park clears a full meter in under
      eight seconds the calm multiplier comes down to keep it a place rather than a switch.
      **Decouple the calm-zone admission distance from the decay**: `_denial_radius()` gets its
      own constant at today's 7.7 a second, so louder rows are not admitted beside parks as a
      side effect of the pram settling faster. Regenerate the cost table in `EVENTS.md` ("What an
      event actually costs"), rewrite the decay table and the crowd paragraphs in
      `MECHANICS.md`, and re-state — not delete — every relationship test that the new number
      breaks, with the reason beside it. Verify on a played rig, not by arithmetic: the same
      walk before and after, net rate in the report.
- [ ] **Three questions the instruction left open, put to the player on 2026-09-12 with a
      recommendation each, and answered the same day: "build as recommended"** — so each is
      a decision now, built with the item above and recorded beside it:
      1. **Standing still.** Today it settles nothing, and that was a decision (playtest 07
         finding 3: standing was the fastest of the three rates and made waiting the strongest
         move in the game). Recommended: unchanged — the fix is on the walking rate, so the
         bar visibly falls while she is being pushed, and waiting stays no plan.
      2. **Alleys.** The player's "maybe". Recommended: an alley keeps today's absolute rate,
         3.5 a second, through a multiplier of its own, so it sits between the main road and an
         ordinary street — pressured ground, not a shortcut to recovery — and the constant dread
         it already adds keeps meaning something.
      3. **A single passer-by.** Once the decay outruns 4.2, one person at arm's length no
         longer costs on their own; a contact (18 a second) and a busy pavement still do.
         Playtest 07 finding 9 asked that brushing past somebody cost something. Recommended:
         accept it — the player's sentence is that *no source around* should read as recovery,
         and a lone passer-by at the pavement's width is the nearest thing to nobody — and keep
         the crowd's own numbers where they are, since raising them to chase the decay raises
         the main road's crossing cost with them.

---

## M118 — A car crash is solid only where the cars are · asked for 2026-09-12

> "a car crash right now has a full bounding box even though there are gaps in the sprite. the
> bounding box should only be the crashed cars but it should emanate an excitement field that
> prevents the player from walking past it"

[PLAYTEST-63](playtests/PLAYTEST-63.md). Prioritised with everything from that round.

**What is true today.** `car_accident` is a hard seal: `SealPlanner._hard_positions` stands one
copy of it across the carriageway, and its body is `GroundShape.band(96.0)` — one capsule 192px
kerb to kerb, the width of the street, like the fallen tree's and the burst water main's. The
picture (`assets/events/car_accident.svg`, 200×50, and its `_vertical` sibling) is two cars locked
side by side with debris between them and an onlooker on each pavement, so the body covers
pavement and debris the picture leaves open. Its `intensity` is 0.0, by the rule in `CITY.md`
that **a closure is silent** — the shape of the route and nothing else — and the crowd is kept
off the street through `CityMap.held_segments`, not through the body.

**What this overturns, on the player's word.** *A closure is silent* · overturned for the
accident on 2026-09-12, because a body that matches the picture leaves gaps, and the player wants
the gaps closed by a field rather than by a wall nobody can see. The fallen tree (one trunk kerb
to kerb) and the burst main (a crater between two barriers) are not named and stay as they are;
whether they follow is the player's question, not this item's.

- [ ] **Two car bodies, not one band.** The def carries a list of solid parts — each an offset in
      the scene's own frame and a `GroundShape` — in place of one shape, and `EventInstance`
      registers a collision body per part and records each part's tiles in M110's per-tile
      solid record (`CityMap`, the record the crowd reads) so the crowd steps round the cars and
      not the debris. Every other row keeps exactly one part, so nothing else changes; `reach()`
      over the parts is what the planners' disc-shaped guarantees are stated over, and it stays
      96 for the accident so no placement rule moves. The parts' positions are read off the
      picture, per axis, at the scale `_draw_wide_scene` fits it to the street: the two cars,
      nothing else. The debug view's bounding-box layer draws each part, which is how the fit is
      checked by eye.
- [ ] **The scene emits.** `Tuning.CAR_ACCIDENT_INTENSITY`, with the field stated over the
      scene's own band — inner radius at the band's edge, a short shoulder outside it — so it is
      felt in the gaps and beside the cars and not from down the street; a sealed street must
      still be discoverable by walking up to it, which is why closures were silent. The number
      is chosen by the walk, the way the main-road crossing is: measure what squeezing through
      the pavement gap and the debris gap costs at a walk, over several seeds, and set it so the
      pass costs **more than half the meter** — the line `tests/test_crowd.gd` draws between
      expensive and fatal, on the fatal side of it — and state that as the test. **One open
      question, built the recommended way and switchable by one number:** whether *prevents*
      means *costs more than she can carry* (recommended: the nearly-crying cue at the pram is
      the turn-back signal, and a fresh meter can still force it at the price of the day) or
      *lethal* (a `hard_fail` inner radius over the gaps, the mechanism a fire already uses —
      stricter, and it makes a crash a thing that kills). `CITY.md`'s closure section and
      `EVENTS.md`'s "Solid things are solid" carry the exception in the same commit.
- [ ] **The seal still seals.** `ClosurePlanner` goes on counting the street as closed for the
      route guarantee and the crowd is still held off it; both are conservative once the street
      is passable at a price, and the direction argument — a pass that only ever removes
      obstruction can only add reachable ground — is written beside the change. A test walks the
      gap on a rig and asserts the cost, and `tests/test_events.gd`'s solidity checks accept a
      row whose silhouette is wider than any one of its parts.

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
queue reprioritised". What is left is one decision nobody implemented and one measurement.

- [ ] **The later dog charges the moment it streams in; whether it should wait to be routed into
      is the player's call.** *"The tutorial dog may appear later but not as tutorial"* (confirmed
      2026-09-09) is built as far as placement goes (`DECISIONS.md`, M96): from day 4
      `charging_dog` is a map placement like `alley_robbery`, never sited on her heading, and day 3
      keeps its unavoidable siting. What the placement does not give it is the robber's *waiting*:
      the dog carries no `pursues_within`, because day 3's lesson depends on it charging at once and
      `tests/test_danger.gd` pins that, so on day 4 and after it begins its telegraph and charge
      the moment it streams in — `Tuning.EVENT_STREAM_RADIUS` (900px) from her, past the edge of
      the view — rather than when she comes inside its own field. That is met by *proximity*, not
      by routing into it, which the decision's own words asked for. **The recommendation** is a
      trigger the dog gains on the same day-keyed switch its spawn mode already uses — waiting
      inside its own outer radius from day 4, so a dog she can see is a dog she can route around,
      exactly the robber's shape — built as a derived answer on the def rather than a mutation, the
      way `spawn_mode_on(day)` is; the alternative is to leave it, if a dog that comes from off
      screen whenever she passes within a block is the encounter wanted after the lesson. The
      lead-time gap playtest 20 measured (1.5s to evade against 0.8–0.9s on the days it killed her)
      is closed by M77 already; the figures are in `DECISIONS.md` under M96
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

## M102 — The finale: out of the apartment, out of the city · asked for 2026-09-09

**Queued on 2026-09-12, behind the flag.** *Planned and not queued on 2026-09-09 ("this is just a
plan for now — we probably won't actually implement it for a while") · overturned by the player on
2026-09-12: "also build the entire escape sequence to the end but make it playable only via flag
today (what is now the apartment escape should continue)".* So the whole sequence is built —
the building with its events, the service exit onto the city, the two chains through three parks
each to the tunnel and the bridge, the explosions and their craters, the hint lines, the
millisecond clock, the section restart and the epilogue — and **today it is reached only through
`--start-escape`**, which already boots the empty building: from the service door that run now
continues into the finale's city rather than returning to the title. The entry from day 14's own
summary is the one item that stays open until the player says the finale is a run's ending, and it
is marked below. Written down on 2026-09-09 so that M62 (checkpoints that divide the map), M56
(the resistance is noticed) and M100's sound lines were built knowing they are also the finale's
parts, as M101 (the fire found before the engine) was.

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
      milestone adds inside it: the exit through the service door onto the city map at the home
      lot's side, the hallway windows that **flash** when an off-screen explosion goes off (the
      explosion row's cue indoors, one or two frames of `hallway_wall_window_flash.svg`), the
      lighting response to the explosions, and the events — mice, the pursuers on the stairs, the
      fire on one stairwell, the steam
- [ ] **The entry from day 14's summary rather than from the flag** — the one item held back on
      2026-09-12 *("make it playable only via flag today")*: the good ending's last won day hands
      over to the hallway instead of the ending screen. Everything else below is built behind
      `--start-escape`, and this is the switch that makes it the run's ending
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
