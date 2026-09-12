class_name Stroller
extends CharacterBody2D
## The mother-and-pram rig the player drives.
##
## `position` is the mother's feet on the ground plane; everything is drawn upward from
## there so that y-sorting against buildings and props matches where she actually stands.
## The pram is drawn as an offset in the facing direction, foreshortened on Y by `OBLIQUE_Y` to
## sell the oblique view (docs/CITY.md, "Rendering").
##
## The SVG mother and pram below are the logical body and the complete drawing in every mode.

## How far ahead of the mother the pram sits, on the ground plane.
const PRAM_DISTANCE := 34.0
## Vertical squash applied to ground-plane offsets, i.e. the obliqueness of the view.
const OBLIQUE_Y := 0.7
## Radians per second the rig turns to face a new input direction.
const FACING_TURN_SPEED := 12.0
## How far the camera leads the player, in px.
const CAMERA_LOOK_AHEAD := 46.0

## `_update_view()` selects one of eight upright projections, indexed clockwise from east. Each
## 22.5° boundary has a five-degree hold so float noise cannot chatter the artwork while the
## physical facing remains continuous — `EightDirection.SECTOR_DEGREES` and
## `EightDirection.HYSTERESIS_DEGREES`, the same selector `CrowdAgent`'s walkers now share.

## The SVG presentation, and the one a build draws unless the illustrated transfer is opted into.
## Two frames per direction: mid-stride, then feet passing.
const MOTHER_FRONT: Array[Texture2D] = [
	preload("res://assets/rig/mother_front_a.svg"), preload("res://assets/rig/mother_front_b.svg")]
const MOTHER_BACK: Array[Texture2D] = [
	preload("res://assets/rig/mother_back_a.svg"), preload("res://assets/rig/mother_back_b.svg")]
const MOTHER_SIDE: Array[Texture2D] = [
	preload("res://assets/rig/mother_side_a.svg"), preload("res://assets/rig/mother_side_b.svg")]
const MOTHER_FRONT_DIAGONAL: Array[Texture2D] = [
	preload("res://assets/rig/mother_front_diagonal_a.svg"), preload("res://assets/rig/mother_front_diagonal_b.svg")]
const MOTHER_BACK_DIAGONAL: Array[Texture2D] = [
	preload("res://assets/rig/mother_back_diagonal_a.svg"), preload("res://assets/rig/mother_back_diagonal_b.svg")]

## The escape scene's rig — the baby in her arms, no pram. Selected in place of the sets above
## whenever `carrying` is set; see `_mother_texture()`.
const MOTHER_CARRYING_FRONT: Array[Texture2D] = [
	preload("res://assets/rig/mother_carrying_front_a.svg"),
	preload("res://assets/rig/mother_carrying_front_b.svg")]
const MOTHER_CARRYING_BACK: Array[Texture2D] = [
	preload("res://assets/rig/mother_carrying_back_a.svg"),
	preload("res://assets/rig/mother_carrying_back_b.svg")]
const MOTHER_CARRYING_SIDE: Array[Texture2D] = [
	preload("res://assets/rig/mother_carrying_side_a.svg"),
	preload("res://assets/rig/mother_carrying_side_b.svg")]
const MOTHER_CARRYING_FRONT_DIAGONAL: Array[Texture2D] = [
	preload("res://assets/rig/mother_carrying_front_diagonal_a.svg"),
	preload("res://assets/rig/mother_carrying_front_diagonal_b.svg")]
const MOTHER_CARRYING_BACK_DIAGONAL: Array[Texture2D] = [
	preload("res://assets/rig/mother_carrying_back_diagonal_a.svg"),
	preload("res://assets/rig/mother_carrying_back_diagonal_b.svg")]

