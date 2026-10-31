class_name ExcitementSource
extends RefCounted
## **One thing in the world that charges the baby**: an event (`EventExcitement`) or a body in the
## crowd (`CrowdExcitement`), composed into it and handed its body. Everything the two have in
## common lives here once — the ledger of what it has landed on her, the walls its field does not
## pass, what she is doing this frame, the cached present rate, the projection of the next
## `Tuning.EXPECTED_IMPACT_HORIZON` seconds and the caret's strength — and a type says only what is
## its own: its field, how far it reaches, the velocity and key its projection runs on, whether it
## projects at all, its clock, whether its course is lethal and what its caret is keyed on.
##
## **Nothing pushes a value at the baby.** `Baby` asks the world
## (`WorldContext.excitement_sources_at()`) for `[source, contribution]` pairs, sums them, and hands
## each source its exact share of what landed (`accumulate_landed()`), so a source's `landed()` can
## never disagree with what the bar did.
## `ExcitementHalo` reads `landed()` back for the rims and asks `expected_impact_at()` and
## `will_be_lethal()` for the carets.
##
## In the world layer: it knows the map its walls are asked of (`WorldMap`) and nothing about
## events, the crowd or how a rim is drawn. A base source has no field at all, which is what a test
## world that answers a fixed noise hands the baby.

## The width of `landed()`'s sliding sum, in seconds — `Tuning.EXPECTED_IMPACT_HORIZON` read
## backward rather than a number of its own: the caret projects the same five seconds forward.
##
## **A true sum, not a decayed average** *(2026-09-08, the player: "if a honking car caused 35
## excitement to the player that's the number that informs the color of the halo")*: a 35-point
## burst reads as 35 for the whole window and then drops, so each source keeps its own list of
## `[when, points]` entries. **`when` is the source's own simulation clock** (`clock()`), so a pause
## longer than the window empties no halo, and a test measures the window on simulated time. Long
## enough that a three-second `cat_dash` colours at all, short enough that a source she walked away
## from stops colouring promptly *(2026-09-07: "5s sounds good for now")*.
const WINDOW := Tuning.EXPECTED_IMPACT_HORIZON

## A source's own share of the decay the bar took over the same window, in proportion to what it
## landed, subtracted from what it landed, floored at zero *(playtest 112: "he gets deep red but my
## bar doesn't move up much. it was supposed to indicate the actual amount I receive over a time
## window")*. `landed` is still traced from the meter, never recomputed from the field.
##
## **The floor is why the sum is exact.** Every source's share scales by the one factor
## `decay / total_landed`, so either it is under one and the nets sum to `total_landed − decay`, the
## bar's own rise, or it is at least one and every source floors to zero together: when the bar is
## not climbing, nothing reads red. `total_landed` is every candidate's `landed()`, picked or not.
## Zero when nothing has landed from anybody.
static func net_landed(landed: float, total_landed: float, decay: float) -> float:
	if total_landed <= 0.0:
		return 0.0
	return maxf(0.0, landed - decay * (landed / total_landed))

## The thing in the world this source charges her from: where its field stands
## (`global_position`), and whether it is still there (`is_queued_for_deletion()`).
var body: Node2D

## How this source's rim is drawn, handed in by the body's view (`SourceRim`), or null for a source
## nobody draws. Typed only as what it is to this layer, since the world names no view class.
var rim: RefCounted = null

## Whether another source of the same kind is the one charging her in this one's place this frame,
## so this one is not projected (`expected_gross_at()` answers zero) and is not picked for a rim
## (`ExcitementHalo.select_sources()`). Told from outside, once a frame: a region boundary's
## structures charge as their strongest (`EventSources`). False until somebody says otherwise.
var outranked := false

func _init(the_body: Node2D) -> void:
	body = the_body

# --------------------------------------------------------------- what she does ---

## Where she is, in world space, or `Vector2.INF` before anybody has said, told once a frame by
## `ExcitementHalo` through `set_player_at()`.
var player_at := Vector2.INF

## Where the caret measures her from (`caret_strength()`): `player_at`, unless the body keeps its
## own account of where she is that more than the halo writes.
func _her_at() -> Vector2:
	return player_at

## Her current velocity, her decay rate (`Baby.decay_rate()`) and the baby's sensitivity
## (`Baby.current_sensitivity()`): everything `expected_impact_at()` needs to answer "if she keeps
## doing what she is doing". The defaults answer held still, nothing given back and nothing damped,
## for any caller — a data-level test among them — that has not said otherwise.
var player_velocity := Vector2.ZERO
var player_decay_rate := 0.0
var player_sensitivity := 1.0

