class_name ExcitementHalo
extends Node2D
## Which live sources are actively charging the meter right now, and how much each has actually
## cost her over its own recent window, read back onto one rim per source in two channels that
## now agree rather than disagree. It answers *which of the six things around her* and *how bad
## has this one actually been*, neither of which the meter's own number can: a number says how
## much in total and never which, and never whether a row that costs the same on the page cost
## her nothing today or cost her the whole meter.
##
## **Both channels read `landed()`, on different curves, and neither reads distance any more.**
## *(2026-09-08, the player, overturning playtest 36's "the intensity of the halo states how far
## away I am": "the transparency shouldn't show distance since distance actually doesn't matter.
## only the actual received amount counts which might depend on the distance but we don't need to
## encode the distance. this frees up transparency for also encoding magnitude." And, on the same
## day, why the two curves differ: "color and transparency shouldn't be the same number.
## transparency can be used to emphasize low values.")* `colour_for()` is linear in `landed()`, so
## hue separates the high end; `magnitude_for()` rises fast and saturates early, so a point or two
## is already faintly visible and the low end is where transparency does its work. A busker at
## arm's length no longer reads as bright as a burning building at arm's length by construction —
## that read the *distance*, and distance is exactly what stopped mattering.
##
## **It draws nothing itself.** *(2026-09-07, the player: "it should use the outline of the
## sprite. that's why it needs to be a shader. or draw the sprite in a uniform color multiple
## times ... the halo should not extend more than a few pixels beyond the object's outline.")* A
## shape drawn here — a circle, a rect, any radius derived from a def — can only ever be a picture
## of a *number*, and the whole licence this cue has to exist is that it draws the *thing* rather
## than the thing's *reach*. `EntityHalo` is the one place that draws, shared by `EventInstance`
## and `CrowdAgent`, told a *target* alpha and colour through `set_halo_strength()` and eased
## toward it on its own clock — see `EntityHalo.FADE_IN_SECONDS`/`FADE_OUT_SECONDS`.
##
## **It does not accumulate anything itself.** *(2026-09-08, the player: "don't derive it from the
## source numbers but trace an increase in excitement back to its constituents".)* What has
## actually landed on her is traced from the meter's own sum: `Baby._update_excitement()` calls
## each source's own `accumulate_landed(points)` with its exact share of what reached the bar,
## sensitivity included, so `landed()` can never disagree with what the bar actually did. This
## node only selects sources and reads `landed()` back for both of a rim's channels.
##
## **The duck type.** GDScript has no interface to lean on, so it is stated here: a candidate is
## any `Node2D` that answers —
##
## - `contribution_at(world_position: Vector2) -> float` — excitement/s this source delivers at a
##   point, the query events and the crowd already share.
## - `accumulate_landed(points: float) -> void` — folds an exact points share, already computed by
##   the caller, into a `WINDOW`-second sliding sum.
## - `landed() -> float` — that sum: everything still inside the last `WINDOW` seconds.
## - `set_halo_strength(alpha: float, colour: Color) -> void` — told once a frame what to show, as
##   a *target* its own halo state eases toward rather than an immediate value; `0` for everything
##   not picked.
##
## `EventInstance` and `CrowdAgent` both satisfy this without sharing a base class.

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
## The candidate set is every live event plus the whole crowd, so unlike the days before the crowd
## joined it, an ordinary busy pavement can put far more than eight candidates inside her reach at
## once — this cap, together with `CONTRIBUTION_FLOOR`, is what keeps that legible. See
## `docs/TODO.md`, "`MAX_SOURCES` (8) is a played question", for the measurement this number is
## checked against.
const MAX_SOURCES := 8

## The width of `landed()`'s sliding sum, in seconds.
##
## **A true sum, not a decayed average.** *(2026-09-08, the player: "if a honking car caused 35
## excitement to the player that's the number that informs the color of the halo".)* A 35-point
## burst has to read as 35 for the whole window and then drop, not fade from the instant it
## happened, so each source keeps its own list of `[when, points]` entries and `landed()` is their
## sum for whatever is still within `WINDOW` — see `EventInstance.landed()`.
##
## **Chosen to be looked at, not derived.** *(2026-09-07: "5s sounds good for now".)* `cat_dash`
## is a three-second interruption and `busker` is continuous, so it has to be long enough that a
## brief scare colours at all and short enough that a source she has walked away from stops
## colouring promptly.
const WINDOW := 5.0

## Which live sources earn a place in the halo, strongest contribution first, capped at
## `MAX_SOURCES`. See the class doc for what a "source" has to answer to.
##
## **A cue that marks everything says nothing** (`.claude/skills/cues/SKILL.md`), so the set is
## never "every source that exists" — it is `contribution_at(at)` above the floor, capped at the
## eight strongest, which keeps a busy pavement legible.
##
## **A `city_wide` source is excluded on purpose.** `contribution_at()` answers it with the flat
## intensity from anywhere in the city — "there is nowhere in the city it does not reach" — so
## drawing a rim at its instance's own position would show a reach it does not have. `docs/
## EVENTS.md`'s vocabulary already has its answer for that source: a HUD line, "for a `city_wide`
## source, which has no position and therefore nothing to stand under."
##
## **The one place the duck type is peeked under.** `city_wide` is an event-only concept — a
## crowd body has no def and is never asked for it — so it is read only after `source is
## EventInstance` says the object in hand actually is one.
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