const PRAM_SIDE := preload("res://assets/rig/pram_side.svg")
const PRAM_FRONT := preload("res://assets/rig/pram_front.svg")
const PRAM_BACK := preload("res://assets/rig/pram_back.svg")
const PRAM_FRONT_DIAGONAL := preload("res://assets/rig/pram_front_diagonal.svg")
const PRAM_BACK_DIAGONAL := preload("res://assets/rig/pram_back_diagonal.svg")

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
## her legs or over her head. The second of those is where the exclamation mark lives, and **two
## cues in one column collide**: the mark means *this will end your day*, and a cue about the meter
## that can be read as part of it takes that meaning away from it.
##
## The lift clears the pram's own art, which is 30px tall from its ground point. Both numbers are
## set by looking: any less and the cue is inside the hood and reads as clutter on the pram, and
## with no lateral step it is over her chest walking south and over her head walking north.
const BABY_CUE_LIFT := 36.0
const BABY_CUE_ASIDE := 34.0
## Slow, because it is a state rather than an alarm; the two urgent ones flash and the two
## calm ones do not. The zzz breathes instead, which is a sleeping baby and not a warning.
const BABY_CUE_FLASHES_PER_SECOND := 2.0
const BABY_CUE_BREATH := 2.0

## The two things that can be true about the ground she is standing on. The danger vocabulary has
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
## The pram's own body, kept on the circumference of her own circle — see `PRAM_BODY_RADIUS`'s doc
## for why this is a second `CollisionShape2D` on the same rig rather than one wider combined
## radius. Null in a test rig built without one.
@onready var _pram_collision: CollisionShape2D = get_node_or_null("PramCollisionShape2D")

var facing := Vector2.DOWN

## The escape scene's carrying rig: the baby in her arms instead of ahead of her in the pram.
## Set once by `main._ready_escape()` before she is ever drawn; nothing else in the game ever
## flips it, so there is no case of switching mid-walk to account for. Her collision circle is
## unchanged either way — see `shape`'s own doc.
var carrying := false

## `InteriorScene.slope_dir_at`, or an unset `Callable` outdoors — the one hook the escape scene's
## diagonal stairs need from this otherwise interior-agnostic rig. Asked every physics frame for
## whether her *current* position sits on a diagonal flight tile (`+1` descending toward east,
## `-1` toward west, `0` off any flight), so a sideways press can be redirected along the slope —
## see `_physics_process()`. Set once by `main._ready_escape()`, the same shape `carrying` is set
## in; unset (`Callable()`) leaves every outdoor run and every other test untouched.
var slope_dir_at := Callable()

## Her own ground shape and the pram's, read by `_draw()` for their shadows — 9px and 12px, the
## same two numbers the shadow always used. Fixed rather than computed in a `setup()`, since
## neither figure changes size. **Not the same datum as the scene's own collision body**: the
## `CircleShape2D` on `scenes/player/stroller.tscn`'s `CollisionShape2D` is one combined physics
## radius for the whole rig, `Tuning.PLAYER_BODY_RADIUS` (14px) — already checked against the
## scene by `tests/test_events.gd`'s `_test_the_pram_is_the_size_the_rules_think_it_is` — and nothing
## here touches it. `pram_shape`'s own 12px radius still sizes the pram's shadow, cue and field,
## which all keep the pram's drawn `PRAM_DISTANCE` (34px) offset; the pram's *collision* body is a
## separate, smaller datum — see `pram_body_shape` below.
var shape := GroundShape.point(9.0)
var pram_shape := GroundShape.point(12.0)

## The pram's own body radius, smaller than `pram_shape`'s 12px — **8px is the pinned
## recommendation, open to overturn** if the far half still reads as too much or too little to
## clip through. `PramCollisionShape2D`'s centre sits on the circumference of her own body
## (`Tuning.PLAYER_BODY_RADIUS`, 14px out along `facing`) rather than at the pram's drawn
## `PRAM_DISTANCE` — *(PLAYTEST-57: "place the center of the stroller hitbox at the circumference
## of the player hitbox", "and don't make it too big")* — so the pram's far half overlaps whatever
## it meets and she can stand against a wall while the pram no longer clips through a corner whole.
## `scenes/player/stroller.tscn`'s own `CircleShape2D` on `PramCollisionShape2D` carries this same
## number; `tests/test_stroller.gd` checks the scene against it directly, the same way
## `tests/test_events.gd`'s `_test_the_pram_is_the_size_the_rules_think_it_is` already does for her
## own body.
const PRAM_BODY_RADIUS := 8.0

