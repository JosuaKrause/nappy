class_name Stroller
extends CharacterBody2D
## The mother-and-pram rig the player drives.
##
## `position` is the mother's feet on the ground plane; everything is drawn upward from
## there so that y-sorting against buildings and props matches where she actually stands.
## The pram is drawn as an offset in the facing direction, foreshortened on Y to sell the
## oblique view (docs/CITY.md, "Rendering").

## How far ahead of the mother the pram sits, on the ground plane.
const PRAM_DISTANCE := 34.0
## Vertical squash applied to ground-plane offsets, i.e. the obliqueness of the view.
const OBLIQUE_Y := 0.7
## Radians per second the rig turns to face a new input direction.
const FACING_TURN_SPEED := 12.0
## How far the camera leads the player, in px.
const CAMERA_LOOK_AHEAD := 46.0

## Two frames per direction: mid-stride, then feet passing.
const MOTHER_FRONT: Array[Texture2D] = [
	preload("res://assets/rig/mother_front_a.svg"),
	preload("res://assets/rig/mother_front_b.svg"),
]
const MOTHER_BACK: Array[Texture2D] = [
	preload("res://assets/rig/mother_back_a.svg"),
	preload("res://assets/rig/mother_back_b.svg"),
]
const MOTHER_SIDE: Array[Texture2D] = [
	preload("res://assets/rig/mother_side_a.svg"),
	preload("res://assets/rig/mother_side_b.svg"),
]
const PRAM_SIDE := preload("res://assets/rig/pram_side.svg")
const PRAM_FRONT := preload("res://assets/rig/pram_front.svg")
const PRAM_BACK := preload("res://assets/rig/pram_back.svg")
const ALERT := preload("res://assets/props/alert.svg")
const ALERT_CLOSE := preload("res://assets/props/alert_close.svg")
## The baby's own three, which ride over the pram rather than over her. See `Baby.Cue`.
const BABY_ZZZ := preload("res://assets/props/baby_zzz.svg")
const BABY_FUSS := preload("res://assets/props/baby_fuss.svg")
const BABY_CRY := preload("res://assets/props/baby_cry.svg")

## How far above her head the warning mark floats, and how fast it flashes. She is 46px tall,
## so this clears her head by a few pixels and no more: at 68 the mark drifted far enough up
## the screen to read as belonging to whatever was standing behind her, which for a cue that
## means "this is about *you*" is the one thing it must not do.
const ALERT_HEIGHT := 54.0
const ALERT_FLASHES_PER_SECOND := 4.0
## The "too close" mark flashes faster, because it is the one that means *now*.
const CLOSE_FLASHES_PER_SECOND := 7.0

## How far above the pram the baby's own cue floats, and how far to one side when the pram is on
## her own axis — walking towards or away from the viewer, where "above the pram" is also over
## her legs or over her head. The second of those is where the exclamation mark lives, and two
## cues in one column is the collision playtest 06's finding 5 names by name: the mark means
## *this will end your day*, and a cue about the meter that can be read as part of it undoes M30.
##
## The lift clears the pram's own art, which is 30px tall from its ground point. Both numbers
## were set by looking: at 18 the cue was inside the hood and read as clutter on the pram, and
## with no lateral step it was over her chest walking south and over her head walking north.
const BABY_CUE_LIFT := 36.0
const BABY_CUE_ASIDE := 34.0
## Slow, because it is a state rather than an alarm; the two urgent ones flash and the two
## calm ones do not. The zzz breathes instead, which is a sleeping baby and not a warning.
const BABY_CUE_FLASHES_PER_SECOND := 2.0
const BABY_CUE_BREATH := 2.0

## The two things that can be true about the ground she is standing on. M22's vocabulary has
## exactly these and no more — a third level would be a number again.
enum Alert {
	NONE,
	## *This spot is about to be bad; move.* A telegraph whose radius already covers her, or a
	## car closing on the lane she is standing in.
	SOON,
	## *It is bad now and you are in it.* Something lethal is live and she is inside its reach
	## with one step left to make. This is the cue that lets every other one be quieter.
	NOW,
}

