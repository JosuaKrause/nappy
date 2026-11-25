priority: bug

# calm-hare — The event director ignores the escape's settings · filed 2026-11-24

The player, after being told where the escape's dog walker comes from (inbox #1737 in minty-hare):
"we have very precise rules around how spawning should work and this doesn't sound at all like how
we defined it. this sounds like what is implemented is pretty far off from what we wanted". Their
earlier words on the escape: "there should be no dog walkers in escape it's not a calm night where
people walk their dogs" (inbox #1733 in spry-ferret); "the escape is just like a normal day with
some special settings", "there really should be no separate code for escape" and "all should be
implemented through the regular game engine's means" (inbox #785 in minty-lemur). And of the
escape's army trucks: "no, trucks get placed ahead of her if they're on route" (inbox #1740 in
minty-hare).

**The band `bug` is the one a refactor step's own defect takes** (inbox #1519 in breezy-magpie): the
refactor made the escape a day spec (minty-quail), and the escape's spec does not reach the event
director. It is fixed before minty-quail's closing pull request, so it has no `after:` line.

**Read as:** the escape follows the rules of a day with special settings, and one of the settings
is what the event director may send her while she walks. Today the director ignores the spec.

**What an audit of main found, read from the code and not measured** (an Opus read-only audit of
main at 47e465438; the ordinary day follows the player's rules, the escape's dawn follows them too):

- `EventsAhead.start_a_given_walk()` calls `EventDirector.start_day()` with the run's calendar day
  and the walk's plans, and never with the walk's `DaySpec`. `EventDirector.start_day()` then fills
  an ordinary day's route bag from the catalogue (`_fill_the_route_bag()`), whatever the walk is.
- **Booted straight into the escape** (`--start-escape`, `?escape=1`) the run is on day 1, so
  `_rig_day_one()` rigs two dog walkers among the first three marbles of the route bag, and
  `rig_her_route()` puts three route-bag slots on the owed list. She meets two dog walkers and one
  more day-1 encounter (a cat, a cyclist, a loose dog or a dog walker) in her first three director
  turns, about 33 to 78 s of walking. That fits inbox #1733 in spry-ferret.
- **Reached from a run** the escape is day 14, and `_owe_the_sprinkled_dog()` sends the charging dog
  at her one escape in four (`CHARGING_DOG_SPRINKLE_CHANCE`, 0.25, on any day past 3).
- `EventManager.step_what_is_ahead()` skips the director only for a scene recipe, never for a walk
  planned whole, so `EventDirector.due()` hands these out in the escape.
- `tests/finale_rig.gd` checks that the escape owes no return leg on day 13 only, with one stream
  and an empty plan. No suite covers the escape city on day 1 or day 14.

**What the context of inbox #1737 in minty-hare and the item no-dog-walkers of calm-walrus said**
(main's escape sends nothing; its route bag is "never drawn from") **is wrong on the direct boot.**

**Item:** `director-follows-the-spec.md`, which also holds that the escape's trucks on her route are
sent ahead of her by the director (inbox #1740 in minty-hare). The escape's other gap against the player's words, the
empty marbles' count, is lilac-marten's (a fuller escape); the explosions are snowy-goose's.
