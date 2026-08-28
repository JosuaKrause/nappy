class_name EventInstance
extends Node2D
## One live event in the world: its lifetime, its telegraph phase, its excitement field and
## its drawing.
##
## The excitement model is entirely a *query* — `contribution_at()`. Nothing pushes a value
## at the baby, so there is no ordering to get wrong, events compose by simple addition, and
## the whole thing is testable without a scene.

signal finished(instance: EventInstance)

const CAT_CROUCHED := preload("res://assets/events/cat_crouched.svg")
const CAT_RUNNING := preload("res://assets/events/cat_running.svg")
const PERSON := preload("res://assets/events/person.svg")
const VEHICLE := preload("res://assets/events/vehicle.svg")
const FLAME := preload("res://assets/events/flame.svg")
const BARRIER_SEGMENT := preload("res://assets/events/barrier_segment.svg")
const BARRIER_END := preload("res://assets/events/barrier_end.svg")
const CAFE_TABLE := preload("res://assets/events/cafe_table.svg")
const DOG := preload("res://assets/events/dog.svg")
const CYCLIST := preload("res://assets/events/cyclist.svg")
const STALL := preload("res://assets/events/stall.svg")
const LEAF_BLOWER := preload("res://assets/events/leaf_blower.svg")
const PIGEON := preload("res://assets/events/pigeon.svg")
const ICE_CREAM_VAN := preload("res://assets/events/ice_cream_van.svg")
const LORRY := preload("res://assets/events/lorry.svg")
const CHARGING_DOG := preload("res://assets/events/charging_dog.svg")

var def: EventDef
## Waypoints for a mobile event, in world space. Empty for a stationary one.
var path: PackedVector2Array = PackedVector2Array()

var age := 0.0
var is_finished := false

## Where the player is, in world space, or `INF` for nowhere.
##
## Written once per frame by `EventManager`, which is the one place that already knows. An instance
## looking her up itself would be thirty lookups a frame for one answer, and — more to the point —
## `EventInstance` has never had to know the player exists, and this keeps that true: it is handed
## a point, and everything it does with the point is a distance.
##
## Two things want it, and neither is a reference to her: a pursuer walks toward it, and anything
## that is *leaving* uses it to know when it is out of sight.
var player_at := Vector2.INF

## Facing, for art with a front and a back. Only a mobile event ever changes it.
var _heading := Vector2.RIGHT
var _path_travelled := 0.0
var _telegraph_announced := false
var _activation_announced := false

## `face` is where a *stationary* event was sited looking. A mobile one overwrites it from the
## direction it is travelling on its first step, which is why the default is harmless.
func setup(definition: EventDef, at: Vector2, route: PackedVector2Array = PackedVector2Array(),
		face := Vector2.RIGHT) -> void:
	def = definition
	path = route
	position = route[0] if route.size() > 0 else at
	_heading = face

func _ready() -> void:
	EventBus.event_telegraphed.emit(self)
	_telegraph_announced = true
	if def.obstructs_radius > 0.0:
		_build_obstruction()

## Some events are physically in the way. The body is a child so it travels with a mobile
## event and disappears with the instance.
func _build_obstruction() -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = def.obstructs_radius
	shape.shape = circle
	body.add_child(shape)
	add_child(body)

func _process(delta: float) -> void:
	if is_finished:
		return
	age += delta

	if not _activation_announced and not is_telegraphing():
		_activation_announced = true
		EventBus.event_activated.emit(self)

	if is_leaving:
		_leave(delta)
		queue_redraw()
		return

	if def.pursues:
		_chase(delta)
	elif def.mobile and path.size() > 1 and not is_telegraphing_still():
		_advance_along_path(delta)

	if _has_expired():
		_be_done()
	queue_redraw()

