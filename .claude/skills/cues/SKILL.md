---
name: cues
description: The visual danger vocabulary — what may be drawn to signal danger, why there are no rings, and the rules that make a short vocabulary work. Load this BEFORE adding or changing any danger cue, caret, screen-edge badge, exclamation mark, HUD element, or anything in src/ui/ or Sprites.
---

# The visual vocabulary

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
- a **badge at the screen edge** whenever something lethal or faster than a walk is off-screen and
  closing **under its own steam**, carrying its own silhouette so it says *what* is coming rather
  than that something is
- above the **player**, a flashing exclamation mark for a soon-to-be-bad spot, doubled and red for
  danger already on her
- over the **pram**, the only cue that is not about the world — four states of the baby herself
- a **thin rim tracing an entity's own silhouette while it is charging the meter right now** — see
  "A glow, not a field" below

## A glow, not a field

*Asked for no rings and no drawn fields, held since the vocabulary was written · overturned on
2026-09-07 for one specific cue, because the player asked for exactly this:* "lastly, let's create
a shader ... to create a soft halo surrounding entities that are currently actively causing
excitement. this is meant as a hint to the player so they know what to walk away from and what is
causing excitement to go up."

**The reasoning above is about danger — what a thing will do to you — and it is not what this cue
answers.** What it answers is *the meter is going up right now and nothing on screen says which of
the things around her is doing it.* The arithmetic is the `ExcitementHalo` class docstring and the
"Entity halo" row of `docs/EVENTS.md`, "The visual vocabulary". **The exception is narrow, and the
narrowness is what stops it from being the next ring somebody wants:**

