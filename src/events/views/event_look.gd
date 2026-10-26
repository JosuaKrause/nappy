class_name EventLook
extends RefCounted
## How a live event looks: the picture it is drawn in, the state only that picture keeps, and the
## redraw gate that decides when it is drawn again. A family of rows that draw alike has a look of
## its own (`EventLooks.for_row()` picks it by the row's picture); this base holds what they share.
##
## **A look reads the event and never writes it.** It holds the eight-view sector last drawn, the
## redraw key, the caret's cache and the drawing nodes a long picture is drawn in, and reads the
## event's public state for everything else. What the event does is its behaviours'
## (`src/events/behaviours/`); nothing here decides it.

## The event this look draws.
var event: EventInstance

func _init(owner: EventInstance) -> void:
	event = owner

## The eight-view sector the event is drawn in, for whichever family reads
## `EventPictures.EIGHT_VIEW_BY_SECTOR` instead of a single side-mirrored picture — see
## `_select_view()`. Set by `face()` to the exact nearest sector for the event's own siting, the
## same "no prior-view hold on a fresh placement" rule `EightDirection.nearest()`'s own doc names.
var _view_sector := 2

## Everything `draw()` reads that can change over time, as one comparable value — see
## `_picture_key()` and `redraw_if_the_picture_changed()`. `x` is a bit field and so is never
## negative, which makes this starting value one no key can ever equal: the first tick of an
## event's life always asks for its own draw rather than relying on a coincidence.
var _picture := Vector4i(-1, 0, 0, 0)

## Asks for a redraw when what the event is showing has actually changed.
##
## Moving a `Node2D` does not invalidate its draw list — the transform is applied when the list is
## replayed — so an event only redraws when its **picture** changes, exactly the gate
## `CrowdAgent._end_the_frame()` already gives every walker and car. Most of a
## day's live instances are scenery that never moves — the seals, a checkpoint's hut, a café
## frontage, a market stall, a barricade — and rebuilding their draw lists at the tick rate is the
## largest single drawing cost in a frame, for a picture that is identical every time. See
## `docs/evidence/m124-frame-cost-2026-09-13/README.md`.
##
## **A term missing from the key is a frozen picture rather than a crash**, which is why the key
## below names every time-varying thing `draw()` and `draw_body()` read rather than a plausible
## subset, and why `_picture_never_settles()` stands beside it for the four cases whose picture is
## a continuous function of the clock and could not be named by a key at all.
##
## The key is stored on every tick whether or not it asked for a draw, so the *transition out of*
## a never-settling state — a van that has finished taking its victim — is still a change the
## comparison can see.
##
## **Off screen none of it runs** (`DrawnView`, `_drawn_reach()`): no key, no caret projection and
## no redraw, never-settling pictures included, since most of a day's live instances are off screen
## and the key's caret was the projection's only caller there. The picture is left as it was, and
## the first tick any of it is back inside the box redraws it from what it is now, caret included,
## before the margin has let any of it onto the screen. The drawing nodes (`move_nodes()`) and the
## scenery are still moved and shown. Answers whether it asked for a draw.
func redraw_if_the_picture_changed() -> bool:
	_update_scenery()
	if not _in_the_drawn_view():
		_picture_is_stale = true
		move_nodes()
		return false
	var key := _picture_key()
	var changed := key != _picture or _picture_is_stale
	_picture = key
	_picture_is_stale = false
	var asked := changed or _picture_never_settles()
	if asked:
		event.queue_redraw()
	move_nodes(asked)
	return asked

## True while what the event shows is not being kept current because none of it can be on the
## screen, so the first tick it is back in the box redraws it whatever the key says.
var _picture_is_stale := false

## Whether anything the event draws can be on the screen (`DrawnView`): its own picture, caret
## and spread about its feet, or a drawing node of its own (`_shows_its_nodes()`, the band a
## roadblock's guard left at his post, whose redraw rides on this gate). A flock that is leaving is
## always drawn, since its birds fly off past any reach.
func _in_the_drawn_view() -> bool:
	if event.is_leaving and not event.birds().is_empty():
		return true
	var reach := _drawn_reach()
	if DrawnView.shows(event, reach):
		return true
	return _shows_its_nodes(reach)

## Everything the event can draw about its feet: the row's whole footprint, caret included
## (`EventInstance.footprint_of()`), with the run its own street gives a spread (`drawn_box()`), and
## the caret at its tallest for a row with no picture of its own to carry one, and a picture that
## reaches past it (`_front_box()`, a street fire's whole burning front and its smoke). Worked out
## once: nothing here moves with the event.
func _drawn_reach() -> Rect2:
	if not _drawn_reach_known:
		_drawn_reach_known = true
		_drawn_reach_box = EventInstance.footprint_of(event.def).merge(event.drawn_box()) \
				.merge(EventPictures.largest_mark_rect())
		var front := _front_box()
		if front.has_area():
			_drawn_reach_box = _drawn_reach_box.merge(front)
	return _drawn_reach_box

var _drawn_reach_box := Rect2()

