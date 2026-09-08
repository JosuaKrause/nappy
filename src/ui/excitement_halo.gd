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
## Pulled out as a static function so a test can hold the selection, the floor and the drop order
## without a scene, a shader or a viewport — the same reason `DangerEdge.announces()` is static.
static func select_sources(instances: Array[EventInstance], at: Vector2) -> Array[EventInstance]:
	var ranked: Array = []
	for instance in instances:
		if instance.def.city_wide:
			continue
		var contribution := instance.contribution_at(at)
		if contribution > CONTRIBUTION_FLOOR:
			ranked.append([contribution, instance])
	# Strongest first, so a cap keeps the sources that matter most to the sum and drops the ones
	# that would have changed it least.
	ranked.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var picked: Array[EventInstance] = []
	for i in mini(ranked.size(), MAX_SOURCES):
		picked.append(ranked[i][1])
	return picked

# ------------------------------------------------------------------ brightness ---
# Size is each entity's own outline now (`EventInstance._draw_halo()`), decided over there, so the
# only question left here is *how much*: `EventInstance.contribution_at(her position)`, over a
# saturation point, clamped and capped — the same arithmetic the field-sized version's own shader
# used to do, moved here because the shader that is left has no uniform of its own to hold it (see
# `assets/shaders/excitement_halo.gdshader`).

## Excitement/s at which a source's own halo reads at its brightest. Shared with
## `Tuning.MARK_WORTH_A_DETOUR` (25/s) — the same line the caret already draws between
## "ignorable" and "worth a detour" — so the halo and the caret agree on what counts as loud.
const SATURATES_AT := 25.0

## The most opaque any halo may ever draw, at a saturated source's own peak, so even a saturated
## source is a glow rather than a solid ring — see docs/EVENTS.md, "Soft, and under everything."
const MAX_ALPHA := 0.75

var _events: EventManager
var _player: Node2D

func setup(events: EventManager, player: Node2D) -> void:
	_events = events
	_player = player

## Every frame: accumulate what actually landed on every live instance, pick the sources, tell
## each one how bright its own ring reads, and tell everything else zero.
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
			var ratio := clampf(instance.contribution_at(here) / SATURATES_AT, 0.0, 1.0)
			instance.set_halo_strength(ratio * MAX_ALPHA)
		else:
			instance.set_halo_strength(0.0)