@onready var _camera: Camera2D = $Camera2D
## The baby rides in the pram and the rig draws itself, so the rig asks her what to draw. Null
## in a test rig built without one, which is why every use is guarded.
@onready var _baby: Baby = get_node_or_null("Baby")

var facing := Vector2.DOWN
var _walk_phase := 0.0
## Deflection from being walked into, decaying like any other velocity. Kept apart from
## `velocity` so an input frame cannot quietly erase it.
var _shove := Vector2.ZERO
## The loudest warning raised this frame, and how long is left on it. Several systems can warn
## her at once — the traffic, an event telegraphing on top of her — so it is a *level with a
## hold* rather than a boolean somebody owns: the last caller to say "no" must not be able to
## clear a warning another one has just raised.
var _alert := Alert.NONE
var _alert_left := 0.0
var _alert_phase := 0.0
## Who raised what is currently up, so that a system can take *its own* warning down early
## without being able to touch anybody else's. See `stand_down()`.
var _alert_source := &""

func _ready() -> void:
	add_to_group("player")

## Takes her out of the world without taking her out of the tree, for the title screen's attract
## mode. *(M38: "as title screen just use the home and street in front without player".)*
##
## **Leaving the `player` group is the whole of it**, and it is worth being explicit about why that
## is the right switch rather than one more flag. Everything that happens *to* her is reached
## through that group and nothing else is: `EventManager` streams, places what the director owes,
## tells the events where she is, warns her about the ground she is on and checks the hard fails
## only `if _find_player()`; `Crowd` looks her up the same way before it can bump her, honk at her
## or run her over. Out of the group, none of it can fire — so a lethal thing on the doorstep cannot
## end a day nobody is playing, and the city in the background is genuinely only a city.
##
## **Her camera stays behind, and it has to keep running.** The view is hers, and the shot the title
## screen wants is the one she would be looking at on the first morning — but the title stops the
## day, which stops her, and `position_smoothing_enabled` is applied in the **camera's own** process
## callback. A paused camera therefore never travels to the thing it is following: it sat at the
## world origin, clamped to the corner of the boundary wall, while ninety-five crowd agents walked
## about the doorstep a thousand pixels off-camera. An empty title screen, with nothing whatever
## wrong with the thing it was supposed to be showing.
##
## What is *not* the reason, having been checked rather than assumed: hiding a `Node2D` does not
## deactivate a `Camera2D` under it. `visible` is all this needs to be.
func stand_aside() -> void:
	remove_from_group("player")
	visible = false
	_camera.process_mode = Node.PROCESS_MODE_ALWAYS
	_camera.reset_smoothing()

## And back in, when the day starts. The camera goes back to being part of the game, so that a real
## pause stops the view moving along with everything else.
func step_back_in() -> void:
	if not is_in_group("player"):
		add_to_group("player")
	visible = true
	_camera.process_mode = Node.PROCESS_MODE_INHERIT

## Whether she is out of the world for the title screen: still here, still carrying the camera,
## simply not drawn. See `stand_aside()`.
var _stood_aside := false

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var top_speed := Tuning.RUN_SPEED if Input.is_action_pressed("run") else Tuning.WALK_SPEED

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * top_speed, Tuning.ACCELERATION * delta)
		_turn_toward(input_dir.normalized(), delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, Tuning.FRICTION * delta)

	move_and_slide()

	# The deflection is moved separately rather than added to `velocity`, which stays what she
	# is steering. Folding it in would have made `is_idle()` and `run_excess_ratio()` — the two
	# questions the baby asks the rig — answer for the crowd rather than for the player.
	if _shove != Vector2.ZERO:
		move_and_collide(_shove * delta)
		_shove = _shove.move_toward(Vector2.ZERO, Tuning.FRICTION * delta)

	# Stride cadence is driven by distance covered, so it stays in step at any speed.
	_walk_phase = wrapf(_walk_phase + velocity.length() * delta * 0.09, 0.0, TAU)
	_alert_phase = wrapf(_alert_phase + delta, 0.0, 1.0)
	_alert_left = maxf(0.0, _alert_left - delta)
	if _alert_left <= 0.0:
		_alert = Alert.NONE
	_update_camera(delta)
	queue_redraw()