- **One cue, not a general licence to draw.** Nothing else in the vocabulary gets a halo of its own
  by analogy to this one. `ExcitementHalo.select_sources()` decides which entities earn one, once a
  frame, and `EntityHalo` is the one place that draws. **The whole crowd is in the candidate set.**
  *(2026-09-08, the player: "a busy street is noisy because of cars and a busy sidewalk is noisy
  because of people ... that will allow us to attribute the source exactly".)*
  `CONTRIBUTION_FLOOR` and `MAX_SOURCES` are what keep a busy sidewalk legible.
- **Traced from the thing, never sized to its reach.** *(2026-09-07, the player: "halo meaning only
  the outline of the object not the influence radius ... it should use the outline of the sprite.
  that's why it needs to be a shader. or draw the sprite in a uniform color multiple times".)*
  `EntityHalo` re-runs the entity's own body-drawing at a ring of offsets `HALO_MARGIN` (4px) out,
  flattened to one colour by `assets/shaders/excitement_halo.gdshader`. A `canvas_item` shader on
  the entity's own sprite cannot do it alone: it writes only inside its own rect, so a dilation is
  clipped at the silhouette's edge. **A radius that means anything about reach is the ring this
  exception does not authorise.**
- **For the cost being charged right now, not for what exists.** Colour is `colour_for()`, linear
  through `Palette.HALO_MID` over `ExcitementHalo.net_landed()`: the source's traced `landed()` less
  its share of the decay the bar took in the same window, floored at zero. A rim reads red only
  while the bar is climbing because of it *(2026-09-20: "he gets deep red but my bar doesn't move up
  much")*. Transparency is `magnitude_for()` over the same net on a curve that saturates early
  *(asked on 2026-09-07 for brightness to show distance · overturned on 2026-09-08: "the
  transparency shouldn't show distance since distance actually doesn't matter. only the actual
  received amount counts ... color and transparency shouldn't be the same number. transparency can
  be used to emphasize low values.")*. Both channels ease rather than jump *(2026-09-08: "all
  changes should transition (hue and transparency) instead of immediately showing the actual
  value")*.
- **Soft and under everything.** Each rim is a child of its own entity with `show_behind_parent`, so
  Y-sort places it behind the entity, the crowd and the player; it stays a hint rather than a wall,
  and the caret, the badge and the exclamation mark keep meaning exactly what they meant.

If something new wants a glow of its own, that is a design conversation this one has not already
settled.

## The rules that make a short vocabulary work

`docs/EVENTS.md`, "The visual vocabulary", states them in full and numbers them; these are the parts
that bite when you are writing the code.

### The entity carries most of it, so one picture per row

**No two rows share a look, no two looks share a silhouette.** `EventInstance.icon_for()` is the
single table, and it is also what the badge draws. `tests/test_events.gd` holds both halves.

**A *category* in an enum is a list waiting to happen.** Rows collapse into it until several are
one drawing, and a player can only report *"the robber"* — so two rows drawn as the same man are one
row as far as any feedback is concerned. The crowd is the deliberate opposite; see the
**crowd-traffic** skill, "The crowd is one picture on purpose".

### A cue that marks everything says nothing

**And a cue that marks the wrong things says something false.** *(2026-09-08, the player: "carets
shouldn't be chosen by source value but by expected impact value".)* What decides the mark is what
the thing is **projected** to net her, not a row's declared cost: `EventInstance` and `CrowdAgent`
each answer `expected_impact_at()` and `will_be_lethal()`. `tests/test_danger.gd` holds the
scenarios: a cat dashing at her is unmarked, a cyclist or a car whose line reaches her is red and one
passing wide is not, and a crowd at ordinary arterial density around a standing player marks
nobody.

- **The projection lives on the entity, not on a second table.** Both answer over the same
  `contribution_at()` and `is_lethal_at()` every other caller uses, so there is no second formula
  for what a thing costs to disagree with the first.
- **A colour is the wrong channel for a phase.** `EVENT_STREAM_RADIUS` is 900px and a telegraph
  lasts a few seconds, so an "amber means telegraphing" rule would only ever be seen on the rows
  sited in front of her and would read as *near*. **The flash carries the phase.**
- **Cache the projection once a frame.** `wants_a_mark()`, `mark_colour()` and the drawing all ask
  in the same frame; `EventInstance._caret_strength()` and `CrowdAgent._caret_strength()` compute
  it once, keyed on the entity's own clock.

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

**The amber caret is the one exception, and it is the player's own overturn.** *(Asked on
2026-09-08 for the source's own velocity with her position fixed, "so nothing about her own
walking can raise or lower it" · overturned on 2026-09-20: "caret communicates anticipated net
gain. basically if I keep doing what I'm doing I very likely get that amount in net gain (so the
halo will match roughly the caret if that happens)".)* `expected_impact_at()` moves her too, at
her own current velocity, and nets what she would gain against what her own current decay gives
back over the horizon (`Baby.decay_rate()`, `Baby.current_sensitivity()`), floored at zero — the
forward half of `net_landed()`'s sentence. It is charged against one source at a time rather than
shared across every source near her; that reads slightly pessimistic when two sources are worth a
mark at once, and is open to a real multi-source pass if it reads so in play.

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

## A picture is an asset, never code

***"Never draw in code -- at the very least use svgs."* Anything that is a *picture* — a glyph, an
icon, a silhouette, a symbol — is authored as an image file under `art/` and drawn as a texture,
never assembled at runtime out of `draw_circle`, `draw_rect`, `draw_line`, `draw_arc` or
`draw_colored_polygon`.** The **godot** skill carries the short version for every `_draw()`; this
is the rule in full.

**SVG or PNG, and which one is the asset's own question rather than this rule's.** SVG is the
default for a glyph or a flat symbol, because it stays hand-editable; a painted or generated sheet
is a PNG, and both satisfy the rule for the same reason — a file a person can open.

**An icon or a symbol on a control is not "graphics" in the sense anything else in this project
uses the word.** *(2026-09-06: "icons/symbols do *not* count as graphics".)* So no argument about
where drawing work sits in the queue is ever cover for painting a button in `_draw()`.

**The reason is the feedback loop, and it is decisive:** *(2026-09-06: "that way you can evaluate
the assets independently of running code".)* An SVG can be opened and looked at — by a person, or by
an agent reading the file — and judged on its own. A picture assembled in `_draw()` can only be
judged by booting the game and taking a screenshot, and **the same headless run that proves the code
correct proves nothing about whether it looks like anything at all.** And an asset is **replaceable
without touching code**: a consumer holds the region name `ui/joystick`, which is whatever
`art/ui/joystick.svg` was baked from, so a better drawing is a drop-in.

**What this does not cover.** A shape that is *layout* rather than a picture — `MeterBar`'s fill, a
scrim, a debug overlay, a pressed button's fill, a knob whose position is live state. The line is
whether a person would call the result an *image*: a joystick, a hand and a fence are.

**Prefer the engine's data over any drawing at all.** A `Button`'s circular fill is a
`StyleBoxFlat` with corner radii and per-state overrides, not a painted disc; its glyph is the
button's own `icon`. Reaching for `_draw()` on a `Control` is the tell that a `StyleBox`, an
`icon` or a `TextureRect` was the answer.

## Drawing through `Sprites`

The engine traps — a negative `Rect2`, `draw_set_transform` replacing rather than composing, Y-sort,
retained `_draw()` — are the **godot** skill, "Physics and drawing". Two things are specific to the
cues' own drawing:

**A caller that sets a canvas transform around a mirrored sprite publishes it.**
`Sprites.draw_standing()` is the only mirrored draw path in the game, and it can only set an
absolute matrix. So a caller pairs its own `draw_set_transform*` with
`Sprites.set_base_transform()`, and clears it back to `Transform2D.IDENTITY` when the pass ends;
`Sprites.mirrored_transform()` composes the mirror under it. `EntityHalo._on_draw()` and
`EventInstance._draw()` are the two callers. A caller that forgets draws every mirrored halo offset
on top of the body, with no rim.

**A redraw gate is a promise about everything the drawing reads.** `EventInstance` and
`CrowdAgent` skip the rebuild while their picture is unchanged, so the key each compares has to
name every time-varying quantity its `_draw()` touches, **not the ones that look like the
picture**. A term missing from the key is a frozen picture rather than a crash, and it shows only on
the bodies that reach the missing term — a car's registration and shadow read its **continuous**
heading while its view, mirror and gait are quantised. A traced rim makes such a freeze visible,
since `EntityHalo` re-draws the body every frame: the halo stands where the body belongs and the
body does not. Sweep the continuous quantity in a test and assert the key moved with it.

**Headless runs never call `_draw()`** — see the **verify** skill, "What each one cannot see".
