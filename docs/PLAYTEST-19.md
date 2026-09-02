# Playtest 19

Played on 2026-09-02, on the deployed build, day 7 of seed 422405261. The trace is
`docs/evidence/run-2026-09-02T174532-seed422405261-45552a7.log` and two screenshots came with it —
a street-level shot of a barrier at a junction, and a telemetry map of the whole city.

**The wording below is the player's, verbatim.** Everything under a *"What this side reads into
it"* heading is this side's analysis and is kept apart from it on purpose.

**Nine findings.** Two are about the drawing of a single row, four are about where things are
placed and when they appear, one is a resistance leak, one is the border again, and one is paint.
The thread running through the middle four is the same one M45 and M50 have been circling: **the
city has plenty to say about the path and nothing at all to say about leaving it.**

---

## 1. Every barrier is horizontal, and offset into whatever it lands on

> "here is an example but it applies to every barrier they're always horizontal even when they
> should be vertical. and they're all placed with an offset that makes them clip into other things
> -- the only barrier that is consistently correct is the full street closure"

Sent with a street-level screenshot: a red-and-white barrier lying across a north–south pavement at
a junction, drawn east–west, its right end overhanging the kerb into the carriageway.

**What this side reads into it.** Both halves are already written down and neither has been built.
`docs/TODO.md`'s M48 carries them: *"a spread is always drawn east–west, whatever street it is on —
nothing rotates an `EventInstance`"*, and *"a body on a pavement has to fit on the pavement"*, which
records `construction` as obstructing 34px and therefore drawing 68px wide on a 64px sidewalk from a
tile centre 16px from one edge — **an 18px overhang whichever lane it lands in**.

What is new is the player's own diagnosis of *which* case works: **the full street closure is
correct because it spans the whole street**, so neither its rotation nor its offset can be wrong.
Every other placement is a body narrower than the ground it sits on, and both defects only become
visible there. That is a sharper way to state the fix than M48 has: **a barrier's rotation is a
property of the street it is on**, and until a spread knows which way its street runs it has a
one-in-two chance of being right.

## 2. There is nothing off the path

> "there is almost never anything when leaving a path. all events are on the path (restaurant
> yeller etc are all *for* the path they force you to switch street sides) but there is *nothing*
> off the path. we need more things for indicating the path (most events we have are for on the
> path) so we need to come up with more things first then actually add them"

Sent with the telemetry map of the whole city: the day's corridor picked out in purple, event
markers clustered along it, and the ground away from it visibly empty.

**What this side reads into it.** This is **M50's placement gradient working exactly as built and
being the wrong shape**. The corridor is the cheapest ground on every day by design, and the
catalogue that fills it is a catalogue of *obstacles* — a yeller, a café, a market stall, a
reversing lorry — every one of which is a reason to cross the street rather than a reason not to go
somewhere. So the city can say *this way is expensive* and cannot say *not this way at all*.

**The instruction is explicitly two-stage and the order is the point**: *come up with more things
first, then add them*. This is a catalogue design problem, not a placement one, and M45's open item
— *"a closure that points"*, with its own trap recorded beside it, **a nudge that removes the
decision is worse than a closure that does nothing** — is the constraint any new row has to satisfy.

## 3. The charging dog has no offscreen warning

> "the charging dog doesn't have an offscreen indication it should start further away and appear
> first as offscreen indicator"

**What this side reads into it.** Two changes in one sentence: the dog is sited **further out**, and
it is **announced by the screen-edge badge before it is visible**. `DangerEdge` already draws that
badge for anything off screen worth one, so the second half may be a placement consequence of the
first rather than new code — a dog sited inside the view has no offscreen phase to be announced in.

The care needed is the day-3 lesson: the dog is the tutorial for running, and it is deliberately
*unavoidable* on that day. A dog that starts further away is a dog with more room to be walked
around, which is the thing that placement was chosen to prevent.

## 4. Cyclists and loose dogs pop in in front of her, and the path costs nothing

> "bikers / unleashed dogs all pop in in front of the player instead of starting off screen. also,
> there is no punishment for staying in the path"

**What this side reads into it.** The first half is finding 3 generalised to every director-sited
row, and it is the same defect: something that materialises inside the view has no approach, so the
warning it owes is spent before the player can see it happening.

The second half is finding 2 said from the other side, and it is the sharper statement of the two.
The corridor is meant to be a *choice*, and a choice needs a cost on both branches: if the path is
cheapest and nothing off it is dangerous, the route decision the whole game is built on has one
correct answer every day.

## 5. The first chalk mark is named in the status line

> "the first chalk mark is written in the status when it should not be"