var _drawn_reach_known := false

## How finely the key reads the two continuous quantities it carries: an eighth of a pixel of the
## body's own lift, and a hundred-and-twenty-eighth of the caret's swell, which moves that mark by
## about a tenth of a pixel. Both are well under anything a screen shows at any zoom the game uses,
## so no visible movement is ever held back waiting for a step — and a coarser quantum would
## visibly stair-step a walking event's bob.
const BOB_STEPS_PER_PX := 8.0

const SWELL_STEPS := 128.0

## Whether this row's picture keeps moving between one tick and the next whatever the key says, so
## that gating it on the key at all would freeze an animation.
##
## Four, and each is a continuous function of the clock rather than a frame chosen from a set: a
## **flock**, whose eleven birds each hold their own position, lift and wingbeat phase; a **burning
## building** and a **firefight**, whose flames and muzzle flashes are sized off `sin(age × k)` and
## are drawn rather than authored; and an **abduction mid-take**, whose victim slides from her
## standing offset to the van over `AbductionSpec.taken_over` seconds. Every one of them is a
## handful of instances on a day at most, and none of them was ever going to be gated.
func _picture_never_settles() -> bool:
	if not event.birds().is_empty():
		return true
	if event.is_taking_a_victim():
		return true
	return event.def.look == EventDef.Look.BURNING_BUILDING \
			or event.def.look == EventDef.Look.FIREFIGHT

## Which heading the next draw would pick the event's eight-view sector from.
##
## Ordinarily `EventInstance.facing_now()`. Two exceptions. A robber who has not noticed her yet:
## `PursuerLook._draw_robber()` picks his view from `_robber_waiting_heading()` — her position,
## whenever anything has told the event where she is and nothing built stands between them — rather
## than from the alley he was
## sited facing, so the key has to read the same thing or the one turn in the game that happens
## without the body moving would never reach the screen. And a roadblock guard still standing at his
## band (`barrier_post`, before he has left its body), who is drawn facing out from his post.
func drawn_heading() -> Vector2:
	if event.def.look == EventDef.Look.ROBBER and event.is_waiting():
		return _robber_waiting_heading()
	if event.barrier_post and not event.barrier_post.has_left_its_body():
		return EventInstance.guard_post_heading(event.runs_vertically(), 1)
	return event.facing_now()

## Which pose `RankLook._draw_protest()` is standing its rank in: 0 for anything that is not a
## protest, 1 for the plain pose, and 2..9 for the eight `protester_point_*` bearings in
## `EventPictures.POINTING_POSES`' own order. The objective (`_protest_objective()`) moves when a
## task step is completed, which is the only thing about a protest's picture that changes while
## nothing about the protest does.
func _protest_pose() -> int:
	if event.def.look != EventDef.Look.PROTEST:
		return 0
	return EventPictures.POINTING_POSES.find(EventPictures.protester_texture(event.global_position,
			_protest_objective())) + 2