## The sum of `expected_gross_at()` over every source `ExcitementHalo` runs this frame, told once a
## frame through `set_expected_total_gross()`. `-1.0`, the default, means nobody has, and
## `expected_impact_at()` nets the whole projected decay against this source alone.
var player_expected_total_gross := -1.0

## This frame's player position, velocity, decay rate and sensitivity, told once a frame to every
## candidate by `ExcitementHalo`, picked or not, since a source below the halo's floor can still be
## worth a caret.
func set_player_at(at: Vector2, velocity: Vector2 = Vector2.ZERO, decay_rate: float = 0.0,
		sensitivity: float = 1.0) -> void:
	player_at = at
	player_velocity = velocity
	player_decay_rate = decay_rate
	player_sensitivity = sensitivity

## Told once a frame by `ExcitementHalo`, after every candidate's `expected_gross_at()` has been
## asked at the same position: the total has to be gathered before any one source's share of the
## decay can be known.
func set_expected_total_gross(total: float) -> void:
	player_expected_total_gross = total

# ------------------------------------------------------------- what has landed ---

## `[when, points]` entries landed on her from this source, `when` from `clock()`, for whatever is
## still inside `WINDOW`. Lazily grown: a source that has never landed anything keeps it empty.
var _landed_history: Array = []

## Every point this source has ever landed on her meter, never pruned — the running total
## `EncounterWatch` measures an encounter's share against, since `landed()` keeps only `WINDOW`
## and an encounter can be longer. Telemetry only: nothing that decides anything reads it.
var landed_ever := 0.0

## Called once, on the first point this source lands on her, or not at all while unset: how a
## creator hears that a source reached her without this source knowing who asked
## (`EventSpawner`'s pelican).
var on_first_landing := Callable()

var _first_landing_told := false

## Folds an exact points share into the window. `points` is not recomputed here:
## `Baby._update_excitement()` traces it back from the meter's own sum as this source's share of
## what landed this frame — `contribution × sensitivity × delta` — so the halo can never disagree
## with what the bar did *(2026-09-08, the player: "don't derive it from the source numbers but
## trace an increase in excitement back to its constituents")*.
func accumulate_landed(points: float) -> void:
	_prune_landed_history()
	if points > 0.0:
		_landed_history.append([clock(), points])
		landed_ever += points
		if on_first_landing.is_valid() and not _first_landing_told:
			_first_landing_told = true
			on_first_landing.call()

## The sum of every entry still inside `WINDOW`. Pruned here too, not only on write, so a source
## nobody has visited in a while reports honestly the moment it is asked.
func landed() -> float:
	if _landed_history.is_empty():
		return 0.0
	_prune_landed_history()
	var total := 0.0
	for entry in _landed_history:
		total += entry[1]
	return total

func _prune_landed_history() -> void:
	var cutoff := clock() - WINDOW
	while not _landed_history.is_empty() and _landed_history[0][0] < cutoff:
		_landed_history.pop_front()

## This source's own simulation clock, in seconds, which `landed()` measures its window on.
func clock() -> float:
	return 0.0

# ---------------------------------------------------------------- the present ---

## Whether the present rate is cached once per `_contribution_stamp()` and point: a type whose field
## changes only when its own stamp moves says so. A crowd body is moved and startled from outside
## its own step, so a cache keyed on its clock could answer with the jolt or the position from
## before the bump that tick, the one frame a fresh startle is meant to show on.
var _caches_contribution := false
var _contribution_stamp_was := NAN
var _contribution_point_was := Vector2.INF
var _contribution_was := 0.0

## Excitement per second this source delivers at a point: its field (`_field()`), and zero wherever
## a wall stands between it and the point (`_walled_off_now()`).
##
## **Nothing reaches her through a building** *(plaid-wombat, inbox #554: "Excitement should not go
## through any wall")*: the wall is asked only of a positive field, so a source out of reach costs
## no line at all. The meter's sum, the halo's pick and the caret's present rate ask the same point
## in a frame, which is what the cache is for, for a type that keeps one.
func contribution_at(at: Vector2) -> float:
	if not _caches_contribution:
		var field := _field(at)
		if field > 0.0 and _walled_off_now(body.global_position, at):
			return 0.0
		return field
	var stamp := _contribution_stamp()
	if stamp == _contribution_stamp_was and at == _contribution_point_was:
		return _contribution_was
	var result := _contribution_uncached(at)
	_contribution_stamp_was = stamp
	_contribution_point_was = at
	_contribution_was = result
	return result