## Knocks her off her line. Called by `Crowd` when she walks into somebody: the contact
## displaces them both, which is finding 2 of playtest 02.
func shove(impulse: Vector2) -> void:
	# The strongest contact of the frame wins rather than the sum of them, or being caught
	# between two people would fire her out of the crowd.
	if impulse.length() > _shove.length():
		_shove = impulse

## Raises a warning over her head for `seconds`, on behalf of `source`.
##
## Additive rather than a setter, and that is the whole reason it is shaped this way: the crowd
## and the events both watch the ground she is standing on, and a setter would let whichever ran
## second clear what the first had just said. The louder level wins while both are live, and a
## `NOW` never gets quietly downgraded to a `SOON` by a system that cannot see the lethal thing.
##
## An *upgrade* takes the new caller's hold rather than keeping the old one's remainder: a
## `SOON` with a second left becoming a `NOW` that is re-raised every frame is the same mark for
## as long as the `NOW` is true, and a second of leftover `SOON` underneath it is a second of
## the mark meaning nothing.
func warn(level: Alert, seconds: float, source: StringName = &"") -> void:
	if level == Alert.NONE:
		return
	var live := _alert_left > 0.0
	if live and level < _alert:
		return
	var extending := live and level == _alert
	_alert = level
	_alert_left = maxf(_alert_left if extending else 0.0, seconds)
	_alert_source = source

## Takes down a warning `source` raised, and only that one.
##
## The hold on a warning exists to bridge a gap in the thing it warns about — the space between
## two cars in one lane — and it cannot tell that apart from the danger being over. Only the
## system that raised it can, so only that system may lower it: the check on the source is what
## keeps this from being the setter the rule above exists to prevent, because a caller that has
## been outbid by something louder finds nothing of its own to take down.
##
## *(Playtest 06, finding 3: "I get the flashing exclamation marks after the fact, at which point
## they're not useful.")*
func stand_down(source: StringName) -> void:
	if _alert_left > 0.0 and _alert_source == source:
		_alert = Alert.NONE
		_alert_left = 0.0

## What is currently over her head. For the telemetry observer, which has to be able to say
## whether she was warned before she was killed.
func alert_level() -> Alert:
	return _alert if _alert_left > 0.0 else Alert.NONE

## How far to one side the baby's cue is stepped, and why it is a function rather than four lines
## inside `_draw`: this is a claim about a *moment*, and nothing that only exists inside a `_draw`
## can be asked about one. *(The M32 lesson — the badge's own two questions are static functions
## for the same reason — arriving at the cue M32 itself added.)*
##
## **There is one reason to step aside and it is conditional**, on both vertical axes. Walking
## towards or away from the viewer the pram shares her column, so "above the pram" is also the
## exclamation mark's column — and that column is only occupied while there is a mark in it.
## *(M37, playtest 07 finding 14.)*
##
## *(M39, playtest 10 finding 3: "when walking downwards the zzz is still left of the stroller while
## walking in any other direction it has the correct position.")* M37 made the **north** case
## conditional and left the south one unconditional, on the argument that walking south "above the
## pram" is over her own chest and nothing about that depends on what else is on screen. That is a
## true observation and the wrong conclusion: it is an argument for lifting the cue over her head,
## which is `baby_cue_lift()`, and not for shoving it sideways off the thing it is about. So the
## rule is one rule now — *dodge the mark, and only the mark* — and the screenshot that made M37's
## own case makes this one: a sleeping baby, nothing else happening, and a zzz a full body's width
## to the right of the pram.
##
## It reads `alert_level()` rather than the flash phase: the mark blinks and the cue beside it
## must not hop back and forth in time with it.
func baby_cue_aside() -> float:
	if absf(facing.x) > absf(facing.y):
		# Walking sideways the pram is already a body's width out in front of her, and there is
		# nothing to step around.
		return 0.0
	if alert_level() == Alert.NONE:
		return 0.0
	return BABY_CUE_ASIDE if facing.x >= 0.0 else -BABY_CUE_ASIDE