## Whether the chase ended because she shook it off rather than because the clock ran out. Read by
## the telemetry, which is the only thing that can tell the two apart from outside.
var gave_up := false
## Whether it ever got to its stand-off. See `_chase`.
var _engaged := false
## For a pursuer with `pursues_within`: the age at which she came close enough for it to take an
## interest, or `INF` while it is still only standing there. Its telegraph and its chase are both
## measured from here rather than from birth. See `is_waiting()`.
var _noticed_at := INF

## Comes after her. *(Playtest 07: running has to be right sometimes, and this is the shape of
## "sometimes".)* See `EventDef.pursues` and `Tuning.validate_pursuit`.
##
## **It comes through its own telegraph**, the way a fire engine does, and that is the whole of
## why a pursuer can force a run at all. A telegraph it spends standing still is a head start she
## can simply walk away with: at `pursue_speed` against `WALK_SPEED` it closes about 56px a
## second, so two seconds of politeness hands her more ground than the entire chase can take
## back. The notice is *the sight of it coming*, and `Tuning.PURSUIT_MIN_NOTICE` is how much of
## that she is owed before it is allowed to end her day.
##
## **But it closes to a stand-off and holds it, rather than arriving.** *(M35, playtest 08 finding
## 4: "I like the running tutorial on day 3 but I don't know how to solve it yet — I died every
## time.")* The paragraph above bought the notice in seconds and never asked *where* the dog spends
## them, and the trace answers that: sited across her line 184px ahead — which is where she was
## already walking — it closed the gap in three quarters of a second and then stood **inside its own
## lethal radius** for the remaining 1.7s of a telegraph that was not yet allowed to kill her. The
## moment it was, it did, from a standing start at 12px. Every line of `validate_pursuit` passed
## while that happened, because every line of it was about speeds and durations and a pursuit is
## played out in distances.
##
## `Tuning.pursuit_standoff()` is the same contract restated as one, and holding it is what makes
## the notice real from *any* approach geometry — including the one the director actually produces.
## And a pursuer may be a **place** before it is a moment. *(M36, playtest 09: "a robber should
## increase excitement on sight… and if you get close they should start moving towards you".)* While
## it is waiting it emits at full strength, is not lethal and does not move; `pursues_within` is
## where that stops. Everything below then runs exactly as it does for a dog sited in front of her —
## the notice, the stand-off and the break-off are the same three distances, started later.
func _chase(delta: float) -> void:
	if player_at == Vector2.INF or is_telegraphing_still():
		return
	var toward := player_at - global_position
	var range_to_her := toward.length()
	if range_to_her < 1.0:
		return
	if is_waiting():
		if range_to_her <= def.pursues_within:
			_noticed_at = age
			# It turns to face her on the frame it notices, which is the whole of the cue: a man who
			# was looking down the alley is now looking at you.
			_heading = toward.normalized()
		return
	_heading = toward.normalized()
	var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.inner_radius)
	_engaged = _engaged or range_to_her <= standoff + 4.0
	# **It gives up when it has been beaten**, which is two things and not one: it got to her and
	# she opened the gap again, or it never got near her in the first place. The second half is what
	# keeps the incentives the right way round — a player who turns and runs on the first frame is
	# never engaged, and gating the break-off on the lunge alone would charge her *more* for
	# reacting sooner, since she would be running through a telegraph that could not end.
	# `PURSUIT_MIN_NOTICE` is the floor under that: it may not lose interest before it has given
	# her the notice the contract owes, or a pursuit could be over before it was ever a threat.
	if (_engaged or chase_age() >= Tuning.PURSUIT_MIN_NOTICE) \
			and range_to_her > Tuning.PURSUIT_BREAK_OFF:
		gave_up = true
		_be_done()
		return
	# Straight at her, and no faster than its own speed: the contract is the speed, so nothing
	# here may quietly exceed it.
	var step := minf(def.pursue_speed * delta, range_to_her)
	if is_telegraphing():
		# **It keeps its distance and the lunge is the activation.** Closing to the stand-off and
		# then *holding* it — backing off if she walks into it, which she will, because it is sited
		# in front of her and forward is where she was already going. Clamping the approach at zero
		# instead would leave the contract true of the dog and false of the encounter: it would
		# stand politely still while she closed the gap herself and died on the first lethal frame.
		step = clampf(range_to_her - standoff,
				-def.pursue_speed * delta, def.pursue_speed * delta)
	position += _heading * step
	# Ground covered, not ground gained: backing off is still moving, and the bob is driven by
	# distance so that a thing holding its ground still reads as alive.
	_path_travelled += absf(step)

