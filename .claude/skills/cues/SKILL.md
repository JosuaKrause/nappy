---
name: cues
description: The visual danger vocabulary — what may be drawn to signal danger, why there are no rings, and the four rules that make a short vocabulary work. Load this BEFORE adding or changing any danger cue, caret, screen-edge badge, exclamation mark, HUD element, or anything in src/ui/ or Sprites.
---

# The visual vocabulary

## No circles around entities

**Standing decision for danger. Do not add a ring, and do not reach for one when something new
needs signalling.**

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
- a **thin rim tracing an entity's own silhouette while it is charging the meter right now**, a few
  pixels out and no further — see "A glow, not a field" below

**The ban on a ring round a threat is untouched.** Every reason above still holds against one: a
ring is a number and a silhouette is a threat, whatever new thing needs signalling next.

## A glow, not a field

*Asked for no rings and no drawn fields, held since the vocabulary was written · overturned on
2026-09-07 for one specific cue, because the player asked for exactly this:* "lastly, let's create
a shader ... to create a soft halo surrounding entities that are currently actively causing
excitement. this is meant as a hint to the player so they know what to walk away from and what is
causing excitement to go up."

**The reasoning above is about danger — what a thing will do to you — and it is not what this cue
answers.** A ring still communicates a falloff radius and a number is still not a threat, which is
why this is not a ring round any one entity. What it answers is a question the vocabulary never
had a cue for: *the meter is going up right now and nothing on screen says which of the six things
around her is doing it.*

