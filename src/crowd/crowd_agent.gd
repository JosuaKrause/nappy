class_name CrowdAgent
extends LaneMover
## One person or one car, going about its business.
##
## An agent is not an event. An event is authored, telegraphed and held to the fairness
## contract; an agent is traffic, and the player is expected to walk around it rather than
## be warned about it. What the two share is the *query*: `Crowd` sums `contribution_at()`
## over its agents exactly as `EventManager` does over its instances, so nothing pushes a
## value at the baby and the crowd composes with the events by plain addition.
##
## The lane movement is `LaneMover`'s; this is the crowd member on top of it: the excitement field
## and the projections of it (`contribution_at()` and its siblings), the halo and the caret, the
## jolt a contact or a horn leaves, and the drawing.

## The walker's five authored views, keyed by name rather than by sector — `WALKER_VIEW_BY_SECTOR`
## below does the sector-to-view lookup, so drawing never repeats an eight-way if-chain of its
## own to get here. All five share one 18x38 canvas and one (9, 38) feet anchor (see
## `docs/evidence/svg-people-2026-09-10/PEOPLE-MATRIX.md`); body is tinted per walker, trim is
## drawn untinted above it — see `_draw_body()`.
##
## Paths rather than `preload()`d textures: the milestone's whole point is that a picture baked
## into `assets/atlases/baked/crowd.png` is not also resident as its own loaded resource.
## `_region_of()` is what turns one of these into the name `AtlasLibrary.region()` and
## `native_size()` actually take.
const WALKER_BODY_BY_VIEW := {
	"front": "crowd/walker_front_body",
	"back": "crowd/walker_back_body",
	"side": "crowd/walker_side_body",
	"front_diagonal": "crowd/walker_front_diagonal_body",
	"back_diagonal": "crowd/walker_back_diagonal_body",
}
const WALKER_TRIM_BY_VIEW := {
	"front": "crowd/walker_front_trim",
	"back": "crowd/walker_back_trim",
	"side": "crowd/walker_side_trim",
	"front_diagonal": "crowd/walker_front_diagonal_trim",
	"back_diagonal": "crowd/walker_back_diagonal_trim",
}
## The walker's second gait frame, feet passing — the mother's own `_b` pose for each view. Only
## the legs and shoes differ from the tables above; the coat stays put in the three-quarter views
## and lifts a pixel in front/back/side, exactly the correction the mother's own frames needed
## (`docs/DECISIONS.md`, "Eight-direction style transfer"). Kept as separate `_b`-suffixed files
## beside the unsuffixed frame-a sources rather than renaming those into `_a`, so nothing that
## already points at `walker_front_body.svg` and so on has to change.
const WALKER_BODY_BY_VIEW_B := {
	"front": "crowd/walker_front_body_b",
	"back": "crowd/walker_back_body_b",
	"side": "crowd/walker_side_body_b",
	"front_diagonal": "crowd/walker_front_diagonal_body_b",
	"back_diagonal": "crowd/walker_back_diagonal_body_b",
}
const WALKER_TRIM_BY_VIEW_B := {
	"front": "crowd/walker_front_trim_b",
	"back": "crowd/walker_back_trim_b",
	"side": "crowd/walker_side_trim_b",
	"front_diagonal": "crowd/walker_front_diagonal_trim_b",
	"back_diagonal": "crowd/walker_back_diagonal_trim_b",
}
## Which authored view each of `EightDirection`'s eight sectors draws — N back, NE/NW
## back_diagonal, E/W side, SE/SW front_diagonal, S front, the same N/NE/E/SE/S coverage the
## mother/pram family uses. Sectors 3 (SW), 4 (W) and 5 (NW) mirror their partner here rather
## than being separately authored — see `EightDirection.is_mirrored()`.
const WALKER_VIEW_BY_SECTOR: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]
## Which authored view each of `EightDirection`'s eight sectors draws — identical to the walker's
## own table above, since the crowd car shares the same five projections and the same west-mirror
## convention (`docs/evidence/svg-vehicles-2026-09-10/facings.csv`, the `car` rows).
const CAR_VIEW_BY_SECTOR: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]
## The car's five authored views, keyed by name the way the walker's own two tables are —
## `CAR_VIEW_BY_SECTOR` above does the sector lookup. Three layers per view on one canvas and one
## anchor: the body, tinted per car; the trim, glass and lamps, untinted above it; and the wheels,
## untinted above both, which stay on the ground while the body and trim ride `_body_bob()` — see
## `_draw_body()`. Front/back are 30x46, side is 52x30, the diagonals are 52x42.
## `car_end_{body,trim}.svg`, the old two-view family's foreshortened top-down picture, is read by
## none of the three tables — see `docs/GRAPHICS.md` for where it stands now.
const CAR_BODY_BY_VIEW := {
	"front": "crowd/car_front_body",
	"back": "crowd/car_back_body",
	"side": "crowd/car_side_body",
	"front_diagonal": "crowd/car_front_diagonal_body",
	"back_diagonal": "crowd/car_back_diagonal_body",
}
const CAR_TRIM_BY_VIEW := {
	"front": "crowd/car_front_trim",
	"back": "crowd/car_back_trim",
	"side": "crowd/car_side_trim",
	"front_diagonal": "crowd/car_front_diagonal_trim",
	"back_diagonal": "crowd/car_back_diagonal_trim",
}
const CAR_WHEELS_BY_VIEW := {
	"front": "crowd/car_front_wheels",
	"back": "crowd/car_back_wheels",
	"side": "crowd/car_side_wheels",
	"front_diagonal": "crowd/car_front_diagonal_wheels",
	"back_diagonal": "crowd/car_back_diagonal_wheels",
}

## `WALKER_BODY_BY_VIEW`'s (and its five sibling tables') own entry as the `StringName` that
## `AtlasLibrary.region()`/`native_size()` take. The tables hold plain `String`s because a `const`
## `Dictionary` cannot hold a `StringName` literal the type checker will keep, and this is the one
## conversion between the two.
static func _region_of(name: String) -> StringName:
	return StringName(name)

## Where a car's own caret sits, and how big it is. Matched to `EventInstance`'s so the two carets
## are the same cue rather than two similar ones, but lower, because a car is 26px of sprite
## against a standing figure's 46.
const MARK_HEIGHT := 30.0
const MARK_WIDTH := 15.0

var colour := Color.WHITE

## `--skip crowd`, handed in by the `Crowd` that makes this agent: `_draw()` returns before
## drawing anything.
var skip_draw := false

## True while the player is touching this agent. Owned by `Crowd`, and the reason it exists is
## that a contact is not instantaneous: she walks faster than a pedestrian does, so a person
## bumped from behind stays inside the contact radius for the better part of a second. Without
## it the contact re-fires every frame and one person costs what a crowd should.
var touching := false

## This frame's player position, or `Vector2.INF` before the first frame — part of
## `ExcitementHalo`'s duck type, told once a frame through `set_player_at()`. `Crowd` only ever
## hands an agent the player's position when the agent is a car near a road (`pedestrian_ahead`),
## so this is the one channel that reaches every agent in the crowd regardless, which is what
## `expected_impact_at()` and `will_be_lethal()` need to answer for a walker as well as a car.
var player_at := Vector2.INF

## Her current velocity, `Baby.decay_rate()` and `Baby.current_sensitivity()` — see
## `EventInstance`'s own copy of these three fields for what `expected_impact_at()` does with
## them. Defaults answer exactly as this function always did for any caller that has not told this
## agent her actual state.
var player_velocity := Vector2.ZERO
var player_decay_rate := 0.0
var player_sensitivity := 1.0

