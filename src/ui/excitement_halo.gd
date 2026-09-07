class_name ExcitementHalo
extends Node2D
## A soft glow under the world, showing the summed excitement field of whatever is actually
## charging the meter right now — the hint the meter itself cannot give, because a number says
## *how much* and never *which of the six things around her*.
##
## Two questions decide what gets drawn, and both are answered by a pure query rather than by a
## picture of every event on the day's plan: which sources count, and how bright the sum reads.
## See `select_sources()` for the first and `docs/EVENTS.md`, "The visual vocabulary", for how
## this cue sits beside the caret, the badge and the exclamation mark rather than replacing any
## of them.

## Excitement/s a source has to reach at her own position before it earns a place in the halo.
##
## **A felt number, not a derived one.** `Busker` (9/s) is the lowest ordinary intensity in the
## catalogue and a `crouching cat` at rest still reaches `Tuning.MARK_WORTH_A_DETOUR` (25/s) at
## its centre, so 1.0/s sits comfortably under both: anything genuinely inside a field is drawn,
## and only the thin, nearly-spent tail of a falloff — where the number would round to nothing
## on the meter anyway — is left off. Checked against a screenshot, not derived from a formula:
## there is no arithmetic that says where "reaching her" starts to matter.
const CONTRIBUTION_FLOOR := 1.0

## The most sources one frame may draw, matched to the shader's own fixed-size uniform arrays in
## `assets/shaders/excitement_halo.gdshader`. **Past the cap the weakest contributors are the
## ones left out**, in `select_sources()` below — not the furthest and not the newest — because
## dropping the smallest terms of a sum is the smallest possible error the drawn total can carry.
## An ordinary corner never approaches this: `CLAUDE.md`'s own note is that the *whole city's*
## concurrent event count stays a few dozen even on the last day, and this is a filter over what
## is above `CONTRIBUTION_FLOOR` at one point, which is a handful by construction.
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
## drawing a localised glow at its instance's own position would show a field it does not have.
## `docs/EVENTS.md`'s vocabulary already has its answer for that source: a HUD line, "for a
## `city_wide` source, which has no position and therefore nothing to stand under."
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