## Where the pram is *drawn* relative to her this frame — `Vector2.ZERO` while `carrying`, since
## there is no pram to be ahead of her. Computed once in `_physics_process()`, and read again by
## `_draw()` so the two can never disagree about where the pram is drawn. **Not the collision
## body's own offset any more** — `PramCollisionShape2D` now sits on her own circumference
## (`facing * Tuning.PLAYER_BODY_RADIUS`, set alongside this in `_physics_process()`), unsquashed,
## since physics stays in the plain 2D plane and only the drawn offset carries `OBLIQUE_Y`.
var _pram_offset := Vector2.ZERO

## The current eight-direction projection, shared by both draw calls so mother and pram cannot
## disagree about which way the rig faces. Starts south to match the default `facing`.
var _view_direction := 2
var _walk_phase := 0.0
## How long her own movement input stays ignored, set by `detain()`. Velocity is not touched here —
## it runs out through the ordinary friction the same as letting go of every key would, which is
## what makes a capture look like stopping rather than like being frozen. See `chatting_mother`.
var _detained_for := 0.0
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

## The point the camera is easing onto instead of following her — set by `focus_camera_on()`,
## cleared by `release_camera_focus()`. Read by `_update_camera()`, the only place any of this
## group is used.
var _camera_focused := false
var _camera_focus_point := Vector2.ZERO
## Where the current ease started and how long it has been running — smooth-stepped over
## `Tuning.CAMERA_EASE_SECONDS` rather than snapped, whether easing onto a focus or back to her.
var _camera_ease_from := Vector2.ZERO
var _camera_ease_elapsed := 0.0
## Whether the camera is easing back to her after a focus ended, as opposed to the ordinary
## per-frame follow `_update_camera()` gives her while walking — the one flag that keeps the two
## from fighting over `_camera.global_position` in the same frame.
var _camera_easing_back := false

func _ready() -> void:
	add_to_group("player")
	if _pram_collision:
		_pram_collision.disabled = carrying

## Takes her out of the world without taking her out of the tree, for the title screen's attract
## mode: the home and the street in front of it, with nobody in it.
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
## callback. A paused camera therefore never travels to the thing it is following: it stays at the
## world origin, clamped to the corner of the boundary wall, while the whole crowd walks about the
## doorstep a thousand pixels off-camera — an empty title screen, with nothing whatever wrong with
## the thing it is supposed to be showing.
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

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _detained_for > 0.0:
		_detained_for = maxf(0.0, _detained_for - delta)
		# Ignored rather than read: the run key doing nothing during a capture falls out of this
		# for free, since `top_speed` below is only ever reached through a nonzero `input_dir`.
		input_dir = Vector2.ZERO
	input_dir = _redirect_along_a_flight(input_dir)
	var top_speed := Tuning.RUN_SPEED if Input.is_action_pressed("run") else Tuning.WALK_SPEED

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * top_speed, Tuning.ACCELERATION * delta)
		_turn_toward(input_dir.normalized(), delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, Tuning.FRICTION * delta)
	_update_view()
	_pram_offset = Vector2.ZERO if carrying \
			else Vector2(facing.x, facing.y * OBLIQUE_Y) * PRAM_DISTANCE
	if _pram_collision:
		# Unsquashed, unlike `_pram_offset` above: the collision body stays in the plain 2D plane
		# every other body in the game collides in, on the circumference of her own
		# `Tuning.PLAYER_BODY_RADIUS` circle rather than out at the pram's drawn `PRAM_DISTANCE`.
		_pram_collision.position = facing * Tuning.PLAYER_BODY_RADIUS
	move_and_slide()

	# The deflection is moved separately rather than added to `velocity`, which stays what she
	# is steering. Folding it in would have made `is_idle()` and `run_excess_ratio()` — the two
	# questions the baby asks the rig — answer for the crowd rather than for the player.
	if _shove != Vector2.ZERO:
		move_and_collide(_shove * delta)
		_shove = _shove.move_toward(Vector2.ZERO, Tuning.FRICTION * delta)
	_walk_phase = wrapf(_walk_phase + velocity.length() * delta * 0.09, 0.0, TAU)

	# Stride cadence is driven by distance covered, so it stays in step at any speed.
	_alert_phase = wrapf(_alert_phase + delta, 0.0, 1.0)
	_alert_left = maxf(0.0, _alert_left - delta)
	if _alert_left <= 0.0:
		_alert = Alert.NONE
	_update_camera(delta)
	queue_redraw()