## The sum of `expected_gross_at()` over every source `ExcitementHalo` is running this frame, told
## once a frame through `set_expected_total_gross()` — `-1.0` (the default) means nobody has, so
## `expected_impact_at()` nets the whole projected decay against this agent alone, exactly as it
## always did. See `EventInstance`'s own copy for the shared arithmetic.
var player_expected_total_gross := -1.0

func set_player_at(at: Vector2, velocity: Vector2 = Vector2.ZERO, decay_rate: float = 0.0,
		sensitivity: float = 1.0) -> void:
	player_at = at
	player_velocity = velocity
	player_decay_rate = decay_rate
	player_sensitivity = sensitivity

## Told once a frame by `ExcitementHalo`, after every live candidate's own `expected_gross_at()`
## has been asked at the same position — see that function's own doc for why the total has to be
## gathered before any one source's share of the decay can be known.
func set_expected_total_gross(total: float) -> void:
	player_expected_total_gross = total

## The sector, flip and third term currently drawn, so a redraw only happens when one of them
## changes. The third is the gait frame for a walker and the body's bob for a car, quantised by
## `CAR_BOB_STEPS_PER_PX` — the two things each kind draws that move without the sector moving.
##
## **This is the quantised half of what the drawing reads, and a car has a continuous half too** —
## `_drawn_heading` below. See `_redraw_if_the_picture_changed()`.
var _picture := Vector3i(-1, -1, -1)
## The live heading a car's picture was last drawn at, quantised by `CAR_HEADING_STEPS` — the other
## half of the redraw key. Always `Vector2i.ZERO` for a walker, whose drawing reads no heading at
## all: its own picture is the sector, the mirror and the gait frame and nothing else.
var _drawn_heading := Vector2i.ZERO
## Whether this car's own caret was up last frame, so it gets one redraw to come off with.
var _was_marked := false
## True while what this agent shows is not being kept current because none of it can be on the
## screen (`DrawnView`), so the first frame it is back in the box redraws it whatever the key says.
var _picture_is_stale := false

## Built lazily on this agent's own first non-zero glow, and freed once it has faded all the way
## back out — see `set_halo_strength()`. A halo built for every agent in a crowd of a couple of
## hundred, whether or not it is ever picked, would be cost paid for nothing — only the handful
## `ExcitementHalo.MAX_SOURCES` ever picks needs one at all.
var _halo: EntityHalo

## Seconds of agitation left, and how loud the agitation started. A person she walked into is
## startled and says so; a car that had to sound its horn keeps sounding for a moment. This is
## how a contact reaches the meter *without* anything writing to `Baby.excitement`: the source
## is the body she touched, summed by `Crowd` exactly like every other body.
var _jolt := 0.0
var _jolt_for := 1.0
var _jolt_intensity := 0.0
var _jolt_inner := 0.0
var _jolt_outer := 0.0:
	set(value):
		_jolt_outer = value
		_widest_jolt_outer = maxf(_widest_jolt_outer, value)

## The widest `_jolt_outer` any agent has carried in this process — it only ever grows, through
## the setter above, however the radius is written. What `silent_beyond()` is stated over, so a
## jolt wider than any `startle()` passes today still counts the moment it exists.
static var _widest_jolt_outer := 0.0

## A distance from any agent beyond which its field is exactly zero: the reach
## `contribution_at()` rejects past, taken over both kinds and the widest jolt there has been.
## `Crowd.excitement_sources_at()` asks it once a sweep and skips a body past it without calling
## into the body at all, which is most of the crowd most of the time.
static func silent_beyond() -> float:
	var outer := maxf(maxf(Tuning.CAR_OUTER_RADIUS, Tuning.PEDESTRIAN_OUTER_RADIUS),
			_widest_jolt_outer)
	return outer / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)

## `[when, points]` entries landed on her from this agent, `when` stamped from `_clock` in
## seconds, for whatever is still inside `ExcitementHalo.WINDOW` — a true sliding sum rather than
## a decayed average. Lazily grown: an agent that has never landed anything keeps this empty.
## Duck-typed with `EventInstance`'s own copy — see `ExcitementHalo`'s class doc for the whole
## shape.
var _landed_history: Array = []

## This agent's own simulation clock, in seconds, advanced by `delta` in `_process()`. `landed()`
## is measured against this rather than `Time.get_ticks_msec()` so that a paused game does not
## empty the halo, and so a rig can measure the window on simulated time by advancing this
## directly instead of waiting on the wall clock.
var _clock := 0.0

## Everything this agent's own drawing can cover, relative to its position — what
## `_redraw_if_the_picture_changed()` asks `DrawnView` about. `ENTRY_PICTURE_ROOM` either side, and
## above that a car's doubled caret at its tallest (`_draw_mark()`): the upper chevron's top stands
## `MARK_HEIGHT + 10 + 1.65 × MARK_WIDTH` above the node, about 65px, with its outline's width on top.
const DRAWN_REACH := Rect2(-ENTRY_PICTURE_ROOM, -(MARK_HEIGHT + 10.0 + MARK_WIDTH * 1.65 + 4.0),
		ENTRY_PICTURE_ROOM * 2.0, MARK_HEIGHT + 10.0 + MARK_WIDTH * 1.65 + 4.0 + ENTRY_PICTURE_ROOM)

## Asks for a redraw when what this agent is showing has actually changed, and answers whether it
## asked.
##
## Moving a Node2D does not invalidate its draw list — the transform is applied when it is
## replayed — so an agent only redraws when its picture actually changes. At this population that
## is the difference between five hundred redraws a frame and a handful.
##
## **And only while any of it can be on the screen** (`DrawnView`, `DRAWN_REACH`). Most of the
## crowd is off screen, and those agents were most of the redraws and every car's caret projection;
## the key is still kept every frame, so nothing about the picture's own state depends on where the
## camera is, and an agent coming back into the box redraws once on that frame whatever the key says.
##
## **A term missing from the key is a frozen picture rather than a crash**, the same rule
## `EventInstance._redraw_if_the_picture_changed()` states for the catalogue's own gate — so the key
## has to name every time-varying thing `_draw_body()` reads and not a plausible subset. A walker's
## drawing is the sector, the mirror and the gait frame, all three quantised and all three above. A
## car's third term is its body's bob instead (`_body_bob()`), which moves on every frame it is
## driving while nothing else about a car in a lane does. **A car's drawing also reads its live
## heading, twice**: `_car_body_anchor()` registers the picture
## `26·|heading.y| + 14·|heading.x|` south of the node, and `_draw_shape_shadow()` sweeps the
## capsule along the same heading. Both are continuous through an arc while the sector is not, so a
## key made only of the quantised half leaves a car that has turned wearing the anchor and the
## shadow axis it last had at a sector boundary — up to 22.5 degrees back, which lands an east- or
## west-bound car's picture about nine pixels south of its own body and keeps it there for the
## rest of its run in that lane, since nothing about the quantised picture ever changes again. The
## rim does not go with it: `EntityHalo` re-traces the body every frame it is drawn, so the halo
## stands where the car should be and the car does not. That is exactly what the player saw.
func _refresh_the_picture() -> bool:
	var third: int
	var view: int
	if kind == Kind.WALKER:
		# One `velocity()` serves the gait and the sector: the same value `_walker_gait_frame()` and
		# `_walker_heading()` would each have computed, nothing between them moves it.
		var along := velocity()
		third = _walker_gait_frame_at(along)
		_walker_view = EightDirection.update(_walker_view, _walker_heading_at(along),
				WALKER_IDLE_SPEED)
		view = _walker_view
	else:
		# One `velocity()` serves the bob and the sector, the same value `_body_bob()` and
		# `_update_car_view()` would each have computed.
		var moving := velocity()
		third = roundi(WheelBob.lift(_car_travelled, moving.length() / CAR_BOB_FULL_SPEED)
				* CAR_BOB_STEPS_PER_PX)
		_car_view = EightDirection.update(_car_view, moving, CAR_IDLE_SPEED)
		view = _car_view
	var picture := Vector3i(view, 1 if _flipped() else 0, third)
	var drawn_heading := _drawn_heading_key()
	var changed := picture != _picture or drawn_heading != _drawn_heading
	_picture = picture
	_drawn_heading = drawn_heading
	# Off screen nothing is redrawn and no caret is projected (`DrawnView`): the picture is left as
	# it was, and the first frame any of it is back inside the box redraws it from what it is now,
	# caret included, which is before the margin has let any of it onto the screen.
	if not DrawnView.shows(self, DRAWN_REACH):
		_picture_is_stale = true
		return false
	if changed or _picture_is_stale:
		_picture_is_stale = false
		# What this redraw puts up is the mark as it stands now — the same answer `_draw()` asks
		# for, cached against the clock — so a mark that drops on the next frame is taken off.
		_was_marked = kind == Kind.CAR and _caret_strength() > 0
		queue_redraw()
		return true
	# A marked car draws a caret that can breathe with its own horn, and a projected approach
	# can change its strength frame to frame with nothing else about the picture moving. The
	# one frame after the mark comes down is what takes the caret off again.
	if kind == Kind.CAR and (_caret_strength() > 0 or _was_marked):
		_was_marked = _caret_strength() > 0
		queue_redraw()
		return true
	return false