## The most opaque any halo may ever draw, once a source's `landed()` clears `LOW_EMPHASIS_POINTS`
## — see docs/EVENTS.md, "Soft, and under everything."
const MAX_ALPHA := 0.75

## Below this, `magnitude_for()` is a floor rather than a read of `landed()`. *(2026-09-08, the
## player: "transparency can be used to emphasize low values ... all changes should transition
## (hue and transparency) instead of immediately showing the actual value".)* A source just picked
## has landed nothing yet — `landed()` is a sliding sum, not instantaneous — and a rim that opened
## at zero alpha would be invisible for the whole time it takes to earn one, which reads as exactly
## the "shows nothing" playtest 38 reported. The floor is what a source fades *in* to before it has
## anything to say about magnitude.
const MIN_MAGNITUDE := 0.2

## Where `magnitude_for()`'s curve is already at `MAX_ALPHA`. *(2026-09-08, the player: "one point
## is faint but present, five is clearly there, fifteen and above is solid, and the colour then
## carries the difference between fifteen and forty".)* Deliberately far below `SATURATES_AT_POINTS`
## (40): transparency's job is the *low* end, so it has finished its work well before colour has
## finished its own climb from pale to red.
const LOW_EMPHASIS_POINTS := 15.0

## How brightly a source's own rim reads: `landed()` on a curve that rises fast and saturates
## early, so a point or two is already faintly visible and fifteen points is already solid — the
## opposite curve from `colour_for()`'s straight line to forty, which is the whole reason the two
## channels no longer say the same thing at once. *(2026-09-08, the player, dropping the "how far
## away" read this replaced: "the transparency shouldn't show distance since distance actually
## doesn't matter. only the actual received amount counts ... this frees up transparency for also
## encoding magnitude." And on the shape of the curve itself: "transparency can be used to
## emphasize low values.")* `sqrt` is the cheap curve with that shape: `sqrt(x)` for `x` in `0..1`
## rises steeply near zero and flattens as it approaches one, unlike the straight line `colour_for`
## wants for its own axis.
static func magnitude_for(landed: float) -> float:
	return MAX_ALPHA * clampf(sqrt(landed / LOW_EMPHASIS_POINTS), MIN_MAGNITUDE, 1.0)

# -------------------------------------------------------------------- colour ---

## Points at which a source's own rim reads fully red — against the 100-point bar, not against
## the caret's own line. *(2026-09-08, the player: "if a honking car caused 35 excitement to the
## player that's the number that informs the color of the halo. with 1/3 of the bar that's pretty
## red already".)* `Tuning.METER_MAX * 0.4` is 40 points: a felt number rather than a derived one,
## expected to move once it has been looked at on screen.
const SATURATES_AT_POINTS := Tuning.METER_MAX * 0.4

## How red a source's own rim reads: pale for a source that has cost her almost nothing over the
## last `WINDOW` seconds, red for one that has actually hurt. `landed` is the points that actually
## reached the meter — see the class doc — not a rate, and it saturates at `SATURATES_AT_POINTS`.
##
## **This is the axis the row's own declared `intensity` was proposed for and rejected.** Put as a
## fork — a lethal `cyclist` (18/s) glowing paler than a harmless `protest` (42/s) — the answer was
## *"magnitude of how much actually landed at the player -- track it over a time window -- then
## you have the real cost"*: what a row is declared to emit is a fact about the catalogue, and what
## it has actually delivered is a fact about the encounter she just had, which is the only one this
## cue should be reporting.
static func colour_for(landed: float) -> Color:
	var t := clampf(landed / SATURATES_AT_POINTS, 0.0, 1.0)
	return Palette.HALO_WEAK.lerp(Palette.HALO_STRONG, t)

var _events: EventManager
var _crowd: Crowd
var _player: Node2D

func setup(events: EventManager, crowd: Crowd, player: Node2D) -> void:
	_events = events
	_crowd = crowd
	_player = player

## Every frame: pick the sources, tell each one how bright its own ring reads and what colour it
## is, and tell everything else zero. **Nothing here accumulates `landed()`** — that happens where
## the meter is fed, in `Baby._update_excitement()`, so this node only reads it back.
## `set_halo_strength()` is what actually stores it and queues that source's own halo child for
## redraw — this node has no `_draw()` of its own left to call.
##
## **The candidate set is every live event and the whole crowd**, not only a startled body —
## *(2026-09-08, the player: "a busy street is noisy because of cars and a busy sidewalk is noisy
## because of people".)* `CONTRIBUTION_FLOOR` and `MAX_SOURCES` are what keep a busy pavement
## legible rather than a special case admitting only the caret-worthy.
func _process(_delta: float) -> void:
	if not _events or not _crowd or not _player:
		return
	var here := _player.global_position
	var candidates: Array = []
	candidates.append_array(_events.instances())
	candidates.append_array(_crowd.agents())
	var picked := select_sources(candidates, here)
	for source in candidates:
		if source in picked:
			var landed: float = source.landed()
			source.set_halo_strength(magnitude_for(landed), colour_for(landed))
		else:
			source.set_halo_strength(0.0, Palette.HALO_WEAK)