## On a diagonal flight tile, a sideways press walks the slope rather than the screen axis it was
## pressed on — *(2026-09-10, playtest 55: "holding right or left on the switchback stairs moves
## the player diagonally")*. `slope_dir_at` answers `+1` on a tile descending toward east, `-1`
## toward west, `0` everywhere else (including a flat landing); off a flight, or outdoors where the
## callable was never set, `raw` is returned unchanged.
##
## The redirection reads only `raw.x`'s **sign**, never its `y` component or which device pressed
## it — key, tap and joystick share this one call. Pressing *toward* the flight's own descending
## side (`sign(raw.x) == slope`) walks toward its lower end; pressing the other way climbs toward
## its upper end; a press with no horizontal component (`raw.x == 0`, including a pure up/down
## press) moves nowhere, since there is no floor beside the tread to step onto. The result keeps
## `raw`'s own magnitude, so an analog joystick still climbs or descends at partial speed.
func _redirect_along_a_flight(raw: Vector2) -> Vector2:
	if not slope_dir_at.is_valid():
		return raw
	var slope: int = slope_dir_at.call(global_position)
	if slope == 0:
		return raw
	if raw.x == 0.0:
		return Vector2.ZERO
	var sign_matches := 1.0 if signf(raw.x) == signf(slope) else -1.0
	return Vector2(slope, 1.0).normalized() * sign_matches * raw.length()

## Locks her own movement input for `seconds` — the one mechanic in the catalogue that takes the
## controls away rather than costing a meter. Called by `EventManager` the frame `chatting_mother`
## decides a conversation has started.
##
## **Takes the longest hold rather than adding them**, the same rule `warn()` uses for the mark: two
## captures can only ever mean one of them is spent trying to start while the other is already
## running, and `EventDef.validate()` refuses a second conversation on an instance that has already
## had one, so this is a defensive maximum rather than something play can actually reach.
##
## Velocity is untouched — it runs out through `Tuning.FRICTION` in `_physics_process`, exactly as
## it would if every key had simply been let go, and the pause menu and the run key are both
## unaffected: pausing stops physics for everybody, and holding run buys nothing when no direction
## is ever read.
func detain(seconds: float) -> void:
	_detained_for = maxf(_detained_for, seconds)

## Whether her own movement input is currently being ignored. For the telemetry, which has to be
## able to tell a capture apart from a player who is simply not moving.
func is_detained() -> bool:
	return _detained_for > 0.0

## A checkpoint's own *"gone inside"* — called by a `redetains` event instance the frame its hold
## starts, on the same `visible` switch `stand_aside()` uses for the same reason: hiding a
## `Node2D` does not touch physics, the meters, `is_detained()`'s own lock, or the `Camera2D`
## riding under it, so the day keeps advancing around a mother the player simply cannot see for a
## moment. The pram, its cue and the alert mark are all drawn from `_draw()`, so one switch is all
## "hidden with her" needs.
func hide_for_inspection() -> void:
	visible = false

