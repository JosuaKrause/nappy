# minty-quail — A car made mid-tick holds its body back round her from its first frame · 2026-11-17

**The ask.** Offered keeping three "slightly wrong" answers found while `WhereSheIs` was built, or
fixing each in a pull request of its own, the player answered: "whatever is the *correct*
implementation. if that is b then let's do that" (inbox #1278 in olive-ferret). **Read as** (the
queue item's, in `event-interface.md` section 7 point 6, open to the player's correction): each
queued answer is made correct, in a pull request of its own. This record is the first of the three,
the queued bullet that names the car.

## What was built

- **`WhereSheIs.heard_so_far()`** is a second handle for a live event, beside `heard_from_now()`.
  `heard_from_now()` answers nowhere until the word after the one told when the handle was made;
  `heard_so_far()` answers the word told so far and every word after it (nowhere until the first
  word is told).
- **`EventInstance.setup()` hands a car the second** (`EventDef.drives()`), every other row the
  first. A car's `_ready()` asks how far its body would be from her (`EventCarDriving.gap_to_her()`)
  and puts the body down unless she stands where it would, in which case
  `_become_solid_once_it_starts()` puts it down the first frame she does not, as the comment at
  that place promises. A car made after the tick's word was answered "nowhere" there, so its body
  went down round her, with her inside it.
- **A test fails at main and passes here**: `tests/test_police_car.gd`,
  `_test_a_car_made_where_she_stands_holds_its_body_back_from_its_first_frame`, whose first check
  ("a car made where she stands holds its body back from its first frame") failed at main.

## What changes in play and in the run log

The answer was wrong in structure: the comment in `EventInstance._ready()` promised that a car holds
its body back round her, and the handle it was given could not deliver it. **Nothing she can see is
expected to change**, since no path in play makes a car with her inside its body: streaming makes a
plan live at `Tuning.EVENT_STREAM_RADIUS` (900px), the fire engine is made just out of sight once its
badge time is over, the patrol the director sends is sited a lead ahead of her, and at dawn and in
the building world no word has been told yet, so the handle answers nowhere as before. The run log
does not change: no entry is written from this path. No picture was taken: the body is a collision
shape with no drawing of its own.

## Why the car alone, and not every event

The queued answer names the car. The other rows keep the timing their own fields had: an event knows
nothing of her until the next word. Handing every event the word told so far was weighed and not
taken in this pull request: it changes what every excitement source and behaviour reads before its
first step, which the queue does not name.

## Measured

`tests/probes/olive_badger_route_mix.gd` was run at this head only (mismatch mean 22.1%, worst day
41%) and not at main; the director's handouts it measures read nothing this change touches, so it
is not compared.
