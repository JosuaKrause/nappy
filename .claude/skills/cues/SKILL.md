---
name: cues
description: The visual danger vocabulary — what may be drawn to signal danger, why there are no rings, and the rules that make a short vocabulary work. Load this BEFORE adding or changing any danger cue, caret, screen-edge badge, exclamation mark, HUD element, or anything in src/ui/ or Sprites.
---

# The visual vocabulary

**The rules not to miss:**

- **No rings, no circles around entities.** How dangerous a thing is shows on the thing itself.
- **The vocabulary is short on purpose**: a new cue picks a row that exists, or is a design decision.
- **The halo is one narrow exception**: traced from the thing's own silhouette, for the cost it is
  charging now, never sized to its reach, and nothing else gets one by analogy.
- **One picture per row**: no two rows share a look, no two looks a silhouette.
- **A mark shows what a thing is projected to net her**, computed on its own source, never a second table.
- **Only a `hard_fail` event and a closing car raise the exclamation mark.**
- **Every caret is `Sprites.draw_caret()`**: no second hand-drawn chevron.
- **A picture is an asset, never code** (PLAYTEST-29 3): a new symbol is an image file. Three
  symbols are drawn in code today (the caret, the home arrow, the badge's pointer).
- **Audio is never the only channel**: the game plays identically with the sound off.

Three reference files beside this one are read whole before the first edit in their area:
`references/halo-and-projection.md` before touching `ExcitementHalo`, `EntityHalo` or what a caret
projects; `references/drawing-and-redraw-gates.md` before touching what `EventLook`, `CrowdAgent`
or `EntityHalo` draw or the key a redraw gate compares; `references/picture-is-an-asset.md` before
drawing anything in a `_draw()` that a person would call an image.

## No circles around entities

**Standing decision for danger. Do not add a ring, and do not reach for one when something new
needs signalling.**

> How dangerous a thing is has to be visible from looking at **the thing**.

A ring communicates a falloff radius, which is a number. A silhouette communicates a threat.

The vocabulary is in `docs/EVENTS.md`, "The visual vocabulary" — four cues, four sentences, and
one language: **caret**, *stand here and this will cost you* (amber) or *end your day* (doubled
red); **halo**, *this is costing you now, and this much*; **exclamation over the player**, *the
clock on you has started*; **badge**, *something lethal or faster than a walk is coming, and this
is what*. One number decides the caret and the halo — the points a source nets her. The red caret
and the badge are measured with her held still, because *this ends your day* and *something is
coming* are claims about the thing's own course.

- the **entity itself** carries most of it
- a **caret above the entity** for anything projected to net her that much if both keep doing what
  they are doing — amber at `Tuning.EXPECTED_IMPACT_POINTS`; doubled deep red when the source's own
  course, her position held fixed, reaches its lethal reach; flashing while it has not started yet
- a **badge at the screen edge** whenever something lethal or faster than a walk is out of sight
  (`VisibleView`) and closing **under its own steam**, carrying its own silhouette so it says *what*
  is coming rather than that something is, and, once raised, staying until the thing is in sight or
  gone — **for the things that telegraph**: a thing telegraphs
  its coming only if it goes fast, comes toward her (PLAYTEST-145 18-23), and carries a heavy
  penalty (olive-hedgehog #598), ending the day or a heavy hit. One that does not
  (`EventDef.telegraphs`) — the loose dog and the cat, the player's own — is outside the badge and
  warning-first placement rather than exempted from them, as are `alley_mouse`, `pigeon_flock` and
  `police_patrol` by the rule's numbers (`docs/EVENTS.md`, "What telegraphs")
- above the **player**, a flashing exclamation mark for a soon-to-be-bad spot, doubled and red for
  danger already on her
- over the **pram**, the only cue that is not about the world — four states of the baby herself
- a **thin rim tracing an entity's own silhouette while it is charging the meter right now** — see
  "A glow, not a field" below

## A glow, not a field

**One cue is drawn around a thing, because the player asked for exactly this**: a soft halo around
the entities actively causing excitement, a hint at what to walk away from
(M89-a-halo-says-what-is-costing-her).

**The reasoning above is about danger — what a thing will do to you — and it is not what this cue
answers.** What it answers is *the meter is going up right now and nothing on screen says which of
the things around her is doing it.* The arithmetic is the `ExcitementHalo` class docstring and the
"Entity halo" row of `docs/EVENTS.md`, "The visual vocabulary". **The exception is narrow, and the
narrowness is what stops it from being the next ring somebody wants:**

- **One cue, not a general licence to draw.** Nothing else gets a halo by analogy to this one;
  `ExcitementHalo._select_sources()` decides which entities earn one and `EntityHalo` is the one
  place that draws.
- **Traced from the thing, never sized to its reach** (M89-a-halo-says-what-is-costing-her). **A
  radius that means anything about reach is the ring this exception does not authorise.**
- **For the cost being charged right now, not for what exists.** A rim reads red only while the
  bar is climbing because of it (PLAYTEST-112 2); only the amount received counts, and colour and
  transparency are not the same number (PLAYTEST-38 3).
- **Soft and under everything**, so the caret, the badge and the exclamation mark keep meaning
  exactly what they meant.

How each of the four is built, with the whole crowd in the candidate set
(M92-the-halo-says-how-much-it-cost), is `references/halo-and-projection.md`.

If something new wants a glow of its own, that is a design conversation this one has not already
settled.

## The rules that make a short vocabulary work

`docs/EVENTS.md`, "The visual vocabulary", states them in full and numbers them; these are the parts
that bite when you are writing the code.

### The entity carries most of it, so one picture per row

**No two rows share a look, no two looks share a silhouette.** `EventPictures.icon_for()` is the
single table, and it is also what the badge draws. `tests/test_events_catalogue.gd` holds both
halves.

**A *category* in an enum is a list waiting to happen.** Rows collapse into it until several are
one drawing, and a player can only report *"the robber"* — so two rows drawn as the same man are one
row as far as any feedback is concerned. The crowd is the deliberate opposite; see the
**crowd-traffic** skill, "The crowd is one picture on purpose".

### A cue that marks everything says nothing

**And a cue that marks the wrong things says something false** (PLAYTEST-37 5). What decides the
mark is what the thing is **projected** to net her, not a row's declared cost: every source
(`ExcitementSource`, which `EventInstance` and `CrowdAgent` each compose) answers
`expected_impact_at()` and `will_be_lethal()`. `tests/test_danger.gd` holds
the scenarios: a cat dashing at her is unmarked, a cyclist or a car whose line reaches her is red
and one passing wide is not, and a crowd at ordinary arterial density around a standing player marks
nobody.

- **The projection lives on the entity's source, not on a second table.** It is written once
  (`ExcitementSource`) over the same field the present rate is (`contribution_at()`) and, for an
  event, the reach `is_lethal_at()` uses, so there is no second formula for what a thing costs to
  disagree with the first.
- **A colour is the wrong channel for a phase.** `EVENT_STREAM_RADIUS` is 900px and a telegraph
  lasts a few seconds, so an "amber means telegraphing" rule would only ever be seen on the rows
  sited in front of her and would read as *near*. **The flash carries the phase.**
- **Cache the projection once a frame.** `_wants_a_mark()`, `_mark_colour()` and the drawing all ask
  in the same frame; `ExcitementSource.caret_strength()` computes it once, keyed on the entity's
  own clock, and for an event on where she is too.

### The mark breathes

Tracking current emission — the one thing the ring did that a discrete symbol does not get for free.
Without it a pulsing event stops being something to time a pass through and becomes something that
hurts at random.

### A cue is a claim about a *moment*

**A cue is lowered by the system that can see its condition.** `Stroller.warn()` takes a source and
`stand_down()` lowers only that source's own mark, so a hold that bridges a gap in the danger — the
space between two cars in one lane — does not also bridge the danger being over.

**And measure the thing, not the gap — except where the player asked for the gap on purpose.** The
badge's closing speed is the event's own approach with the player held still, because a rate that
includes her own walking is a cue for walking; `will_be_lethal()` keeps the same shape, because
*this ends your day* has to stay true whatever she is doing right now.

**The amber caret is the one exception**: it is the net gain she very likely gets if she keeps doing
what she is doing, so it moves her too, and the halo roughly matches it when she does
(PLAYTEST-115 7). How `expected_impact_at()` nets it is `references/halo-and-projection.md`.

Nothing in `tests/test_danger.gd` can see a moment, which is why the `cue` telemetry entry exists.

## The exclamation mark is the load-bearing one

Every other cue says *a thing exists*. That one says **the fairness contract is now about you and
the clock has started**, which is the difference between information and instruction.

**Only a `hard_fail` event and a closing car raise it.** Raised for every telegraph it would mean "a
number is about to move faster" for most of the catalogue — which the meter already says, and the
player's verdict on that (PLAYTEST-05 3) was that she can just keep doing what she was doing.

Its `NOW` level is **two** conditions: within `WarningBoard.LETHAL_MARK_LEAD` of the radius that ends the day,
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
holds **no reference to the world or the event system**; it keeps the run it is handed (a
`RunState`, through `use_run()`) and the baby and the stroller, each found by a group lookup. Anything that has to *ask the world* where things are every
frame does not belong in it: `DangerEdge` is its own layer, created by `main`, for exactly that
reason.

## A picture is an asset, never code

**Anything that is a *picture* — a glyph, an icon, a silhouette, a symbol — is authored as an image
file under `art/` and drawn as a texture, never assembled at runtime out of `draw_circle`,
`draw_rect`, `draw_line`, `draw_arc` or `draw_colored_polygon`** (PLAYTEST-29 3). The reason is the
feedback loop (woolly-finch 3): a file can be opened and judged on its own, and a picture assembled
in `_draw()` can only be judged by booting the game. Layout is not a picture: a bar's fill, a scrim,
a debug overlay, a knob whose position is live state.

**Three symbols are drawn in code today**, each a filled polygon with an outline
(`draw_colored_polygon()` and `draw_polyline()`): the caret above an entity
(`Sprites.draw_caret()`); the arrow that points the way home and, from a second instance, to the
day's resistance task (`HomeArrow._draw_chevron()`); and the pointer on the screen-edge badge
(`DangerEdge._draw_chevron()`), whose backing disc and rim are a `draw_circle()` and a
`draw_arc()`. The player's rule names none of them as an exemption (PLAYTEST-29 3). A new symbol is
an image file.

The rule in full — SVG or PNG, why an icon on a control is no exception, where the line between a
picture and layout runs, and the engine's own data before any drawing — is
`references/picture-is-an-asset.md`. The **godot** skill carries the short version for every
`_draw()`.

## Proposed, not asked for

- **Whether the three symbols drawn in code stay drawn in code or become pictures is not decided**:
  the caret above an entity (`Sprites.draw_caret()`), the arrow that points home or to the day's
  task (`HomeArrow._draw_chevron()`) and the pointer on the screen-edge badge
  (`DangerEdge._draw_chevron()`). The player's rule names no exemption (PLAYTEST-29 3). A new symbol
  is a picture.