## The other half, called the frame the hold ends.
func show_after_inspection() -> void:
	visible = true

## Eases the camera onto `point` instead of following her — a checkpoint's hut or post, currently
## the only caller — over `Tuning.CAMERA_EASE_SECONDS`, smooth-stepped rather than snapped or slid.
## `top_level` is set so the camera's own `global_position` stops being computed from her transform
## for the duration; `release_camera_focus()` is what hands it back.
func focus_camera_on(point: Vector2) -> void:
	_camera_ease_from = _camera.global_position
	_camera_ease_elapsed = 0.0
	_camera_focused = true
	_camera_focus_point = point
	_camera_easing_back = false
	_camera.top_level = true

## Eases the camera back onto her — the other half of `focus_camera_on()`. The target is her *own*
## `global_position`, read fresh every frame in `_update_camera()` rather than captured here, so a
## release that teleports her mid-ease (`teleport_to()`, the same frame a checkpoint's hold ends)
## still arrives at where she actually ends up rather than where she was caught.
func release_camera_focus() -> void:
	_camera_ease_from = _camera.global_position
	_camera_ease_elapsed = 0.0
	_camera_focused = false
	_camera_easing_back = true

## Whether the baby is awake right now — for anything that has to price itself differently by her
## state without ever writing to her meters. `true` with no baby at all, which is what a test rig
## built without one gets: the ordinary behaviour, rather than a silent asleep-shaped one.
func baby_is_awake() -> bool:
	return _baby == null or _baby.state == GameEnums.BabyState.AWAKE

## Puts her at `where` outright — the checkpoint's own teleport, released from a detention on the
## far side of the band she was captured in. Nothing else in this game has ever moved the player;
## everywhere else "where she is" is the honest sum of what she pressed and what the world did to
## it, and a route that could be won by teleporting through a wall would make every closure a
## suggestion.
##
## **Not `move_and_collide()` or `move_and_slide()`.** Both resolve a *displacement* against the
## world she is already touching — the checkpoint's own body is exactly what she is inside of at
## the moment of release, so either would immediately re-collide with the thing she is being moved
## clear of, and a slide along it could walk her back toward the band rather than away from it.
## Setting `global_position` outright is the one honest way to say *this frame, she is simply
## there* — same as `reset_at()` puts her on the doorstep at the start of a day.
##
## Velocity and the shove are both zeroed, not merely left to run out: `_shove`'s own friction is
## keyed to wherever the last contact pushed it, and a residual one now points at the pavement she
## was just standing on — inside the band she is being released from — so letting it run out would
## carry her straight back in. See `EventManager._release_from_door()`, the only caller.
func teleport_to(where: Vector2) -> void:
	global_position = where
	velocity = Vector2.ZERO
	_shove = Vector2.ZERO

## Knocks her off her line. Called by `Crowd` when she walks into somebody: the contact
## displaces them both, so a crowd is something she has to steer through rather than walk over.
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
## A mark that stays up after the thing it warns about has gone is not useful; it is the complaint
## about getting the exclamation marks after the fact, one step later.
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
## can be asked about one. The badge's own two questions are static functions for the same reason.
##
## **There is one reason to step aside and it is conditional**, on the two facings that put the
## pram in her column — `_pram_shares_her_column()`. Walking due towards or away from the viewer,
## "above the pram" is also the exclamation mark's column, and that column is only occupied while
## there is a mark in it.
##
## The rule is one rule: *dodge the mark, and only the mark*. Walking south, "above the pram" is
## over her own chest and nothing about that depends on what else is on screen — which is an
## argument for lifting the cue over her head, and that is `baby_cue_lift()`, not for shoving it
## sideways off the thing it is about. Made unconditional it produces the picture nobody wants: a
## sleeping baby, nothing else happening, and a zzz a full body's width to the right of the pram.
##
## It reads `alert_level()` rather than the flash phase: the mark blinks and the cue beside it
## must not hop back and forth in time with it.
func baby_cue_aside() -> float:
	if not _pram_shares_her_column():
		return 0.0
	if alert_level() == Alert.NONE:
		return 0.0
	return BABY_CUE_ASIDE if facing.x >= 0.0 else -BABY_CUE_ASIDE