## Forces the next `contribution_at()` to recompute rather than trust the cache: for a field that
## changed without its stamp moving.
func invalidate_contribution() -> void:
	_contribution_stamp_was = NAN

func _contribution_uncached(at: Vector2) -> float:
	var field := _field(at)
	if field > 0.0 and _walled_off_now(body.global_position, at):
		return 0.0
	return field

## The field alone at a point, no wall asked: zero for a base source.
func _field(_at: Vector2) -> float:
	return 0.0

## What the present rate's cache is keyed on with the point, for a type that keeps one.
func _contribution_stamp() -> float:
	return NAN

# ------------------------------------------------------------------ the walls ---

## The map whose walls this source's field does not pass (`WorldMap.wall_between()`), or null for
## nowhere walled. Read by the debug view's fields layer too, which cuts a source's outline along
## the same lines (`DebugLayers.open_runs()`).
func wall_grid() -> WorldMap:
	return null

## Whether a wall stands between a source at `source_at` and her at `her_at`, deep enough to keep
## its excitement from her.
func _walled_off(source_at: Vector2, her_at: Vector2) -> bool:
	var grid := wall_grid()
	return grid != null and grid.wall_between(source_at, her_at)

## The last line `contribution_at()` asked about and its answer, kept by value. The answer depends
## on nothing but the two points and the map, so a body moved from outside is a new key and nothing
## here can answer stale the way a clock-keyed cache of the field would.
var _wall_from := Vector2.INF
var _wall_to := Vector2.INF
var _wall_grid: WorldMap = null
var _wall_answer := false

## `_walled_off()` through that one-line cache, for `contribution_at()` alone: the projection asks a
## different pair at every step and would only push the frame's own pair out.
func _walled_off_now(source_at: Vector2, her_at: Vector2) -> bool:
	var grid := wall_grid()
	if source_at != _wall_from or her_at != _wall_to or grid != _wall_grid:
		_wall_from = source_at
		_wall_to = her_at
		_wall_grid = grid
		_wall_answer = grid != null and grid.wall_between(source_at, her_at)
	return _wall_answer

# ------------------------------------------------------------ the next seconds ---

## One bounded integral cache per source, with a by-value key rather than a clock or identity.
var _expected_landed_key: Array = []
var _expected_landed_cache := 0.0

## The gross points this source is anticipated to land over `Tuning.EXPECTED_IMPACT_HORIZON` **if
## she and it both carry on exactly as they are**, before her own decay is netted against it;
## `ExcitementHalo` sums it once a frame to learn what the horizon's decay is shared between
## *(2026-09-20: "caret communicates anticipated net gain. basically if I keep doing what I'm doing
## I very likely get that amount in net gain")*. Her `player_velocity` moves her through the
## projection as the source's own `_projection_velocity()` moves it.
##
## **Skipped without sampling once neither body is moving, or the pair's closing speed cannot cross
## the reach inside the horizon.** Floored at zero and scaled by `player_sensitivity` here, so the
## total the halo sums is already in the units the shared decay is taken out of. The present rate
## subtracted is the real `contribution_at()` — what she is charged right now — so the answer is the
## approach minus the honest present.
##
## **The reach is asked before whether it projects at all** (`_projects()`): every check before the
## sampling answers zero and changes nothing, so their order is free, and most of a day's sources
## are out of reach, so the type's question is asked only of the few near enough to matter. The halo
## asks this of every source every drawn frame.
func expected_gross_at(player_position: Vector2) -> float:
	if outranked:
		return 0.0
	var velocity := _projection_velocity()
	var closing := player_velocity - velocity
	var reach := closing.length() * Tuning.EXPECTED_IMPACT_HORIZON + _projection_reach()
	if body.global_position.distance_to(player_position) > reach:
		return 0.0
	if (velocity.is_zero_approx() and player_velocity.is_zero_approx()) or not _projects():
		return 0.0
	var current_rate := contribution_at(player_position)
	_begin_the_projection(velocity)
	var future_integral: float
	var key := _projection_key(player_position, velocity)
	if key.is_empty():
		future_integral = _sample_expected_landed(player_position, velocity)
	else:
		if key != _expected_landed_key:
			_expected_landed_cache = _sample_expected_landed(player_position, velocity)
			_expected_landed_key = key
		future_integral = _expected_landed_cache
	var gross := future_integral - current_rate * Tuning.EXPECTED_IMPACT_HORIZON
	return maxf(gross * player_sensitivity, 0.0)