## How far along its route this instance has got, so streaming it out and back in can resume it
## instead of rewinding it. See `EventManager._stream_in`.
func path_travelled() -> float:
	return _path_travelled

## Puts an instance back where a previous incarnation of the same plan had got to. Restores the
## age as well as the distance, so the telegraph, the pulse phase and the duration all continue
## rather than starting again — an event that streams in and out must not become immortal by
## being visited twice.
func resume(from_age: float, from_travelled: float) -> void:
	if from_age <= 0.0:
		return
	age = from_age
	_path_travelled = from_travelled
	if def.mobile and path.size() > 1:
		_advance_along_path(0.0)

# --------------------------------------------------------------- going away ---
# *(M35, playtest 08 findings 2 and 3: "running dog events etc — things that move disappear on
# screen; they should at least run offscreen before despawning", and "pigeons are also completely
# ineffective".)*
#
# **Nothing vanishes while you are looking at it.** An event's end was `_finish()` wherever it
# happened to be standing, which for the two shortest-lived rows in the game is directly in front
# of her: the cat's route is one street wide and ends in the open, and the pigeons hang in the air
# for a fifth of a second and are deleted. Both were reported as the same thing, and both are the
# same fix — the end of an event is a **departure**, not a deletion.
#
# What is deliberately *not* here: a fade. A thing that fades out is still a thing that disappears,
# and it disappears in a way nothing in the world could explain. The cat runs on, the flock climbs
# away, the dog that lost interest trots off — and each of them is gone because it left.

## True once it has stopped being an event and is only getting out of shot. It emits nothing, it
## cannot end the day, and it carries no cue: whatever it was, it is over.
var is_leaving := false
var _leaving_for := 0.0

## The most it may spend on the way out. A backstop rather than a timing: with no player to be out
## of sight of — a headless rig, a streamed-out day — nothing else would ever end it.
const LEAVING_GIVES_UP := 6.0

## The end of an event: it leaves if it has anywhere to go, and stops existing if it has not.
##
## Two things never leave, and both would break something that reads the finishing position. An
## event with a `spawns_on_finish` stops **where the thing it leaves belongs** — a fire engine's
## fire is at the building, not two streets past it. And anything with no departure speed has no
## way to go anywhere; a café that closes has always simply been over.
func _be_done() -> void:
	if is_finished or is_leaving:
		return
	if def.departure_speed() <= 0.0 or def.spawns_on_finish != "":
		_finish()
		return
	is_leaving = true
	_leaving_for = 0.0
	# Something on a route carries on the way it was going; anything else goes away from her,
	# which is the only direction a flushed flock or a dog that has lost interest can mean.
	if not (def.mobile and path.size() > 1) and player_at != Vector2.INF \
			and not global_position.is_equal_approx(player_at):
		_heading = (global_position - player_at).normalized()

func _leave(delta: float) -> void:
	_leaving_for += delta
	var step := def.departure_speed() * delta
	position += _heading * step
	_path_travelled += step
	var gone := player_at != Vector2.INF \
			and global_position.distance_to(player_at) > Tuning.OUT_OF_SIGHT
	if gone or _leaving_for >= LEAVING_GIVES_UP:
		_finish()

