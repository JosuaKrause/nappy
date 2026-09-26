## What to do next, in order — *superseded; see "Where to pick up" at the top of this file*

**This section is M37-era and is kept as history rather than as a queue.** The live order is the
pick-up block at the top: M52's calm shapes, then M53's junctions, then M54, then M50's leftovers.
Two lists of next steps in one file is how a to-do gets filed and not read, which this session paid
for four times — so if these two ever disagree, the top of the file wins and this heading is the one
to correct.

What is still worth reading here is the **playtest questions**, which are not stale: most of them
have still never been answered by a person, and they are the shape of question a rig cannot answer.

### First: play it, and look at the people

**M37 drew fourteen silhouettes and a contact sheet is the only thing that has looked at them.**
Five of the fourteen are reachable before day 4 and the rest have never been met by anybody, so
this is the cheapest playtest the project has had in a while: walk a day and see whether the street
tells you what is on it. What a rig cannot answer:

- **Can you tell the man shouting from the busker without walking up to them?** That is the whole
  claim. Playtest 09's *"who is the person killing me?"* is the question this milestone exists to
  answer, and the answer is now supposed to be *look at him*.
- **Do the robber's two postures read at an alley's length?** *(Day 8, so probably not this run.)*
  The waiting one has no face in the hood and the coming one is leaning out over a forward leg, and
  the entire point is that they are told apart **before** the 140px trigger rather than after it.
  Nothing else in the game asks a silhouette to carry a state change.
- **Does the protest read as a wall?** It is 55px of body where it was 11, drawn as two ranks of
  placards across exactly that width, and it sits on crossings and squares from day 12. If it reads
  as an obstacle course rather than as a crowd, that is the one gameplay number M37 moved.
- **And does anything now hide behind a building?** Buildings sort against nothing, which is a
  strictly larger claim than *the bug is fixed*. If a sprite ever looks like it is floating in front
  of a wall it should be behind, that is this change and not the art.

### Then: play it, and look at a street that is solid

**M34 has still been walked by a rig and by nobody's eyes**, and it is the milestone that changed
what an ordinary pavement *is*: about two thirds of the catalogue has a body, and day 1 went from
12.2 things that take a 64px footway to 17.2. The count of events placed did not move, so the
question is not density — it is whether a street that stops you reads as a route decision or as an
obstacle course. Three specific things to watch, because a rig cannot:

- **Does a blocked pavement read as a decision?** A van at the kerb takes the footway and the
  answer is meant to be *the other side of the street*, the same answer `construction` has asked
  for since M19. If it reads as "walk into the road", that is the density of blockers, not the
  bodies.
- **Does anything trap her?** She is 14px and a van is 22, so the gap between a van and the
  frontage is smaller than she is: she stops. That is intended and it is also exactly the shape of
  M19's *"no line to walk"* mistake, which took a rig walking a real pavement to see.
- **Does the lorry read as backing into the yard?** It is turned to face out of the frontage it is
  against, and about half its box end is behind the building's front wall. That used to be finding
  4 happening and reading *correctly* by accident; since M37 the lorry is simply in front of the
  wall, so it is worth a second look at whether it still reads as reversing into something.

### Then: the three left from playtest 07

Listed at the bottom of [PLAYTEST-07.md](../playtests/PLAYTEST-07.md), and none of them is large: **1**, the cat
crossing perpendicular to her *heading*, which is a run down the middle of the carriageway when she
is crossing a road; **8**, a four-block calm zone rolling `QUIET_SQUARE` and becoming a 22-tile
concrete plaza with thirty trees on it; and **6**, a car turning swapping axes in one frame with no
diagonal art to turn through.

### Then: play it, and read the `idle` and `cue` entries

Nothing is queued ahead of a person playing. Six of playtest 06's own findings and playtest 05's
before them came out of somebody walking around for a few minutes, and M32 in particular is five
changes to *when things appear on screen*, judged by a rig and a trace and by nobody's eyes.
What to look for, in the order it would show up:

- **Does the mark still turn up after the fact?** Every `cue` line for the mark says how long it
  was up and how much of that she spent on the road. In a probe run they are 0.3–0.7s and *all*
  of it on the road. A span with a road figure well under its duration is this bug coming back.
- **Do the badges still flicker?** A `cue` pair with a fraction of a second between them is a
  flicker with a name on it now. The "gone" line says where the thing was when the badge went,
  which is the difference between the badge doing its job and the badge giving up mid-approach.
- **Does the pram read?** The four states have been screenshotted in every facing and never
  watched. The one to distrust is *not settling* (amber waves): it is the only one that can be
  up for a long stretch, and a cue that is up for a long stretch is how the rings started.
- **Is a retry the right length of punishment?** Three nerves are now three attempts. Whether
  that is too soft is a question only a run can answer.

### Then: M25, patrols and running that matters

The biggest thing outstanding, narrowed in M31 to **acts III and IV** by decision — *"patrol
shouldn't be there for act I"*. See the section below and `docs/TODO.md`.

### And the questions the fifth and sixth playtests still have not answered

Playtest 06 settled the big one — ***"I like the difficulty now"*** — which retires *"no balance
number has been felt by a human"* and means the next balance argument starts from "this is
roughly right". These are the ones it did not reach, and every one is now being asked of a
**much busier street** than the one that prompted it, so they are worth re-reading off a trace
before anything is tuned:

