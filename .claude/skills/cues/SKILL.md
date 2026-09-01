---
name: cues
description: The visual danger vocabulary — what may be drawn to signal danger, why there are no rings, and the four rules that make a short vocabulary work. Load this BEFORE adding or changing any danger cue, caret, screen-edge badge, exclamation mark, HUD element, or anything in src/ui/ or Sprites.
---

# The visual vocabulary

## No circles around entities

**Standing decision. Do not add one, and do not reach for a ring when something new needs
signalling.**

> How dangerous a thing is has to be visible from looking at **the thing**.

A ring communicates a falloff radius, which is a number. A silhouette communicates a threat.

The vocabulary is in `docs/EVENTS.md`, "The visual vocabulary":

- the **entity itself** carries most of it
- a **caret above the entity** for anything worth changing your route for — amber for *go round it*,
  doubled deep red for *it ends your day*, flashing while it has not started yet
- a **badge at the screen edge** whenever something lethal or faster than a walk is off-screen and
  closing **under its own steam**, carrying its own silhouette so it says *what* is coming rather
  than that something is
- above the **player**, a flashing exclamation mark for a soon-to-be-bad spot, doubled and red for
  danger already on her
- over the **pram**, the only cue that is not about the world — four states of the baby herself

**Nothing draws a field.**

## Four rules that are the whole reason it beats the rings

### 1. The entity carries most of it, so one picture per row

**No two rows share a look, no two looks share a silhouette.** `EventInstance.icon_for()` is the
single table, and there is no generic to reach for.

**A *category* in an enum is a list waiting to happen.** Five categories once drew sixteen of the
twenty-eight visible rows between them, and it cost real findings: a player can only say *"the
robber"*, so two rows that draw the same man are one milestone spent fixing the wrong one, and the
one cue whose entire content is *what* is coming was drawing a delivery van for a fire engine
because it kept a second table.

`tests/test_events.gd` holds both halves. The **crowd** is the deliberate opposite — two hundred and
forty bodies share one `person.svg`, because a crowd is what an authored event has to stand out
from.

### 2. A cue that marks everything says nothing

**And a cue that marks the wrong things says something false.** The rule is the player's own
expectation, stated as an **invariant a test can hold**:

> **If A is marked and B is not, A costs more to walk through than B.**

`EventDef.walk_through_cost()` is the order, `Tuning.MARK_WORTH_A_DETOUR` is where the line falls,
lethal is marked whatever it costs, and `tests/test_danger.gd` asserts the monotonicity over the
whole catalogue plus two bounds — the whole catalogue is never marked at once, and day 1 leaves its
cheap end alone.

Two things to carry beyond that row:

- **The cost integral lives on `EventDef`**, because the game asks the question the test was asking,
  and two copies of it is a defect waiting to happen.
- **A colour is the wrong channel for a phase.** `EVENT_STREAM_RADIUS` is 900px and no telegraph is
  longer than 4s, so an "amber means telegraphing" rule is only ever seen on the `AHEAD_OF_PLAYER`
  rows and in play it means *near*. **The flash carries the phase**, because a flash is a property
  of the mark rather than of a moment she had to be present for.

### 3. The mark breathes

Tracking current emission — the one thing the ring did that a discrete symbol does not get for free.
Without it a pulsing event stops being something to time a pass through and becomes something that
hurts at random.

### 4. A cue is a claim about a *moment*

**A cue is lowered by the system that can see its condition.** `Stroller.warn()` takes a source and
`stand_down()` lowers only that source's own mark, so a hold that bridges a gap in the danger — the
space between two cars in one lane — does not also bridge the danger being over.

**And measure the thing, not the gap.** The badge's closing speed is the event's own approach with
the player held still, because a rate that includes her 92px/s is a cue for walking.

Nothing in `tests/test_danger.gd` can see a moment, which is why the `cue` telemetry entry exists.

## The exclamation mark is the load-bearing one

Every other cue says *a thing exists*. That one says **the fairness contract is now about you and
the clock has started**, which is the difference between information and instruction.

**Only a `hard_fail` event and a closing car raise it.** Raised for every telegraph it would mean "a
number is about to move faster" for most of the catalogue — which the meter already says, and the
player's verdict on that was *"I can just keep doing what I was doing"*.

Its `NOW` level is **two** conditions: within `LETHAL_MARK_LEAD` of the radius that ends the day,
**and closing**.

Note that it uses the **relative** rate where the badge deliberately uses the thing's **own**: the
badge says *a thing exists and is coming*, so her walking must not raise one, and this mark says
*the contract is now about you*, which is a statement about the pair of them. **Two cues, two
sentences, two answers to the same-looking question — do not unify them.**

## A cue that belongs to the vocabulary does not belong to a class

The caret lives in `Sprites.draw_caret()`, not on `EventInstance` — otherwise "the entity carries
its own cue" quietly means "the *event* entity does", and the one lethal thing in the game that is
not in the catalogue, a car, has nothing at all.

If a new kind of thing needs a cue from the table, it draws the same shape from the same place. **A
second hand-drawn chevron is how a deliberately short vocabulary gets long.**

`Stroller.warn()` is additive rather than a setter, because the crowd and the events both watch the
ground she is standing on in the same frame and a setter lets whichever runs second clear what the
first just said. `stand_down(source)` is the smallest thing that is not a setter.

## Audio is never the only channel

Every cue that will eventually be audio must **also** exist visually, and the visual must be
sufficient on its own — **the game has to play identically with the sound off.** Build the visual
first and judge it alone; audio is added afterwards as redundancy.

An event whose telegraph only works "because you hear it coming" is unfinished, and the fairness
contract cannot catch it: `validate_event()` checks the geometry, not whether the player was
actually warned. See `docs/EVENTS.md`, "Showing the danger".

## Adding things

**Add a danger cue** — first read `docs/EVENTS.md`, "The visual vocabulary", and **pick a row that
already exists.** The vocabulary is deliberately short and adding to it is a design decision, not a
drawing one. Never a ring.

**Add a HUD element** — `scenes/ui/hud.tscn` plus `src/ui/hud.gd`. The HUD listens to `EventBus` and
holds **no reference to the world**. Anything that has to *ask the world* where things are every
frame does not belong in it: `DangerEdge` is its own layer, created by `main`, for exactly that
reason.

## Drawing traps

**A negative-width `Rect2` does not flip `draw_texture_rect`.** It is normalised on the way through,
so the sprite lands a full width to one side — which looks like art sliding off its own shadow, not
like a failed flip. Mirror with `draw_set_transform(at, 0, Vector2(-1, 1))` around the anchor
instead. `Sprites.draw_standing()` is the one place that does it.

**Y-sorting compares origins**, so a thing whose mass extends away from its own origin sorts wrong.
**Before reaching for a better comparison, ask whether the two things can ever legitimately be on
opposite sides of each other.** Buildings cannot — no lot tile is walkable — so they are a layer of
their own and sort against nothing.

**`_draw()` is retained.** It re-runs only on `queue_redraw()`, so an expensive one-off draw (the
10k-tile city ground) is fine, but anything animated must call `queue_redraw()` itself.

**A green `check.sh` says nothing about whether the game looks right** — headless runs never call
`_draw()`. If you touched anything visual, take a screenshot and actually look at it.