## Whether the pram is drawn in her own column, which is the one question both cues below turn on.
##
## **Not *which axis is she mostly facing*.** That answer puts a **diagonal** on the vertical side
## of the line, so a diagonal walk takes the southward lift, over a pram that was never behind her
## to begin with.
##
## Asked as geometry instead, because it is a question about geometry: `pram_offset` carries
## `facing.x` at full `PRAM_DISTANCE`, so the pram is 24px to one side on a diagonal and 34px on
## a due east or west, and only a due north or south leaves it in her column at all. That is
## **six of the eight facings** it has nothing to do on, where the axis test said four.
##
## It is a distance rather than `absf(facing.x) > absf(facing.y)` for a second reason worth
## keeping: `_turn_toward` rotates by an angle and normalises, so on a diagonal the two components
## are equal only to within float noise, and a strict comparison between them lets the cue flicker
## between two positions while she walks in a straight line. A report of the cue moving on its own
## is not worth saving 10px of margin over.
func _pram_shares_her_column() -> bool:
	# Carrying, `pram_offset` in `_draw()` is always `Vector2.ZERO` — the bundle rides at her own
	# position on every facing, so it shares her column on all eight rather than on two.
	if carrying:
		return true
	return absf(facing.x) * PRAM_DISTANCE < Tuning.PLAYER_BODY_RADIUS

## How far above the pram the cue floats, which is more on exactly one of the eight facings.
##
## `BABY_CUE_LIFT` clears the pram's own art, which is all it has to do when the
## pram is the topmost thing under the cue. Walking **due south** it is not: the pram is in front of
## her and therefore *lower* on the screen, so a cue lifted off the pram alone lands over her chest.
## Clearing her as well is what puts it above the pair of them, over the pram's own column, which is
## where a cue about the baby belongs — and it is why the step aside above could stop being
## unconditional.
##
## South**-east** and south-west are not that facing, whatever they have in common with it: the
## pram is already 24px to one side, nothing is behind anything, and the extra `FIGURE_HEIGHT`
## would lift the cue off a pram it is supposed to be sitting on.
func baby_cue_lift() -> float:
	if _pram_shares_her_column() and facing.y > 0.0:
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

## Her own walking follow — `_camera.offset`'s look-ahead lerp — for every frame that is not a
## focus or its own return; a focus takes the camera off her entirely, driven below instead.
func _update_camera(delta: float) -> void:
	if _camera_focused:
		_camera_ease_elapsed += delta
		var t := clampf(_camera_ease_elapsed / Tuning.CAMERA_EASE_SECONDS, 0.0, 1.0)
		_camera.global_position = _camera_ease_from.lerp(
				_camera_focus_point, smoothstep(0.0, 1.0, t))
		return
	if _camera_easing_back:
		_camera_ease_elapsed += delta
		var t := clampf(_camera_ease_elapsed / Tuning.CAMERA_EASE_SECONDS, 0.0, 1.0)
		_camera.global_position = _camera_ease_from.lerp(global_position, smoothstep(0.0, 1.0, t))
		if t >= 1.0:
			# Arrived: hand the camera back to the ordinary parented follow rather than keep
			# driving `global_position` by hand forever. `position = Vector2.ZERO` is exactly what
			# `top_level = false` already means for a camera sitting on her — the ease's own target
			# was her `global_position`, so there is nothing to reconcile.
			_camera_easing_back = false
			_camera.top_level = false
			_camera.position = Vector2.ZERO
			_camera.reset_smoothing()
		return
	var lead := Vector2(facing.x, facing.y * OBLIQUE_Y) * CAMERA_LOOK_AHEAD
	_camera.offset = _camera.offset.lerp(lead, clampf(delta * 3.0, 0.0, 1.0))