## How far above the pram the cue floats, which is not the same on both vertical axes.
##
## *(M39, finding 3.)* `BABY_CUE_LIFT` clears the pram's own art, which is all it has to do when the
## pram is the topmost thing under the cue. Walking **south** it is not: the pram is in front of her
## and therefore *lower* on the screen, so a cue lifted off the pram alone lands over her chest.
## Clearing her as well is what puts it above the pair of them, over the pram's own column, which is
## where a cue about the baby belongs — and it is why the step aside above could stop being
## unconditional.
func baby_cue_lift() -> float:
	if absf(facing.y) >= absf(facing.x) and facing.y > 0.0:
		return BABY_CUE_LIFT + FIGURE_HEIGHT
	return BABY_CUE_LIFT

## How tall she is, in px, from the ground point her sprite is anchored at. Only the cue above the
## pram needs it, and it needs it as a number rather than as a texture size because the cue is
## placed before anything is drawn.
const FIGURE_HEIGHT := 46.0

func _turn_toward(target: Vector2, delta: float) -> void:
	var step := FACING_TURN_SPEED * delta
	var diff := angle_difference(facing.angle(), target.angle())
	facing = facing.rotated(clampf(diff, -step, step)).normalized()

func _update_camera(delta: float) -> void:
	var lead := Vector2(facing.x, facing.y * OBLIQUE_Y) * CAMERA_LOOK_AHEAD
	_camera.offset = _camera.offset.lerp(lead, clampf(delta * 3.0, 0.0, 1.0))

## Puts the rig back on the doorstep at the start of a day, stopped and facing the street.
func reset_at(where: Vector2, look: Vector2 = Vector2.DOWN) -> void:
	global_position = where
	velocity = Vector2.ZERO
	facing = look.normalized()
	_walk_phase = 0.0
	_shove = Vector2.ZERO
	_alert = Alert.NONE
	_alert_left = 0.0
	_alert_source = &""
	if _camera:
		_camera.offset = Vector2.ZERO
		_camera.reset_smoothing()
	queue_redraw()

## Stops the camera from panning past the edge of the city.
func set_camera_limits(bounds: Rect2) -> void:
	_camera.limit_left = int(bounds.position.x)
	_camera.limit_top = int(bounds.position.y)
	_camera.limit_right = int(bounds.end.x)
	_camera.limit_bottom = int(bounds.end.y)

# ------------------------------------------------------------------ queries ---
# Consumed by Baby (M2) to decide how the meters move.

func current_speed() -> float:
	return velocity.length()

## True when the rig is close enough to stationary that sleepiness should drain.
func is_idle() -> bool:
	return velocity.length() < Tuning.IDLE_SPEED_THRESHOLD

## 0.0 at walking pace or below, 1.0 at a full sprint. Scales excitement from running.
func run_excess_ratio() -> float:
	var excess := velocity.length() - Tuning.WALK_SPEED
	if excess <= 0.0:
		return 0.0
	return clampf(excess / (Tuning.RUN_SPEED - Tuning.WALK_SPEED), 0.0, 1.0)

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	var gait := clampf(velocity.length() / Tuning.WALK_SPEED, 0.0, 1.6)
	var pram_offset := Vector2(facing.x, facing.y * OBLIQUE_Y) * PRAM_DISTANCE

	# Shadows belong to the ground plane, so they always go underneath both figures.
	Sprites.draw_shadow(self, Vector2.ZERO, 9.0)
	Sprites.draw_shadow(self, pram_offset, 12.0)

	# Facing away from the viewer puts the pram further up the screen, i.e. behind her.
	if facing.y < 0.0:
		_draw_pram(pram_offset)
		_draw_mother(gait)
	else:
		_draw_mother(gait)
		_draw_pram(pram_offset)

	_draw_baby_cue(pram_offset)
	_draw_alert()