## A walker's stride starts at rest for a placement.
func restart_the_picture() -> void:
	_walker_gait_phase = 0.0

func advance_the_picture(delta: float) -> void:
	if kind == Kind.CAR:
		_advance_car_bob(delta)
	else:
		_advance_walker_gait(delta)

func _dress() -> void:
	colour = _colour()

func _tick_the_member(delta: float) -> void:
	_clock += delta
	_jolt = maxf(0.0, _jolt - delta)

## How finely the redraw key reads a car's own live heading: each component of the unit vector to
## the nearest hundred-and-twenty-eighth. That is at most 1/256 of error per component, so the
## anchor it decides — `26·|heading.y| + 14·|heading.x|`, whose steepest term is the 26 —
## can be held back by at most `(26 + 14) / 256`, about a sixth of a world pixel, and the shadow
## capsule's own axis by about a quarter of a degree. Nothing a screen can show at any zoom the game
## uses is ever frozen waiting for a step.
##
## **A car in a lane costs nothing for it.** `heading()` there is exactly `(±1, 0)` or `(0, ±1)` —
## built from `_direction` rather than integrated from a float — so the key is the same value every
## tick and no redraw is asked for, which is the whole of what the gate is for. Only the seconds a
## car is actually on an arc pay, and that is a handful of cars on the busiest street.
const CAR_HEADING_STEPS := 128.0

## The continuous half of the redraw key — see `_redraw_if_the_picture_changed()`. A walker answers
## `Vector2i.ZERO` and means it: nothing in the walker branch of `_draw_body()` reads a heading, so
## there is no continuous term for its own key to carry.
func _drawn_heading_key() -> Vector2i:
	if kind != Kind.CAR:
		return Vector2i.ZERO
	return Vector2i((heading() * CAR_HEADING_STEPS).round())

## Excitement per second this agent contributes at a point. Same falloff as an event, so
## the crowd and the events are the same kind of quantity to the baby — and the same kernel too:
## `GroundShape.eccentric_distance()`, eccentric while moving and the plain distance a disc always
## used the instant it stops, off `velocity()` rather than a shape of its own — a crowd body is
## always a point in field terms (see `GroundShape`'s class doc on why nobody builds the general
## capsule-and-ellipse sum), so there is no body to set aside the way a stationary event's is.
##
## The jolt is added on top of the body's ordinary noise rather than replacing it, and it
## fades linearly over its own duration — so a bump is a spike with a tail rather than a step
## that ends abruptly, and two people bumped in the same second cost twice. **The same distance
## prices both** — the horn or the bump is the same source being louder, not a second one.
## **Not cached the way `EventInstance.contribution_at()` now is.** *(docs/DECISIONS.md, M124:
## per-frame audit.)* A per-`_clock` cache was tried and reverted: unlike an event, whose own
## motion and telegraph state only ever change inside its own `_process()` alongside `age`, a
## crowd agent's position and jolt are written from **outside** it — `Crowd._bump()` and
## `Crowd._horn()` call `startle()` and move an agent mid-tick, from `Crowd`'s own step rather than
## this agent's `_process()` — so a cache keyed on `_clock` could answer with the jolt or the
## position from before the bump that tick, the one frame a fresh startle is supposed to show up
## on. `tests/test_crowd.gd`'s own `_test_walking_into_somebody_displaces_and_startles_them` reads
## `contribution_at()` again immediately after a bump with `_clock` unmoved and expects the fresh
## jolt, which is exactly the case a clock-keyed cache would have answered stale.
##
## **Nothing reaches her through a building**, the same rule an event's field keeps: a positive
## field is zero when `_walled_off()` says a building stands between this body and the point. The
## horn and a startled walker included — *(plaid-wombat, inbox #554: "Excitement should not go
## through any wall")* — since the jolt is this body being louder, not a second source. `walls`
## false answers the field alone, which is what the caret's projection asks before it asks about
## walls at the two bodies' own projected places. One function rather than a field function called
## from this one: every body in the crowd is asked this every frame, most of them out of reach, and
## a second call each is a cost paid by the whole crowd for the handful a wall could matter to.
func contribution_at(world_position: Vector2, walls := true) -> float:
	# d_eff = r * (1 - e * cos(theta)) is at least r * (1 - e_max), at every speed
	# and heading. Outside this bound both falloffs are zero, so the common distant-body
	# case needs no velocity/turn/pocket lookup or elliptical distance calculation. Read the
	# current jolt each time: a horn or an external bump can extend its reach between queries.
	var outer := Tuning.CAR_OUTER_RADIUS if kind == Kind.CAR else Tuning.PEDESTRIAN_OUTER_RADIUS
	if _jolt > 0.0:
		outer = maxf(outer, _jolt_outer)
	var reach := outer / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
	var origin := global_position
	if origin.distance_squared_to(world_position) > reach * reach:
		return 0.0
	var distance := GroundShape.eccentric_distance(origin, velocity(), world_position)
	var total := 0.0
	if kind == Kind.CAR:
		total = Tuning.falloff(distance, Tuning.CAR_INTENSITY,
				Tuning.CAR_INNER_RADIUS, Tuning.CAR_OUTER_RADIUS)
	else:
		total = Tuning.falloff(distance, Tuning.PEDESTRIAN_INTENSITY,
				Tuning.PEDESTRIAN_INNER_RADIUS, Tuning.PEDESTRIAN_OUTER_RADIUS)
	if _jolt > 0.0:
		total += Tuning.falloff(distance, _jolt_intensity * (_jolt / _jolt_for),
				_jolt_inner, _jolt_outer)
	if walls and total > 0.0 and _walled_off_now(origin, world_position):
		return 0.0
	return total