func _advance_along_path(delta: float) -> void:
	# Movement starts when the telegraph does, so an approaching siren is audible and
	# visible while it is still far away — which is what makes the warning usable.
	_path_travelled += def.speed * delta
	var remaining := _path_travelled
	# **A beat rather than a journey.** *(M36.)* The distance covered is folded back and forth over
	# the route, so the same walk up and down happens for ever and the end of the path is never
	# reached — which is what stops a fixture that moves from departing like something that was
	# passing through. Folded rather than reset, so streaming it out and back in resumes it mid-beat
	# exactly as `resume()` promises.
	var back := false
	if def.paces:
		var beat := _path_length()
		if beat <= 0.0:
			return
		var cycle := fmod(_path_travelled, beat * 2.0)
		back = cycle > beat
		remaining = beat * 2.0 - cycle if back else cycle
	for i in range(1, path.size()):
		var segment := path[i] - path[i - 1]
		var length := segment.length()
		if remaining <= length:
			_heading = segment.normalized()
			# Facing the way it is actually walking. Without this a man pacing a pavement moons
			# along it backwards for half of every beat, which is worse than not moving at all.
			if back:
				_heading = -_heading
			position = path[i - 1] + segment.normalized() * remaining
			return
		remaining -= length
	position = path[path.size() - 1]
	if def.paces:
		return
	# A mobile event that has driven off the end of its route is done, whatever its
	# nominal duration says — and it keeps going until it is out of sight, rather than stopping
	# dead on the pavement she is walking down. See "going away" above.
	_be_done()

## The length of the whole route, in px.
func _path_length() -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i].distance_to(path[i - 1])
	return total

func _has_expired() -> bool:
	if is_waiting():
		# It has not happened yet, and it is not going to until she walks up to it.
		return false
	return def.duration > 0.0 and chase_age() >= def.telegraph_time + def.duration

func _finish() -> void:
	if is_finished:
		return
	is_finished = true
	EventBus.event_finished.emit(self)
	finished.emit(self)

# ------------------------------------------------------------------ emission ---

## True while the event is visible but has not yet reached full strength.
func is_telegraphing() -> bool:
	if is_waiting():
		return false
	return chase_age() < def.telegraph_time

## True for a pursuer that is only standing there, because she has not come near enough for it to
## take an interest. It emits at full strength, it is not lethal, and it does not move.
## See `EventDef.pursues_within`.
func is_waiting() -> bool:
	return def.pursues_within > 0.0 and _noticed_at == INF

## How long this has been *happening*, which is not always how long it has existed.
##
## For everything in the catalogue but one it is the age. For a pursuer that waits, the clock starts
## when it notices her — a telegraph spent at dawn, four streets away, is not a notice, and
## `telegraph_time` and `duration` are both promises about the encounter rather than about the day.
func chase_age() -> float:
	if def.pursues_within <= 0.0:
		return age
	return 0.0 if _noticed_at == INF else age - _noticed_at

## Current peak intensity at the centre, after the telegraph damping and the pulse envelope.
func current_intensity() -> float:
	if is_finished or is_leaving:
		# On the way out it is scenery. Emitting while it goes would mean the excitement of an
		# event trailing after her for as long as it took the thing to get off screen.
		return 0.0
	var value := def.intensity
	if not is_equal_approx(def.intensity_ramp, 1.0) and def.duration > 0.0:
		var through := clampf((age - def.telegraph_time) / def.duration, 0.0, 1.0)
		value *= lerpf(1.0, def.intensity_ramp, through)
	if def.pulse_period > 0.0:
		# 0.25..1.0, so a pulsing event is never entirely silent between beats.
		var phase := TAU * age / def.pulse_period
		value *= 0.25 + 0.75 * (0.5 - 0.5 * cos(phase))
	# The damping says *this has not started yet*. A pursuer that waits has been standing there
	# since she came round the corner — what has not started is the lunge, not the man — so its
	# notice is the only telegraph in the game that does not quieten what it is warning about.
	if is_telegraphing() and def.pursues_within <= 0.0:
		value *= Tuning.TELEGRAPH_INTENSITY_FRACTION
	return value

