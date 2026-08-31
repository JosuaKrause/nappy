# Playtest 16

Played on `main` at M50 — `5d2a276`, seed `374709573` (both screenshots) — with M51's seven
findings in the build. Reported mid-run, in five messages, three of them with a screenshot
attached. The wording below is the player's, verbatim.

**Eight findings, in three groups.**

**Four of them are one complaint**: the city draws a lattice it does not have, and the crowd walks
it. It goes onto a bridge with no footway, off a bulkhead into the sea, and through crossroads whose
arms are grass or a wall — and in every case it then vanishes where somebody is looking at it.

**Two are the first report anybody has ever made about the back half of the game**, and both are
`docs/TODO.md` entries that have been sitting under "Known-shaky ground" waiting for exactly this.
The robber works — *"very good and effective… the timing is good"* — and walks through walls. The
resistance is invisible: the player reached a chalk mark and could not tell that anything had
happened, which is the deliberate risk that file has named since the beginning finally being run.

**And the third group is a different kind of finding and the more uncomfortable one**: calm areas at the
edge of the map, *"which should be impossible"* — and the rule saying so is already written down,
unbuilt, in `docs/TODO.md`'s M47, along with its measurement. Together with M41's T-junction item
and M51's cul-de-sac, that is **three findings in one session that the project had recorded and not
built**, plus the same M47 entry answering M52's *"2x2 courtyard and rectangular calm zones"*
verbatim. Writing a finding down is only half of the rule; the other half is reading the file
before designing against it.

**The through-line is the edge of the world and the edges inside it.** M51 was about the city
drawing things it does not mean; this is the same sentence one scale out, and about a specific
thing: **the lattice draws a full crossroads wherever two corridors cross, whether or not the arms
of it are streets.** At the shore that produces a junction whose southern arm is the sea. Beside a
precinct or a park it produces a crossroads whose arms are paving and grass. Both are the same
missing rule — *a junction should be the junction of the streets that actually meet there* — and
both were already half-known: `docs/TODO.md`'s M41 has carried **"T-intersections everywhere else
on the edge — the lattice currently runs into the boundary and stops"** as an unbuilt item since
M41, and M51 finding 1 was the same defect on a cul-de-sac.

---

## 1. Cars and people still go off the map

> "cars and people still go off the map"

Sent with a screenshot of the **southern shore**: a full four-way intersection with zebras, its
southern arm running straight into the water, and pedestrians and a car on it walking off the
bulkhead and disappearing.

**"Still" is the important word.** M51 finding 7 fixed a car reaching the **bridge** and blinking
out, and the fix was deliberately narrow — *"outside the map is water, forest and mountainside, so
letting every agent overrun the boundary would drive cars into the sea at every corridor"* — so
overrunning was allowed for a **car on the main road going north or south** and nobody else.
Everybody else "keeps the tile of slack they had". This report is that the tile of slack is
visible, at an edge with nothing beyond it, and that it is people as well as cars.

Two things it could be and they want different fixes:

- The agent is **recycled on screen** at the boundary, which is M35's *"nothing vanishes while you
  are looking at it"* not reaching the crowd anywhere except the three holes in the border.
- The junction should not be there at all. The southern arm of that crossroads is not a street —
  it is the bulkhead — so an agent aiming down it is aiming at something the map does not have,
  which is finding 2 and M41's unbuilt T-junction item.

## 2. Intersections where there should be a pedestrian street or a T-junction

> "here are two examples of intersections in places that should be pedestrian street or t-junction"

Sent with a screenshot of an ordinary asphalt crossroads — full zebras on all arms, cars stopped at
it — where the ground to the **east** is an unbroken paved precinct and the ground to the **south**
is park. So the crossroads has arms that no vehicle can use and the paint promises a road that is
not there.

**The player names both answers rather than one**, and the difference is which thing is wrong:

- **A pedestrian street.** Where the corridor beyond is precinct, the junction is part of a
  pedestrianised stretch and should be laid as one — `CityGenerator._street_tile` already lays a
  precinct `SIDEWALK` from frontage to frontage, so what is missing is that the *junction* between
  two precinct arms is still asphalt with zebras on it.
- **A T-junction.** Where the arm beyond is not a street at all — a park, a calm zone's absorbed
  corridor, the shore — the junction has three arms and should be drawn with three.

**This is one rule with two outcomes, not two features**, and it is the same rule finding 1 needs:
*what a junction is made of is decided by the streets that actually meet at it.* Today it is
decided by the lattice, which has an entry at every crossing whether or not there is a street on
the other side of it.

## 3. People walk over the bridge, and only cars should

> "also people are walking over the bridge (and disappearing) when only cars should be able to"

**This is M51 finding 7's fix read back**, and it says the fix answered half of its own sentence.
M51 wrote the bridge, the tunnel and the road out as *"a stretch of carriageway with no pavement
beside it"* — that is the whole design, and it is why the player may walk out of the world there
and be run over rather than be stopped by a wall. `City._paint_outside_the_map` lays carriageway at
the spine's width and nothing else, and the overrun was granted to **a car on the main road going
north or south**.

So there are two things wrong and the second is the interesting one:

- A **pedestrian** is walking onto a deck that has no footway on it. The overrun permission was
  narrowed correctly and the *lane* was not: a walker's lanes still run the length of the corridor,
  and at the boundary the corridor is a bridge.
