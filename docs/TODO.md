# TODO

**The queue. Open work only.** Each entry is a folder under [todo/](todo/), named
`<date filed>-<adjective>-<animal>` and spoken by its two words ("busy-badger"); an entry filed
before names keeps its milestone number (`2026-09-26-M210`). Its `README.md` holds the player's
words, the playtest links and the context, and each item is a file of its own beside it, written
in full prose. Finishing an item deletes its file; when the last one goes, the folder goes and the
entry's record is written to [decisions/](decisions/) under the same name, in the same commit.
Search the records (`tools/decisions.sh <noun>`) before designing anything. No ticked boxes, no
"Done:" paragraphs, no branch names or status words in headings, here or in an entry.

`tools/new-name.sh todo "<title>"` makes a new entry's folder and prints its name. Read
[HANDOFF.md](HANDOFF.md) first for the state of the tree.

Each entry is one git branch, squash-merged to `main` through its pull request. An item somebody
is mid-way through says so in its own text.

---

## The order

### [M109 — Convert the SVG catalogue to PNG](todo/2026-09-10-M109/)

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

The entries, in the order the gameplay queue above gives them, reassessed on 2026-09-09:

- [M175 — A row states what it costs, and the cost table is checked in](todo/2026-09-20-M175/)
- [M182 — A finished task is shown by the world, never by text](todo/2026-09-20-M182/)
- [M185 — A ground floor is blank wall or shops](todo/2026-09-23-M185/)
- [M199 — The roadblock closes its whole street](todo/2026-09-25-M199/)
- [M205 — The man shouting charges the meter again](todo/2026-09-25-M205/)
- [M206 — The title screen after a game over is the right way up](todo/2026-09-25-M206/)
- [M207 — A warning comes shortly before its danger](todo/2026-09-25-M207/)
- [M210 — The brief between two days is the coming day's](todo/2026-09-26-M210/)
- [M211 — The pause screen's held restart starts a new game](todo/2026-09-26-M211/)
- [M212 — The held restart fills and restarts on a phone, first time](todo/2026-09-26-M212/)
- [M213 — The chalk mark's robber stands at the far end of its alley](todo/2026-09-26-M213/)
- [M215 — The power station's chimneys stand in front of her](todo/2026-09-26-M215/)
- [M216 — The small courtyard building's roofs go around the corner](todo/2026-09-26-M216/)
- [M217 — Nerves are stars on every screen](todo/2026-09-26-M217/)
- [M218 — The burning building burns](todo/2026-09-26-M218/)
- [M219 — On a pedestrian street a blocked walker turns round](todo/2026-09-26-M219/)
- [M220 — "The same face is on most of them." starts its own line](todo/2026-09-26-M220/)
- [M221 — A failed day leaves no chalk mark behind](todo/2026-09-26-M221/)
- [M222 — The red arrow for the van ends on the van](todo/2026-09-26-M222/)
- [M159 — A slow frame names the frame that was slow](todo/2026-09-19-M159/)
- [M129 — A path through the city never has to cost · one route in five still breaks](todo/2026-09-25-M129/)
- [M137 — The contact is whoever she hands the note to, and the trap comes to her](todo/2026-09-13-M137/)
- [M125 — The test suite is slow again](todo/2026-09-13-M125/)
- [M56 — The resistance is noticed](todo/2026-09-01-M56/)
- [M99 — The corridor's density after the sealing](todo/2026-09-09-M99/)
- [M100 — Small, real, and nobody's](todo/2026-09-09-M100/)