## Excitement per second this event contributes at a point.
func contribution_at(world_position: Vector2) -> float:
	if is_finished or is_leaving:
		return 0.0
	# A city-wide source has no falloff: there is nowhere in the city it does not reach.
	if def.city_wide:
		return current_intensity()
	return Tuning.falloff(global_position.distance_to(world_position),
			current_intensity(), def.inner_radius, def.outer_radius)

## True when a point is inside the radius that ends the day, for a hard-fail event that is
## no longer merely telegraphing.
func is_lethal_at(world_position: Vector2) -> bool:
	if is_finished or is_leaving or is_waiting() or not def.hard_fail or is_telegraphing():
		return false
	return global_position.distance_to(world_position) <= def.inner_radius

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	if is_finished:
		return
	# **A moving event has to look like it is moving.** *(M31.)* Every crowd agent has a
	# two-frame stride; an `EventInstance` has never had one, so a dog walker at 32px/s — a tile
	# a second, against the player's three — slid along without a leg moving and read as parked.
	# It was reported as *"dog walkers are not moving?"*, and it was not the movement.
	#
	# A bob rather than a gait, because the art has legs drawn into it and a sprite cannot swing
	# its own (the M12c note). Driven by **distance covered**, not by time, so it is the movement
	# itself that shows: something stopped is still, and something fast bobs faster.
	var bob := 0.0
	if def.pursues or is_leaving:
		bob = -absf(sin(_path_travelled * BOB_PER_PX)) * BOB_HEIGHT
	elif def.mobile and def.speed > 0.0 and path.size() > 1 and not is_telegraphing_still():
		bob = -absf(sin(_path_travelled * BOB_PER_PX)) * BOB_HEIGHT
	draw_set_transform(Vector2(0.0, bob), 0.0, Vector2.ONE)
	_draw_body()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_mark()

## Whether it is holding still through its telegraph — a crouching cat is not walking.
func is_telegraphing_still() -> bool:
	return def.still_while_telegraphing and is_telegraphing()

## The bob a moving event rides on: a stride's worth of lift, once per stride's worth of ground.
## Sized against a walking pace rather than a running one — 34px is roughly a step.
const BOB_PER_PX := PI / 34.0
const BOB_HEIGHT := 2.5

# ------------------------------------------------------------------ the mark ---
# M22, playtest 02 finding 8 and playtest 04 finding 2. The aura rings are gone: a ring
# communicates a falloff radius, which is a number, and a number is not a threat. What replaces
# it over an entity is a small mark, and it earns its place by three rules.

## How far above the entity the mark floats, and how big it is at full strength.
const MARK_HEIGHT := 44.0
const MARK_WIDTH := 15.0
const MARK_FLASHES_PER_SECOND := 3.0

## Whether this event is worth a mark at all.
##
## **The mark is for danger that changes over time, and for nothing else.** That is the whole
## rule, and it is the answer to the half of finding 8 that says a ring marked a notice board
## exactly as hard as it marked an abduction and therefore explained nothing:
##
## - **It is about to start.** The telegraph is the promise the fairness contract makes, and a
##   promise nobody can see is not one.
## - **It ends the day.** Nothing else in the game is a different kind of thing from everything
##   else in the game, and that deserves its own mark whether or not the silhouette carries it.
## - **It comes and goes.** A pulsing or swelling event has to be *timed*, and timing is the one
##   thing the ring genuinely did well. See `mark_swell()`.
##
## Everything steady is left to its own silhouette, which is the standing decision in
## `CLAUDE.md` — a barricade, a boarded shopfront and a burnt-out shell are large, distinct and
## visibly what they are, and pointing at them adds nothing but noise. A first pass used
## "louder than the walking decay" instead and marked all three of those, which is the ring's
## own mistake in a new shape.
func wants_a_mark() -> bool:
	if is_finished or is_leaving or def.city_wide:
		# A floor under the whole city has nothing to stand over. That is the HUD's job.
		return false
	if def.kind == GameEnums.EventKind.AMBIENT:
		# A permanent feature of a fixed map never appears, so there is no moment to mark and
		# nothing to time. The same reason the fairness contract exempts it.
		return false
	if def.hard_fail or is_telegraphing():
		return true
	if not is_equal_approx(def.intensity_ramp, 1.0):
		return true
	return can_be_timed()