## Puts the rig back on the doorstep at the start of a day, stopped and facing the street.
func reset_at(where: Vector2, look: Vector2 = Vector2.DOWN) -> void:
	global_position = where
	velocity = Vector2.ZERO
	facing = look.normalized()
	_shove = Vector2.ZERO
	_detained_for = 0.0
	_alert = Alert.NONE
	_alert_left = 0.0
	_alert_source = &""
	# A day boundary can land mid-hold if the run ends inside one; neither a stuck hidden rig nor
	# a camera still glued to a `top_level` focus should ever survive into the next day.
	visible = true
	_camera_focused = false
	_camera_easing_back = false
	if _camera:
		_camera.top_level = false
		_camera.position = Vector2.ZERO
		_camera.offset = Vector2.ZERO
		_camera.reset_smoothing()
	# A reset has no preceding turn to preserve, so choose `look` directly instead of applying the
	# moving-view hold from whichever direction the last day happened to finish facing.
	_view_direction = _nearest_view_direction()
	_walk_phase = 0.0
	queue_redraw()

## Stops the camera from panning past the edge of the city.
func set_camera_limits(bounds: Rect2) -> void:
	_camera.limit_left = int(bounds.position.x)
	_camera.limit_top = int(bounds.position.y)
	_camera.limit_right = int(bounds.end.x)
	_camera.limit_bottom = int(bounds.end.y)

## Rotates the world in the viewport without asking the device to rotate — see
## `ScreenOrientation`. Every other piece of screen furniture is a `CanvasLayer` and takes
## `ScreenOrientation.rotation_transform()` straight, but the world is drawn on the root viewport's
## own canvas rather than through a `CanvasLayer`, and a `Camera2D`'s `rotation` is the only handle
## on that canvas's transform — so it is kept, rather than folded into the layer mechanism, because
## there is nothing to fold it into.
##
## **The sign is the opposite of `rotation_transform()`'s own +90°, and has to be**: a `Camera2D`
## rotated by `+r` turns the *view* by `-r` — rotating the thing you are looking through one way
## swings what you see through it the other way — so passing `+90°` here once turned the world
## counter-clockwise while every layer turned clockwise, 180° apart. `-90°` turns the view by
## `+90°`, which agrees.
##
## `Camera2D.ignore_rotation` defaults to `true` — a camera's own rotation does nothing to the
## rendered view until this is turned off, which nothing before this needed.
func set_screen_rotation(radians: float) -> void:
	_camera.ignore_rotation = is_zero_approx(radians)
	_camera.rotation = -radians

# ------------------------------------------------------------------ queries ---
# Consumed by `Baby` to decide how the meters move.

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
	# Carrying her in arms rather than pushing her ahead in the pram: there is no second figure
	# and nothing offset in front of her, so the cue over the bundle floats over her own column —
	# see `_draw_baby_cue()` and `baby_cue_lift()`, both of which already treat a zero offset as
	# "shares her column" without a branch of their own.
	var pram_offset := _pram_offset

	# Shadows belong to the ground plane, so they always go underneath both figures.
	shape.draw_shadow(self, Vector2.ZERO)
	var gait := clampf(velocity.length() / Tuning.WALK_SPEED, 0.0, 1.6)
	if carrying:
		_draw_mother(gait)
	else:
		pram_shape.draw_shadow(self, pram_offset)
		if facing.y < 0.0:
			_draw_pram(pram_offset)
			_draw_mother(gait)
		else:
			_draw_mother(gait)
			_draw_pram(pram_offset)

	_draw_baby_cue(pram_offset)
	_draw_alert()

