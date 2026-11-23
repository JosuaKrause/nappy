class_name RoadblockParts
extends RefCounted
## A roadblock's barrier post and the departure its guards walk off by, composed as
## `EventBehaviours.compose()` composes them for a hunting row and handed the figure of a real
## event that stands on the band and that nothing steps. What a suite asks of it is the far guard's
## walk, which its own tick drives once a frame (`tick()`) on the ground and with the word of where
## she is that the suite hands in, and the guard on her side's set-off and start of his walk away
## (`lose_the_guard()`), which sends the far guard off.

## The barrier post: its guards, the near one's set-off and the far one's walk.
var post: EventBarrierPost
## The departure the guard on her side leaves by, which plans the far guard's way out.
var departure: EventDeparture
## The event whose figure they move.
var _host: EventInstance

## The parts of `row` standing on `band` over `map`, told where she is by `where`, with `host`
## put in `t`'s tree so that its body is down. Free it with `release()`.
static func on(t: Node, row: EventDef, band: Vector2, map: WorldMap,
		where: WhereSheIs) -> RoadblockParts:
	var parts := RoadblockParts.new()
	var surroundings := EventSurroundings.new().on(map).hearing(where)
	parts._host = EventInstance.new()
	parts._host.setup(row, band, PackedVector2Array(), Vector2.RIGHT, surroundings)
	t.add_child(parts._host)
	parts._host.set_process(false)
	var composed := EventBehaviours.compose(row, where.handle_for_an_event(),
			EventInstance.Figure.new(parts._host), surroundings.map(), surroundings.navigator(),
			EventInstance.mover_for(row), surroundings.trace(), surroundings.lights(),
			MoveProposal.new())
	parts.post = composed.barrier_post()
	parts.departure = composed.departure()
	return parts

## The guard on her side sets off from his post, and his partner at the far post is sent off the
## frame he starts to walk away: what the event's tick does when his chase is over.
func lose_the_guard() -> void:
	post.leave_the_body()
	departure.begin()

## One frame of the far guard's walk, run as the event's own tick runs it.
func tick(delta: float) -> void:
	post.walk_the_far_guard_off(delta)

## Frees the event the parts stand on.
func release() -> void:
	_host.free()