## Whether this event's pulse is something a player can actually **play against**.
##
## *(Playtest 07, finding 2: "there was a person right on the home block but walking up to them
## didn't do anything — not sure what that person was supposed to be — it had a red triangle.")*
##
## The rule used to be `pulse_period > 0`, and six of the ten rows available on day 1 have a pulse.
## So the caret was over most of an ordinary street, on things that were not going anywhere and
## were not about to do anything, and a player walked up to one to find out what it meant and
## found out that it meant nothing. That is the deleted aura ring's own mistake — *a cue that
## marks everything says nothing* — arriving in the shape M22 invented to replace it.
##
## What M22 got right is the reason to keep any of it: *"a pulsing event has to be **timed**, and
## timing is the one thing the ring genuinely did well."* The mistake was reading "has a pulse" as
## "can be timed". A beat of eleven seconds cannot be timed — you cannot stand and wait out an ice
## cream van — and from inside its field the intensity only ever moves one way, so what the mark
## breathes with is not a rhythm, it is a drift.
##
## So it is a **relationship**, and the relationship is the definition: a pulse can be timed when
## its period is shorter than the time it takes to walk across the field it is pulsing in. Under
## that, the beat changes while she is inside it and a pass can be slipped between two of them.
## Over it, the pulse is slower than the whole encounter and there is nothing to time.
##
## It leaves the caret on exactly the two steady act I rows it should be on — the loose dog and
## the leaf blower, which are the two whose whole counterplay is *go now* — and takes it off the
## café, the market stall, the busker, the ice cream van, the dog walker and the man shouting,
## every one of which is a place you route around rather than a beat you wait out.
func can_be_timed() -> bool:
	if def.pulse_period <= 0.0:
		return false
	return def.pulse_period < 2.0 * def.outer_radius / Tuning.WALK_SPEED

## How hard the mark is breathing, 0..1, from what the event is emitting right now.
##
## **This is the one thing the ring did that a symbol does not get for free**, and it is
## load-bearing: a pulsing event can be timed and slipped past between beats, and a mark that
## sat there at a constant size would turn the pulse envelope from something to play against
## into something random.
func mark_swell() -> float:
	if def.intensity <= 0.0:
		return 1.0
	return clampf(current_intensity() / def.intensity, 0.0, 1.0)

func mark_colour() -> Color:
	if def.hard_fail:
		return Palette.MARK_LETHAL
	return Palette.MARK_TELEGRAPH if is_telegraphing() else Palette.MARK_ACTIVE

## A caret over anything worth looking at, breathing with what it is currently emitting.
##
## What is deliberately *not* here: any drawing of where the danger reaches. That is the ring,
## and its absence is the milestone.
func _draw_mark() -> void:
	if not wants_a_mark():
		return
	# Flashing while telegraphing, which is the phase that means *this has not happened yet*.
	# A steady mark for something already happening: it has stopped being a warning.
	var telegraphing := is_telegraphing()
	if telegraphing and fmod(age * MARK_FLASHES_PER_SECOND, 1.0) > 0.55:
		return

	var swell := mark_swell()
	# Never all the way to nothing: between beats the mark shrinks, it does not vanish, or a
	# pulsing event would read as flickering in and out of existence.
	var scale := 0.55 + 0.45 * swell
	var at := Vector2(0.0, -(MARK_HEIGHT + 10.0 * swell))
	Sprites.draw_caret(self, at, MARK_WIDTH * scale, mark_colour())
	if def.hard_fail:
		# Doubled, so lethal reads at a glance and never has to be told apart by hue.
		Sprites.draw_caret(self, at - Vector2(0.0, MARK_WIDTH * scale * 0.85),
				MARK_WIDTH * scale, mark_colour())

