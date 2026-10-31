class_name ExcitementHalo
extends Node2D
## Which live sources are actively charging the meter right now, and how much each is actually
## *responsible for the bar climbing*, read back onto one rim per source in two channels. It answers
## *which of the six things around her* and *how bad has this one actually been*, neither of which
## the meter's own number can: a number says how much in total and never which.
##
## **Both channels read `ExcitementSource.net_landed()`, on different curves, and neither reads
## distance** *(2026-09-08, the player: "the transparency shouldn't show distance since distance
## actually doesn't matter. only the actual received amount counts ... color and transparency
## shouldn't be the same number. transparency can be used to emphasize low values.")*
## `colour_for()` is linear in the net, so hue separates the high end; `magnitude_for()` rises fast
## and saturates early, so the low end is where transparency does its work.
##
## **The net, not the gross** *(playtest 112: "he gets deep red but my bar doesn't move up much")*:
## each source's own `landed()` less its share of the decay the bar took in the same window, so a
## source reads red only while the bar is actually climbing because of it.
##
## **It draws nothing itself** *(2026-09-07, the player: "it should use the outline of the
## sprite")*: a shape drawn here could only ever be a picture of a *number*, and the licence this
## cue has is that it draws the *thing*. Each source's body draws its own rim (`SourceRim`, handed
## to the source as `ExcitementSource.rim`), told a *target* alpha and colour that it eases toward
## on its own clock (`EntityHalo.FADE_IN_SECONDS`/`FADE_OUT_SECONDS`).
##
## **It accumulates nothing itself.** What has landed on her is traced from the meter's own sum:
## `Baby._update_excitement()` hands each source its exact share (`accumulate_landed()`), and
## `Baby.decay_in_window()` is the same meter's decay over the same window. This node only selects
## sources and combines the two into each rim's net, and tells every source where she is and what
## the frame's projected total is for its caret (`ExcitementSource.set_player_at()`,
## `set_expected_total_gross()`).
##
## **Its candidates are every source of the sets it is handed** (`ExcitementSources`, the world's
## own `WorldContext.excitement_sources`): the events and the whole crowd in the city, the events
## alone in the building.

## Excitement/s a source has to reach at her own position before it earns a place in the halo.
##
## **A felt number, not a derived one.** `Busker` (9/s) is the lowest ordinary intensity in the
## catalogue, so 1.0/s sits comfortably under it: anything genuinely inside a field is drawn, and
## only the thin, nearly-spent tail of a falloff — where the number would round to nothing on the
## meter anyway — is left off. Checked against a screenshot, not derived from a formula: there is
## no arithmetic that says where "reaching her" starts to matter.
const CONTRIBUTION_FLOOR := 1.0

## The most sources one frame may light up. **Past the cap the weakest contributors are the
## ones left out**, in `select_sources()` below — not the furthest and not the newest — because
## dropping the smallest terms of a sum is the smallest possible error the drawn total can carry.
## The candidate set is every live event plus the whole crowd, so an ordinary busy sidewalk can put
## far more than eight candidates inside her reach at once — this cap, together with
## `CONTRIBUTION_FLOOR`, is what keeps that legible. See
## `docs/TODO.md`, "`MAX_SOURCES` (8) is a played question", for the measurement this number is
## checked against.
const MAX_SOURCES := 8

## Which live sources earn a place in the halo, strongest contribution first, capped at
## `MAX_SOURCES`. Every candidate is an `ExcitementSource`.
##
## **A cue that marks everything says nothing** (`.claude/skills/cues/SKILL.md`), so the set is
## never "every source that exists" — it is `contribution_at(at)` above the floor, capped at the
## eight strongest, which keeps a busy pavement legible.
##
## **A source outranked by another is excluded on the same line** (`ExcitementSource.outranked`).
## The region boundary's own pieces — a door's hut, boom and post, and the `roadblock` a wall stands
## as — charge as one source, the strongest at her position, so the others land nothing and a rim on
## one of them would be a cue marking a thing that is costing her nothing while its neighbour reads
## red.
##
## Pulled out as a static function so a test can hold the selection, the floor and the drop order
## without a scene, a shader or a viewport — the same reason `BadgeModel.announces()` is static.
static func select_sources(candidates: Array, at: Vector2) -> Array:
	var ranked: Array = []
	for source in candidates:
		if source.outranked:
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
## at zero alpha would be invisible for the whole time it takes to earn one, which reads as showing
## nothing. The floor is what a source fades *in* to before it has anything to say about magnitude.
const MIN_MAGNITUDE := 0.2

## Where `magnitude_for()`'s curve is already at `MAX_ALPHA`. *(2026-09-08, the player: "one point
## is faint but present, five is clearly there, fifteen and above is solid, and the colour then
## carries the difference between fifteen and forty".)* Deliberately far below
## `Tuning.EXPECTED_IMPACT_POINTS` (40): transparency's job is the *low* end, so it has finished
## its work well before colour has finished its own climb from pale to red.
const LOW_EMPHASIS_POINTS := 15.0

