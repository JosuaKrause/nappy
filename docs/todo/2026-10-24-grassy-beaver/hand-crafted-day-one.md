# Day 1 is hand-crafted, with a park close by

The player: "let's hand craft", "also, let's have one park relatively close", and "that also
teaches day two to go somewhere else (player can just retry the same path again and will find the
park blocked)" (curly-moose #819); the toolbox line it answers: "we can handcraft day 1 to force a
certain order of events (still within a generated city; just manipulating spawn order)".

**Build:** day 1's events are placed in a fixed order on the way to a park close to home, inside the
generated city and inside every fairness check (checked before accepted, two cost-free routes, every
day winnable): first a noise source she can pass wide, then one with less room, then one sidewalk
fully blocked so she crosses with no cars about (the lesson (d)), then a crossing with cars, then
the yeller, then the park, as "The tutorial route" below sets out (gentle-owl #1253). One park is "relatively close" to her
door on day 1.

**Read as:** "close" is the builder's to measure (a walk a new player finishes in the first minute
is the target). Day 2 keeps the existing rule that spoils a calm area used the day before with events
while it stays walkable (`docs/EVENTS.md`, "Going to the same park on day one and day two must not be
possible"): asked whether the park must be blocked, the player, "spoiled actually teaches the
lesson" (minty-dolphin #834); `day-two.md` carries the path past it.

*Proposed, not asked for:* the four-step order (introduce safely, develop, twist, conclude), from
the research. A retry of day 1 replays the same order.

**The loud car accident moves to day 2.** Asked on the board whether the car accident (a hard seal
that emits, `docs/EVENTS.md`'s `car_accident` row, placed from day 1 and day 1's largest crying loss)
comes off day 1, the player: "yes, let's keep things light on day 1. move it to day 2"
(minty-dolphin #834). Its first day becomes 2.

**The homeless yeller comes last on day 1.** Asked whether day 2 should teach timing a moving
obstacle (lesson (e)), the player: "yeller is also a moving obstacle. -- also we can teach multiple
things in a day if we make things progressively harder. we could teach the yeller on day 1 but after
the other lessons" (minty-dolphin #834). The yeller is the pacing man who walks a beat on a
sidewalk. **Read as:** day 1's sequence ends with the yeller, after the park lesson's three steps
and before the park, so (e) is taught on day 1; a day may teach several lessons, each harder than
the one before. *Proposed, not asked for:* the yeller placed where she has to time her pass along
his beat rather than walk wide of him.

## The tutorial route

**Placed at dawn on the way to the park, ordinary placement elsewhere.** Said while placement by
construction (minty-quail) was being built: "so for the day 1 tutorial we do static placement of
obstacles at dawn to the park we want the player to go. the progression is authored to teach
lessons. the player can at any time walk a different route and placement will happen normally for
non-tutorial paths", and "let's sketch out the progression" (gentle-owl #1253). **Read as:** day 1's
lessons are a placement phase at dawn: fixed, authored events in the locations along the path to the
park she is meant to reach (the tutorial route), in an order that teaches one lesson after another.
Every location off it draws from its view's bag as on any other day (`docs/EVENTS.md`, "The three
views and the placement order"), so a player who walks another way meets ordinary placement.

**The progression.** Sketched with the orchestrator in the chat on 2026-11-08 (gentle-owl #1253):
"no cars on the first block. what lessons do we want to teach? crossing the road should first be
when the cars are still not there. then one crossing the road with cars. timing the yeller should
be one lesson, too"; then, of the lesson the orchestrator's first sketch numbered #2, a noise source
she can pass wide, "we should do that before we teach crossing"; then, of its #3, a noise source
with less room, "we can keep the original #3 between the new #2 and #3 -- I liked both
progressions". **Read as**, the order: (1) get to the park (the opening shot and the direction
bubble); (2) a noise source she can pass wide; (3) a noise source with less room; (4) crossing the
road with no cars about, where her sidewalk is blocked; (5) crossing the road with cars, where the
cars start (`car-free-start.md`); (6) timing the yeller; then the park. The crossing is taught
twice, first with no cars about. *Proposed, not asked for* (the
orchestrator's sketch, which the player's words name only by number): the market stall on the far
sidewalk as the noise passed wide, and the dog walker coming toward her on her own sidewalk as the
one with less room.

**Closed off past its first block.** Asked how many streets the walk to the close park offers and
whether day 1 guarantees them, the player, on the orchestrator's proposal of a park exactly 5
streets out, one street per lesson from (2) to (6): "okay, we can make it even more guaranteed and
seal off the tutorial route except for the first block (so other routes can be placed)", then "so
every side street after the first one on the tutorial route has blocking obstacles and no
branching", then "doesn't have to be a full hard seal -- street can be open -- just both sidewalks
need to be blocked -- no valid route goes off of the tutorial route past the first block"
(gentle-owl #1253). **Read as:** each side street off the tutorial route past its first block
carries a soft seal, both sidewalks blocked and the carriageway open, so no valid route leaves the
tutorial route past its first block; on the first block she can still turn off, and the day's other
routes start there with every guarantee they have (two cost-free routes, the day winnable). Past
its first block no shortcut skips a lesson, so the route need not be the shortest walk to its park.
*Proposed, not asked for:* the soft seals' objects are day-1 rows (a delivery van, café tables, a
market stall), since construction starts on day 2; the count of 5 streets is the orchestrator's.

**Measured** (120 seeds, day 1's street network, a street counted as one segment between junctions,
the doorstep's own segment included, as the note records it): the nearest calm area is 3 streets
from the door on 107 seeds and 4 on 13; every seed has a calm area whose shortest walk is 5 or 6
streets, 113 of 120 one at exactly 5. With the route sealed past its first block it need not be the
shortest walk, so a 5-street tutorial route to a park exists on every seed measured.