## Everything `draw()` reads that can change from one tick to the next, as one comparable value.
##
## `x` is a bit field — one bit per question the drawing asks, in an order that is arbitrary and
## only has to be stable. `y` carries the three small integers: the eight-view sector the next draw
## would land on (`_select_view()` is what actually advances `_view_sector`, and it only runs inside
## a draw, so the key has to compute the sector it *would* move to rather than read the one left
## over from the last one), the caret's own 0/1/2 strength, and the protest pose. `z` and `w` are
## the two continuous quantities, quantised — see `BOB_STEPS_PER_PX` and `SWELL_STEPS`.
func _picture_key() -> Vector4i:
	# `_caret_strength()` is cached against `age` and was already asked once per draw through
	# `wants_a_mark()`, so asking it here costs a frame exactly what it always cost.
	var caret := _caret_strength()
	var swell := 0.0
	var flashed_off := false
	if caret > 0:
		swell = mark_swell()
		# The flash is the mark's telegraph phase and takes it off the screen for part of every
		# beat, so it is part of the picture rather than of the mark's size.
		flashed_off = event.is_telegraphing() \
				and fmod(event.age * EventPictures.MARK_FLASHES_PER_SECOND, 1.0) > 0.55
	# **Only the looks that actually read an idle timer carry one.** `_idle_stepping()` is a
	# function of the clock alone and knows nothing about the row asking, so handing it to every
	# instance would flip every seal's key twice a second for an animation it does not have — the
	# gate would then be paying its whole cost and buying nothing. Smoke and fountain phases
	# belong to their own small layers, while the steam is already a cloud-only picture.
	var idle := false
	if event.def.look == EventDef.Look.CAFE:
		idle = _idle_stepping(EventPictures.SITTER_IDLE_PERIOD)
	elif event.def.look == EventDef.Look.BUSKER:
		idle = _idle_stepping(EventPictures.BUSKER_STRUM_PERIOD)
	elif event.def.look == EventDef.Look.POSTER_CREW:
		idle = _idle_stepping(EventPictures.POSTER_CREW_PASTE_PERIOD)
	elif event.def.look == EventDef.Look.STEAM:
		idle = _idle_stepping(EventPictures.STEAM_BILLOW_PERIOD)
	var flags := 0
	flags = flags * 2 + (1 if event.is_finished else 0)
	flags = flags * 2 + (1 if event.is_suppressed_by_its_own_hold() else 0)
	flags = flags * 2 + (1 if event.is_leaving else 0)
	flags = flags * 2 + (1 if _gait_stepping() else 0)
	# The normal dog alone tells its two steps apart (`EventPictures.dog_picture()`), so only its
	# two looks carry the stride's half: every other family draws the same picture in both halves.
	var three_pose_dog := event.def.look in [EventDef.Look.DOG_WALKER, EventDef.Look.LOOSE_DOG]
	flags = flags * 2 + (1 if three_pose_dog and _gait_second_half() else 0)
	flags = flags * 2 + (1 if _heading_is_west() else 0)
	flags = flags * 2 + (1 if event.is_telegraphing() else 0)
	flags = flags * 2 + (1 if event.is_waiting() else 0)
	flags = flags * 2 + (1 if event.is_chatting() else 0)
	flags = flags * 2 + (1 if event.has_stopped_her() else 0)
	flags = flags * 2 + (1 if event.is_its_guard_inside() else 0)
	flags = flags * 2 + (1 if event.is_taking_a_victim() else 0)
	flags = flags * 2 + (1 if _victim_gait_stepping() else 0)
	flags = flags * 2 + (1 if idle else 0)
	flags = flags * 2 + (1 if event.gate_state != null and event.gate_state.raised else 0)
	flags = flags * 2 + (1 if event.guard_warns_her else 0)
	flags = flags * 2 + (1 if EventPictures.gate_runs_north_south(event.facing_now()) else 0)
	flags = flags * 2 + (1 if flashed_off else 0)
	# A mast's lamp and arcs (`FigureLook._draw_mast()`): amber in the telegraph that opens every
	# broadcast cycle, green with the arcs while it speaks, and neither once silenced — read off the
	# city's broadcast clock rather than `is_telegraphing()`, which a mast passes once at creation.
	var mast := event.def.look == EventDef.Look.LOUDSPEAKER_MAST
	flags = flags * 2 + (1 if mast and event.silenced else 0)
	flags = flags * 2 + (1 if mast and _mast_is_telegraphing_now() else 0)
	var sector := EightDirection.update(_view_sector, drawn_heading())
	# A car's picture is anchored on its live heading (`_body_anchor()`), and its shadow and
	# body turn with it, so a car rounding a corner redraws as it turns rather than only when it
	# crosses into another sector. Whole degrees, above the protest's own poses.
	var turn := posmod(roundi(rad_to_deg(event.facing_now().angle())),
			360) if event.def.vehicle != null else 0
	return Vector4i(
			flags,
			sector + 8 * caret + 32 * _protest_pose() + 320 * turn,
			roundi(current_bob() * BOB_STEPS_PER_PX),
			roundi(swell * SWELL_STEPS))

## The whole frame on the event's own canvas: the body, lifted by its bob, and the caret over it.
func draw() -> void:
	# `--skip events` returns before anything below is asked for, so a frame under the flag differs
	# from an ordinary one by drawing alone — the excitement field, the telegraph and everything
	# else `EventInstance` does keep running.
	if event.skip_draw:
		return
	if event.is_finished:
		return
	if event.is_suppressed_by_its_own_hold():
		return
	var bob := current_bob()
	# Told to `Sprites` as well as to the canvas, for the reason `Sprites._base_transform` gives:
	# the mirror inside `draw_standing()` sets an absolute matrix and can read nothing back, so a
	# west-facing family that was not handed this lift would drop it — a dog walker heading west
	# drawn flat while the same walker heading east bobs.
	var lift := Transform2D(0.0, Vector2(0.0, bob))
	Sprites.set_base_transform(lift)
	event.draw_set_transform_matrix(lift)
	draw_body(event)
	Sprites.set_base_transform(Transform2D.IDENTITY)
	event.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_mark()

## **A moving event has to look like it is moving.** Without a gait a dog walker at 32px/s — a
## tile a second, against the player's three — slides along without a leg moving and reads as
## parked, which gets reported as *the dog walkers are not moving* when the movement is fine.
##
## A bob rather than a stride, because the art has legs drawn into it and a sprite cannot swing
## its own. Driven by **distance covered**, not by time, so it is the movement itself that shows:
## something stopped is still, and something fast bobs faster.
##
## Apart from `draw()` so `EntityHalo` can ride the same lift: a walking entity's ring of
## re-drawn bodies has to bob with it, or the outline slides off the sprite it is meant to trace.
##
## **A vehicle rolls rather than strides**: a look in `EventPictures.WHEELS_BY_LOOK` rides
## `WheelBob.lift()` over the ground it has covered while it is covering any, about a pixel on the
## body alone — see `_draw_eight_view()` for the wheels it leaves on the ground — and sits still the
## tick it stops.
func current_bob() -> float:
	if EventPictures.WHEELS_BY_LOOK.has(event.def.look):
		return WheelBob.lift(event.path_travelled()) if event.gait_is_moving() else 0.0
	if event.def.pursuit != null or event.is_leaving:
		return -absf(sin(event.path_travelled() * EventPictures.BOB_PER_PX)) \
				* EventPictures.BOB_HEIGHT
	if event.def.mobile and event.def.speed > 0.0 and event.path.size() > 1 \
			and not event.is_telegraphing_still():
		return -absf(sin(event.path_travelled() * EventPictures.BOB_PER_PX)) \
				* EventPictures.BOB_HEIGHT
	return 0.0