## Whether a building stands between this body at `body_at` and her at `her_at`, deep enough to
## keep its noise from her — `CityMap.wall_between()`, as `EventInstance._walled_off()` asks it.
## False with no map, which is every data-level rig built without one.
func _walled_off(body_at: Vector2, her_at: Vector2) -> bool:
	return _map != null and _map.wall_between(body_at, her_at)

## The grid `_walled_off()` asks, the city's map or `null` — read by the debug view's fields layer,
## which cuts this body's outline from its own position along the same lines
## (`DebugLayers.open_runs()`).
func wall_grid() -> CityMap:
	return _map

## The last line `contribution_at()` asked about and its answer, kept by value. The meter's sum,
## the halo's pick and the caret's present rate ask the same pair in a frame, and the answer
## depends on nothing but the two points and the map — a body moved from outside is a new key, so
## nothing here can answer stale the way a clock-keyed cache of the field would.
var _wall_from := Vector2.INF
var _wall_to := Vector2.INF
var _wall_map: CityMap = null
var _wall_answer := false

## `_walled_off()` through that one-line cache, for `contribution_at()` alone: the caret's
## projection asks a different pair at every step and would only push the frame's own pair out.
func _walled_off_now(body_at: Vector2, her_at: Vector2) -> bool:
	if body_at != _wall_from or her_at != _wall_to or _map != _wall_map:
		_wall_from = body_at
		_wall_to = her_at
		_wall_map = _map
		_wall_answer = _walled_off(body_at, her_at)
	return _wall_answer

## The furthest this agent's own field can currently reach — its ordinary outer radius, or the
## jolt's own if a jolt is running and reaches further, the way a car's `CAR_HORN_OUTER_RADIUS`
## (132px) reaches past its ordinary `CAR_OUTER_RADIUS` (104px), then grown forward by
## `Tuning.field_scale()` at the fastest this agent's own kind ever moves. What `expected_impact_at()`
## and `will_be_lethal()` both compare a projected approach against, so a source mid-jolt or
## mid-approach is not skipped early on a reach that no longer describes it — a car's own forward
## reach at `CAR_SPEED.y` (the top of its own speed range, not merely its current one) is the widest
## this agent's field can ever be, so the early-out has to be stated over that rather than over
## whatever it happens to be doing this frame.
##
## **Not `EventDef.field_reach()`'s business.** That one adds a segment's `half_length` back in for
## a stationary body; a crowd agent has no body in field terms — see `contribution_at()`'s own doc.
func _current_reach() -> float:
	var reach := Tuning.CAR_OUTER_RADIUS if kind == Kind.CAR else Tuning.PEDESTRIAN_OUTER_RADIUS
	if _jolt > 0.0:
		reach = maxf(reach, _jolt_outer)
	var top_speed := Tuning.CAR_SPEED.y if kind == Kind.CAR else Tuning.PEDESTRIAN_SPEED.y
	return reach * Tuning.field_scale(Tuning.field_eccentricity(top_speed))

## One bounded integral cache per source; effective inputs include externally written state.
var _expected_landed_key: Array = []
var _expected_landed_cache := 0.0

## The gross points this agent is anticipated to land over `Tuning.EXPECTED_IMPACT_HORIZON` if she
## and it both carry on exactly as they are, before her own decay is netted against it —
## `EventInstance.expected_gross_at()`'s own quantity, read here off `velocity()` instead of
## `travel_velocity()`. See that method for the full reasoning, `player_velocity`/
## `player_sensitivity` included; the reach test below skips anything the pair's own closing speed
## cannot cross inside the horizon without sampling it. Floored at zero, the same as the net it
## feeds: a source she is outrunning has nothing to share with the others `ExcitementHalo` is
## summing this frame.
func expected_gross_at(player_position: Vector2) -> float:
	var vel := velocity()
	var closing := player_velocity - vel
	var reach := closing.length() * Tuning.EXPECTED_IMPACT_HORIZON + _current_reach()
	if global_position.distance_to(player_position) > reach:
		return 0.0
	if vel.is_zero_approx() and player_velocity.is_zero_approx():
		return 0.0
	var current_rate := contribution_at(player_position)
	# Velocity includes turns, yielding, door holds and pockets. Read it and every jolt value
	# afresh: the crowd can move/startle this body without advancing its own clock.
	var key := [global_position, player_position, player_velocity, vel, kind,
		_jolt, _jolt_for, _jolt_intensity, _jolt_inner, _jolt_outer]
	if key != _expected_landed_key:
		_expected_landed_cache = _sample_expected_landed(player_position, vel)
		_expected_landed_key = key
	var gross := _expected_landed_cache - current_rate * Tuning.EXPECTED_IMPACT_HORIZON
	return maxf(gross * player_sensitivity, 0.0)

## The future samples alone are reusable; current contribution, sensitivity and the net's
## shared decay are still evaluated for each request. Tuning inputs are immutable constants.
func _sample_expected_landed(player_position: Vector2, vel: Vector2) -> float:
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	var integral := 0.0
	for i in steps:
		# The field translates; a wall does not. So the wall is asked between the two bodies'
		# own projected places, where a building actually stands, never at the translated point.
		var t := float(i + 1) * dt
		var rate := contribution_at(player_position + player_velocity * t - vel * t, false)
		if rate > 0.0 and _walled_off(global_position + vel * t, player_position + player_velocity * t):
			rate = 0.0
		integral += rate * dt
	return integral

## The net points this agent is anticipated to add to the bar over `Tuning.EXPECTED_IMPACT_HORIZON`
## — `expected_gross_at()` less her own decay over the same horizon.
##
## **Shared with every other source worth a mark when `ExcitementHalo` is driving the frame,
## charged against this agent alone otherwise.** `player_expected_total_gross` is `-1.0` for any
## caller that has not told this agent the frame's total — a data-level test among them — and the
## decay nets whole against this agent exactly as it always did; `ExcitementHalo` sets it once a
## frame to the sum of every live candidate's own `expected_gross_at()`, and this agent's own share
## of the decay then follows `ExcitementHalo.net_landed()`'s own arithmetic, forward instead of
## back — see `EventInstance.expected_impact_at()`'s doc for why summing that share across every
## source it was taken from reproduces the bar's own projected rise exactly, not approximately.
func expected_impact_at(player_position: Vector2) -> float:
	var gross := expected_gross_at(player_position)
	if gross <= 0.0:
		return 0.0
	var decay := player_decay_rate * Tuning.EXPECTED_IMPACT_HORIZON
	if player_expected_total_gross >= 0.0:
		return ExcitementHalo.net_landed(gross, player_expected_total_gross, decay)
	return maxf(gross - decay, 0.0)