## How brightly a source's own rim reads: `ExcitementSource.net_landed()` on a curve that rises
## fast and saturates early, so a point or two is already faintly visible and fifteen points is
## already solid — the opposite curve from `colour_for()`'s straight line to forty, so the two
## channels never say the same thing at once *(2026-09-08, the player: "transparency can be used to
## emphasize low values.")* `sqrt` is the cheap curve with that shape: `sqrt(x)` for `x` in `0..1`
## rises steeply near zero and flattens as it approaches one, unlike the straight line `colour_for`
## wants for its own axis.
static func magnitude_for(net: float) -> float:
	return MAX_ALPHA * clampf(sqrt(net / LOW_EMPHASIS_POINTS), MIN_MAGNITUDE, 1.0)

# -------------------------------------------------------------------- colour ---

## How red a source's own rim reads: pale for a source that has cost her almost nothing over the
## last `ExcitementSource.WINDOW` seconds, red for one that has actually raised the bar. `net` is
## `ExcitementSource.net_landed()` — what actually reached the meter less this source's own share of
## what walking gave back — not a rate, and it saturates at `Tuning.EXPECTED_IMPACT_POINTS`, the
## same line the caret goes amber at read the other way round.
##
## **What it delivered, never what the row declares it emits** *(the player: "magnitude of how much
## actually landed at the player -- track it over a time window -- then you have the real cost")*:
## a lethal `cyclist` (18/s) may rightly read paler than a harmless `protest` (42/s), since the cue
## reports the encounter she just had, not the catalogue.
##
## **Through `Palette.HALO_MID`, not a straight lerp past it.** *(Playtest 38, finding 4: "there is
## also no real fade from yellow to red (eg when standing next to the other baby lady".)* A chat
## with `chatting_mother` lands `Tuning.CHAT_EXCITEMENT` (25) over `detain_seconds`, past this
## ramp's midpoint — and a single `HALO_WEAK.lerp(HALO_STRONG, t)` passes through a desaturated
## salmon there, because averaging two saturated colours pulls the saturation down with the hue.
## Two lerps either side of the midpoint keeps every point on the ramp as saturated as its own
## ends.
static func colour_for(net: float) -> Color:
	var t := clampf(net / Tuning.EXPECTED_IMPACT_POINTS, 0.0, 1.0)
	if t < 0.5:
		return Palette.HALO_WEAK.lerp(Palette.HALO_MID, t * 2.0)
	return Palette.HALO_MID.lerp(Palette.HALO_STRONG, (t - 0.5) * 2.0)

## The sets of sources this halo picks among (`ExcitementSources`): the world's, handed in.
var _sets: Array[ExcitementSources] = []
var _player: Node2D
var _baby: Baby

## Reused across frames rather than a fresh `Array` every tick — `.clear()` keeps whatever backing
## storage the previous frame's appends grew, so a day at a steady candidate count
## (events plus the whole crowd, ~275) stops paying for a new allocation every frame for an array
## whose size barely moves frame to frame.
var _candidates: Array = []

## Every source holding a rim at the end of the last `_process()`, as dictionary keys — what the
## budget is counted from, carried across frames so a source that has left the candidate set (or is
## queued for deletion) is still counted while its rim exists. Rebuilt every frame; at most
## `EntityHalo.RIM_BUDGET` entries.
var _holders := {}

## **The building shows what the city shows.** `sets` is whatever the world it is handed holds —
## the city's events and crowd, or the building's events alone — so a masked man on the stairs or a
## steam vent in the basement wears the same rim a dog on a sidewalk does. **Called again when the
## escape walks out of the service door**, with the city's sets in place of the building's.
func setup(sets: Array[ExcitementSources], player: Node2D, baby: Baby) -> void:
	_sets = sets
	_player = player
	_baby = baby