func _draw_body() -> void:
	match def.look:
		EventDef.Look.FIRE:
			_draw_fire()
		EventDef.Look.ANIMAL:
			_draw_animal()
		EventDef.Look.PERSON:
			_draw_person()
		EventDef.Look.VEHICLE:
			_draw_vehicle()
		EventDef.Look.OBJECT:
			_draw_spread(BARRIER_SEGMENT, BARRIER_END)
		EventDef.Look.TABLES:
			_draw_spread(CAFE_TABLE)
		EventDef.Look.DOG_WALKER:
			_draw_dog_walker()
		EventDef.Look.CYCLIST:
			_draw_simple(CYCLIST, 12.0)
		EventDef.Look.LOOSE_DOG:
			_draw_loose_dog()
		EventDef.Look.STALL:
			_draw_spread(STALL)
		EventDef.Look.LEAF_BLOWER:
			_draw_simple(LEAF_BLOWER, 8.0)
		EventDef.Look.BIRDS:
			_draw_birds()
		EventDef.Look.ICE_CREAM_VAN:
			_draw_simple(ICE_CREAM_VAN, 20.0)
		EventDef.Look.LORRY:
			_draw_simple(LORRY, 26.0)
		EventDef.Look.CHARGING_DOG:
			_draw_simple(CHARGING_DOG, 13.0)
		EventDef.Look.NONE:
			pass

## A shadow and a sprite, facing the way it is going. What most of M31's new looks are, and
## having it once is what stopped seven near-identical three-line functions.
func _draw_simple(texture: Texture2D, shadow: float) -> void:
	Sprites.draw_shadow(self, Vector2.ZERO, shadow)
	Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