## Whether this car's own strike box reaches her at some point before
## `Tuning.EXPECTED_IMPACT_HORIZON`, on its current course, her position held fixed — a car's
## equivalent of `EventInstance.will_be_lethal()`, over the same rectangle `Crowd._strike()` tests
## for the actual collision: the car's front half, from its centre forward. Never true for a
## walker: nothing about a pedestrian ends the day, and never true for a car already too slow to strike at all (`Crowd._strike()`'s own guard).
func will_be_lethal(player_position: Vector2) -> bool:
	if kind != Kind.CAR or _speed < Tuning.CAR_STRIKE_MIN_SPEED:
		return false
	var vel := velocity()
	var forward := heading()
	var side := Vector2(-forward.y, forward.x)
	var offset := player_position - global_position
	if absf(offset.dot(side)) > Tuning.CAR_STRIKE_HALF_WIDTH:
		return false
	# The box is the car's front half, 26px long, and a fast car covers more than that between
	# two samples, so the question is answered on the line rather than by stepping: the car
	# closes on her at `closing` px/s along its heading, and she is struck when the distance
	# ahead of its centre falls into [0, CAR_STRIKE_HALF_LENGTH] within the horizon.
	var ahead := offset.dot(forward)
	if ahead < 0.0:
		return false
	var closing := vel.dot(forward)
	if closing <= 0.0:
		return ahead <= Tuning.CAR_STRIKE_HALF_LENGTH
	return (ahead - Tuning.CAR_STRIKE_HALF_LENGTH) / closing <= Tuning.EXPECTED_IMPACT_HORIZON

## Duck-typed with `EventInstance`'s own copy — see `ExcitementHalo`'s class doc. `points` is not
## recomputed here: `Baby._update_excitement()` traces it back from the meter's own sum as this
## agent's exact share of what landed this frame, so an ordinary walker's colour and a honking
## car's colour both come from the same place a bump or a horn ever reached the meter at all.
## Stamped with `_clock`, this agent's own simulation clock, rather than the wall clock, so a
## paused game does not empty the halo and a rig can measure the window on simulated time.
func accumulate_landed(points: float) -> void:
	_prune_landed_history()
	if points > 0.0:
		_landed_history.append([_clock, points])

## The sum of every entry still inside `ExcitementHalo.WINDOW`. Pruned here too, not only on
## write, so an agent nobody has visited in a while reports honestly the moment it is asked.
func landed() -> float:
	_prune_landed_history()
	var total := 0.0
	for entry in _landed_history:
		total += entry[1]
	return total

func _prune_landed_history() -> void:
	var cutoff := _clock - ExcitementHalo.WINDOW
	while not _landed_history.is_empty() and _landed_history[0][0] < cutoff:
		_landed_history.pop_front()

## Startles this agent for `seconds`. The only way anything outside the crowd adds excitement
## to the world, and it deliberately adds it to a *body* rather than to the baby.
func startle(intensity: float, seconds: float, inner: float, outer: float) -> void:
	# Never shortens an agitation already running: a second bump on top of the first must not
	# be able to make the first one quieter.
	if _jolt > 0.0 and intensity * seconds < _jolt_intensity * _jolt:
		return
	_jolt = seconds
	_jolt_for = seconds
	_jolt_intensity = intensity
	_jolt_inner = inner
	_jolt_outer = outer

## True while this agent is agitated, so the same contact is not written down twice.
func is_startled() -> bool:
	return _jolt > 0.0

## The jolt's own inner and outer radii, valid only while `is_startled()` — read by `DebugLayers`
## so its fields layer can draw the extra field a running jolt adds on top of this agent's ordinary
## one, the same pair `contribution_at()` sums in.
func jolt_radii() -> Vector2:
	return Vector2(_jolt_inner, _jolt_outer)

## Forwards to `_halo`'s own `set_glow()` — see `EntityHalo`'s class doc for the duck-typed shape
## `EventInstance` shares. Called by `ExcitementHalo` once a frame for every agent in the crowd —
## nonzero for the handful `select_sources()` picked, zero for everything else. Builds `_halo`
## lazily on first use, rather than paying for an `EntityHalo` on every agent the crowd ever holds,
## and frees it once `EntityHalo.is_faded_out()` says the fade is actually over — not the frame the
## target first reaches zero, or a burst that just left `MAX_SOURCES` would be cut off mid-fade
## instead of draining over `EntityHalo.FADE_OUT_SECONDS`. See `EntityHalo`'s class doc for the web
## renderer's ceiling that this lifetime, and `ExcitementHalo`'s budget, keep under.
func set_halo_strength(strength: float, colour: Color) -> void:
	if strength <= 0.0:
		if _halo:
			_halo.set_glow(0.0, colour)
			if _halo.is_faded_out():
				release_halo()
		return
	if not _halo:
		_halo = EntityHalo.new(_draw_body, _body_bob)
		add_child(_halo)
	_halo.set_glow(strength, colour)

## Whether this agent holds a rim right now, lit or still fading — what `ExcitementHalo` counts
## against `EntityHalo.RIM_BUDGET`.
func holds_a_halo() -> bool:
	return _halo != null

## Frees the rim on the spot rather than through `queue_free()`, so its block in the web renderer's
## instance buffer is free before any rim built later this frame asks for one — see
## `EntityHalo.release()`. The same pair `EventInstance.release_halo()` is.
func release_halo() -> void:
	if _halo:
		EntityHalo.release(_halo)
		_halo = null

## The lift this agent's body rides right now, the `bob()` `EntityHalo` asks every owner for: a
## walker's is zero, since its stride is two frames rather than a lift; a car's is `WheelBob.lift()`
## over the ground it has covered, at full height from `CAR_BOB_FULL_SPEED` up and fading to
## nothing as it slows, so a car braking to a light settles onto its wheels rather than freezing
## mid-rise, and a stopped car sits still. `_draw()` lifts the whole drawing by it and
## `_draw_body()` draws the wheels and the shadow back down by it, which is what lets the halo's
## ring ride the same lift and trace the body where it is drawn.
func _body_bob() -> float:
	if kind != Kind.CAR:
		return 0.0
	return WheelBob.lift(_car_travelled, velocity().length() / CAR_BOB_FULL_SPEED)

## The speed a car's bob reaches its full height at: a car in a turn and every car cruising down a
## lane bob fully, and only a car braking below it settles.
const CAR_BOB_FULL_SPEED := Tuning.CAR_TURN_SPEED

## How finely the redraw key reads a car's bob: a quarter of a world pixel, half a screen pixel at
## the camera's zoom. A car in a lane changes nothing else about its picture from one frame to the
## next, so this is the step it redraws on while it is moving, and a stopped one never does.
const CAR_BOB_STEPS_PER_PX := 4.0

## Advances `_car_travelled` by the ground this car covered this tick. Called once from
## `_process()`, never from the drawing, which a halo ring calls several times a frame — the same
## rule `_advance_walker_gait()` states for the walker's stride.
func _advance_car_bob(delta: float) -> void:
	_car_travelled = wrapf(_car_travelled + velocity().length() * delta, 0.0, WheelBob.WAVELENGTH)

## This car has hit another one in a junction. It stops dead and sounds off, and then pulls away
## again on its own — `_cruise` is untouched, so recovery is the ordinary acceleration.
##
## The startle is what makes it *loud where it happened* rather than a number written at the baby;
## see `Crowd._collide_in_the_box` for why a collision is this and not a catalogue row. Already
## being startled is enough to skip it, which is the same hysteresis a contact uses: a pair sitting
## inside each other for half a second must cost one crash, not thirty.
func crashed_into() -> void:
	if _jolt > 0.0:
		return
	_speed = 0.0
	startle(Tuning.CAR_HORN_INTENSITY, Tuning.CAR_HORN_DURATION * 2.0,
			Tuning.CAR_HORN_INNER_RADIUS, Tuning.CAR_HORN_OUTER_RADIUS)

# ---------------------------------------------------------------- drawing ---

## The sector each kind is currently drawn in — `EightDirection`'s own indexing, clockwise from
## east — persisted across frames so `_update_walker_view()`/`_update_car_view()` can hold it
## through the boundary and hysteresis `EightDirection.update()` applies. A walker and a car keep
## separate fields because they read different headings: a walker's is `_walker_heading()`'s
## along-plus-cross blend, a car's is `velocity()` alone.
var _walker_view := 2
var _car_view := 2