- **Do the seven new entities read as what they are** without the caret telling you? That is the
  one thing no test can see and the reason each got its own silhouette.
- **Is a four-block calm zone a route?** M21's whole claim, and the number behind it — 10.8s
  corner to corner against 23.8s for a full meter — is arithmetic, not a verdict. The trace
  entry that says it is `settled`: whether she walks a line through it or laps it anyway.
- **Is the arterial crossable?** Walking its length loses day 1 in fourteen seconds, which is
  intended; crossing it at a zebra should be routine, and since M29 the giving-way is finally
  legible from the kerb. `road` and `crowd` entries say which happened.
- **Do bumps read as the player's fault?** Eleven contacts down a lane centre against one on the
  midline. Whether a person finds that line is a different question from whether it exists.
- **Does anybody get run over, and does it feel fair?** A `lost` line preceded by a `crowd` horn
  line is a fair death; one with no horn before it is a bug in M19's work. M30 gives the horn a
  picture now, so the trace and the screen should agree.
- **Do the cues get read?** A `run` or `turn` following a badge is the evidence, and nothing in
  a test can see it. *(M32 closed the half of this that was a missing instrument: there is a
  `cue` entry now, so the log finally answers "what was she warned about". Whether she then did
  anything about it is still a question for a person's trace.)*

### What is left of M21

The calm-zone half is done. Two halves are not, and both are open by decision rather than by
oversight:

- **Main roads with lights against side roads with zebras** — playtest 02's finding 6, where a
  main road is crossed rather than walked. Decision 3 of that document said the way to get there
  is *"making walking it hostile, reusing finding 3's hazard mechanism, rather than by deleting
  its pavement"*, and **M19 and M27 did exactly that**: the carriageway is lethal, the traffic
  is dense, and walking the arterial's length loses day 1 in fourteen seconds. So what is
  actually left is the *lights* — a signalled junction, which is a mechanic (a window that opens
  and shuts) rather than a piece of scenery, and which nobody has asked for since.
- **The canal**, dropped out of M16 into M21 because it is the one feature that would **move a
  walkable tile**, and M21 was going to be where a lattice with holes was already paid for. It
  is paid for now — `absent_segments` and `is_street()` are the shape a bridge would use — so
  this is cheaper than it was, and still unasked-for.

### M17 — the route map, **backlogged**

*Not the next thing, by decision taken in this session: "in case you have it still in your notes
about showing a brief map at the start let's not do that for now — we might revisit later but
for now let's put it in the backlog."* Nothing below is withdrawn and the gap is real; it is
simply not what the game needs next. Kept here so that when it is picked up, the argument for
it is still assembled.

The planning screen, rendering the block states M15 introduced *and* the closures M16 adds.
`CityState.changed_on(block)` is already recorded for exactly this — shading "this is new" is
what makes the screen worth opening twice.

M16 raised the value of this: closures are legible at the junction and **not** before it. A
player two junctions away cannot know a street is shut, and the map is the only thing that
can tell them. That gap is stated as a gap in `docs/CITY.md` rather than papered over.

M23 raised it again, and gave it a test: the log's `closure` entries say where a barrier was
seen from, and a `turn` following one says whether it changed the plan. If closures read as
scenery in the traces, that is the argument for the map screen — and afterwards, the same two
entries are how to tell whether the map fixed it.

### Then the rest, per PLAYTEST-02.md

M18, M19, M22, M23, M24 and M27 done; M21 half done (see above); M17 backlogged.
**M20 traffic that behaves** is **parked, not queued**: M27 shipped the half that mattered
(cars follow and queue; zero overlapping pairs a frame, down from 5.2), and what is left —
overtaking, eight-way driving, a crash as a catalogue event — is unasked-for by any playtest.
**M25 patrols, and running that matters** is the biggest thing outstanding and its scope
**narrowed** in M31: a patrol was ruled out for act I by decision — *"patrol shouldn't be there
for act I"* — so this is now specifically the answer for **acts III and IV**, where the streets
are deliberately empty and the threat should follow rather than sit. The `run` entries are the
measurement it will be judged by and today they all say the same thing: running is the wrong
move against every event in the game, so a patrol needs a mechanic running *escapes* — something
that pursues, a lethal radius that grows, a window that shuts — and a fairness contract stated
over `RUN_SPEED` rather than `WALK_SPEED`. It also picks up playtest 03 finding 3, the walk home
being a formality: patrols that were not there on the way out are the return phase's own
pressure.
**M26 teaching the controls** — delete the interact key, then teach walking and running,
ending in a scripted day-1 event that requires a short run. M26 must come after M25 for
correctness, not scheduling: forcing a run before running is ever the right answer teaches a
move that is never correct again.

**M21 was expected to rewrite the lattice enumeration in `src/routes/street_network.gd` and it
did not have to.** The prediction was right about the consequence and wrong about the shape: the
graph half of that file — route counting, the invariant, the doorway exemptions — did survive
untouched, and route redundancy did stop being true by construction. But the enumeration
survived too. A street a calm zone absorbed is one the lattice still *lists* and this city does
not *have*, and every route search already took a set of streets to ignore, because M16 built one
for the closures. `CityMap.absent_segments` joins that set and nothing else changed. The one new
function on `StreetNetwork` is `around_blocks()`, because "the ways into this calm area" stopped
being derivable from a block coordinate the moment a calm area could be more than a block.
