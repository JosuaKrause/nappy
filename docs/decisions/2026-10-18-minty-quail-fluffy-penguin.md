# minty-quail — An officer let out of a car is handed the whole word on where she is · 2026-11-17

**The ask.** The same words as the record minty-quail-lilac-ferret: "whatever is the *correct*
implementation. if that is b then let's do that" (inbox #1278 in olive-ferret), **read as** (the
orchestrator's, open to the player's correction) covering the three answers found in building
`WhereSheIs`. This record is the second of the three.

## What was built

- **`WhereSheIs.hear_so_far()`** makes a live event's handle answer the word told so far, ahead of
  the word after it (`heard_from_now()` makes a handle that answers nowhere until that word).
- **`EventInstance.hear_the_word_so_far()`** replaces `EventInstance.see_her_at()`, whose only
  caller was `EventsAhead.let_the_officers_out()`. The man a stopped vehicle lets out used to be
  told her position by hand (`WhereSheIs.see_her_at()`) and none of the five other facts: her
  pram's place, the camera's view, whether she runs, whether the baby is awake, whether a door's
  hold has her. He now hears the tick's whole word as he is let out. `WhereSheIs.see_her_at()`
  stays: the halo's word and a pursuer set on her from outside use it.
- **A new suite, `tests/test_where_she_is.gd`**, holds the handle's timing on plain values: a
  handle knows nothing until the word after the one told when it was made; one that hears the word
  so far answers all six facts at once and follows the words after; the point an event sees itself
  reaches no other handle. At the branch's base (without `hear_so_far()`) the suite does not load.

## What changes in play and in the run log

The officer's first moments are the window between his being let out, at the end of the tick, and
his first step, on the next tick after that tick's word (`EventManager._step_them()` steps a copy
of the instances, so what is made after it takes its first step the tick after). The next word
already reaches him before that step, so **nothing he does differs in play**: his reads between the
two are her position (the same point the word holds, since nothing moves her between the word and
the let-out in a tick) and the drawing. The other five facts matter to an officer only in his step
(whether she runs, whether a door holds her), which always hears the new word. The run log does
not change: the let-out entry (`ahead`, "a policeman gets out") is written from the vehicle's side
and carries none of the facts. No picture was taken: nothing is drawn differently.

So the answer was slightly wrong in its structure (one fact told by hand, five missing, two ways
of being told where she is) and not in anything she or the log can show; it is made correct as the
player's words ask, and no behavioural test can fail at main, since no reading of the five facts
happens in the window. The suite above is the test, and it fails to load at main.

## Rejected

A test that moves her between the word and the let-out to tell the live position from the word
reaches a state the game cannot reach (writing-tests: a test whose setup the game cannot reach
holds nothing), so none was written.