## A walker's stride, in the same units `Stroller._walk_phase` uses: wrapped 0..TAU, advanced by
## distance actually covered (`_advance_walker_gait()`) rather than by time, so it stays in step
## at any speed the way the mother's own does. Cars have no gait; only a walker reads this.
var _walker_gait_phase := 0.0

## How much ground this car has covered, wrapped to one `WheelBob.WAVELENGTH`, which is the phase
## of the rise and fall its body rides over its wheels. Advanced by distance actually covered
## (`_advance_car_bob()`), once per tick, the same way `_walker_gait_phase` is. A walker never
## reads it.
var _car_travelled := 0.0

## Radians of gait per pixel walked. `Stroller._physics_process()` advances `_walk_phase` at the
## identical rate, so the crowd and the player share one stride length per pixel covered — and
## `_stride_seconds()` reads it back to price a stride as a distance.
const WALKER_GAIT_RATE := 0.09

## Below this speed a walker's own applied heading (`_walker_heading()`) is too close to zero to
## mean a facing, so it holds whatever it was last drawn as rather than chattering on the residual
## few px/s `WalkerStrategy._yield_factor()` and float noise can still leave in it. Well under
## `Tuning.PEDESTRIAN_SPEED`'s own floor (46px/s), so only an actually-stopped walker — a give-way,
## a queue, a halt — ever reads as idle.
const WALKER_IDLE_SPEED := 5.0

## The same hold for a car. `velocity()` is `heading()` — always unit length, cardinal in a lane or
## the tangent of an arc mid-turn — times the actual speed, so a car braked to a stop reads as a
## zero heading rather than whatever axis it last pointed along. Well under
## `Tuning.CAR_STRIKE_MIN_SPEED` (20px/s, the floor below which a car cannot strike anybody) and far
## under `Tuning.CAR_SPEED.x` (130px/s), so only a car actually stopped — a light, a gate, a
## give-way — ever reads as idle.
const CAR_IDLE_SPEED := 5.0

## Which of `EightDirection`'s eight sectors the agent is showing, advanced here for whichever kind
## it is — `_process()` already calls `_frame()` once every physics tick, so this is where the
## hold actually runs rather than in a second per-frame hook. Calling it again — `_draw_body()`'s
## own call, and every halo ring atop that — is safe: asking `EightDirection.update()` twice with
## the same starting sector and the same heading always answers the same way.
func _frame() -> int:
	if kind == Kind.CAR:
		_update_car_view()
		return _car_view
	_update_walker_view()
	return _walker_view

func _flipped() -> bool:
	return EightDirection.is_mirrored(_car_view if kind == Kind.CAR else _walker_view)

## The walker's own instantaneous heading this frame: its along-lane velocity (`velocity()`, the
## actual-motion quantity M111's own turning work already reads elsewhere) plus whatever its
## steering is doing across the lane right now — the term `_frame()`'s old lane-axis-only version
## never had, and the one that swings a walker rounding a corner, or nudged aside by
## `step_aside()`, onto a diagonal view a moment before its lane assignment itself turns. The
## cross term is `_set_cross()`'s own target (`_lane_centre + _detour`) minus where it actually is,
## signed and capped at `STEER_SPEED` — the rate `_process()`'s own `move_toward` steers at while
## it has not yet arrived. Zero once it has arrived with no detour running, which a stopped walker
## (give-way, queue, halted) always has, since `WalkerStrategy._yield_factor()` also zeroes the along term then.
func _walker_heading() -> Vector2:
	return _walker_heading_at(velocity())

## `_walker_heading()` for a `velocity()` the caller already holds.
func _walker_heading_at(along: Vector2) -> Vector2:
	var cross_gap := _lane_centre + _detour - _cross()
	if is_zero_approx(cross_gap):
		return along
	var cross_speed := signf(cross_gap) * STEER_SPEED
	return along + (Vector2(cross_speed, 0.0) if _vertical else Vector2(0.0, cross_speed))

## Advances `_walker_view` for this frame. `setup()` and `_recycle()` place a walker with no
## cross-lane steering yet running (`_set_cross(_lane_centre)`, `_forget_the_detour()`), so
## `_walker_heading()` right after either is always exactly along the new lane axis — a sector
## centre 45° clear of its neighbours, twice the hold's own 27.5° reach — and the ordinary test
## below already replaces whatever sector was drawn before without a special reset call into
## either function. Both are owned by the concurrent lane-turning work on this file (see the class
## doc), which is the other reason this reaches for the plain hold here rather than a call added
## to either placement.
func _update_walker_view() -> void:
	_walker_view = EightDirection.update(_walker_view, _walker_heading(), WALKER_IDLE_SPEED)

## Advances the walker's stride by how far it actually travelled this tick — `velocity()`, the
## along-lane speed the crowd already stops to zero at a give-way, a queue or a light, the same
## quantity `_current_reach()` and `contribution_at()` read. Called once from `_process()` rather
## than from `_draw_body()`/`_walker_gait_frame()`, which a halo ring calls several times a frame:
## unlike the sector hold above, adding a distance is not idempotent, so it must run once per tick
## or a walker with three halo rings would stride three times as fast as one with none.
## `Stroller._physics_process()`'s own `_walk_phase` uses the identical 0.09 rate, so the crowd and
## the player share one stride length per pixel walked.
func _advance_walker_gait(delta: float) -> void:
	_walker_gait_phase = wrapf(_walker_gait_phase + velocity().length() * delta * WALKER_GAIT_RATE,
			0.0, TAU)

## Which of the walker's two gait frames to draw right now: frame 1 (feet passing) for half of
## every stride while actually moving, frame 0 (the rest pose) otherwise — `Stroller._draw_mother()`'s
## own `stepping` test, read here off `WALKER_IDLE_SPEED` instead of the mother's own small gait
## floor, since a walker already has that threshold for exactly "is this body actually moving".
func _walker_gait_frame() -> int:
	return _walker_gait_frame_at(velocity())

## `_walker_gait_frame()` for a `velocity()` the caller already holds.
func _walker_gait_frame_at(along: Vector2) -> int:
	if along.length() <= WALKER_IDLE_SPEED:
		return 0
	return 1 if sin(_walker_gait_phase * 2.0) > 0.0 else 0

## Advances `_car_view` for this frame. **There is no cross term the way a walker has one**: a
## car's own `velocity()` already is its instantaneous line of travel — cardinal in a lane, the
## tangent of its own arc mid-turn (`heading()`) — so the sector runs through the diagonal for
## exactly the length of a turn and holds at whichever cardinal or diagonal it last pointed while
## the car is at or under `CAR_IDLE_SPEED`. `setup()` and `_recycle()` place a car with no turn
## running and its heading exactly on a lane axis — a sector centre 45° clear of its neighbours,
## twice the hold's own reach — so the ordinary update below already replaces whatever sector was
## drawn before, the same "no reset call needed" property `_update_walker_view()` documents for the
## walker.
func _update_car_view() -> void:
	_car_view = EightDirection.update(_car_view, velocity(), CAR_IDLE_SPEED)