## Every frame: tell every candidate where she is standing, pick the sources, tell each one's rim
## how bright it reads and what colour it is, and tell everything else zero.
##
## **The candidate set is every source of every set, the whole crowd included** *(2026-09-08, the
## player: "a busy street is noisy because of cars and a busy sidewalk is noisy because of
## people")*: `CONTRIBUTION_FLOOR` and `MAX_SOURCES` keep a busy sidewalk legible.
##
## **`total_landed` and `decay` are read once, over every candidate, before anybody's net is
## computed**, and `expected_gross_at()` is asked of every candidate right after `set_player_at()`,
## its sum handed back through `set_expected_total_gross()` before anything asks a caret: every
## source's share scales by one factor (`ExcitementSource.net_landed()`), so the floor catches all of
## them together, never one at a time depending on loop order. `_player` is a `Node2D`, so her
## velocity is a soft cast: a stand-in with no `CharacterBody2D` answers held still.
##
## **No more than `EntityHalo.RIM_BUDGET` rims exist at once, none is cut short to keep it so, and
## the strongest picks are lit first** *(2026-10-04, the player: "if we have a limit with number of
## halos the selection should be by intensity so only the top k most intensive halos show at any
## one time")*. On the web a rim past the renderer's sixteenth block draws nothing (`EntityHalo`'s
## class doc), and every change a rim shows eases rather than jumps, so a rim dropped from the picks
## always fades all the way out. A pick that already holds a rim is lit at once, in place; picks with
## no rim are served strongest first, by this frame's `contribution_at()`, while blocks remain, and
## one that cannot be served shows nothing yet and is asked again next frame.
##
## **The count is taken after every block that can come back this frame has**, because the engine
## hands a new rim its block before it releases one freed by a queued deletion: every source not to
## be lit is told zero before any unserved pick is served, and a rim whose fade is over is freed on
## the spot inside that call. `_holders` carries last frame's holders over, so a source that has left
## the candidates still counts while its rim exists, and one whose body is queued for deletion gives
## its rim back on the spot here and is never lit again.
func _process(_delta: float) -> void:
	if FrameRecord.on:
		var outer := FrameRecord.enter(FrameRecord.CUES)
		_pick_and_predict()
		FrameRecord.leave(outer)
	else:
		_pick_and_predict()

## Picking the rims and predicting the carets, timed under `FrameRecord.CUES`.
func _pick_and_predict() -> void:
	if _sets.is_empty() or not _player or not _baby:
		return
	var here := _player.global_position
	var player_velocity := (_player as CharacterBody2D).velocity \
			if _player is CharacterBody2D else Vector2.ZERO
	var player_decay_rate := _baby.decay_rate()
	var player_sensitivity := _baby.current_sensitivity()
	_candidates.clear()
	for set in _sets:
		set.every_source(_candidates)
	var picked := select_sources(_candidates, here)
	# A `Dictionary` keyed by the picked sources themselves, built once off the (at most
	# `MAX_SOURCES`) picked set, so the loop below tests membership in O(1) rather than a linear
	# scan of `picked` for every one of up to ~275 candidates.
	var picked_set := {}
	for source in picked:
		picked_set[source] = true
	var total_landed := 0.0
	for source in _candidates:
		total_landed += source.landed()
	var decay := _baby.decay_in_window()
	var total_expected_gross := 0.0
	for source in _candidates:
		# Every candidate, picked or not — a source below the halo's own floor can still be worth
		# a caret, since the two cues answer different questions over different sets.
		source.set_player_at(here, player_velocity, player_decay_rate, player_sensitivity)
		total_expected_gross += source.expected_gross_at(here)
	# Every block that can come back this frame comes back before any unserved pick is served —
	# see this function's doc. First the rims of last frame's holders whose bodies are going anyway.
	for source in _holders:
		if is_instance_valid(source.body) and source.body.is_queued_for_deletion():
			var going = source.rim
			if going:
				going.release()
	var holders := {}
	for source in _candidates:
		source.set_expected_total_gross(total_expected_gross)
		if picked_set.has(source):
			continue
		# A rim not held has nothing to fade, so only a held one is told zero.
		var rim = source.rim
		if rim == null or not rim.is_held():
			continue
		rim.set_strength(0.0, Palette.HALO_WEAK)
		if rim.is_held():
			holders[source] = true
	# A holder that is no longer a candidate at all still holds its block; told zero like any other
	# unpicked source, so it fades and gives it back rather than counting against the budget forever.
	for source in _holders:
		if not is_instance_valid(source.body) or picked_set.has(source) or holders.has(source):
			continue
		var rim = source.rim
		if rim == null:
			continue
		rim.set_strength(0.0, Palette.HALO_WEAK)
		if rim.is_held():
			holders[source] = true
	# Picks that already hold a rim are lit at once, in place: relighting needs no new block. Picks
	# with no rim are served strongest first (`picked` is in that order) while blocks remain; the
	# rest are told zero and show nothing yet.
	for source in picked:
		var rim = source.rim
		if rim == null or source.body.is_queued_for_deletion():
			continue
		if rim.is_held():
			holders[source] = true
	for source in picked:
		var rim = source.rim
		if rim == null or source.body.is_queued_for_deletion():
			continue
		if not rim.is_held():
			if holders.size() >= EntityHalo.RIM_BUDGET:
				rim.set_strength(0.0, Palette.HALO_WEAK)
				continue
			holders[source] = true
		var net := ExcitementSource.net_landed(source.landed(), total_landed, decay)
		rim.set_strength(magnitude_for(net), colour_for(net))
	_holders = holders
