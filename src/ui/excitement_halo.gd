class_name ExcitementHalo
extends Node2D
## Which live events are actively charging the meter right now — an identification cue, not a map.
## It answers *which of the six things around her*, which the meter itself cannot: a number says
## how much, never which.
##
## **It draws nothing itself.** *(2026-09-07, the player: "it should use the outline of the sprite.
## that's why it needs to be a shader. or draw the sprite in a uniform color multiple times ...
## the halo should not extend more than a few pixels beyond the object's outline.")* A shape drawn
## here — a circle, a rect, any radius derived from `EventDef` — can only ever be a picture of a
## *number*, and the whole licence this cue has to exist is that it draws the *thing* rather than
## the thing's *reach*. So the outline is each entity's own: `EventInstance._halo` re-runs that
## entity's own `_draw_body()` at a ring of offsets a few pixels out, flattened to a silhouette by
## `assets/shaders/excitement_halo.gdshader`. What is left for this node is exactly one job every
## frame: deciding which entities that ring belongs to, and how brightly it reads.
##
## Two questions decide what is drawn: which sources count (`select_sources()`) and how strongly
## each one's own ring reads (`set_halo_strength()`, called on the instance itself, once a frame,
## for every live instance). See `docs/EVENTS.md`, "The visual vocabulary", for how this cue sits
## beside the caret, the badge and the exclamation mark rather than replacing any of them.
##
## **A source also carries `accumulate_landed(contribution: float, delta: float) -> void` and
## `landed() -> float`** — a duck-typed pair (GDScript has no interface), currently implemented
## identically on `EventInstance` and due on `CrowdAgent` as this cue's candidate set widens. They
## fold what a source has actually delivered to her into a `WINDOW`-second exponential moving sum,
## which is what will let its colour answer *how much this has cost her* rather than only its
## brightness answering *how close*.

## The time constant of the moving sum `accumulate_landed()`/`landed()` keep, in seconds.
##
## **A time constant, not a boxcar window, and the two are not the same sentence.** `landed =
## landed * exp(-delta / WINDOW) + contribution * delta` forgets continuously — there is no instant
## at which a five-second-old contribution drops out all at once — but its steady state for a
## constant rate `r` is the same `r * WINDOW` a true five-second running sum would give, so the
## number means the same thing either way. Said here because "a 5s window" is what the next reader
## assumes from the name, and it is not the shape this is.
##
## **Chosen to be looked at, not derived.** *(2026-09-07: "5s sounds good for now".)* `cat_dash` is
## a three-second interruption and `busker` is continuous, so it has to be long enough that a brief
## scare colours at all and short enough that a source she has walked away from stops promptly.
const WINDOW := 5.0

## Excitement/s a source has to reach at her own position before it earns a place in the halo.
##
## **A felt number, not a derived one.** `Busker` (9/s) is the lowest ordinary intensity in the
## catalogue and a `crouching cat` at rest still reaches `Tuning.MARK_WORTH_A_DETOUR` (25/s) at
## its centre, so 1.0/s sits comfortably under both: anything genuinely inside a field is drawn,
## and only the thin, nearly-spent tail of a falloff — where the number would round to nothing
## on the meter anyway — is left off. Checked against a screenshot, not derived from a formula:
## there is no arithmetic that says where "reaching her" starts to matter.
const CONTRIBUTION_FLOOR := 1.0

## The most sources one frame may light up. **Past the cap the weakest contributors are the
## ones left out**, in `select_sources()` below — not the furthest and not the newest — because
## dropping the smallest terms of a sum is the smallest possible error the drawn total can carry.
## An ordinary corner never approaches this: `CLAUDE.md`'s own note is that the *whole city's*
## concurrent event count stays a few dozen even on the last day, and this is a filter over what
## is above `CONTRIBUTION_FLOOR` at one point, which is a handful by construction — the same rule
## the caret already answers to: **a cue that marks everything says nothing.**
const MAX_SOURCES := 8