func _draw() -> void:
	if FrameRecord.on:
		FrameRecord.drew(FrameLedger.DRAWS_CROWD)
	# `--skip crowd`'s own probe (docs/DECISIONS.md, M124, "the desktop half", row (d)): returns
	# before anything is drawn, so a frame under the flag differs from an ordinary one by drawing
	# alone — the crowd's own motion, lanes and traffic negotiation keep running. `_draw_body()` is
	# left alone rather than gated itself, since `EntityHalo` calls it too for a picked agent's own
	# ring, which is a different drawing than the ordinary frame this flag measures.
	if skip_draw:
		return
	# Told to `Sprites` as well as to the canvas, for the reason `EventInstance._draw()` gives: the
	# mirror inside `draw_standing()` sets an absolute matrix, so a west-facing car not handed the
	# lift would drop it.
	var bob := _body_bob()
	var lift := Transform2D(0.0, Vector2(0.0, bob))
	Sprites.set_base_transform(lift)
	draw_set_transform_matrix(lift)
	_draw_body(self)
	Sprites.set_base_transform(Transform2D.IDENTITY)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if kind == Kind.CAR:
		_draw_mark()

## Draws this agent's own body onto `canvas`. `EntityHalo` calls this once per ring offset to
## trace whichever silhouette the sprite actually is; the ordinary frame draws it once at self.
##
## **Both callers have already lifted the canvas by `_body_bob()`**, so what stays on the ground —
## a car's wheels and its shadow — is drawn back down by the same amount here, and the body and the
## trim are drawn where the lift puts them. That split is the whole of the bob: the wheels never
## move, the paint and the glass above them rise and fall about a pixel.
##
## **Reads `AtlasLibrary.region()`, which is null with an engine error the moment `crowd` is not
## acquired.** `Crowd.start_day()` acquires it before an agent exists to draw and `Crowd.clear()`
## releases it once every agent is freed, so nothing here has a lifetime of its own to manage —
## see the class doc on `Crowd` for why the owner holds one reference for the whole day rather
## than every agent acquiring for itself.
func _draw_body(canvas: CanvasItem) -> void:
	var frame := _frame()
	var flip := _flipped()
	if kind == Kind.CAR:
		var forward := _travel_axis()
		var grounded := Vector2(0.0, -_body_bob())
		_draw_shape_shadow(canvas, shape, grounded, forward)
		var view: String = CAR_VIEW_BY_SECTOR[frame]
		# The same heading the shadow above and the debug view's bounding box are drawn on, so the
		# picture cannot register against a car that is not there — see `_car_body_anchor()`.
		var anchor := _car_body_anchor(view, forward)
		var body := AtlasLibrary.region(_region_of(CAR_BODY_BY_VIEW[view]))
		var trim := AtlasLibrary.region(_region_of(CAR_TRIM_BY_VIEW[view]))
		var wheels := AtlasLibrary.region(_region_of(CAR_WHEELS_BY_VIEW[view]))
		Sprites.draw_standing(canvas, body, anchor, Vector2.ZERO, flip, colour)
		Sprites.draw_standing(canvas, trim, anchor, Vector2.ZERO, flip)
		# Last, as they were when they were part of the trim: each tyre is drawn over the paint.
		Sprites.draw_standing(canvas, wheels, anchor + grounded, Vector2.ZERO, flip)
		return
	_draw_shape_shadow(canvas, shape, Vector2.ZERO, Vector2.RIGHT)
	var view: String = WALKER_VIEW_BY_SECTOR[frame]
	# One lookup decides both layers, so the coat and the legs can never show two different
	# instants of the same stride.
	var stepping := _walker_gait_frame() == 1
	var body_paths: Dictionary = WALKER_BODY_BY_VIEW_B if stepping else WALKER_BODY_BY_VIEW
	var trim_paths: Dictionary = WALKER_TRIM_BY_VIEW_B if stepping else WALKER_TRIM_BY_VIEW
	var body := AtlasLibrary.region(_region_of(body_paths[view]))
	var trim := AtlasLibrary.region(_region_of(trim_paths[view]))
	# The body is tinted per agent (`colour`, `_colour()`'s "authored near-white and multiplied");
	# the trim above it draws at `Sprites.draw_standing()`'s own default `Color.WHITE` — the split
	# that keeps a crowd from reading as one silhouette in one colour. Two separate baked regions
	# rather than one, so tinting one never touches the other's own pixels.
	Sprites.draw_standing(canvas, body, Vector2.ZERO, Vector2.ZERO, flip, colour)
	Sprites.draw_standing(canvas, trim, Vector2.ZERO, Vector2.ZERO, flip)

## How much empty canvas each authored view leaves below its own drawn content, in px — read off
## `facings.csv`'s alpha bounds (`docs/evidence/svg-vehicles-2026-09-10/facings.csv`, the `car`
## rows): the two diagonals draw to y40 of a 42-tall canvas and front/back to y44 of a 46-tall one,
## while the side view's own content touches the bottom row. The anchor below adds it back, so what
## lands on the ground line is the drawn corner rather than the empty edge above it.
const CAR_CANVAS_BOTTOM_MARGIN := {
	"front": 2.0,
	"back": 2.0,
	"side": 0.0,
	"front_diagonal": 2.0,
	"back_diagonal": 2.0,
}

## Where a car's own body texture is anchored for `Sprites.draw_standing`. `draw_standing` always
## bottom-centres a texture at the point it is given, and every one of the five authored views is a
## standing elevation whose bottom row is the car's **nearest ground contact** — the part of its
## footprint closest to the camera. So there is one registration rule for the whole family, and it
## is stated over the heading rather than per view:
##
## > the drawn content's bottom edge lands on the southernmost point of the car's body.
##
## That body is `Tuning.CAR_STRIKE_HALF_LENGTH` (26) by `CAR_STRIKE_HALF_WIDTH` (14), centred on the
## node and rotated onto the heading, so its southern reach is `26·|heading.y| + 14·|heading.x|` —
## 26 pointed along a vertical lane, 14 along a horizontal one, `(26 + 14)/sqrt(2)` ≈ 28.28 at
## exactly 45 degrees, and every value between while a car is on an arc.
##
## **Read off the live heading rather than off the quantised view, because a turn is continuous and
## the eight views are not.** `EightDirection` swaps the texture at a sector boundary; if the anchor
## swapped with it the body would jump the whole difference between two views' ground lines in one
## frame, which is what a turning car was doing — and the same arithmetic keeps the shadow capsule,
## the debug view's bounding box and the picture travelling together for the whole manoeuvre
## instead of the first two rotating while the third sat still and then leapt. A standing car's
## heading is exactly cardinal, so this is an exact value there and nothing about a car in a lane
## depends on a texture's own axis.
##
## **Because it is read off the heading, the redraw gate has to read the heading too.** This is one
## of the two continuous terms `_redraw_if_the_picture_changed()`'s key carries; keyed on the
## quantised view alone, a car that has turned keeps the anchor it had at the last sector boundary
## and its picture sits south of its own body for the rest of its run.
func _car_body_anchor(view: String, forward: Vector2) -> Vector2:
	var south_reach := Tuning.CAR_STRIKE_HALF_LENGTH * absf(forward.y) \
			+ Tuning.CAR_STRIKE_HALF_WIDTH * absf(forward.x)
	return Vector2(0.0, south_reach + float(CAR_CANVAS_BOTTOM_MARGIN[view]))

## The car's own along-track length and across-track width for the shadow capsule below — fixed
## constants rather than read off a texture. This used to take the side view's own width for the
## along measurement and the end view's for the across one straight off `CAR_BODY[1]`/`CAR_BODY[0]`;
## the side view (`car_side_body.svg`) is still 52px wide and still that same along-track
## measurement, and 30px is the same across-track measurement the old end view carried, now pinned
## here directly. Reading it off a texture again would mean reading it off one of the five standing
## views' own width, which no longer has to agree with this number the way the old two-slot table's
## did by construction — pinning it is what stops a binding a picture cannot resize.
const CAR_SHADOW_ALONG := 52.0
const CAR_SHADOW_ACROSS := 30.0

