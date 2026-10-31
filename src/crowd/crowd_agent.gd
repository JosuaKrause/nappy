class_name CrowdAgent
extends LaneMover
## One person or one car, going about its business.
##
## An agent is not an event. An event is authored, telegraphed and held to the fairness
## contract; an agent is traffic, and the player is expected to walk around it rather than
## be warned about it. What the two share is the *source*: each composes an `ExcitementSource`
## (`excitement`, a `CrowdExcitement` here), so nothing pushes a value at the baby and the crowd
## composes with the events by plain addition.
##
## The lane movement is `LaneMover`'s; this is the crowd member on top of it: its excitement, the
## rim and the caret drawn on it, the jolt a contact or a horn leaves, and the drawing.

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

## This body as a thing that charges the baby (`CrowdExcitement`): its field, the jolt a contact or
## a horn leaves and its share of the field, its clock, its ledger of what it has landed, its
## projection and its caret's strength. `ExcitementHalo` tells it once a frame where she is, which
## is the one channel that reaches every body in the crowd whether or not it is near a road.
var excitement := CrowdExcitement.new(self)

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

## The rim `ExcitementHalo` lights on this body (`SourceRim`), handed to its source: built on its
## first nonzero glow and given back once faded, so only the handful `ExcitementHalo.MAX_SOURCES`
## picks ever holds one.
var _rim := SourceRim.new(_build_rim)

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
##
## **It runs on the physics tick, at the end of the agent's step, and nothing of the crowd is left to
## a drawn frame.** Everything the key reads (the velocity, the gait, the bob, the heading, the
## excitement's caret) changes only on a tick, and an interpolated node replays the list it was last
## drawn with wherever the frame puts it, so a drawn frame between two ticks has nothing to redraw.
## The one thing that moves between ticks is the camera, and the drawn box's margin
## (`DrawnView.MARGIN`, two tiles) is far wider than it moves in a tick. **The one exception is a
## marked car's caret while its horn runs**, redrawn every drawn frame by `_process()`.
func _end_the_frame(delta: float) -> bool:
	# The clocks only a crowd member keeps, its excitement's clock and the seconds of agitation a
	# contact or a horn left, run here because every tick that is not skipped ends here.
	excitement.advance(delta)
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
		_was_marked = _carets and excitement.caret_strength() > 0
		queue_redraw()
		return true
	# A marked car draws a caret that can breathe with its own horn, and a projected approach
	# can change its strength frame to frame with nothing else about the picture moving. The
	# one frame after the mark comes down is what takes the caret off again.
	if _carets and (excitement.caret_strength() > 0 or _was_marked):
		_was_marked = excitement.caret_strength() > 0
		queue_redraw()
		return true
	return false

## The frames between two ticks of a marked car whose horn is still running: the caret's breathing
## is redrawn at the screen's rate (`_draw_mark()`), the only crowd drawing that is. A car's bob
## and the walkers' gait are drawn on the tick (30 times a second): redrawing every car on every
## frame would cost the per-frame work the crowd's step on the tick gave up.
func _ready() -> void:
	super._ready()
	set_process(false)

func _process(_delta: float) -> void:
	if not excitement.is_startled():
		set_process(false)
		return
	queue_redraw()

## Builds this body's rim from its look, which a new kind changes.
func _build_rim() -> EntityHalo:
	var halo := EntityHalo.new(_look.draw_body, _look.bob)
	add_child(halo)
	return halo

## This car has hit another one in a junction. It stops dead and sounds off, and then pulls away
## again on its own — `_cruise` is untouched, so recovery is the ordinary acceleration.
##
## The startle is what makes it *loud where it happened* rather than a number written at the baby;
## see `Crowd._collide_in_the_box` for why a collision is this and not a catalogue row. Already
## being startled is enough to skip it, which is the same hysteresis a contact uses: a pair sitting
## inside each other for half a second must cost one crash, not thirty.
func crashed_into() -> void:
	if excitement.is_startled():
		return
	_speed = 0.0
	excitement.startle(Tuning.CAR_HORN_INTENSITY, Tuning.CAR_HORN_DURATION * 2.0,
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
	excitement.rim = _rim

## A new kind brings its look; a walker's stride and a car's travelled ground start afresh with it.
func _kind_installed() -> void:
	_look = CarLook.new(self) if kind == Kind.CAR else WalkerLook.new(self)
	_carets = _look.carets()
	excitement.take_kind(kind)

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
	if canvas == _rim.entity_halo():
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
## Doubled and in `MARK_LETHAL` exactly when `excitement.will_be_lethal()` says the strike box
## reaches her, because a car is exactly as lethal as a `hard_fail` event and being told apart by
## hue is what the doubling exists to avoid. **Breathes with the horn's own decay while one is running** —
## the one thing a ring does that a discrete symbol does not get for free — and holds full size
## the rest of the time, since a projected approach with no jolt running has no envelope of its
## own to breathe with.
func _draw_mark() -> void:
	var strength := excitement.caret_strength()
	if strength <= 0:
		return
	# **Breathes on every drawn frame, not only on the tick.** The jolt runs down by a tick at a time,
	# and the swell is read a fraction of a tick further on (`Engine.get_physics_interpolation_fraction()`
	# of one tick) so the caret shrinks smoothly on a screen faster than 30 frames a second. This is
	# draw-only: nothing in the simulation reads it. `_process()` below redraws a marked car with a
	# jolt running, which is a handful of cars, and stops when the jolt does.
	var ahead := Engine.get_physics_interpolation_fraction() / float(Engine.physics_ticks_per_second)
	var swell := excitement.jolt_swell_after(ahead)
	set_process(excitement.is_startled())
	var scale := 0.55 + 0.45 * swell
	var at := Vector2(0.0, -(MARK_HEIGHT + 10.0 * swell))
	var colour := Palette.MARK_LETHAL if strength == 2 else Palette.MARK_COSTLY
	Sprites.draw_caret(self, at, MARK_WIDTH * scale, colour)
	if strength == 2:
		Sprites.draw_caret(self, at - Vector2(0.0, MARK_WIDTH * scale * 0.85),
				MARK_WIDTH * scale, colour)