## The dog, and the lead it is no longer on.
##
## Read against `_draw_dog_walker()`, which draws the lead *taut between two bodies*: that is
## the span it owns and the reason to cross the street. Here the same lead trails on the ground
## behind one body, and the difference between the two pictures is the whole event.
func _draw_loose_dog() -> void:
	var behind := Vector2(26.0 if _heading_is_west() else -26.0, 0.0)
	Sprites.draw_shadow(self, Vector2.ZERO, 9.0)
	# On the ground and slack, not held up at hip height. Nobody is holding it.
	draw_line(Vector2(0.0, -8.0), behind + Vector2(0.0, -2.0), Palette.OUTLINE, 2.0)
	Sprites.draw_standing(self, DOG, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

## A flock going up. Scattered by the instance's own position rather than randomly, so the
## same flock is the same shape every frame instead of boiling.
##
## Three phases and they are the whole event: **on the ground**, pecking, while it telegraphs — which
## is the thing that was missing, because a flock that is already in the air is a flock she has
## walked past and there is nothing left to decide; **up**, all at once, for the duration; and then
## **away**, climbing as they go. *(M35: they used to be deleted at the top of the climb, which is
## playtest 08's "pigeons are also completely ineffective" and playtest 07's "birds just disappear
## if I get close and do nothing" — the same complaint, twice.)*
func _draw_birds() -> void:
	var rise := clampf(age / maxf(def.telegraph_time, 0.01), 0.0, 1.0)
	if is_telegraphing():
		# On the pavement and about to go: no lift at all until the burst, so what she sees from
		# down the street is a flock she could still walk around.
		rise = 0.0
	var seed_value := int(global_position.x) * 31 + int(global_position.y)
	# Climbing away, so the last thing on screen is them leaving rather than them stopping.
	var climb := _leaving_for * CLIMB_PER_SECOND
	for i in 7:
		var spread := float((seed_value + i * 37) % 11 - 5) * 7.0
		var lift := 6.0 + float((seed_value + i * 53) % 7) * 5.0
		Sprites.draw_standing(self, PIGEON,
				Vector2(spread, -lift * rise - 4.0 * float(i % 3) - climb))

## How fast a departing flock gains height, on top of the ground it covers. Enough that they are
## visibly going *up and away* rather than skimming the pavement.
const CLIMB_PER_SECOND := 42.0

func _draw_animal() -> void:
	# Crouched while telegraphing, stretched out once it bolts. The crouch *is* the
	# telegraph, so the two silhouettes have to differ at a glance, not by a scale factor.
	var texture := CAT_CROUCHED if is_telegraphing() else CAT_RUNNING
	Sprites.draw_shadow(self, Vector2.ZERO, 7.0)
	Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

func _draw_person() -> void:
	Sprites.draw_shadow(self, Vector2.ZERO, 8.0)
	Sprites.draw_standing(self, PERSON, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

func _draw_vehicle() -> void:
	Sprites.draw_shadow(self, Vector2.ZERO, 20.0)
	Sprites.draw_standing(self, VEHICLE, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

## Flames scaled by what the event is currently emitting, so a fire visibly roars.
func _draw_fire() -> void:
	var strength := 1.0
	if def.intensity > 0.0:
		strength = clampf(current_intensity() / def.intensity, 0.2, 1.0)
	Sprites.draw_shadow(self, Vector2.ZERO, 22.0)
	for i in 5:
		var offset := (i - 2.0) * 11.0
		var flicker := 1.0 + 0.25 * sin(age * 9.0 + i * 1.7)
		var height := (34.0 + i % 2 * 14.0) * strength * flicker
		Sprites.draw_standing(self, FLAME, Vector2(offset, 0.0), Vector2(18.0, height))

## A blocking object is drawn at exactly the width it obstructs, by repeating a segment
## across it. Anything else would be a lie about where the player can walk.
func _draw_spread(segment_texture: Texture2D, cap: Texture2D = null) -> void:
	var half := maxf(11.0, def.obstructs_radius)
	Sprites.draw_shadow(self, Vector2.ZERO, half * 0.9)
	var segment := segment_texture.get_size()
	var segments := maxi(1, ceili(half * 2.0 / segment.x))
	var width := half * 2.0 / segments
	for i in segments:
		Sprites.draw_standing(self, segment_texture,
				Vector2(-half + width * (i + 0.5), 0.0), Vector2(width, segment.y))
	if not cap:
		return
	for side in [-1.0, 1.0]:
		Sprites.draw_standing(self, cap, Vector2(side * half, 0.0))

## The person, the dog, and the lead between them.
##
## The lead is drawn because it is the mechanic: what makes a dog walker worth crossing the
## street for is the span it owns, and a span you cannot see is a span you walk into. The dog
## leads on the side the walker is heading, so the pair reads as being dragged along.
func _draw_dog_walker() -> void:
	var reach := def.inner_radius * 0.8
	var to_the_dog := Vector2(-reach if _heading_is_west() else reach, 0.0)
	Sprites.draw_shadow(self, Vector2.ZERO, 8.0)
	Sprites.draw_shadow(self, to_the_dog, 9.0)
	# Slack in the middle, so it reads as a lead rather than as a bar.
	draw_line(Vector2(0.0, -26.0), to_the_dog + Vector2(0.0, -6.0), Palette.OUTLINE, 2.0)
	Sprites.draw_standing(self, PERSON, Vector2.ZERO, Vector2.ZERO, _heading_is_west())
	Sprites.draw_standing(self, DOG, to_the_dog, Vector2.ZERO, _heading_is_west())

## Which way a mobile event is travelling, for art that has a front and a back. A
## stationary event never flips.
func _heading_is_west() -> bool:
	return _heading.x < 0.0