## Which of a family's two gait frames to draw right now: frame b (mid-stride) for half of every
## stride while `EventInstance._advance_gait()` last saw ground covered, frame a (rest) otherwise —
## the walker's own `WalkerLook.gait_frame()` test, `sin(phase * 2.0) > 0.0`, gated on "did anything
## move this tick" instead of a speed floor, since an event's own stop states (`is_waiting()`,
## `is_chatting()`, `is_telegraphing_still()`) already read as zero distance covered rather than a
## small residual speed to floor against. A pure query on state the event's tick already settled, so
## calling it more than once — the main draw, then once per halo ring — always agrees with itself.
func _gait_stepping() -> bool:
	return event.gait_is_moving() and sin(event.gait_phase() * 2.0) > 0.0

## Whether the stride is in its second half — the half a stepping normal dog takes its opposite
## step in (`EventPictures.dog_picture()`). `_gait_stepping()` is true twice per turn of the
## event's `gait_phase()`, once in
## each half, so the two together split the turn into four equal beats: step, rest, opposite step,
## rest, each `PI / 2 / GAIT_RATE` (17.5px) of ground. The dog therefore changes picture exactly
## when the dog walker's own two frames swap, and a whole four-beat walk is 70px: a beat is 545ms
## at the dog walker's 32px/s, close to the 450ms the pictures were reviewed at, and 132ms at the
## loose dog's 132px/s, where the dog is running.
func _gait_second_half() -> bool:
	return event.gait_phase() >= PI

## The victim's own short scripted walk to the van (`EventAbduction`) is a straight-line lerp on
## `age` rather than anything that touches the ground travelled, so it gets its own derived stride
## instead of sharing `gait_phase()` — a persistent field would have nothing to reset between takes
## that the walk's own time (`EventAbduction.walked_for()`) restarting at zero does not already
## give it. The walk is at a constant speed by construction (linear interpolation over a fixed
## time), so the distance covered by moment `t` is exactly `t * (AbductionSpec.standing_offset /
## AbductionSpec.taken_over)`, fed through the same
## `GAIT_RATE` and doubled-phase test `_gait_stepping()` uses. `sin(0) == 0`, so the walk always
## starts on frame a rather than mid-stride.
func _victim_gait_stepping() -> bool:
	if not event.is_taking_a_victim():
		return false
	var elapsed := event.abduction.walked_for()
	var speed := event.def.abduction.standing_offset / event.def.abduction.taken_over
	return sin(elapsed * speed * EventInstance.GAIT_RATE * 2.0) > 0.0

## Whether the café sitters' or the busker's own idle frame is up right now: a plain 50/50 split of
## `period` seconds, offset per event by `idle_offset()` so two placed the same day do not
## swap in lockstep. Driven by `clock()` rather than `age`, the same simulated-time clock `landed()`
## already measures against, so a paused game holds the frame rather than drifting it.
func _idle_stepping(period: float) -> bool:
	var phase := fmod(event.clock() + event.idle_offset() * period, period)
	return phase >= period * 0.5

