extends Node2D
## Boot scene: loads the world, then the HUD (which needs the baby the world spawned).
## The right-hand overlay is a developer readout, not part of the game's UI.

const DEBUG_WORLD := preload("res://scenes/world/debug_world.tscn")
const HUD := preload("res://scenes/ui/hud.tscn")

@onready var _status: Label = $CanvasLayer/Status

var _player: Stroller
var _baby: Baby

func _ready() -> void:
	GameState.start_run()
	add_child(DEBUG_WORLD.instantiate())
	_player = get_tree().get_first_node_in_group("player") as Stroller
	_baby = get_tree().get_first_node_in_group("baby") as Baby
	_apply_meter_override()
	add_child(HUD.instantiate())

	var screenshot := AutoScreenshot.from_command_line()
	if screenshot:
		add_child(screenshot)

func _process(_delta: float) -> void:
	if not _player or not _baby:
		return
	_status.text = "\n".join([
		"seed %d" % GameState.run_seed,
		"",
		"speed       %6.1f" % _player.current_speed(),
		"run excess  %6.2f" % _player.run_excess_ratio(),
		"idle        %6s" % ("yes" if _player.is_idle() else "no"),
		"",
		"incoming    %6.2f /s" % _baby.last_incoming,
		"decay       %6.2f /s" % _baby.last_decay,
		"net         %6.2f /s" % (_baby.last_incoming - _baby.last_decay),
		"",
		"arrows/WASD walk",
		"shift       run",
		"esc         quit",
	])

## Dev flag: `-- --meters <sleepiness> <excitement>` seeds the bars, so a UI state can be
## screenshotted without having to play all the way to it. Applied before the HUD is
## created, which reads the starting values.
func _apply_meter_override() -> void:
	if not _baby:
		return
	var args := OS.get_cmdline_user_args()
	var index := args.find("--meters")
	if index == -1 or index + 2 >= args.size():
		return
	_baby.sleepiness = clampf(float(args[index + 1]), 0.0, Tuning.METER_MAX)
	_baby.excitement = clampf(float(args[index + 2]), 0.0, Tuning.METER_MAX)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().quit()
