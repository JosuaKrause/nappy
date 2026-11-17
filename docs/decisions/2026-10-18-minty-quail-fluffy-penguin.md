# minty-quail — Every event made after the tick's word hears the word so far, and the officer let out of a car with it · 2026-11-17

**The ask.** The same words as the record minty-quail-lilac-ferret: "whatever is the *correct*
implementation. if that is b then let's do that" (inbox #1278 in olive-ferret), with the queue item's
`Read as:` making each queued answer correct in a pull request of its own. This record is the
second of the three, the queued bullet that names the officer let out of a car.

**Read as** (the orchestrator's, open to the player's correction): the same words cover the other
events made after the tick's word, which have the same one-tick window with no word. The man a
stopped vehicle lets out was the queued case; a successor an event sets off inside its own step
and a door's guard (`CheckpointController`) are the two more the review of this pull request found.
The plainer alternative, handing the officer alone the whole word, was built first and replaced: it
chose the timing in two places under two names.

## What was built

- **One rule in one place.** `WhereSheIs.handle_for_an_event()` makes a live event's handle, and the
  handle answers the word told so far, all six facts (where she stands, her pram's place, the
  camera's view, whether she runs, whether the baby is awake, whether a door's hold has her), and
  every word after it; nowhere until the first word is told. `EventInstance.setup()` takes it for
  every row. The earlier handle that answered nowhere until the word after its creation, the car's
  second one and the officer's mutator are gone, with `EventInstance.see_her_at()`, whose only
  caller was the officer's let-out. `WhereSheIs.see_her_at()` stays: the halo's word and a pursuer
  set on her from outside use it.
- **The car-only keying of the first record is redundant** and replaced: a car hears the word so
  far because every event does.
- **The word is forgotten as a walk begins.** The world's `WhereSheIs` lives for the whole boot,
  and `EventManager._take()` streams events in before a walk's first word, so with the one rule
  day 2's events heard day 1's last word (her last position, whether she ran, a door's hold, the
  camera's view) until the first tick. `WhereSheIs.forget()` resets the word in place, so every
  handle answers nowhere, and `EventManager.clear()` calls it; every walk's start (a day, an
  escape section, a scene recipe) goes through `_begin()`, so through `clear()`, before `_take()`.
- **Tests.** `tests/test_where_she_is.gd` holds the handle and `forget()` on plain values, and the
  one combined check of `EventInstance.setup()`'s handle: "a man made after the tick's word has her
  in sight before the next word", which fails at #1494's head (it gave only a car the word so far).
  `tests/test_event_manager.gd`, "a walk begun forgets the last walk's word for every handle",
  fails without the `forget()` call.

## What changes in play and in the run log

The answer was wrong in structure: one fact told by hand, five missing, and the timing chosen per
case. Nothing she can see is expected to change. An event made after the tick's word takes its
first step the tick after, and that step already hears the next word; what it reads in between is
her position (the same point in the word as in the old hand-told one, since nothing moves her
between the word and a let-out within a tick) and its drawing. The five other facts are read, for
an officer, only in his step (whether she runs, whether a door holds her). The run log does not
change: the let-out entry is written from the vehicle's side. No picture: nothing is drawn
differently.

## Measured

`tests/probes/director_placement_fingerprint.gd` (it covers `let_the_officers_out()`) printed
identical `DP ` lines at this branch's head and at main: 2359 lines each, `diff` empty.
`tests/probes/olive_badger_route_mix.gd` at the head before `forget()` was added: mismatch mean 22.1%,
worst day 41%; it was not run at main.

## Rejected

A test that moves her between the word and the let-out to tell the live position from the word
reaches a state the game cannot reach (writing-tests), so none was written.