## The stride is two frames rather than a procedural swing: with the legs drawn into the sprite
## there is nothing left to swing. The frames carry the body's bob too, which is why nothing here
## offsets her vertically. The source texture's native size supplies the complete geometry.
func _draw_mother(gait: float) -> void:
	var stepping := gait > 0.05 and sin(_walk_phase * 2.0) > 0.0
	var frame := 1 if stepping else 0
	Sprites.draw_standing(self, _mother_texture(frame), Vector2.ZERO, Vector2.ZERO,
			_mother_is_mirrored())

## The pram has authored front, back, side and diagonal projections. A hood belongs to its own
## three-quarter body plane, rather than sliding across an unchanged basket as the rig turns.
func _draw_pram(at: Vector2) -> void:
	Sprites.draw_standing(self, _pram_texture(), at, Vector2.ZERO, _pram_is_mirrored())

## The mother texture selected by the live drawing path for a gait frame.
func _mother_texture(frame: int) -> Texture2D:
	if carrying:
		if _view_direction == 0 or _view_direction == 4:
			return MOTHER_CARRYING_SIDE[frame]
		if _view_direction == 1 or _view_direction == 3:
			return MOTHER_CARRYING_FRONT_DIAGONAL[frame]
		if _view_direction == 2:
			return MOTHER_CARRYING_FRONT[frame]
		if _view_direction == 5 or _view_direction == 7:
			return MOTHER_CARRYING_BACK_DIAGONAL[frame]
		return MOTHER_CARRYING_BACK[frame]
	if _view_direction == 0 or _view_direction == 4:
		return MOTHER_SIDE[frame]
	if _view_direction == 1 or _view_direction == 3:
		return MOTHER_FRONT_DIAGONAL[frame]
	if _view_direction == 2:
		return MOTHER_FRONT[frame]
	if _view_direction == 5 or _view_direction == 7:
		return MOTHER_BACK_DIAGONAL[frame]
	return MOTHER_BACK[frame]

## West-facing projections mirror their corresponding east-authored SVGs about the feet anchor.
func _mother_is_mirrored() -> bool:
	return EightDirection.is_mirrored(_view_direction)

## The pram texture selected by the live drawing path.
func _pram_texture() -> Texture2D:
	if _view_direction == 0 or _view_direction == 4:
		return PRAM_SIDE
	if _view_direction == 1 or _view_direction == 3:
		return PRAM_FRONT_DIAGONAL
	if _view_direction == 2:
		return PRAM_FRONT
	if _view_direction == 5 or _view_direction == 7:
		return PRAM_BACK_DIAGONAL
	return PRAM_BACK

## West-facing prams share the same explicit east-authored symmetry as the mother.
func _pram_is_mirrored() -> bool:
	return EightDirection.is_mirrored(_view_direction)

## Decides the eight-direction projection for this frame, with hysteresis rather than a single
## switching angle — `EightDirection.update()`, the selector `CrowdAgent`'s walkers now share.
##
## The east/west mirror the side view picks by the sign of `facing.x` needs no hysteresis of its
## own: turning between facing mostly-east and mostly-west at `FACING_TURN_SPEED` sweeps through
## facing mostly-north-or-south on the way, which is deep in the front-or-back band, not near
## either side boundary, so the new direction is already decided by the time either draw function
## reads it.
func _update_view() -> void:
	_view_direction = EightDirection.update(_view_direction, facing)

## The nearest of the eight projections, without the moving-view hysteresis.
func _nearest_view_direction() -> int:
	return EightDirection.nearest(facing)

## How the baby is, drawn where the player is already looking — a zzz above the stroller when the
## baby is asleep, and something louder as the excitement approaches full, rather than a number
## she has to look away from the street to read.
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
## This is the load-bearing cue of the danger vocabulary. Every other mark says *a thing exists*;
## this one says the fairness contract is now about you and the clock has started. The traffic
## needs it as much as the events do, because a lethal car has no telegraph phase to ring.
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