## Only the future integral is reusable. Projecting the source forward by `velocity * t` and asking
## its field at her own projected place is the same number as holding the source still and asking
## at the pair's relative offset, so the field is asked at the translated point
## (`_projected_field()`); **the field translates, a wall does not**, so the wall is asked between
## the two bodies' own projected places.
func _sample_expected_landed(player_position: Vector2, velocity: Vector2) -> float:
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	var integral := 0.0
	# Where it stands and the walls it asks, read once: neither moves while it samples.
	var from := body.global_position
	var grid := wall_grid()
	for i in steps:
		var t := float(i + 1) * dt
		var sample := player_position + player_velocity * t - velocity * t
		var rate := _projected_field(sample, velocity)
		if rate > 0.0 and grid != null and grid.wall_between(from + velocity * t,
				player_position + player_velocity * t):
			rate = 0.0
		integral += rate * dt
	return integral

## The net points this source is anticipated to add to the bar over the horizon — the caret's own
## answer to *"if I keep doing what I'm doing, how much will I get"*: `expected_gross_at()` less her
## own decay over the same horizon.
##
## **Shared with every other source when `ExcitementHalo` drives the frame, charged against this
## source alone otherwise** *(2026-09-20, on the unshared answer: "with two sources near her every
## caret reads low")*. `net_landed()`'s arithmetic, forward instead of back: every source's share of
## the horizon's decay scales by the one factor, so the shares sum back to the bar's own projected
## rise exactly.
func expected_impact_at(player_position: Vector2) -> float:
	var gross := expected_gross_at(player_position)
	if gross <= 0.0:
		return 0.0
	var decay := player_decay_rate * Tuning.EXPECTED_IMPACT_HORIZON
	if player_expected_total_gross >= 0.0:
		return net_landed(gross, player_expected_total_gross, decay)
	return maxf(gross - decay, 0.0)

## Whether this source projects anything at all right now.
func _projects() -> bool:
	return true

## The velocity the projection moves this source at.
func _projection_velocity() -> Vector2:
	return Vector2.ZERO

## The furthest this source's field can reach, which the projection's early-out is stated over.
func _projection_reach() -> float:
	return 0.0

## Anything the projection works out once before it samples, `velocity` the course it runs on.
func _begin_the_projection(_velocity: Vector2) -> void:
	pass

## Every input the projection's samples read, by value, or empty where none is cached.
func _projection_key(_player_position: Vector2, _velocity: Vector2) -> Array:
	return []

## The field at a translated sample point, for the projection.
func _projected_field(_sample: Vector2, _velocity: Vector2) -> float:
	return 0.0

## Whether this source's course puts her where it ends the day before the horizon is out, her
## position held fixed: the doubled caret's question. Never, for a base source.
func will_be_lethal(_player_position: Vector2) -> bool:
	return false

# ------------------------------------------------------------------ the caret ---

var _caret_key_was: Variant = null
var _caret_known := false
var _caret := 0

## The caret's own answer for this source, 0 (none), 1 (amber) or 2 (doubled red), against where
## she is (`_her_at()`): doubled exactly when `will_be_lethal()`, amber when `expected_impact_at()` reaches
## `Tuning.EXPECTED_IMPACT_POINTS` *(2026-09-08, the player: "carets shouldn't be chosen by source
## value but by expected impact value")*. **Cached on `_caret_key()`**: a body's drawing and its
## redraw check both ask in the same frame, and each answer is a fresh sampling loop.
func caret_strength() -> int:
	var key: Variant = _caret_key()
	if _caret_known and key == _caret_key_was:
		return _caret
	_caret_known = true
	_caret_key_was = key
	_caret = 0
	if _may_mark():
		var her := _her_at()
		if will_be_lethal(her):
			_caret = 2
		elif expected_impact_at(her) >= Tuning.EXPECTED_IMPACT_POINTS:
			_caret = 1
	return _caret

## What the caret's answer is cached on: the clock, unless a type says otherwise.
func _caret_key() -> Variant:
	return clock()

## Whether this source may carry a caret at all right now: not before anybody has said where she is.
func _may_mark() -> bool:
	return _her_at() != Vector2.INF