## How the baby is, drawn where the player is already looking. *(Playtest 06, finding 5:
## "having something above the player might be better — like a zzz above the stroller when the
## baby is fully asleep — and warnings when the excitement is about to be full.")*
##
## Four states, no gauge, and the reasoning for both is on `Baby.Cue`. What is decided *here* is
## only where it goes: over the pram, and stepped aside when the pram is behind her, so that the
## one cue in the game that means "this will end your day" never has to share a column with a
## cue about a meter.
func _draw_baby_cue(pram_offset: Vector2) -> void:
	if not _baby:
		return
	var cue := _baby.cue()
	if cue == Baby.Cue.NONE:
		return
	var texture := BABY_ZZZ
	var flashing := false
	match cue:
		Baby.Cue.UNSETTLED:
			texture = BABY_FUSS
		Baby.Cue.NEARLY_CRYING:
			texture = BABY_CRY
			flashing = true
		Baby.Cue.STIRRING:
			flashing = true
	if flashing and fmod(_alert_phase * BABY_CUE_FLASHES_PER_SECOND, 1.0) > 0.6:
		return

	var aside := baby_cue_aside()
	# The steady ones breathe rather than sit still, or a mark that is up for the whole walk
	# home stops being read. The urgent two flash instead.
	var breath := 0.0 if flashing else sin(_alert_phase * TAU) * BABY_CUE_BREATH
	Sprites.draw_standing(self, texture,
			pram_offset + Vector2(aside, -baby_cue_lift() + breath))

## *This spot is about to be bad; move* — or, doubled and red, *it is bad now.* Drawn over the
## player rather than over the thing that is coming, because "there is a car on this road" is
## information and "you are standing in front of it" is an instruction, and only the second one
## is a move.
##
## This is the load-bearing cue of M22's vocabulary. Every other mark says *a thing exists*;
## this one says the fairness contract is now about you and the clock has started. It shipped
## early, in M19, because a lethal car has no telegraph phase to ring — M22 only had to give it
## a second level and let the events raise it too.
##
## Flashing rather than steady: a mark that is always there stops being read, and the flash is
## also what distinguishes it from the props she walks past. See docs/EVENTS.md, "The visual
## vocabulary".
func _draw_alert() -> void:
	if _alert == Alert.NONE or _alert_left <= 0.0:
		return
	var rate := CLOSE_FLASHES_PER_SECOND if _alert == Alert.NOW else ALERT_FLASHES_PER_SECOND
	if fmod(_alert_phase * rate, 1.0) > 0.55:
		return
	var mark := ALERT_CLOSE if _alert == Alert.NOW else ALERT
	Sprites.draw_standing(self, mark, Vector2(0.0, -ALERT_HEIGHT))

## The stride is two frames rather than a procedural swing: with the legs drawn into the
## sprite there is nothing left to swing. The frames carry the body's bob too, which is why
## nothing here offsets her vertically any more.
func _draw_mother(gait: float) -> void:
	var stepping := gait > 0.05 and sin(_walk_phase * 2.0) > 0.0
	var frame := 1 if stepping else 0
	var flip := false
	var texture: Texture2D
	if absf(facing.x) > absf(facing.y):
		texture = MOTHER_SIDE[frame]
		flip = facing.x < 0.0
	elif facing.y > 0.0:
		texture = MOTHER_FRONT[frame]
	else:
		texture = MOTHER_BACK[frame]
	Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2.ZERO, flip)

## Three profiles rather than one drawing with the hood nudged sideways. Sliding the hood
## along a fixed basket made it overhang the end of the pram whenever she turned, which is
## what "the canopy is offset going sideways" was: the hood was drawn at the rear, but the
## basket underneath it never changed shape, so the two stopped agreeing.
func _draw_pram(at: Vector2) -> void:
	if absf(facing.x) > absf(facing.y):
		# Authored travelling east, hood at the rear; mirrored to travel west.
		Sprites.draw_standing(self, PRAM_SIDE, at, Vector2.ZERO, facing.x < 0.0)
	elif facing.y > 0.0:
		Sprites.draw_standing(self, PRAM_FRONT, at)
	else:
		Sprites.draw_standing(self, PRAM_BACK, at)