## Which live events earn a place in the halo, strongest contribution first, capped at
## `MAX_SOURCES`.
##
## **A cue that marks everything says nothing** (`.claude/skills/cues/SKILL.md`), so the set is
## never "every event the day planned" — it is `EventInstance.contribution_at(at)` above the
## floor, which is a handful at a time by construction and goes to zero the instant she walks out
## of every field at once.
##
## **A `city_wide` source is excluded on purpose.** `contribution_at()` answers it with the flat
## intensity from anywhere in the city — "there is nowhere in the city it does not reach" — so
## drawing an outline at its instance's own position would show a reach it does not have. `docs/
## EVENTS.md`'s vocabulary already has its answer for that source: a HUD line, "for a `city_wide`
## source, which has no position and therefore nothing to stand under."
##
## **The duck type a candidate has to answer to**, since `select_sources()` no longer takes
## `Array[EventInstance]`: `contribution_at(world_position: Vector2) -> float`, plus
## `accumulate_landed()`/`landed()` above and a `set_halo_strength(alpha: float, colour: Color)`
## to be told the result. `EventInstance` already answers all of it; `CrowdAgent` is due to as its
## own halo-drawing lands.
##
## **The one place the duck type is peeked under.** `city_wide` is an event-only concept — a crowd
## body has no def and is never asked for it — so it is read only after `source is EventInstance`
## says the object in hand actually is one.
##
## Pulled out as a static function so a test can hold the selection, the floor and the drop order
## without a scene, a shader or a viewport — the same reason `DangerEdge.announces()` is static.
static func select_sources(candidates: Array, at: Vector2) -> Array:
	var ranked: Array = []
	for source in candidates:
		if source is EventInstance and source.def.city_wide:
			continue
		var contribution: float = source.contribution_at(at)
		if contribution > CONTRIBUTION_FLOOR:
			ranked.append([contribution, source])
	# Strongest first, so a cap keeps the sources that matter most to the sum and drops the ones
	# that would have changed it least.
	ranked.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var picked: Array = []
	for i in mini(ranked.size(), MAX_SOURCES):
		picked.append(ranked[i][1])
	return picked

# ------------------------------------------------------------------ brightness ---

## Excitement/s at which a source's own halo reads at its brightest. Shared with
## `Tuning.MARK_WORTH_A_DETOUR` (25/s) — the same line the caret already draws between
## "ignorable" and "worth a detour" — so the halo and the caret agree on what counts as loud.
const SATURATES_AT := 25.0

## The most opaque any halo may ever draw, at a source standing on its own field's own peak, so
## even the brightest rim is a glow rather than a solid ring — see docs/EVENTS.md, "Soft, and
## under everything."
const MAX_ALPHA := 0.75

## How brightly a source's own rim reads: the fraction of its own peak that is actually reaching
## her, capped at `MAX_ALPHA`. **Brightness answers only "how close", never "how much"** — a
## busker at arm's length reads exactly as bright as a burning building at arm's length, and only
## `colour_for()` tells them apart. That is what *"the intensity of the halo states how far away I
## am"* (docs/PLAYTEST-36.md) asks for, and it is the opposite of what this cue did before it.
##
## `peak` is the source's own `contribution_at(its own global_position)` — no separate per-class
## notion of a centre is needed: it is `current_intensity()` for a point body, the field's own
## peak for a spread, and the middle of the overlap for a flock, which is where a flock's own body
## actually is densest.
static func alpha_for(contribution: float, peak: float) -> float:
	if peak <= 0.0:
		return 0.0
	return clampf(contribution / peak, 0.0, 1.0) * MAX_ALPHA

# -------------------------------------------------------------------- colour ---

## How red a source's own rim reads: pale for a source that has cost her almost nothing over its
## own `WINDOW`, red for one that has actually hurt. `landed` is excitement points (rate × time),
## not a rate, and it saturates at `SATURATES_AT * WINDOW` (125 — 25/s sustained for the whole
## window), the same line `Tuning.MARK_WORTH_A_DETOUR` already draws between ignorable and worth a
## detour.
##
## **This is the axis the row's own declared `intensity` was proposed for and rejected.** Put as a
## fork — a lethal `cyclist` (18/s) glowing paler than a harmless `protest` (42/s) — the answer was
## *"magnitude of how much actually landed at the player -- track it over a time window -- then
## you have the real cost"*: what a row is declared to emit is a fact about the catalogue, and what
## it has actually delivered is a fact about the encounter she just had, which is the only one this
## cue should be reporting.
static func colour_for(landed: float) -> Color:
	var t := clampf(landed / (SATURATES_AT * WINDOW), 0.0, 1.0)
	return Palette.HALO_WEAK.lerp(Palette.HALO_STRONG, t)

var _events: EventManager
var _crowd: Crowd
var _player: Node2D

## `crowd` is stored but not yet a candidate source in `_process()` below — `CrowdAgent` does not
## yet answer `set_halo_strength()`, so calling it on a picked agent would crash. Wiring it in is
## the next commit's job, once `CrowdAgent` can actually draw a rim.
func setup(events: EventManager, crowd: Crowd, player: Node2D) -> void:
	_events = events
	_crowd = crowd
	_player = player

## Every frame: accumulate what actually landed on every live instance, pick the sources, tell
## each one how bright its own ring reads and what colour it is, and tell everything else zero.
## `EventInstance.set_halo_strength()` is what actually stores it and queues that instance's own
## halo child for redraw — this node has no `_draw()` of its own left to call.
func _process(delta: float) -> void:
	if not _events or not _player:
		return
	var here := _player.global_position
	var instances := _events.instances()
	for instance in instances:
		instance.accumulate_landed(instance.contribution_at(here), delta)
	var picked := select_sources(instances, here)
	for instance in instances:
		if instance in picked:
			var peak := instance.contribution_at(instance.global_position)
			instance.set_halo_strength(alpha_for(instance.contribution_at(here), peak),
					colour_for(instance.landed()))
		else:
			instance.set_halo_strength(0.0, Palette.HALO_WEAK)
