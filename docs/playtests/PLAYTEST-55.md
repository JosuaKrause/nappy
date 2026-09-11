# Playtest 55 — 2026-09-10

A desktop debug run on `main` at the M61 field merge, started with `--day 7` to see the regions
and their checkpoints for the first time, on seed 3045005721. The run folder is copied under
`docs/evidence/` when the session ends. The first picture is `006s-attempt2-asked.png` from that
run: a roadblock band across the street south of a checkpoint hut and a boom gate, the robber's
silhouette on a roof, and a chalk mark on the carriageway behind the band.

## Barriers in front of a checkpoint

> the barriers are oddly placed. why would they be in front of a checkpoint? a path would create a
> checkpoint but the barrier suggests that the road is blocked and in fact there is no way to
> actually get to the checkpoint here.

> but the checkpoint suggests that there was a path planned through so there shouldn't be a
> barrier

> this shouldn't happen by construction

The bands are the `roadblock` row, which is placed on any road or crossing tile from day 7 and
knows nothing about the region wall's doors. Filed under M100's blocked-street defect, whose fix —
placement keyed on the segment — is the same fix, and the player's principle is the rule: a door is
where the day's route passes, so its ground is never among the candidate tiles a blocking row can
be offered, refused where the scheduler already refuses closed tiles rather than checked or
repaired afterwards.

## The robber on the roof, and the mark out of reach

> also the robber is inside the roof as usual and there is no way to even reach the chalk mark.

A re-report of M100's robber defect (playtests 50 and this one); the mark is behind the same
band, so the two findings share the first fix.

## The barrier does not read as one thing

> the barrier itself also doesn't read as a continuous element. is it using the texture of the
> other orientation and concatenating that one?

It repeats one picture — `checkpoint_block.svg`, a 22×30 concrete block with a hazard panel —
along the band, with no end cap and no orientation sibling, so a band is a row of identical
blocks. Filed under M100.

## Cars through barriers and checkpoints

> also cars go through the barriers and checkpoints

A re-report of playtest 52's finding, widened: not only the seals but the region walls, their
doors with the checkpoints on them, and the roadblock bands are driven through. Added to M110,
the crowd goes round a seal, which now covers every body that holds a street. Asked which of two
answers a door should get — shut to cars, or cars let through — the player chose the fuller one
and gave its choreography:

> at checkpoints cars should slow down halt then the bar should lift then the car drives through
> then it closes again

Asked whether a bar raised for a car also lets her through without a hold:

> attempting to do that should just start a regular checkpoint inspection

## An alley at the home, and the robber who spawns with it

> one bug that will automatically resolve once we pick the no alley at home up. right now if there
> spawns an alley at the home (which shouldn't happen) the robber spawns too leading to a spawn
> kill every time.

> there was a bug report a while back -- where did it go -- how can the no alley item not exist?

It went into the archive as closed. Playtest 11, finding 1 — *"events/hazards should not spawn on
the home block"* — is recorded in `DECISIONS.md` as **Nothing is placed on the home block**, but
what was built is `EventScheduler._the_street_she_starts_on()`: the one street segment outside the
front door is never offered to the catalogue. An alley carved through the home block is a
different segment, so it keeps `alley_robbery`, and `ResistanceDirector._maybe_set_a_trap()`
never asked either. The finding was narrowed from *block* to *street* without anybody saying so,
which is the silent overturn the feedback rule exists to catch. Reopened under M100 from the old
finding, in two parts: no alley is carved into the home block at all (today the notch is only
slid sideways off one, `docs/CITY.md`, "Place home"), and the placement exemption covers the whole
block's ground — every segment bordering it and anything inside it — for the scheduler and the
resistance trap alike.

## The car's dead zone trails the car

> from the debug view I can tell the dead zone of a car is trailing the car instead of leading the
> car?

Confirmed in the code: a car's picture is drawn standing, bottom-centre at the node's position,
while its strike box and its shape are centred on that position — so on a north–south street the
lethal box sits half a car behind the picture going north and half a car ahead going south. Filed
under M100's defects.

## The field when a car stops

> also while the car moves the field gets narrower and oval -- this is good but when the car stops
> it becomes round and bigger? this is counter intuitive. the stretching should retain the area so
> an unstretched car field should be the same width with shorter height

This overturns the orchestrator's decision in M61's field record — that the catalogued outer
radius is the moving field's *forward* reach, so the field only shrinks behind and abeam — in
favour of the player's: the resting disc is the reference and the moving field stretches out of
it. Filed as M114, the moving field grows forward. "Retain the area" and "the same width" ask for
slightly different ellipses; asked which, the player chose the width:

> if anything the moving size should be bigger than the rest size since moving causes more
> excitement.

## The building, sketched

Four hand-drawn sketches for M112, the escape scene, walkable, supplied as phone photos and
ingested through `tools/reference.sh` as `docs/reference/escape-floor-hallway-sketch-01.jpg`,
`escape-stairwell-sketch-01.jpg`, `escape-lobby-sketch-01.jpg` and `escape-basement-sketch-01.jpg`:

> references for the escape sequence in the building: [the hallway] layout of each floor. notches
> at the bottom left are locked apartment doors and the open two ones on the right are the
> staircase doors that are open and can be used to transition to the staircase map [the stairwell]
> staircase map one staircase one each side. each floor has two doors that can be entered which
> lead to the same hallway layout as above. bottom doors lead to lobby [the lobby] left and right
> notches at the bottom are the doors to the stairway notch in the middle leads to basement. [the
> basement] basement starts at the bottom (horizontal lines indicate a small stair leading down)
> top is the exit door

This replaces the layout the M112 entry was first written with — a stairwell room at each end of
every hallway, each floor its own map — with the sketched one: hallway maps that open through
their stair doors onto **one** stairwell map, a double staircase whose flights descend left and
right from each floor's landing, with a lobby below it and a winding basement corridor below that.
The entry is rewritten; the stairs-as-walkable-tiles principle is unchanged.

Asked whether the hallway's two open notches really both sit at the right end, the player
confirmed it and reopened the shape of the stairs:

> they do both sit at the right end but now I'm thinking we could have one stairway map only show
> one stairway (instead of both in the same map) and have their doors at the opposing ends. that
> way having a fire on the stairs forces you to enter a floor hallway and walk to the other end.
> on the other hand where would we put the elevator then? and how would the staircase connect to
> the lobby? the lobby would need to be as wide as the hallway

The orchestrator's assessment — two stairwells give the fire its route decision, the lift stays in
the hallway's north wall where the sketch has it, and the lobby sketch's three notches already
read as left stairwell, right stairwell and basement — was accepted:

> okay, fine

So the building is **two stairwell maps**, each a plain switchback with one door per landing on
the hallway side, at opposite ends of every hallway and of the lobby; the sketched double
staircase is not built.

And how a flight is walked:

> holding right or left on the switchback stairs moves the player diagonally

This settles what the M112 entry had left as an open refinement: she does move vertically on a
flight. A flight is a diagonal run of tiles, and on it a sideways press is redirected along the
slope, so she visibly descends or climbs.

## The inspection

> the checkpoint itself, 2s should be enough -- both the guard and the player should disappear
> during the inspection, the camera should center on the hut (use a smooth ease in out for non
> player caused camera movement if possible) after the inspection the player and the guard should
> reappear

Filed as M113, the inspection reads as one. The hold today is `Tuning.CHECKPOINT_DETAIN_SECONDS`
at 6 seconds, and nothing else happens while she is held.
