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
      UI buttons and identity/export consumers. The application icon is done — it is the root
      `icon.png`, bound directly rather than through the SVG-override comparison, since nothing
      else reads `icon.svg` any more (`DECISIONS.md`, the application icon is the enhanced
      stroller). Provide registered PNG bindings for every remaining live SVG without altering
      draw transforms; verify both flag states and missing/mismatched fallback. The SVG override
      remains the comparison control during review.
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
3. **M99 and M100**, in no order between them: the corridor's density after the sealing, and the
   consolidated small work. M96, the teaching day, and M97, the calm areas, are both done — M96's
   one remaining item, the cliff at 89, is closed (`DECISIONS.md`, M96, the day ends crying only
   after a push at the top), and M97's are closed by the player's own word (`DECISIONS.md`, M97,
   calm areas that hold is closed). Each of the four was rewritten on 2026-09-09 from an older
   milestone after checking which of its items the code had already answered; the record of what
   was found built is in `DECISIONS.md` under "The queue reprioritised". M98, pressure in the
   empty acts, was the fifth of them and is built (`DECISIONS.md`, M98); whether its return reads
   as pressure or punishment is in `REVIEW.md`.
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
| M100 — Small, real, and nobody's | Compare `alley_draft.svg` in context before deciding whether it replaces the live alley. Bind the sound arcs with their event timing. |

M102, the finale, owns the impact-crater decals and the carrying-mother set and has bound what it
needs of them; `GRAPHICS.md` names which sources are live and which stay
prepared, and whether the interior's event layering reads is a `REVIEW.md` question.

**A milestone still holds either drawings or not**, so that ordering one never parks work that needs
no artist.

**M79 is tabled rather than queued.** It is the city seen at an angle — a presentation change with
the lattice left cardinal — and it is written down so that whoever chooses the projection does it
with the code's constraints in hand. It is not queued and it is not rejected.

**M102, the finale, is built and is the run's ending**: a won day 14 with every task complete goes
on to it, and `--start-escape` reaches it directly. It is the good ending's last scene — out of
the apartment, out of the city. Its brief, the four collisions the player answered and the record
of what was built are in `DECISIONS.md` under M102; what only a play can settle is in `REVIEW.md`.

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
      resistance has a reason, and a task is one day. Those still without one: the van's drop,
      the burnt shell, the named door, the roadblock's band, and the power station's door, whose
      blackout comes only once she is 512px away. The warned neighbor runs, the silenced mast goes
      dark and the swing's park is taken (`DECISIONS.md`, M181, slice two). Each answer is
      something that happens where she is looking, and none is text.

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

## M198 — A rig's window never becomes the active app · asked for 2026-09-25

> "are all agents using the non-focus rig now? I still lose focus and even accidentally closed one
> window"

[PLAYTEST-133](playtests/PLAYTEST-133.md), statement 6. A rig's window takes no key focus
(`DECISIONS.md`, M195, a rig's window takes no focus, hears no stray key, and always closes), but
macOS still activates the Godot app when it launches.

- [ ] **`tools/shot.sh` and a rig's `tools/run.sh` launch Godot without activating it** on macOS
      (launch services' background launch, `open -g -n -W` with its output routed back, or
      whatever the measurement supports), keeping their exit status, their time limit and their
      output. Verified on this Mac by the player's own focus staying put, since no other app may
      be scripted to check it.

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
      counters do not rule out unobserved script work. The readout's `process` and `physics`
      lines are the engine's previous-second maxima (`DECISIONS.md`, M143), not per-frame costs.
      A pacing switch remains
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
      M125. `test_resistance.gd` joined them: about 160 s under load once the narrow targets'
      reachability test landed (`DECISIONS.md`, M181, the narrow targets are reachable by
      construction), against the 43 s `suite_costs.txt` still records. The two suites M124 and M135 added have no row in `suite_costs.txt` until then and
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

- [ ] **Does the escape grow with the ordinary day?** It stays 180 s (`Tuning.FINALE_LENGTH_SECONDS`,
      now stated on its own) while days 1 to 5 went to 210 s (`DECISIONS.md`, M192, a curfew day
      is the old full day). Asked with the day length, not yet answered; 180 s keeps "the escape
      shouldn't be easy" ([PLAYTEST-121](playtests/PLAYTEST-121.md))

- [ ] **`test_finale.gd` leaves `GameState.escape_section` set.** Run in one process just before
      `test_resistance.gd`, a finale test leaves the section at `BUILDING`, so the next `City`'s
      `Blackout` starts dark at `setup()` (`_in_the_escape()` reads that flag) and
      `_test_the_sabotage_silences_the_city` fails three checks; every suite is green alone and CI's
      shards keep them apart. Found building M192

- [ ] **Day 8's mark line runs off the screen at 1280×720.** The player's own wording, 79
      characters ("Something was left in the stroller in the night. Take it to the burnt
      building."), is wider than the HUD's teaching line, which does not wrap (`src/ui/`). Found
      building M181, slice two

- [ ] **A door can set her down inside a building.** A door's release reflects her through the
      crossing's line and keeps how far off the door's axis she was when it caught her, so a
      catch from the side can land her on a building tile; the route rig works round it by
      re-planning from the nearest open tile (`DECISIONS.md`, M184, the rig gets through
      chokepoints). The release is `EventManager`'s, in `src/events/`

- [ ] **Pressing into a lowered boom off its centre line slides her round it to the hut.** The
      boom's body is a 32px circle across a carriageway, so pushing into it off-centre slides her
      round its edge into the notch beside the hut, where the hut inspects her. A body shaped to
      the arm (a capsule across the road) would stop her flat.

- [ ] **A car pulling away from a stop line honks later than the contract asks.** Starting from a
      standstill at a boom or a signal, a car's first horn comes less than `required_horn_time()`
      before it reaches her; the horn's watch (`DECISIONS.md`, M191) assumes a car already at
      speed. Found building the boom's walk-under

- [ ] **`--spawn event:checkpoint_gate` stands her on a hut's own tile**, so she is inspected at
      once, and once physics pushed her across the hut's line and it logged as a walk under the
      boom (`src/dev/dev_rig.gd`)

- [ ] **Walking may read as running at some bearings.** A `--walk` bearing of 175° read as running
      in the run log and the door guard broke off his chase; `Stroller.run_excess_ratio()` may be
      treating a unit input a hair over 1 as running. Not yet confirmed

**Drawings, as SVG:**

- [ ] **The basement's floor decals are drawn over her feet.** The puddle, debris and rat decals
      sit in the building's depth-sorted layer (`InteriorScene._rebuild_overlays()`), so each is
      drawn over her feet while she stands on its northern half; the vent's grate lies at the floor
      tiles' own layer for exactly this reason (`DECISIONS.md`, M100, the basement vent is a floor
      grate)

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