- And the walker **disappears**, which is finding 1 again — an agent recycled where somebody is
  looking at it.

Note what is *not* being asked for: the bridge is not to be made safe. The player's own design has
her able to walk onto it and be killed by the traffic. What may not happen is the **crowd**
strolling across it as though it were a street with pavements.

## 4. Calm areas at the edge of the map

> "this map shows multiple calm zones at the edge of the map which should be impossible"

Sent with one of the new telemetry maps: three of its green outlines are in the outermost block
column, two on the west edge and one on the east.

**"Should be impossible" is right and the repo already agrees with it.** `docs/TODO.md`'s M47
carries the rule, unbuilt, in the player's own earlier words: *"another way to get density is to
make a rule to not have a calm area at the edge of the map or next to the main road."* The entry
even states why it was never true — `_assign_purposes` constrains a single calm block three ways
and none of them is about the edge, and `_zone_fits` only refuses a footprint that would *absorb*
the arterial, which is about swallowing the street rather than being beside it.

**So this is the third thing in one session that the project had already written down and not
built**, after M41's T-junctions and M51's cul-de-sac. It is also the second time the *same* M47
entry has come back: M52's *"2x2 courtyard and rectangular calm zones"*, asked for earlier in this
same session, is verbatim the request sitting two lines above it — *"an inner courtyard (surrounded
by buildings) should have a footprint of 2x2 blocks (apartment complex) — this never got
implemented… also, add calm varieties that take up 2x1 non-square shapes."*

Which answers, from the record rather than from the player, two of the four questions M52 was
recorded with. That is the lesson worth more than the fix: **the answer to "what exactly did you
mean" was on disk, and asking again is the cost of a to-do that was filed and not read.**

## 5. The back of a cul-de-sac still has a pedestrian crossing on it

> "the backside of a cul-de-sac should not have a pedestrian crossing"

Sent with a screenshot of a junction whose **northern arm is built over** — the dead end's plug is
right there in the picture, a building where the street would have continued — and a full zebra
still painted across it, with a traffic light beside it.

**This is finding 2 again and it is the clearest statement of it**, because here there is no
argument about what the arm *is*: `CityMap.built_over` names those exact tiles. The junction is
drawn with four arms because the lattice has four entries at that crossing, and nothing that lays
paint asks whether the street on the other side exists. A crossing marks *where to cross to*, so a
zebra onto a wall is the city promising something it does not have — M51's own sentence, in the one
place M51 was already looking.

## 6. The run hint comes back after the tutorial has taught it

> "hold SHIFT to run randomly shows up sometimes after the running tutorial. it should only show up
> for the tutorial"

Stated as a rule rather than as a bug, and the rule is the useful half: **the hint belongs to the
lesson, not to the mechanic.** Once day 3 has taught the run, a line telling her to hold shift is
the game explaining something she has already been made to do — which is the "a cue that marks
everything says nothing" problem arriving in the HUD.

## 7. The resistance never announced itself

> "I'm not sure if I ever did the resistance. I walked on one chalk symbol once but there was no
> indication at the end of the day or any guidance what to do next. during the day brief there
> should be instructions from the chalk marks to tell me what the next task is. only the first
> encounter (the chalk mark) should come without hint (yes, no hint even at the bottom left). the
> chalk mark has to be placed dynamically alongside a route"

**The first playtest ever to reach the resistance, and it reports that reaching it is invisible.**
`docs/TODO.md` has carried this as a deliberate risk since the beginning — *"no quest log or marker
for the resistance… this is a deliberate risk: a player may finish a run never knowing the good
ending existed"* — and listed it as an open question for playtesting. This is the answer to that
question, and it is that the risk did not pay off.

Four separate instructions, and they are not the same instruction:

1. **The day brief carries the resistance's own words.** *"During the day brief there should be
   instructions from the chalk marks to tell me what the next task is."* So the between-days screen
   gains a line, in the fiction's voice, saying what the next step is.
2. **The first chalk mark is the one exception and it is absolute.** *"Only the first encounter (the
   chalk mark) should come without hint (yes, no hint even at the bottom left)."* The parenthesis is
   the player pre-empting the obvious half-measure: the HUD line that exists today does not count as
   "no hint", and it is to be gone for that first encounter.
3. **A chalk mark is placed against a route.** *"The chalk mark has to be placed dynamically
   alongside a route."* This is M50's set-piece machinery applied to the thing `docs/TODO.md`
   already names as its second caller — the item under step 2 that says `ResistanceDirector` places
   a contact rather than an event and so does not simply inherit the covering set.
4. And implicitly: **the end of a day has to say whether anything happened.** *"There was no
   indication at the end of the day."*

## 8. The robber runs through walls

> "the robber is very good and effective only thing is that he can run through walls other than
> that the timing is good"

**A verdict and a bug, and the verdict is the rarer thing.** `docs/TODO.md`'s "Known-shaky ground"
has said since M36 that *"the robber has never been met and act III has never been reached — every
number on him is a rig's, and the row is now the most mechanically complicated in the catalogue"*.
He has now been met and the timing is right, so that entry can close on everything except the walls.

The bug is precise: a pursuing `EventInstance` moves by setting its own position, and nothing in the
event system has ever collided with the city — which was harmless while every mobile row travelled a
route the scheduler had already checked, and stops being harmless the moment something steers at the
player.
