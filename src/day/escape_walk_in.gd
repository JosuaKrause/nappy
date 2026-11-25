class_name EscapeWalkIn
extends Node
## The escape's last steps: once the city section is won at the threshold of the tunnel or the
## bridge, the game walks her on by herself into the tunnel's dark or across the whole deck, and
## says when she is in (`arrived`), which is when the ending screen comes.
##
## **Nothing can catch her on the way.** The section is already won when this begins
## (`DayController` has ended the day, so no loss path is listening), and whoever starts the walk
## freezes the world around her for it (`main` pauses the tree and leaves only her and this node
## running), so no car, walker or event moves. **No walkable ground is added**: she is led through
## the map's boundary wall (`Stroller.lead()`), over what `CityEdge` draws past the edge.
##
## Each way out is configured by what `CityEdge` draws, never by a number of its own: the tunnel is
## walked as deep as its opening (`CityEdge.TUNNEL_DEPTH_TILES` rows, where the ramp is fully
## dark) and the bridge as far as its deck runs (`CityEdge.BRIDGE_DECK_PX`), both from the map's
## edge, half a tile past the threshold row's centre.

signal arrived

## How fast the game walks her. A run: the deck is a long way over open water.
const SPEED := Tuning.RUN_SPEED

var _player: Stroller = null
var _heading := Vector2.ZERO
var _target := Vector2.ZERO

func _ready() -> void:
	set_physics_process(false)

## Where the walk ends for a way out (`CityExit.Kind`, as an `int`), from its threshold point
## (`DaySpec.exit_points()`: the middle of the carriageway on the spine's last row).
static func _target_for(exit_kind: int, threshold: Vector2) -> Vector2:
	var half_row := Tuning.TILE_SIZE * 0.5
	if exit_kind == CityExit.Kind.TUNNEL:
		return threshold + Vector2(0.0,
				-(half_row + CityEdge.TUNNEL_DEPTH_TILES * float(Tuning.TILE_SIZE)))
	return threshold + Vector2(0.0, half_row + CityEdge.BRIDGE_DECK_PX)

## Takes her by the hand at the threshold of `exit_kind`, whose point on the spine is `threshold`.
func begin(player: Stroller, exit_kind: int, threshold: Vector2) -> void:
	_player = player
	_target = _target_for(exit_kind, threshold)
	_heading = Vector2.UP if exit_kind == CityExit.Kind.TUNNEL else Vector2.DOWN
	set_physics_process(true)
	_steer()

## Whether she is being walked in.
func is_walking() -> bool:
	return _player != null

func _physics_process(_delta: float) -> void:
	if _player == null:
		return
	if (_target - _player.global_position).dot(_heading) <= 0.0:
		var done := _player
		_player = null
		set_physics_process(false)
		done.release()
		arrived.emit()
		return
	_steer()

## Along the way out, bending toward the spine's centre line as she goes.
func _steer() -> void:
	var left := _target - _player.global_position
	_player.lead(Vector2(left.x * 0.05, left.y) if absf(left.y) > 1.0 else _heading, SPEED)
