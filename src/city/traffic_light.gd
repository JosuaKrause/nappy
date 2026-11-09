class_name TrafficLight
extends ScenerySprite
## One signal head, standing on the corner of a junction and facing the arm it controls.
##
## It is the only thing in the game that tells the player when a main road is safe to cross, so
## it is held to the vocabulary's first rule — *the entity itself carries it* — rather than being
## a coloured dot: the head is drawn, the live lamp is painted in its own place on the head, and
## which lamp is lit is the whole message. There is no caret and no badge, because a signal is
## not a danger that changes over time; it is an instruction that is either given or not.
##
## Feet-anchored like everything else and added to the y-sorted layer, so she walks in front of a
## head on the near kerb and behind one on the far side of the junction.

## Region names on the `street_kit` atlas group — `_enter_tree()`/`_exit_tree()` acquire and
## release it, matching `ClosureMarker`'s own pairing since both belong to the same group.
const HEAD := &"props/signal_head"
const HEAD_BACK := &"props/signal_head_back"
const HEAD_SIDE := &"props/signal_head_side"

## Where each lamp sits on the head, as an offset from the node's feet, and how big the lit patch
## is. Matched by hand to the drawings: all are 42 tall with the lamps at y 2, 8 and 14 from
## the top, and the side view shows a cone under a visor rather than a full disc.
##
## **The three views are the cue.** Four identical heads on one junction say nothing about which
## road each is stopping, and from directly above a head has no face to point with. So the one
## facing down the screen is drawn face-on, the ones facing across it are drawn edge-on, and the
## one facing up the screen — north of the junction, looking at the traffic coming down the spine —
## shows its back and no lamp at all: what you can see of the lamp *is* which street it means, and
## the face-on head across the junction already carries the whole of that arm's message.
const LAMP_HEIGHTS := [-38.0, -32.0, -26.0]
const LAMP_SIZE := Vector2(6.0, 4.0)
const LAMP_SIZE_SIDE := Vector2(3.0, 2.0)
## How far along its own visor the side view's lit cone sits, in px from the post's centre.
const LAMP_SIDE_OFFSET := 3.0

## The junction this head belongs to and which of its two arms it is showing. A head faces the
## traffic it stops, so one junction has up to four of them and each says something different.
var junction := Vector2i.ZERO
var arm_is_vertical := false
## Which way an edge-on head faces, so its visors point at the traffic they are stopping rather
## than away from it. Meaningless for a face-on one.
var _mirrored := false
## Whether this head faces up the screen, away from the camera, so only its back is drawn and no
## lamp is painted. Meaningless for an edge-on one.
var _faces_away := false

var signals: TrafficSignals
## The baked atlas pages this head draws from (`AtlasLibrary`), handed by the city before it is
## added; a head nobody handed one (a suite's) makes its own when it first enters the tree.
var atlas: AtlasLibrary = null
## What the head and its lit lamp are drawn through (`TrafficLightDrawer`), handed by the city
## before the head is added, the same one to every head it stands; a head nobody handed one makes
## its own over its `atlas` when it first enters the tree.
var drawer: TrafficLightDrawer = null

## Mounts the head at `at_junction`, drawing from `library` through `heads` and showing what `lights`
## says, before the city adds it. See `atlas`, `drawer`, `junction` and `signals`.
func mount(library: AtlasLibrary, heads: TrafficLightDrawer, at_junction: Vector2i,
		lights: TrafficSignals) -> void:
	atlas = library
	drawer = heads
	junction = at_junction
	signals = lights

func _enter_tree() -> void:
	if atlas == null:
		atlas = AtlasLibrary.new()
	if drawer == null:
		drawer = TrafficLightDrawer.new(atlas)
	atlas.acquire(&"street_kit")

func _exit_tree() -> void:
	atlas.release(&"street_kit")

## Overrides ScenerySprite.set_scenery_resident.
func set_scenery_resident(resident: bool) -> void:
	super.set_scenery_resident(resident)
	set_process(resident and not _faces_away)

## Overrides ScenerySprite.scenery_bounds.
func scenery_bounds() -> Rect2:
	return Rect2(global_position - Vector2(16, 48), Vector2(32, 64))

## `_lamp()`'s answer while the power is out: no lamp at all, which is what a dead light looks like
## and the whole of how the blackout reaches a signal head.
const DARK := -2

## What was drawn last, so a head redraws on the two or three frames a minute its lamp changes
## rather than on every frame of the day. The lights are the one piece of scenery in this city
## that animates, and there are four at every junction on the spine.
var _lit := -1

## Points an edge-on head at the traffic it stops. `heading` is the way that traffic travels, so
## the visors have to face back down it.
func faces(heading: Vector2) -> void:
	arm_is_vertical = absf(heading.y) > 0.0
	_mirrored = heading.x > 0.0
	# Traffic heading down the screen is stopped by a head that looks back up it.
	_faces_away = heading.y > 0.0

func _process(_delta: float) -> void:
	# Nothing on the back of a head changes with the phase, so it never needs redrawing.
	if _faces_away:
		return
	var lit := _lamp()
	if lit != _lit:
		_lit = lit
		queue_redraw()

## 0 red, 1 amber, 2 green, or `DARK` with the power out. Amber belongs to the arm losing its
## green, so an arm that is neither green nor ambering is simply red — there is no separate
## red-amber.
func _lamp() -> int:
	if not signals:
		return 0
	if not signals.is_powered():
		return DARK
	if signals.green_for(junction, arm_is_vertical):
		return 2
	if signals.amber_for(junction, arm_is_vertical):
		return 1
	return 0

func _draw() -> void:
	if not scenery_resident:
		return
	if arm_is_vertical and _faces_away:
		drawer.draw_head(self, HEAD_BACK, false)
		return
	drawer.draw_head(self, HEAD if arm_is_vertical else HEAD_SIDE, _mirrored)
	var lamp := _lamp()
	# With the power out the head is all that is left: its three lenses are drawn dark in the
	# picture itself, and no lamp is painted over any of them.
	if lamp == DARK:
		return
	drawer.draw_lamp(self, lamp, not arm_is_vertical, _mirrored)
