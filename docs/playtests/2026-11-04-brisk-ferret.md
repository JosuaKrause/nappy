# Playtest brisk-ferret — Drawn art tests: placement by the rng in isolation, a mock drawer for the holder

2026-11-04.

## #1018

1. **Context** (the assistant's):

   Answered on the Nappy board, question drawn-art-tests (2026-11-04): "how should the tests check what the game draws, when no game code reads that drawing back?" It blocked the roof art test files (scenery animation, roof entities, recipe roofs, residency, blackout, city decay) and the event picture rectangles (the catalogue's caps, the fire's flames), about 250 private-read lines in minty-quail's tests-public-seams item. The options were (a) a drawer handed in: buildings' roofs and event pictures draw through a drawer object they are given, the game hands in the real one and a test one that records what was drawn where; (b) leave the reads private on record; (c) compare real pixels on a graphics device. The orchestrator's pick was (a), piloted on the roof art. The player's answer:

2. **The note.**

   > what are we testing here? the placement of the elements is defined by the rng which can be tested in isolation. the drawing happens through general drawing code which is also tested in isolation elsewhere. if you're just testing the holder for it the inject a mock drawer that confirms that all elements are properly drawn

3. **Read as:** (the assistant's interpretation, not the player's words)

   Three things tested apart: where the elements go, which the random draws decide, is tested on its own as a function of the seed; the drawing code is general and already tested elsewhere; the thing that holds the elements (a building's roof, an event's picture) is tested with a mock drawer injected into it that confirms every element is drawn. That is option (a), with the placement read off the random draws rather than off what is drawn.

4. **Context** (the assistant's):

   Said in the chat right after the orchestrator settled the board question drawn-art-tests with the reading: placement tested on its own through the random draws, the general drawing code not retested, and the holder tested with an injected mock drawer.

5. **The player's words.**

   > take the answer as a more general statement on how to design unit tests: the core is to break down the problem into individual components that are isolated. don't write tests for components that are already tested. use dependency injection to confirm correctness. if you are reading a private member or creating an escape hatch you're either trying to test too much at once, are not using dependency injection as intended, or are trying to test internals in a setting where external functionality matters

6. **Read as:** (the assistant's interpretation, not the player's words)

   A testing rule for the whole project, not only drawn art: split the problem into isolated components and test each on its own; never retest a component tested elsewhere; check a component's correctness by injecting its dependencies (fakes or mocks handed in through the paths the game uses); and treat a private read or an escape hatch in a test as a sign of one of three mistakes: testing too much at once, not injecting as intended, or testing internals where the outside behaviour is what matters.

7. **Context** (the assistant's):

   Said right after the general testing statement above, about how strictly it applies.

8. **The player's words.**

   > this is not a hard rule but rather a guidance

9. **Context** (the assistant's):

   Said right after calling the testing statement guidance rather than a hard rule; it is about the three reasons the statement gives for a test reading a private member or creating an escape hatch.

10. **The player's words.**

    > and hypotheticals here are also not exhaustive. there could be other reasons to end up in this situation that I don't mention

## #1024

1. **Context** (the assistant's):

   Asked how the filing of inbox #1018 would band its testing-guidance entry (plaid-moose, the verify skill's unit-test guidance), the orchestrator said it was proposed at the now band. The player's answer:

2. **The note.**

   > proposed at the now band, -- let's do immediate instead

3. **Read as:** (the assistant's interpretation, not the player's words)

   There is no band called immediate; read as: keep the entry at now with upnext: true so it prints first, and start the verify skill edit right away rather than in queue order.

4. **Context** (the assistant's):

   Said right after, while the orchestrator was reading "immediate" as no band of its own. Above now there are the band bug, filed only when the player names it, and the up-next marker (upnext: true), which the player once described as "immediately after the current items are done" (mossy-ferret).

5. **The player's words.**

   > there are tiers higher than now!

6. **Read as:** (the assistant's interpretation, not the player's words)

   "immediate" is the up-next marker: the entry keeps band now, carries upnext: true, and prints first, ahead of bug.

## #1025

1. **Context** (the assistant's):

   Said after the orchestrator read the player's "let's do immediate instead" (inbox #1024, about the band of the testing-guidance entry plaid-moose) as the up-next marker, upnext: true, rather than as a band of its own or as bug.

2. **The note.**

   > make sure immediate is understood as up-next

3. **Read as:** (the assistant's interpretation, not the player's words)

   From now on the player's word "immediate" for an entry means the up-next marker (upnext: true beside its band), in the queue's docs and in the inbox skill, so no later session reads it as a band.
