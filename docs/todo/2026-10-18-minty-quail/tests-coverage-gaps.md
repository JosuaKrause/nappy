# Game rules no suite holds

*Proposed by the orchestrator, from the reviews of the underscore pass, not asked for:* the rule
below was mutated in a review and no suite failed, and it was so before that pass too. It rests on
the player's ask that a test holds what the player can meet (curly-rabbit #1097), read the other way:
a rule the player meets that nothing checks.

- **Which calm ground is spoiled.** `EventScheduler._is_spoiled()` decides which calm ground the
  walkability repair keeps a route to; making it always answer "not spoiled" fails nothing, since no
  suite builds a day where the choice matters. The check builds such a day (an event spoiling one
  calm area beside a clean one) and reads which one the repaired routes reach (record
  minty-quail-snowy-panda).
  Such a day is rare: with `_is_spoiled()` mutated, eight `build_day` cases (about 2.7 s each)
  showed no difference, so the check needs a (seed, day, target) found by an offline search first
  (record minty-quail-breezy-chipmunk).