**Two shapes were built and rejected on screenshots before this one.** A field-sized halo drawn at
a source's own `outer_radius` (up to 200px against a visible world of 640x360 at zoom 2) painted
most of the frame — **and no brightness curve on top of it fixed that**, which is the part worth
remembering: linear, squared and cubed mappings were each tried against the same two screenshots,
and the cube that finally killed the wash also dimmed a lone source to nothing. **The footprint was
the defect, not the curve.** A compact circle sized off `EventDef.obstructs_radius` fixed the
footprint but was still the shape of a number rather than the shape of the thing: *(2026-09-07, the
player: "halo meaning only the outline of the object not the influence radius ... it should use the
outline of the sprite. that's why it needs to be a shader. or draw the sprite in a uniform color
multiple times".)* A protest's rank of placards or a barricade's run of segments has no single
circle that is its outline.

**So the halo is traced, not sized: `EntityHalo` re-runs the entity's own body-drawing at a ring
of offsets `HALO_MARGIN` (4px) out**, flattened to one colour by
`assets/shaders/excitement_halo.gdshader` — "draw the sprite in a uniform colour multiple times,"
the hack the player named, made cheap because the shader never has to trace an outline itself, only
discard each redraw's own texture colours and keep its alpha. A `canvas_item` shader on the entity's
own sprite could not have done this alone: it can only write inside the rect it is given, tight to
the art, so a dilation would be clipped at the silhouette's own edge and read as an inward outline
rather than a glow around it. `EntityHalo` is its own class rather than a method on `EventInstance`
because `CrowdAgent` draws the same rim — see the "One cue" bullet below.

**The exception is narrow, and the narrowness is what stops it from being the next ring somebody
wants:**

- **One cue, not a general licence to draw.** Nothing else in the vocabulary gets a halo of its
  own by analogy to this one. `ExcitementHalo` is the selector — `select_sources()` decides which
  entities earn one, once a frame, over an untyped candidate array documented as a duck type on
  `ExcitementHalo` itself — and `EntityHalo` is the one place that draws. **The whole crowd is in
  that candidate set, not only a caret-worthy body.** *(2026-09-08, the player: "a busy street is
  noisy because of cars and a busy sidewalk is noisy because of people ... that will allow us to
  attribute the source exactly".)* The crowd is the noise and the noise is attributable, so
  `Crowd.agents()` sits beside `EventManager.instances()` on the same terms; `CONTRIBUTION_FLOOR`
  and `MAX_SOURCES` are what keep a busy pavement legible rather than a rule about who is caret-
  worthy. A honking car and a bumped walker clear the floor at any distance an ordinary one does,
  so "a caret implies a halo" — the narrower rule this started as — still holds by construction.
- **Traced from the thing, never sized to its reach.** A busker's rim is its own 11px body redrawn
  a ring out; a barricade's is its own run of segments. **A radius that means anything about reach
  is the ring this exception does not authorise**, and now there is no radius on a def deciding the
  size at all — only `HALO_MARGIN`, the same few pixels for every row.
- **For the cost being charged right now, not for what exists.** The set it draws is the sources
  whose `contribution_at(her position)` clears a floor — a handful at a time by construction, the
  same *"a cue that marks everything says nothing"* rule the caret already answers to. It goes to
  nothing the moment she walks out of reach, which is the *"what to walk away from"* half answering
  itself.
- **Two channels now, both reading `landed()`, on different curves.** *(2026-09-07, the player: "the
  intensity of the halo states how far away I am. the color should state how dangerous it is.")*
  That first framing put brightness on *distance* — the fraction of a source's own peak reaching
  her — and it was overturned the next session, once the same player asked for magnitude to be
  tracked at all: *(2026-09-08: "the transparency shouldn't show distance since distance actually
  doesn't matter. only the actual received amount counts ... this frees up transparency for also
  encoding magnitude. color and transparency shouldn't be the same number. transparency can be used
  to emphasize low values.")* **Colour** is `ExcitementHalo.colour_for()`, linear over `landed()` —
  points that actually reached the meter, traced back from the meter's own sum in
  `Baby._update_excitement()` rather than recomputed from `contribution_at()`, over a true
  five-second sliding sum — pale to red by forty of the hundred-point bar. *(2026-09-08, the
  player: "if a honking car caused 35 excitement to the player that's the number that informs the
  color of the halo. with 1/3 of the bar that's pretty red already".)* **Brightness** is
  `ExcitementHalo.magnitude_for()`, the same `landed()` on a curve that rises fast and saturates by
  fifteen points, so transparency does the low end's work — a point or two is faintly there rather
  than invisible — while colour is still climbing toward forty. **Both channels ease toward
  whatever they are last told, in time rather than jumping** — `EntityHalo.FADE_IN_SECONDS` /
  `FADE_OUT_SECONDS` — because *(2026-09-08, the player: "all changes should transition (hue and
  transparency) instead of immediately showing the actual value".)* Both reach the shader as one
  `instance uniform` — one shared material, one value per entity, set through
  `set_instance_shader_parameter()` rather than `modulate` (which a custom fragment function does
  not see). Each entity's ring is its own translucent layer rather than one shader's summed field,
  so two overlapping rings read brighter where they cross the ordinary way two half-transparent
  things do, not because anything sums their numbers.
- **Soft and under everything.** Each ring is a child of its own entity with `show_behind_parent`,
  so it draws behind that entity — and Y-sort, which reaches down through the whole tree, places it
  behind the crowd and the player the same way it already places that entity's own shadow. The
  entities, the crowd and the player still draw over it, never under it, so it stays a hint rather
  than a wall — and the caret, the badge and the exclamation mark keep meaning exactly what they
  meant before it existed: *worth a detour*, *something is coming*, *the contract is now about you*.
  Three sentences, one apiece, unchanged by a fourth.

If something new wants a glow of its own, that is a design conversation this one has not already
settled.

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

## A picture is an asset, never code

***"Never draw in code -- at the very least use svgs."* Anything that is a *picture* — a glyph, an
icon, a silhouette, a symbol — is authored as an image file under `assets/` and drawn as a texture,
never assembled at runtime out of `draw_circle`, `draw_rect`, `draw_line`, `draw_arc` or
`draw_colored_polygon`.**

**SVG or PNG, and which one is the asset's own question rather than this rule's.** SVG is the
default for a glyph or a flat symbol, because it stays hand-editable; a painted or generated sheet
is a PNG, and both satisfy the rule for the same reason — a file a person can open.

**An icon or a symbol on a control is not "graphics" in the sense anything else in this project
uses the word.** *(2026-09-06: "icons/symbols do *not* count as graphics".)* So no argument about
where drawing work sits in the queue is ever cover for painting a button in `_draw()`.

**The reason is the feedback loop, and it is decisive:** *(2026-09-06: "that way you can evaluate
the assets independently of running code".)* An SVG can be opened and looked at — by a person, or by
an agent reading the file — and judged on its own. A picture assembled in `_draw()` can only be
judged by booting the game, taking a screenshot and reasoning about draw order, transforms and
state. So a wrong asset is one file to look at and one file to fix, while a wrong `_draw()` is a
debugging session, and **the same headless run that proves the code correct proves nothing about
whether it looks like anything at all.**

The second reason follows from the first: an asset is **replaceable without touching code**. A
`preload()` of `assets/ui/joystick.svg` takes whatever is at that path, so a better drawing — from
anybody, at any time — is a drop-in.

**What this does not cover.** A rectangle that is a *bar* rather than a picture is layout —
`MeterBar`'s fill is not a drawing of anything. The line is whether a person would call the result
an *image*: a meter's fill, a scrim and a debug overlay are not, and a joystick, a hand and a
fence are.

**Prefer the engine's data over any drawing at all.** A `Button`'s circular fill is a
`StyleBoxFlat` with corner radii and per-state overrides, not a painted disc; its glyph is the
button's own `icon`. Reaching for `_draw()` on a `Control` is the tell that a `StyleBox`, an
`icon` or a `TextureRect` was the answer.

**`TouchControls` predates this rule and violates it** — the on-screen stick, `RUN` and pause
button are assembled from primitives in its `_draw()`. Converting them is not urgent and is not
free (`ScreenOrientation` remaps its input against fixed constants), but **nothing new joins it**,
and a change that rewrites that file anyway should take the opportunity.

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