## A car's own shadow shape — a capsule along its travel axis, sized from `CAR_SHADOW_ALONG`/
## `CAR_SHADOW_ACROSS` rather than a hand-picked radius: `radius` is half the across measurement and
## `half_length` is what is left of half the along once the two end caps are accounted for.
##
## **No body for a car.** A car's lethality is `TrafficIndex`'s, not a field's, and a `StaticBody2D`
## here would change the crowd's own collision rules rather than only how it looks — see
## docs/EVENTS.md and the **crowd-traffic** skill on why separation between bodies is positional,
## never a shape a car could get pinned against. This shape exists for the shadow alone.
static func _car_shadow_shape() -> GroundShape:
	var radius := CAR_SHADOW_ACROSS * 0.5
	return GroundShape.segment(CAR_SHADOW_ALONG * 0.5 - radius, radius)

## Which way this car is travelling, on the ground plane — the axis its shadow's capsule sweeps
## along. `heading()` is already continuous — cardinal in a lane, the tangent of its own arc
## mid-turn — so the capsule, and through `travel_axis()` below the debug view's own shadow layer,
## rotates with the turn instead of snapping between two axes at the moment one starts or ends.
func _travel_axis() -> Vector2:
	return heading()

## `_travel_axis()`, read by `DebugLayers` so its shadow layer rotates a car's capsule the same way
## `_draw_body()` already does, rather than a second guess at which axis this agent is travelling
## along.
func travel_axis() -> Vector2:
	return _travel_axis()

## The drop shadow under this agent's own `shape`, skipped for its own halo ring — the same rule
## `EventInstance._draw_shape_shadow` has, for the same reason: the shadow is the ground under the
## thing, not the thing, and a cue for what is charging her right now has nothing to say about it.
func _draw_shape_shadow(canvas: CanvasItem, shape: GroundShape, at: Vector2, axis: Vector2) -> void:
	if canvas == _halo:
		return
	shape.draw_shadow(canvas, at, axis)

## The caret's own answer for this car, 0 (none), 1 (amber) or 2 (doubled red), cached against
## `_clock` for the same reason `EventInstance._caret_strength()` caches against `age`: `_draw()`
## and `_process()`'s own redraw-forcing check below both ask in the same frame, and each is a
## fresh sampling loop over `expected_impact_at()` or `will_be_lethal()` if they do not share one.
var _mark_strength_clock := -1.0
var _mark_strength := 0

func _caret_strength() -> int:
	if _mark_strength_clock == _clock:
		return _mark_strength
	_mark_strength_clock = _clock
	_mark_strength = 0
	if player_at != Vector2.INF:
		if will_be_lethal(player_at):
			_mark_strength = 2
		elif expected_impact_at(player_at) >= Tuning.EXPECTED_IMPACT_POINTS:
			_mark_strength = 1
	return _mark_strength

## The caret over a car, in the same two strengths `EventInstance` draws.
##
## The vocabulary's first row is *the entity itself carries most of it*, and the traffic is the
## easiest place to leave that undone: the caret is drawn by `EventInstance` and a car is not an
## event, so without this a lethal thing bearing down on the player produces a mark over **her**
## head and nothing anywhere else — the load-bearing cue paying for a warning it should only be
## adding to.
##
## **The honk is a consequence of this, not the rule it follows.** `Crowd._horn()` still sounds and
## still startles — that is what makes the jolt in `swell` below real noise on a real body — but a
## car projected onto her without ever coming close enough to trigger `_horn()`'s own tighter
## proximity gate is marked all the same: a car whose lane she is standing in is projected into
## her, on its current course, whether or not it has honked yet.
##
## Doubled and in `MARK_LETHAL` exactly when `will_be_lethal()` says the strike box reaches her,
## because a car is exactly as lethal as a `hard_fail` event and being told apart by hue is what
## the doubling exists to avoid. **Breathes with the horn's own decay while one is running** —
## the one thing a ring does that a discrete symbol does not get for free — and holds full size
## the rest of the time, since a projected approach with no jolt running has no envelope of its
## own to breathe with.
func _draw_mark() -> void:
	var strength := _caret_strength()
	if strength <= 0:
		return
	var swell := (_jolt / _jolt_for) if _jolt > 0.0 else 1.0
	var scale := 0.55 + 0.45 * swell
	var at := Vector2(0.0, -(MARK_HEIGHT + 10.0 * swell))
	var colour := Palette.MARK_LETHAL if strength == 2 else Palette.MARK_COSTLY
	Sprites.draw_caret(self, at, MARK_WIDTH * scale, colour)
	if strength == 2:
		Sprites.draw_caret(self, at - Vector2(0.0, MARK_WIDTH * scale * 0.85),
				MARK_WIDTH * scale, colour)

## The coat, or the paintwork. Authored near-white and multiplied, the same trick the
## buildings use, so a crowd is not one silhouette in one colour ninety times over.
func _colour() -> Color:
	var palette := Palette.CAR_PAINT if kind == Kind.CAR else Palette.COATS
	return palette[_rng.randi_range(0, palette.size() - 1)]

## How far this kind's own drawn picture reaches past `_along()`, along this axis, in the
## direction a plain edge lies — read off the baked region's own native size and the same anchor
## arithmetic `_draw_body()`/`_car_body_anchor()` use, not a guessed number, because "the whole
## picture inside the map" means exactly what `_draw_body()` puts on screen. `native_size()`
## answers from the region table with nothing acquired, which matters here: a placement roll in
## `setup()` asks this before `Crowd.start_day()`'s own acquire needs to have happened.
##
## **`entry_room()` grants room past the true edge; this grants none, and states what "none" has
## to mean instead.** A walker or an off-spine car's `entry_room()` is 0.0 — no room *past* the
## line — but a centre sitting exactly on the line still has a picture straddling it, since
## `Sprites.draw_standing` anchors a walker's whole canvas bottom-centred on its own position: the
## height rises entirely to the north of it and nothing at all to the south, so a walker's picture
## overhangs a north edge by its full canvas height and a south edge by nothing. A car's canvas is
## anchored south of its own position by `_car_body_anchor()`'s own reach, so both overhangs are
## real and unequal there too. **The larger of the two is kept for both edges of the axis**, so one
## number clears whichever edge this placement is beside without the caller having to say which —
## conservative on the edge that needed less, never short on the one that needed more. Only the
## cardinal (`front`, `side`) views are asked, since a fresh entry never lands mid-turn.
func _entry_picture_clearance() -> float:
	if kind == Kind.CAR:
		if _vertical:
			var body := AtlasLibrary.native_size(_region_of(CAR_BODY_BY_VIEW["front"]))
			var south_reach := Tuning.CAR_STRIKE_HALF_LENGTH \
					+ float(CAR_CANVAS_BOTTOM_MARGIN["front"])
			return maxf(south_reach, float(body.y) - south_reach)
		var side := AtlasLibrary.native_size(_region_of(CAR_BODY_BY_VIEW["side"]))
		return float(side.x) * 0.5
	var walker := AtlasLibrary.native_size(_region_of(WALKER_BODY_BY_VIEW["front"]))
	return float(walker.y) if _vertical else float(walker.x) * 0.5

