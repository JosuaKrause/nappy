# Game rules no suite holds

*Proposed by the orchestrator, from the reviews of the underscore pass, not asked for:* each rule
below was mutated in a review and no suite failed, and each was so before that pass too. It rests on
the player's ask that a test holds what the player can meet (curly-rabbit #1097), read the other way:
a rule the player meets that nothing checks.

- **A fixed-site mast's scar.** A loudspeaker mast on one of the city's fixed sites leaves a scar
  that silences that site the next day; making the scar not silence it fails no suite, while the
  same mutation for a queued mast is caught. The check plans two days on one city and reads the
  second day's masts (the review of the events' underscore pass, record minty-quail-snowy-panda).
- **Which calm ground is spoiled.** `EventScheduler._is_spoiled()` decides which calm ground the
  walkability repair keeps a route to; making it always answer "not spoiled" fails nothing, since no
  suite builds a day where the choice matters. The check builds such a day (an event spoiling one
  calm area beside a clean one) and reads which one the repaired routes reach (record
  minty-quail-snowy-panda).
