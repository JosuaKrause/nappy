# minty-quail — A car made mid-tick holds its body back round her from its first frame · 2026-11-17

**The ask.** Offered keeping three "slightly wrong" answers found while `WhereSheIs` was built, or
fixing each in a pull request of its own, the player answered: "whatever is the *correct*
implementation. if that is b then let's do that" (inbox #1278 in olive-ferret). **Read as** (the
orchestrator's, open to the player's correction): the three found in building where she is as one
object are covered by the same words. This record is the first of the three.

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

In play: a patrol car or fire engine that appears with her standing where its body would stand no
longer has a solid body around her for its first frames; the body comes down the first frame she is
clear of it. Nothing about a car made with her elsewhere changes. In the run log nothing changes:
no entry is written from this path, so no line differs. No picture was taken: the body is a
collision shape with no drawing of its own, so no car appears differently.

## Why the car alone, and not every event

The other rows keep the timing their own fields had: an event knows nothing of her until the next
word. Nothing else reads her in its first frame in a way that is visibly wrong, so the player's
words ("every slightly wrong answer is made correct") are met by the one that is. Handing every
event the word told so far was weighed and not taken: it changes what every excitement source and
behaviour reads before its first step, for no answer found wrong.

## Measured

`tests/probes/olive_badger_route_mix.gd` is unchanged by it (the director's handouts do not read
where she is in a car's first frame).
