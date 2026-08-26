extends Node2D
## Boot scene. Loads the world and shows a debug readout of the values the baby's meters
## will consume in M2, so the movement feel can be tuned against real numbers.

const DEBUG_WORLD := preload("res://scenes/world/debug_world.tscn")

@onready var _status: Label = $CanvasLayer/Status

var _player: Stroller

func _ready() -> void:
	GameState.start_run()
	var world := DEBUG_WORLD.instantiate()
	add_child(world)
	# The world spawns the player, so it only exists after the world's _ready has run.
	_player = get_tree().get_first_node_in_group("player") as Stroller
	var screenshot := AutoScreenshot.from_command_line()
	if screenshot:
		add_child(screenshot)

func _process(_delta: float) -> void:
	if not _player:
		return
	_status.text = "\n".join([
		"NAPPY  -  M1 movement",
		"seed %d   day %d/%d   act %d" % [
			GameState.run_seed, GameState.day, Tuning.RUN_LENGTH_DAYS, GameState.current_act()],
		"",
		"speed      %6.1f px/s" % _player.current_speed(),
		"idle       %s" % ("yes" if _player.is_idle() else "no"),
		"run excess %6.2f" % _player.run_excess_ratio(),
		"facing     %5.2f, %5.2f" % [_player.facing.x, _player.facing.y],
		"",
		"arrows/WASD walk   shift run   esc quit",
	])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().quit()