Visible in the screenshot: `resistance ....   somewhere out there: a chalk mark` while the player
has not yet found one.

**What this side reads into it.** This is the **no-hint-for-the-first-encounter rule leaking**, and
that rule is in `CLAUDE.md` under things deliberately not done: *the **first** encounter comes with
no hint at all, because finding the difficulty dial is meant to be the player's own doing. After
that the resistance speaks.* The HUD line is fed by `resistance_contact_available`, which does not
distinguish the first mark from the rest.

## 6. The chalk mark is hard to find, and should be placed where she can see it

> "it's hard to find the chalk mark remember it should be dynamically placed on the path where the
> player can see it. if it was placed but never on screen it should count as not placed and be
> placed on the next alley the player comes close to"

**What this side reads into it.** *"Remember"* is the player pointing at an instruction that already
exists, and the second sentence is a mechanism that does not: **a mark that was never on screen has
not been placed**, so it is re-placed at the next alley she comes near. That is a placement that
follows the player rather than the day's plan, and it is a different shape from anything in
`ClosurePlanner` or `EventScheduler` today — both of which decide at dawn and stand.

It also interacts with finding 5: a mark she can actually find is what makes the silent first
encounter fair.

## 7. The robber can be placed inside a building

> "the robber can be placed inside buildings which makes him unable to move at all"

**What this side reads into it.** `alley_robbery` places on `ALLEY` tiles and pursues, and
`EventInstance._walkable_step` clamps a chase to walkable ground — so a robber who begins inside a
building is not merely oddly sited, he is **permanently stuck**, since every step he tries is
refused. The lethal radius still travels with him, which makes an invisible fatal spot in a wall.

## 8. The north edge again, and the intersections are not T-junctions

> "the north edge still has people and cars walking into the mountain and disappearing also the
> intersections are not t intersections"

**What this side reads into it.** Both halves are open items being reported again. M49 carries
*"people walk out onto the border and vanish there"* with the cause already found —
`CrowdAgent._blocked_ahead` returns `false` for a tile out of bounds, so the one wall that should
stop them reports as clear — and *"junctions are four-way where an arm dead-ends"*, which had been
**not reproduced** across three candidate locations. **The north edge is the fourth, and it is the
one.**

> "it happens on all sides"

> "here is an example of a proper closed off side of the intersection (towards the right to the
> park) and an improperly closed off side (towards the south it should be closed off but isn't)"

**Reproduced with a picture**, sent when this side had still not managed it from a rig:
`docs/evidence/run-2026-09-02T181431-seed2927659514-ffa2830-061s-asked.png` — seed 2927659514,
day 1, standing at tile (80,1). The zebras on the north–south streets run all the way to the border
and a crossing box is painted on an arm with nothing beyond it, **and the same frame has a car and
two pedestrians standing on the out-of-bounds ground above the top pavement**. Both halves of this
finding are one screenshot, which is the strongest argument that they are one cause: whatever
decides what lies beyond the last tile is answering *street* to both the painter and the crowd.

**Every side, not the north one**: the same seed at tile (5,88) is the west border with the
identical crossings painted into it (`…-045s-asked.png`).

**And one frame carries a working case beside a broken one** (`…-030s-asked.png`, tile (13,87)),
which is the most useful thing said about this finding. The arm running **east into the park** is
terminated correctly — the carriageway stops and the pavement carries on across it — while the arm
running **south**, with nothing beyond it either, is drawn as though the street continued. That
makes the question *what is different between those two arms* rather than *where is the bug*, and
M49's own wording already suggests the answer: it lists the cases an arm can dead-end into — *"a
park, a calm zone's absorbed corridor, the shore"* — so **the case that works is the one somebody
wrote down**, and the fix is to state it over anything that is not a street rather than over a list.

## 9. A main road's junction should be four dotted crossings, not zebras

> "minor issue -- for a main street intersection all four crossings should be lines instead of zebra
> crossing since all four are controlled by the traffic light"

**What this side reads into it.** The rule exists and is stated one arm at a time.
`GroundTiles._crossing_variant` draws the two dotted lines rather than a zebra for a **main road's**
crossing, and `CityGenerator._street_tile`'s docstring gives the reason: *traffic on a main road
does not give way to somebody at the kerb, it obeys the light, so the crossing is a timing problem
where an ordinary one is a gap-hunting problem. A zebra there is paint promising the wrong one of
those.*

The player's point is that the property belongs to **the junction, not the arm**: where a main road
crosses an ordinary street, all four crossings are governed by the same light, so all four are a
timing problem and the two on the side street are currently painted as a promise the traffic does
not make.
