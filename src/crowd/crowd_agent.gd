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
## `CarLook.BOB_STEPS_PER_PX` — the two things each kind draws that move without the sector moving.
##
## **This is the quantised half of what the drawing reads, and a car has a continuous half too** —
## `_drawn_heading` below. See `_end_the_frame()`.
var _picture := Vector3i(-1, -1, -1)
## The live heading a car's picture was last drawn at, quantised by `CarLook.HEADING_STEPS` — the other
## half of the redraw key. Always `Vector2i.ZERO` for a walker, whose drawing reads no heading at
## all: its own picture is the sector, the mirror and the gait frame and nothing else.
var _drawn_heading := Vector2i.ZERO
## Whether this car's own caret was up last frame, so it gets one redraw to come off with.
var _was_marked := false
## True while what this agent shows is not being kept current because none of it can be on the
## screen (`CrowdView.drawn_box()`), so the first frame it is back in the box redraws it whatever the key says.
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
## `_end_the_frame()` asks `CrowdView.drawn_box()` about. `ENTRY_PICTURE_ROOM` either side, and
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
## **And only while any of it can be on the screen** (`CrowdView.drawn_box()`, `DRAWN_REACH`). Most
## of the crowd is off screen, and those agents were most of the redraws and every car's caret
## projection; the key is still kept every frame, so nothing about the picture's own state depends
## on where the camera is, and an agent coming back into the box redraws once on that frame whatever
## the key says.
##
## **A term missing from the key is a frozen picture rather than a crash**, the same rule
## `EventLook.redraw_if_the_picture_changed()` states for the catalogue's own gate — so the key
## has to name every time-varying thing the look draws and not a plausible subset. A walker's
## drawing is the sector, the mirror and the gait frame, all three quantised (`AgentLook.picture()`).
## A car's third term is its body's bob instead, which moves on every frame it is driving while
## nothing else about a car in a lane does. **A car's drawing also reads its live heading, twice**:
## `CarLook.body_anchor()` registers the picture `26·|heading.y| + 14·|heading.x|` south of the
## node, and the shadow capsule sweeps along the same heading. Both are continuous through an arc
## while the sector is not, so `CarLook.heading_key()` carries the live heading too. A key made only
## of the quantised half leaves a car that has turned wearing the anchor and the shadow axis it last
## had at a sector boundary — up to 22.5 degrees back, which lands an east- or west-bound car's
## picture about nine pixels south of its own body for the rest of its run in that lane — while
## `EntityHalo`, which re-traces the body every frame it is drawn, stands where the car belongs.
func _end_the_frame(delta: float) -> bool:
	# The clocks only a crowd member keeps: its simulation clock, and the seconds of agitation a
	# contact or a horn left, run down here because every frame that is not skipped ends here.
	_clock += delta
	_jolt = maxf(0.0, _jolt - delta)
	var picture := _look.picture(velocity())
	var drawn_heading := _look.heading_key()
	var changed := picture != _picture or drawn_heading != _drawn_heading
	_picture = picture
	_drawn_heading = drawn_heading
	# Off screen nothing is redrawn and no caret is projected: the picture is left as it was, and
	# the first frame any of it (`DRAWN_REACH`) is back inside the box the screen shows
	# (`CrowdView.drawn_box()`) redraws it from what it is now, caret included, which is before the
	# margin has let any of it onto the screen. An agent with no view, or out of the tree, is always
	# drawn: a hand-built rig has no screen to be off.
	if view != null and is_inside_tree() \
			and not view.drawn_box().intersects(Rect2(global_position + DRAWN_REACH.position, DRAWN_REACH.size)):
		_picture_is_stale = true
		return false
	if changed or _picture_is_stale:
		_picture_is_stale = false
		# What this redraw puts up is the mark as it stands now — the same answer `_draw()` asks
		# for, cached against the clock — so a mark that drops on the next frame is taken off.
		_was_marked = _carets and _caret_strength() > 0
		queue_redraw()
		return true
	# A marked car draws a caret that can breathe with its own horn, and a projected approach
	# can change its strength frame to frame with nothing else about the picture moving. The
	# one frame after the mark comes down is what takes the caret off again.
	if _carets and (_caret_strength() > 0 or _was_marked):
		_was_marked = _caret_strength() > 0
		queue_redraw()
		return true
	return false

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
		_halo = EntityHalo.new(_look.draw_body, _look.bob)
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

## How this agent is drawn, installed with `kind`: a `WalkerLook` or a `CarLook`. Everything the
## drawing differs on between the two kinds asks it.
var _look: AgentLook

## Whether this agent's look is marked by a caret, kept here by `_kind_installed()` as a plain
## member because the redraw gate reads it every frame of every agent.
var _carets := false

func _init() -> void:
	super()
	_look = WalkerLook.new(self)

## A new kind brings its look; a walker's stride and a car's travelled ground start afresh with it.
func _kind_installed() -> void:
	_look = CarLook.new(self) if kind == Kind.CAR else WalkerLook.new(self)
	_carets = _look.carets()

func restart_the_picture() -> void:
	_look.restart()

func advance_the_picture(delta: float) -> void:
	_look.advance(velocity(), delta)

## The coat, or the paintwork. Authored near-white and multiplied, the same trick the buildings use,
## so a crowd is not one silhouette in one colour ninety times over.
func _dress() -> void:
	var palette := _look.palette()
	colour = palette[_rng.randi_range(0, palette.size() - 1)]

func _entry_picture_clearance() -> float:
	return _look.entry_clearance(_vertical)

## The drop shadow under this agent's own `shape`, skipped for its own halo ring — the same rule
## `EventLook._draw_shape_shadow` has: the shadow is the ground under the thing, not the thing,
## and a cue for what is charging her right now has nothing to say about it.
func draw_shadow(canvas: CanvasItem, at: Vector2, axis: Vector2) -> void:
	if canvas == _halo:
		return
	shape.draw_shadow(canvas, at, axis)

func _draw() -> void:
	if frame_timing != null and frame_timing.running():
		frame_timing.drew()
	# `--skip crowd`'s own probe (docs/DECISIONS.md, M124, "the desktop half", row (d)): returns
	# before anything is drawn, so a frame under the flag differs from an ordinary one by drawing
	# alone — the crowd's own motion, lanes and traffic negotiation keep running. `AgentLook.draw_body()` is
	# left alone rather than gated itself, since `EntityHalo` calls it too for a picked agent's own
	# ring, which is a different drawing than the ordinary frame this flag measures.
	if skip_draw:
		return
	# Told to `Sprites` as well as to the canvas, for the reason `EventLook.draw()` gives: the
	# mirror inside `draw_standing()` sets an absolute matrix, so a west-facing car not handed the
	# lift would drop it.
	var bob := _look.bob()
	var lift := Transform2D(0.0, Vector2(0.0, bob))
	Sprites.set_base_transform(lift)
	draw_set_transform_matrix(lift)
	_look.draw_body(self)
	Sprites.set_base_transform(Transform2D.IDENTITY)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _carets:
		_draw_mark()

## The caret's own answer for this car, 0 (none), 1 (amber) or 2 (doubled red), cached against
## `_clock` for the same reason `EventLook._caret_strength()` caches against `age`: `_draw()`
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