## The drop shadow under an entity, drawn for the entity itself and skipped for its halo.
##
## *(2026-09-07, the player: "the halo should not include the shadow".)* `EntityHalo` re-runs
## `draw_body()` on its own canvas to trace the silhouette, and the shadow is the first thing
## `draw_body()` puts down — so without this the ellipse got traced too, putting a soft amber lobe
## on the pavement beside every glowing entity. **The shadow is not part of the thing**: it is the
## ground under it, and a cue that means *this is charging you* has nothing to say about the ground.
##
## Routed through here rather than guarded at each of the fifteen call sites, so a `_draw_*` helper
## added later gets the rule by using the same function every other one uses.
func _draw_shadow(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	if canvas == event.rim():
		return
	Sprites.draw_shadow(canvas, at, radius)

## The shadow for a row read off its own `GroundShape` rather than a fixed radius — every
## spread-drawn row (`SpreadLook._draw_spread()`, `RankLook`'s café, protest and firefight,
## `SpreadLook._draw_wide_scene()`'s own fallback) and the stationary vehicles
## (`EventVehicleLook._draw_stationary_vehicle()`). Same halo guard as `_draw_shadow` above, routed
## through `shape.draw_shadow()` along `EventInstance.solid_axis()` — a point shape ignores the
## axis, same as `GroundShape.draw_shadow()` does.
func _draw_shape_shadow(canvas: CanvasItem, shape: GroundShape, at: Vector2 = Vector2.ZERO) -> void:
	if canvas == event.rim():
		return
	shape.draw_shadow(canvas, at, event.solid_axis())

## This row's own body shadow: one `GroundShape` shadow per solid piece, at the piece's own offset
## along the spread axis: one ellipse or capsule for anything that declares no parts, and two
## patches under two cars for the one row that does, so the ground under a crash is dark where the
## cars are and lit where the picture leaves a way through.
##
## `def.draws_body_shadow` opts a row out entirely (its own doc names which) — leaving its
## body and its picture untouched: this is the one function that puts a shadow patch down, so
## refusing here is the whole of "no shadow" rather than a special case at each call site.
func _draw_body_shadow(canvas: CanvasItem, origin := Vector2.ZERO) -> void:
	if not event.def.draws_body_shadow:
		return
	for piece in event.def.parts():
		_draw_shape_shadow(canvas, piece.shape,
				origin + event.spread_at(piece.offset_for(event.runs_vertically())))

## The caret's own answer, 0 (none), 1 (amber) or 2 (doubled red), computed once and cached —
## `wants_a_mark()`, `mark_colour()`, `_draw_mark()` and `_picture_key()` all ask in the same
## frame, and each is a fresh sampling loop over `expected_impact_at()` or `will_be_lethal()` if
## they do not share one. **Cache per frame, the way the halo already does its own once-a-frame
## work**, rather than pricing the projection four times over for every visible source every draw.
##
## **Keyed on where she is as well as on the clock, and the pair is load-bearing.** The answer is
## a projection of this event's course against her position, so it goes stale when either moves —
## and the two do not move together: `player_at` is written by `EventManager` and `ExcitementHalo`
## once a frame, from outside, at whatever point in the frame those nodes run, while
## `redraw_if_the_picture_changed()` asks for the caret at the end of the event's own tick. Keyed
## on `age` alone, the first of those to ask fixes the answer for the whole
## tick, and a caret computed against last frame's position — or against `Vector2.INF`, before
## anything has said where she is at all — is the one that stands.
var _caret_strength_age := -1.0

var _caret_strength_at := Vector2.INF

var _caret_strength_cache := 0

func _caret_strength() -> int:
	if _caret_strength_age == event.age and _caret_strength_at == event.player_at:
		return _caret_strength_cache
	_caret_strength_age = event.age
	_caret_strength_at = event.player_at
	_caret_strength_cache = 0
	# A permanent feature of a fixed map never appears, so there is no moment to mark: the same
	# reason the fairness contract exempts an `AMBIENT` row.
	if not (event.is_finished or event.is_leaving or event.def.kind == GameEnums.EventKind.AMBIENT):
		if event.will_be_lethal(event.player_at):
			_caret_strength_cache = 2
		elif event.expected_impact_at(event.player_at) >= Tuning.EXPECTED_IMPACT_POINTS:
			_caret_strength_cache = 1
	return _caret_strength_cache

## Whether this event is worth a mark at all.
##
## **The mark is raised by what a thing is projected to do to her, held still, and by nothing
## else.** *(2026-09-08, the player: "carets shouldn't be chosen by source value but by expected
## impact value".)* A row's own declared cost does not decide it — `expected_impact_at()` and
## `will_be_lethal()` do, at wherever she is
## actually standing and however this thing is actually moving, so the same row is marked at one
## moment and not at the next: a café she is standing in is unmarked, and a cyclist whose line
## reaches her is marked while one passing wide of her is not.
##
## **A stationary thing never earns a caret.** Held still, nothing about it changes under the
## projection — see `expected_impact_at()` — which is the halo's job from the moment she is in its
## field, not the caret's.
func wants_a_mark() -> bool:
	return _caret_strength() > 0

## How hard the mark is breathing, 0..1, from what the event is emitting right now.
##
## **This is the one thing the ring did that a symbol does not get for free**, and it is
## load-bearing: a pulsing event can be timed and slipped past between beats, and a mark that
## sat there at a constant size would turn the pulse envelope from something to play against
## into something random.
func mark_swell() -> float:
	if event.def.intensity <= 0.0:
		return 1.0
	return clampf(event.current_intensity() / event.def.intensity, 0.0, 1.0)

## What colour the mark is, and it means exactly one thing: **how bad this is.**
##
## **Colour is the wrong channel for a *phase*.** Amber while telegraphing and red once live is a
## good sentence and a cue nobody can read, because of **streaming**: `EVENT_STREAM_RADIUS` is 900px
## and no telegraph in the catalogue is longer than four seconds, so all but the `AHEAD_OF_PLAYER`
## rows finish telegraphing before they are anywhere near the screen. In play that makes amber mean
## *near* and red mean *far*, which is a colour carrying no information and being read as something
## else.
##
## **Follows the strength `_caret_strength()` computed, not `def.hard_fail`.** *(2026-09-08, the
## player: "we can keep the double red == lethal", then "and not all lethal things need a caret
## either".)* A `hard_fail` row still reads doubled red exactly when its own current course would
## put her inside the radius that ends the day — `will_be_lethal()` — and reads amber like anything
## else the rest of the time: a robber waiting in an alley she is not in carries no mark at all
## until he stands up and comes.
##
## So the colour is the scale and the **flash** — visible whether or not she was there when the
## event started — is what says it has not happened yet. See `_draw_mark`.
func mark_colour() -> Color:
	return Palette.MARK_LETHAL if _caret_strength() == 2 else Palette.MARK_COSTLY

## A caret over anything worth looking at, breathing with what it is currently emitting.
##
## What is deliberately *not* here: any drawing of where the danger reaches. Nothing draws a field.
func _draw_mark() -> void:
	if not wants_a_mark():
		return
	# **The flash is the phase**, and the only channel that can carry it: it flashes while
	# telegraphing — *this has not happened yet* — and is steady once it has. The colour cannot do
	# this, because a telegraph is usually over before the event is on screen; a flash is a property
	# of the mark rather than of a moment she had to be present for.
	if event.is_telegraphing() and fmod(event.age * EventPictures.MARK_FLASHES_PER_SECOND,
			1.0) > 0.55:
		return

	var swell := mark_swell()
	# Never all the way to nothing: between beats the mark shrinks, it does not vanish, or a
	# pulsing event would read as flickering in and out of existence.
	var scale := 0.55 + 0.45 * swell
	var at := Vector2(0.0, _picture_drop_now() - (EventPictures.MARK_HEIGHT + 10.0 * swell))
	Sprites.draw_caret(event, at, EventPictures.MARK_WIDTH * scale, mark_colour())
	if _caret_strength() == 2:
		# Doubled, so lethal reads at a glance and never has to be told apart by hue.
		Sprites.draw_caret(event, at - Vector2(0.0, EventPictures.MARK_WIDTH * scale * 0.85),
				EventPictures.MARK_WIDTH * scale, mark_colour())

## The rectangle, in the event's own space, the caret `_draw_mark()` would draw this frame — its one
## or two chevrons at their swell, outline included — or an empty one when no mark is wanted. The
## same arithmetic the drawing does, so a test can ask what is actually drawn.
func mark_rect() -> Rect2:
	if not wants_a_mark():
		return Rect2()
	var swell := mark_swell()
	var width := EventPictures.MARK_WIDTH * (0.55 + 0.45 * swell)
	var at := Vector2(0.0, _picture_drop_now() - (EventPictures.MARK_HEIGHT + 10.0 * swell))
	var top := at.y - width * 0.8
	if _caret_strength() == 2:
		top -= width * 0.85
	var outline := 1.0
	return Rect2(-width - outline, top - outline, (width + outline) * 2.0,
			at.y + width * 0.5 + outline - (top - outline))

## The rectangle, in the event's own space, of what it draws this frame: its picture (the box of
## every picture its look can draw, since which view is drawn turns with its heading), its shadow at
## its feet, its danger caret as `_draw_mark()` would draw it now (`mark_rect()`, which asks the
## event's own projection of her), and a picture that reaches past its footprint (`_front_box()`, a
## street fire's whole burning front and smoke). What `tests/test_no_pop_in.gd` checks against the
## view on a thing's first frame: the caret is measured from the drawing's own numbers, not from
## `EventInstance.footprint_of()`'s worst case, so a footprint that leaves it out fails there.
func drawn_rect_now() -> Rect2:
	var rect := event.drawn_box()
	for picture in EventPictures.family_sources(event.def.look):
		var size := EventPictures.native_size(picture)
		if size.x > 0.0 and size.y > 0.0:
			rect = rect.merge(Rect2(-size.x * 0.5, -size.y, size.x, size.y))
	if event.def.draws_body_shadow and event.def.shape != null:
		var r := event.def.obstructs_radius if event.def.obstructs_radius > 0.0 \
				else event.def.shape.radius
		rect = rect.merge(Rect2(-r, -r, r * 2.0, r * 2.0))
	if event.def.look == EventDef.Look.LOOSE_DOG:
		var behind := EventInstance.LOOSE_LEAD_REACH if _heading_is_west() \
				else -EventInstance.LOOSE_LEAD_REACH
		rect = rect.merge(Rect2(Vector2(minf(behind, 0.0), -8.0),
				Vector2(absf(behind), 6.0)).grow(1.0))
	rect.position.y += current_bob()
	if event.rim() != null:
		rect = rect.grow(EntityHalo.HALO_MARGIN)
	var mark := mark_rect()
	if mark.has_area():
		rect = rect.merge(mark)
	var front := _front_box()
	if front.has_area():
		rect = rect.merge(front)
	return rect

## Draws the body onto `canvas`: the event itself for the ordinary frame, or `EntityHalo` once per
## ring offset to trace the silhouette. Nothing while its own hold hides it.
func draw_body(canvas: CanvasItem) -> void:
	if event.is_suppressed_by_its_own_hold():
		return
	_draw_figure(canvas)

## What this family draws for its row, on `canvas`. Nothing here: a row with no picture of its own
## (`NONE`, and `BURNT_SHELL`, which is drawn on the building it stands against).
func _draw_figure(_canvas: CanvasItem) -> void:
	pass

## A shadow and a sprite, facing the way it is going. What most looks are, and having it once is
## what keeps a dozen near-identical three-line functions from existing.
##
## `picture_b` is `mouse`'s own second frame, read off `_gait_stepping()` when given; `""` for
## everything else this draws (`skip`, and `mouse` before its own dash starts), which keeps every
## other caller exactly as it was.
func _draw_simple(picture: String, canvas: CanvasItem,
		picture_b: String = "") -> void:
	_draw_body_shadow(canvas)
	var drawn := picture_b if not picture_b.is_empty() and _gait_stepping() else picture
	Sprites.draw_standing(canvas, EventPictures.drawn(drawn), Vector2.ZERO, Vector2.ZERO,
			_heading_is_west())

## Where a car's picture is anchored for `Sprites.draw_standing`, which bottom-centres it — a car
## that drives, the patrol car or the fire engine (`EventPictures.is_anchored_over_its_body()`):
## **the drawn content's bottom edge lands on the southernmost point of its body**, the crowd car's
## own registration rule (`CarLook.body_anchor()`), because every view is a standing elevation whose
## bottom row is the car's nearest ground contact. The body is its `shape`, a capsule centred on the
## node and laid along the heading (`EventDef.vehicle`), so its southern reach is `half_length ·
## |heading.y| + radius` — the patrol car's 12px driving east or west, 21 north or south — plus the
## view's own canvas margin (`EventPictures.canvas_margins()`), and the picture sits over the body
## she walks into rather than standing in front of it. Read off the live heading rather than the
## quantised view, the crowd car's reason: the body turns continuously as a car rounds a corner, and
## a picture anchored on the view would jump at every sector boundary. The caret over it is lowered
## by the same amount (`_picture_drop_now()`).
func _body_anchor(view: String) -> Vector2:
	var south := event.def.shape.half_length * absf(event.solid_axis().y) + event.def.shape.radius
	return Vector2(0.0, south + float(EventPictures.canvas_margins(event.def.look).get(view, 0.0)))

## How far below its own node the event's picture is drawn this frame — a car's
## `_body_anchor()`, zero for every other row — so the caret over it stands the same height
## above the picture as it does over anything else.
func _picture_drop_now() -> float:
	if not EventPictures.is_anchored_over_its_body(event.def.look) or event.def.shape == null:
		return 0.0
	return _body_anchor(EventPictures.EIGHT_VIEW_BY_SECTOR[_view_sector]).y

func _draw_eight_view(by_view: Dictionary, heading: Vector2, canvas: CanvasItem,
		side_faces_west := false, by_view_b: Dictionary = {}, draw_shadow := true,
		at := Vector2.ZERO) -> void:
	var wheels_by_view: Dictionary = EventPictures.WHEELS_BY_LOOK.get(event.def.look, {})
	var grounded := at
	if not wheels_by_view.is_empty():
		grounded = at + Vector2(0.0, -current_bob())
	if draw_shadow:
		_draw_body_shadow(canvas, grounded)
	var view := _select_view(heading)
	var mirror := EightDirection.is_mirrored(_view_sector)
	if view == "side" and side_faces_west:
		mirror = not mirror
	var picture: String = by_view[view]
	if not by_view_b.is_empty() and _gait_stepping():
		picture = by_view_b[view]
	var wheels: String = wheels_by_view.get(view, "")
	var behind := wheels in EventPictures.WHEELS_BEHIND_THE_BODY
	if not wheels.is_empty() and behind:
		Sprites.draw_standing(canvas, EventPictures.drawn(wheels), grounded, Vector2.ZERO, mirror)
	Sprites.draw_standing(canvas, EventPictures.drawn(picture), at, Vector2.ZERO, mirror)
	if not wheels.is_empty() and not behind:
		Sprites.draw_standing(canvas, EventPictures.drawn(wheels), grounded, Vector2.ZERO, mirror)

## Which way the waiting posture faces: her, whenever a caller has told the event where she is
## (`set_player_at()`) and **nothing built stands between them** (`clear_line_to()`, the test his
## notice asks), since she is the one thing worth turning toward before he has actually noticed
## her — `EventPursuit`'s own `is_waiting()` branch does not turn the event until she is inside
## `EventDef.notice`, see that function's doc. With a building between them he has not seen her, so
## he does not visibly track her round the corner *(leafy-puffin, inbox #648: "yes noticing needs
## a clear line")*: he keeps the facing he was sited with, which is also the harmless default a
## data-level rig with no player position gets.
func _robber_waiting_heading() -> Vector2:
	if event.player_at != Vector2.INF:
		var toward := event.player_at - event.global_position
		if toward.length_squared() > 0.0001 and event.clear_line_to(event.player_at):
			return toward
	return event.facing_now()

## Whether the mast is in the silent, amber-lamped warning that opens every broadcast cycle right
## now — `Tuning.MAST_FIRST_DAY`'s own "a 3s telegraph, a 22s period", read off `age` because a
## mast's `age` **is** the city's broadcast clock (`EventManager._broadcast_clock`, carried in at
## every `resume()`), not a per-instance clock that started whenever she happened to walk up.
## That is what makes the telegraph repeat every period rather than firing once at creation the way
## `is_telegraphing()` does for an ordinary row, and what keeps two masts met minutes apart in the
## same phase of it. `current_intensity()`'s own cosine pulse is untouched by this — the field
## keeps swelling and fading on the same clock; this only decides the lamp and the arcs.
func _mast_is_telegraphing_now() -> bool:
	if event.def.pulse_period <= 0.0:
		return false
	return fmod(event.age, event.def.pulse_period) < event.def.telegraph_time

## Where a protest points: what the event was handed to ask (`EventInstance.points_at`), or
## `Vector2.INF`, nothing to point at, when it was handed nothing.
func _protest_objective() -> Vector2:
	if not event.points_at.is_valid():
		return Vector2.INF
	return event.points_at.call()

## Which way a mobile event is travelling, for art that has a front and a back. A
## stationary event never flips.
func _heading_is_west() -> bool:
	return event.facing_now().x < 0.0

## Advances `_view_sector` from `heading` and returns the view name to read out of whichever
## family's own `_BY_VIEW` table is live — `WalkerLook.sector()`'s own shape, copied
## rather than shared since an event and a walker have no common base to hang one field on. No
## idle floor of its own: every `heading` a caller below feeds in is already a unit vector that is
## never actually zero — a moving actor's heading is only ever overwritten by an actual step or
## an actual notice, and a stationary one's is its own fixed siting — the same reason `Stroller`
## never passes one either (`EightDirection.update()`'s own doc). Safe to call more than once a
## frame with the same heading: `EntityHalo` redraws `draw_body()` once per ring, and asking
## `EightDirection.update()` twice from the same starting sector always answers the same way.
func _select_view(heading: Vector2) -> String:
	_view_sector = EightDirection.update(_view_sector, heading)
	return EventPictures.EIGHT_VIEW_BY_SECTOR[_view_sector]

## Draws `texture` so its own ground anchor lands at `at` (local space, default the body's own
## origin) — `Sprites.draw_standing`'s bottom-centre assumption is wrong for this kit: a boom
## gate's anchor sits between its two posts rather than under the middle of the canvas, and the
## hut's doorway is a few pixels short of the canvas's own bottom edge. No mirroring, unlike
## `Sprites.draw_standing` — nothing in the kit that draws this way ever needs to flip.
func _draw_at_anchor(canvas: CanvasItem, picture: String, anchor: Vector2,
		at: Vector2 = Vector2.ZERO) -> void:
	canvas.draw_texture_rect(EventPictures.drawn(picture), Rect2(at - anchor,
			EventPictures.native_size(picture)), false)

# ------------------------------------------------------------- the drawing nodes ---
# A long picture is drawn in slices that sort against her one by one, and a roadblock's band stands
# as a node of its own (`SpreadLook`, `RoadblockLook`). The event builds, attaches, moves and lets
# go of them through these, at the moments its own node is made, enters and leaves the tree; a look
# with none does nothing.

## Faces the picture along `heading` with no hold from an earlier view, for a fresh placement.
func face(heading: Vector2) -> void:
	_view_sector = EightDirection.nearest(heading)

## Builds the drawing nodes, once, when the event is made.
func build_nodes() -> void:
	pass

## Puts the drawing nodes into the world beside the event. Safe to call again.
func attach_nodes() -> void:
	pass

## Builds the drawing nodes again for an event put back into the tree after they were let go.
func enter_tree() -> void:
	pass

## Keeps the drawing nodes where the body is, shown while the event is, and redrawn when asked.
func move_nodes(_redraw := false) -> void:
	pass

## Lets go of every drawing node, for an event leaving the tree.
func release_nodes() -> void:
	pass

## Hides the scenery a finished event leaves standing until it is freed.
func hide_the_scenery() -> void:
	pass

## The band a roadblock's barrier stands as, or null.
func band_node() -> Node2D:
	return null

## What a rim around the event's own picture stands behind instead of the event, or null for the
## event itself.
func rim_holder() -> Node2D:
	return null

## Draws a roadblock's band at `at` on `canvas`; nothing for any other look.
func draw_the_band(_canvas: CanvasItem, _at: Vector2) -> void:
	pass

## Whether a drawing node of its own can be on the screen when the event's feet are not.
func _shows_its_nodes(_reach: Rect2) -> bool:
	return false

## The scenery's frame for this tick, on a look that has scenery.
func _update_scenery() -> void:
	pass

## A picture that reaches past the event's footprint, such as a street fire's burning front.
func _front_box() -> Rect2:
	return Rect2()
