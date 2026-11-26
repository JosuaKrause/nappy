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
lesson" (minty-dolphin #834); day 2 leaves day 1's walk to it open (the record grassy-beaver-rosy-trout).

*Proposed, not asked for:* the four-step order (introduce safely, develop, twist, conclude), from
the research. A retry of day 1 replays the same order.

**The homeless yeller comes last on day 1.** Asked whether day 2 should teach timing a moving
obstacle (lesson (e)), the player: "yeller is also a moving obstacle. -- also we can teach multiple
things in a day if we make things progressively harder. we could teach the yeller on day 1 but after
the other lessons" (minty-dolphin #834). The yeller is the pacing man who walks a beat on a
sidewalk. **Read as:** day 1's sequence ends with the yeller, after the park lesson's three steps
and before the park, so (e) is taught on day 1; a day may teach several lessons, each harder than
the one before. *Proposed, not asked for:* the yeller placed where she has to time her pass along
his beat rather than walk wide of him.

## The tutorial route

**The route itself exists; its lessons are what is open.** `TutorialRoute`
(`src/routes/tutorial_route.gd`) works out day 1's tutorial route once from the city: the
doorstep's street, then five lesson streets (six where no five-street route keeps every rule), then
the tutorial park. Day 1's tree is grown with it, and the seals close every side street and
through-alley off it past its first block, so no valid route leaves it there (gentle-owl #1253;
`docs/CITY.md`, "How the corridor is built" and "Sealing the tree"). `DayStreets.tutorial_route()`
hands it to every reader on the day whose spec walks it (`DaySpec.walks_the_tutorial()`). What this
item still asks is the lessons on it: each lesson's row stood in its place along the route at dawn,
the route's other locations past its first block left empty, and the director's handouts held on
the route before the park (the design's "the lessons on the route").

**Placed at dawn on the way to the park, ordinary placement elsewhere.** Said while placement by
construction (the design review's) was being built: "so for the day 1 tutorial we do static placement of
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
road with no cars about, where her sidewalk is blocked next to a zebra crossing; (5) crossing the
road with cars, at a zebra crossing, where the cars start (the car-free start, `docs/MECHANICS.md`); (6) timing the yeller; then the park. The crossing is taught
twice, first with no cars about. *Proposed, not asked for* (the
orchestrator's sketch, which the player's words name only by number; each list as shown is quoted
before the answer it drew, gentle-owl #1253): the market stall on the far
sidewalk as the noise passed wide, and the dog walker coming toward her on her own sidewalk as the
one with less room.
